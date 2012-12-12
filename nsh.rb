#!/usr/bin/ruby
# TODO
# allow domain suffix
# allow for username per host
# make host sorting an option
# add configuration file
# confirmation flag

class Nsh
  require 'optparse'
  require 'rubygems'
  require 'net/ssh'

  attr_accessor :host_list, :options
  
  def initialize (opts = {})
    @opts   = {
      :banner     => true,
      :commands   => [],
      :excludes   => [],
      :group_path => File.expand_path('~/.nsh/groups') + '/',
      :groups     => [],
      :hosts      => [],
      :script     => '',
      :wait       => 0
    }.merge(opts)
    @host_list = []
  end

  # Adds to @host_list from groups specified in @opts[:groups]
  def add_group(group)
    File.readlines(@opts[:group_path] + group).each do |line| 
      @host_list << line.chomp
    end
  end

  def add_groups
    @opts[:groups].each do |group|
      # Group files ending in .g will be processed as a groups of groups
      if group =~ /\.g$/
        add_group_of_groups(group)
      else
        add_group(group)
      end
    end
  end

  # Adds groups of groups to @host_list. Need to add a check for loops.
  def add_group_of_groups (group)
    File.readlines(@opts[:group_path] + group).each do |line|
      add_groups(line.chomp)
    end
  end

  # Adds a list of individual host to @host_list
  def add_hosts
    @host_list |= @opts[:hosts]
  end

  # This will give us the variable @host_list. These are the hosts that we want
  # to run commmands on
  def build_host_list
    add_groups
    add_hosts
    exclude_hosts if @opts[:excludes] != nil
    clean_host_list
    @host_list
  end

  # Sort and remove dupes from the @host_list
  def clean_host_list 
    @host_list.sort!
    @host_list.uniq!
  end

  # Remove 
  def exclude_hosts (exclude = @opts[:excludes])
    exclude.each {|item| @host_list.delete(item)}
  end

  def run_commands (commands = @opts[:commands], 
                    wait = @opts[:wait], 
                    ssh_user = @opts[:ssh_user], 
                    ssh_password = @opts[:password])
    @output = Array.new
    first_run = true
    @host_list.each do |server|
      sleep wait unless first_run
      puts "---=== #{server} ===---"
      Net::SSH.start(server, ssh_user, :password => ssh_password) do |ssh|
        commands.each { |command| ssh.exec(command) }
      end
      first_run = false
    end
  end

  def run_script
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
      op.on('-g', '--groups x,y,z', Array, 'Select groups seperated by commas') do |groups|
        @opts[:groups] = groups
      end
      op.on('-H', '--hosts x,y,z', Array, 'List of individual hosts to iterate') do |hosts|
        @opts[:hosts] = hosts
      end
      op.on('-l', '--list GROUP', "List hosts in GROUP") do |group|
        @opts[:list] = group
      end
      op.on('-p', '--group-path PATH', "Set path to group files") do |path|
        @opts[:group_path] = path
      end
      op.on('-s', '--script SCRIPT', 'Execute local script on remote hosts') do |script|
        @opts[:script] = script
      end
      op.on('--suffix SUFFIX', 'Add suffix to domain names listed in groups') do |suffix|
        @opts[:suffix] = suffix
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

def get_memory_usage
  `ps -o rss= -p #{Process.pid}`.to_i
end

def nothing
  nsh = Nsh.new(
    :groups     => ['ksplit'], 
    :commands   => ['uptime && whoami'],
    :group_path => File.expand_path('~/.nsh/groups') + '/',
    :exclude    => ['wallaby']
  )
end

if __FILE__ == $0
  nsh = Nsh.new
  nsh.parse_flags
  p nsh.build_host_list
  nsh.run_commands
end
