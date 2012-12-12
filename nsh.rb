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
  

  def initialize (options = {})
    @options   = {
      :banner     => true,
      :commands   => [],
      :excludes   => [],
      :group_path => File.expand_path('~/.nsh/groups') + '/',
      :groups     => [],
      :hosts      => [],
      :script     => '',
      :wait       => 0
    }.merge(options)
    @host_list = []
  end

  # Adds to @host_list from groups specified in @options[:groups]
  def add_groups(group)
    File.readlines(@options[:group_path] + group).each {|line| @host_list << line.chomp}
  end

  # Adds groups of groups to @host_list. Need to add a check for loops.
  def add_group_of_groups (group)
    File.readlines(@options[:group_path] + group).each do |line|
      add_groups(line.chomp)
    end
  end

  # Adds a list of individual host to @host_list
  def add_hosts
    @host_list |= @options[:hosts]
  end

  # This will give us the variable @host_list. These are the hosts that we want
  # to run commmands on
  def build_host_list
    @host_list = []
    @options[:groups].each do |group|
      # Group files ending in .g will be processed as a groups of groups
      if group =~ /\.g$/
        add_group_of_groups(group)
      else
        add_groups(group)
      end
    end
    add_hosts
    exclude_hosts if options[:excludes] != nil
    clean_host_list
    p @host_list
  end

  # Sort and remove dupes from the @host_list
  def clean_host_list 
    @host_list.sort!
    @host_list.uniq!
  end

  # Remove 
  def exclude_hosts (exclude = options[:excludes])
    exclude.each {|item| @host_list.delete(item)}
  end

  def run_commands (commands = @options[:commands], 
                    wait = @options[:wait], 
                    ssh_user = @options[:ssh_user], 
                    ssh_password = @options[:password])
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

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} blah blah"
      opts.separator ""
      opts.separator "Specific options:"

      opts.on( '-h', '--help', 'Display this screen') do
        puts opts
        exit
      end

      opts.on('-c', '--command COMMAND', 'Select groups seperated by commas') do |command|
        @options[:commands] << command
      end

      opts.on('-g', '--groups x,y,z', Array, 'Select groups seperated by commas') do |groups|
        @options[:groups] = groups
      end

      opts.on('-H', '--hosts x,y,z', Array, 'List of individual hosts to iterate') do |hosts|
        @options[:hosts] = hosts
      end

      opts.on('-l', '--list GROUP', "List hosts in GROUP") do |group|
        @options[:list] = group
      end

      opts.on('-p', '--group-path PATH', "Set path to group files") do |path|
        @options[:group_path] = path
      end

      opts.on('-s', '--script SCRIPT', 'Execute local script on remote hosts') do |script|
        @options[:script] = script
      end

      opts.on('-w', '--wait SEC', 'Time to wait between executing on hosts') do |sec|
        @options[:wait] = sec.to_i
      end

      opts.on('-x', '--exclude x,y,z', Array, 'Exclude specific hosts from listed groups') do |hosts|
        @options[:excludes] = hosts
      end

    end
    opts.parse!

    @options
  end
end

def get_memory_usage
    `ps -o rss= -p #{Process.pid}`.to_i
end

def nothing
  nsh = Nsh.new(:groups     => ['ksplit'], 
                :commands   => ['uptime && whoami'],
                :group_path => File.expand_path('~/.nsh/groups') + '/',
                :exclude    => ['wallaby']
               )
end

if __FILE__ == $0
# p options[:groups]
  print get_memory_usage
  nsh = Nsh.new
  nsh.parse_flags
  nsh.build_host_list
  nsh.run_commands
  print get_memory_usage
end


