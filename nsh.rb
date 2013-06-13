#!/usr/bin/ruby

require 'optparse'
require 'net/ssh'
require 'io/console'
  
class Nsh

  attr_accessor :host_list, :opts
  
  def initialize (opts = {})
    @opts   = {
      :banner      => true,
      :change_user => false,
      :commands    => [],
      :confirm     => false,
      :group_path  => File.expand_path('~/.nsh/groups') + '/',
      :groups      => [],
      :hosts       => [],
      :script      => '',
      :sort        => true,
      :user        => nil,
      :wait        => 0
    }.merge(opts)
    @host_list = []
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
    @host_list.sort! if @opts[:sort]
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

  def run_commands (commands = @opts[:commands], 
                    wait = @opts[:wait], 
                    user = @opts[:user], 
                    password = @opts[:password])
    @output = Array.new
    first_run = true
    @host_list.each do |server|
      sleep wait unless first_run
      puts "---=== #{server} ===---"
      Net::SSH.start(server, user, :password => password) do |ssh|
        commands.each { |command| ssh.exec(command) }
      end
      first_run = false
    end
  end

  def run_script
  end

  def set_password
    @opts[:password] = STDIN.noecho(&:gets)
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
      op.on('-c', '--command COMMAND', 'Select groups seperated by commas') do |command|
        @opts[:commands] << command
      end
      op.on('--[no-]confirm', 'To confirm or not to confirm before executing') do |confirm|
        @opts[:confirm] = confirm
      end
      op.on('-g', '--groups x,y,z', Array, 'Select groups seperated by commas') do |groups|
        @opts[:groups] = groups
      end
      op.on('-H', '--hosts x,y,z', Array, 'List of individual hosts to iterate') do |hosts|
        @opts[:hosts] = hosts
      end
      op.on('-l', '--list GROUP', 'List hosts in GROUP') do |group|
        @opts[:list] = group
      end
      op.on('-p', '--[no-]password', 'Set password') do |maybe|
        @opts[:set_pass] = maybe
      end
      op.on('-P', '--group-path PATH', "Set path to group files") do |path|
        @opts[:group_path] = path
      end
      op.on('-s', '--script SCRIPT', 'Execute local script on remote hosts') do |script|
        @opts[:script] = script
      end
      op.on('--[no-]sort', 'Sort host execution order') do |sort|
        @opts[:sort] = sort
      end
      op.on('--suffix SUFFIX', 'Add suffix to domain names listed in groups') do |suffix|
        @opts[:suffix] = suffix
      end
      op.on('-u', '--user USER', 'Set user to connect with. Defaults to current user') do |user|
        @opts[:user] = user
      end
      op.on('-w', '--wait SEC', 'Time to wait between executing on hosts') do |sec|
        @opts[:wait] = sec.to_i
      end
      op.on('-x', '--exclude x,y,z', Array, 'Exclude specific hosts from listed groups') do |hosts|
        @opts[:excludes] = hosts
      end
    end
    op.parse!
    @opts
  end
end

if __FILE__ == $0
  nsh = Nsh.new
  nsh.parse_flags
  nsh.build_host_list

  nsh.add_suffix unless nsh.opts[:suffix] == nil
  confirmed = true
  confirmed = nsh.confirmed? if nsh.opts[:confirm]

  if nsh.opts[:set_pass]
    print 'Password: '
    nsh.set_password 
  end

  nsh.run_commands if confirmed
end
