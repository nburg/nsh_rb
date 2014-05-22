#!/usr/bin/ruby

require 'optparse'
require 'io/console'
require 'sshkit'
require 'sshkit/dsl'
  


# Monkey patch sshkit so that run isn't broken by a single failed ssh connection
module SSHKit
  module Backend
    class Netssh
      def _execute(*args)
        command(*args).tap do |cmd|
          output << cmd
          cmd.started = true
          begin
            ssh.open_channel do |chan|
              chan.request_pty if Netssh.config.pty
              chan.exec cmd.to_command do |ch, success|
                chan.on_data do |ch, data|
                  cmd.stdout = data
                  cmd.full_stdout += data
                  output << cmd
                end
                chan.on_extended_data do |ch, type, data|
                  cmd.stderr = data
                  cmd.full_stderr += data
                  output << cmd
                end
                chan.on_request("exit-status") do |ch, data|
                  cmd.stdout = ''
                  cmd.stderr = ''
                  cmd.exit_status = data.read_long
                  output << cmd
                end
                #chan.on_request("exit-signal") do |ch, data|
                #  # TODO: This gets called if the program is killed by a signal
                #  # might also be a worthwhile thing to report
                #  exit_signal = data.read_string.to_i
                #  warn ">>> " + exit_signal.inspect
                #  output << cmd
                #end
                chan.on_open_failed do |ch|
                  # TODO: What do do here?
                  # I think we should raise something
                end
                chan.on_process do |ch|
                  # TODO: I don't know if this is useful
                end
                chan.on_eof do |ch|
                  # TODO: chan sends EOF before the exit status has been
                  # writtend
                end
              end
              chan.wait
            end
            ssh.loop
          rescue => e
            cmd.exit_status = 1
            output << cmd
          end
        end
      end
    end
  end
end


class Nsh

  attr_accessor :host_list, :opts
  
  def initialize (opts = {})
    @opts = {
      commands: [],
      confirm: false,
      group_path: File.expand_path('~/.nsh/groups') + '/',
      groups: [],
      hosts: [],
      user: ENV['USER'],
      wait: 0
    }.merge(opts)
    @host_list = []
    parse_flags
    build_host_list
    add_suffix unless @opts[:suffix] == nil
    set_password if @opts[:set_pass]
    set_sshkit_options
  end

  # Adds to @host_list from groups specified in @opts[:groups]
  def add_group (group)
    File.readlines(@opts[:group_path] + group).each do |line| 
      @host_list << line.chomp
    end
    @host_list
  end

  def add_groups (groups = @opts[:groups])
    groups.each do |group|
    # Group files ending in .g will be processed as a groups of groups
      group =~ /\.g$/ ? add_group_of_groups(group) : add_group(group)
    end
    @host_list
  end

  # Adds groups of groups to @host_list. Need to add a check for loops.
  def add_group_of_groups (group)
    File.readlines(@opts[:group_path] + group).each do |line|
      add_group(line.chomp)
    end
  end

  # Adds a list of individual host to @host_list
  def add_hosts (hosts = @opts[:hosts])
    @host_list |= hosts
  end

  def add_suffix (suffix = @opts[:suffix])
    suffix = '.' + suffix unless suffix =~ /^\./
    @host_list.collect! {|x| x + suffix}
  end

  # This will give us the variable @host_list. These are the hosts that we want
  # to run commmands on
  def build_host_list
    add_groups
    add_hosts
    exclude_hosts unless @opts[:excludes] == nil
    clean_host_list
    @host_list
  end

  # Sort and remove dupes from the @host_list
  def clean_host_list 
    @host_list.sort!
    @host_list.uniq!
  end

  def confirmed?
    puts 'Run the commands:'
    p @opts[:commands]
    puts 'On:'
    p @host_list
    print '[y/n]: '
    confirmation = gets.chomp
    confirmation == 'y'
  end

  # Remove 
  def exclude_hosts (exclude = @opts[:excludes])
    exclude.each {|item| @host_list.delete(item)}
    @host_list
  end

  def run_commands (commands = @opts[:commands])
    on host_list, in: @opts[:mode], limit: @opts[:limit], wait: @opts[:wait] do
      commands.each { |command| execute command, raise_on_non_zero_exit: false }
    end
  end

  def set_password
    print 'Password: '
    @opts[:password] = STDIN.noecho(&:gets)
  end

  def set_sshkit_options
    SSHKit::Backend::Netssh.configure do |ssh|
      ssh.ssh_options = { user: @opts[:user] } if @opts[:user]
    end
    SSHKit.config.output_verbosity = Logger::DEBUG if @opts[:verbose]
  end

  def parse_flags
    op = OptionParser.new do |op|
      op.banner = "Usage: #{$0} -c COMMAND -g GROUP"
      op.separator ""
      op.separator "Specific options:"
      op.on( '-h', '--help', 'Display this screen') do
        puts op
        exit
      end

      op.on('-c', '--command COMMAND',
            'Command to execute. You can have more than one -c'
      ) do |command|
        @opts[:commands] << command
      end

      op.on('--[no-]confirm',
            'To confirm or not to confirm before executing'
      ) do |confirm|
        @opts[:confirm] = confirm
      end
      op.on('-g', '--groups x,y,z', Array,
            'Select groups seperated by commas'
      ) do |groups|
        @opts[:groups] = groups
      end

      op.on('-H', '--hosts x,y,z', Array,
            'List of individual hosts to iterate'
      ) do |hosts|
        @opts[:hosts] = hosts
      end

      @opts[:limit] = 2
      op.on('-l', '--limit LIMIT',
            'Limit groups run to LIMIT hosts at a time.'
      ) do |limit|
        @opts[:limit] = limit.to_i
      end

      op.on('--list GROUP',
            'List hosts in GROUP'
      ) do |group|
        @opts[:list] = group
      end

      @opts[:mode] = :sequence
      op.on('-m', '--mode MODE',
            'Set execution mode to sequence, parallel, or group (s,p,g). Default s.'
      ) do |group|
        case group
        when 's'
          @opts[:mode] = :sequence
        when 'p'
          @opts[:mode] = :parallel
        when 'g'
          @opts[:mode] = :groups
        else
          raise
        end
      end

      op.on('-p', '--[no-]password',
            'Set password'
      ) do |maybe|
        @opts[:set_pass] = maybe
      end

      op.on('-P', '--group-path PATH',
            "Set path to group files"
      ) do |path|
        @opts[:group_path] = path
      end

      remote_user = false
      op.on('-r', '--remote-user REMOTEUSER',
            'Run remote command as REMOTEUSER'
      ) do |remote_user|
        @opts[:remote_user] = remote_user
      end

      op.on('--suffix SUFFIX',
            'Add suffix to domain names listed in groups'
      ) do |suffix|
        @opts[:suffix] = suffix
      end

      op.on('-u', '--user USER',
            'Set user to connect with. Defaults to current user'
      ) do |user|
        @opts[:user] = user
      end

      @opts[:verbose] = false
      op.on('-v', 'Show command output') do
        @opts[:verbose] = true
      end

      op.on('-w', '--wait SEC',
            'Time to wait between executing on hosts'
      ) do |sec|
        @opts[:wait] = sec.to_i
      end

      op.on('-x', '--exclude x,y,z', Array,
            'Exclude specific hosts from listed groups'
      ) do |hosts|
        @opts[:excludes] = hosts
      end
    end
    op.parse!
    @opts
  end
end

if __FILE__ == $0
  nsh = Nsh.new

  confirmed = true
  confirmed = nsh.confirmed? if nsh.opts[:confirm]

  nsh.run_commands if confirmed
end
