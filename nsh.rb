#!/usr/bin/ruby
# TODO
# exclude servers from group lists
# allow domain suffix
# allow for username per host
# groups of groups
# make host sorting an option
# add configuration file


class Nsh
  require 'optparse'
  require 'rubygems'
  require 'net/ssh'
  require 'ostruct'

  attr_accessor :password, :group_path, :host_list, :host, :ssh_user, :options
  

  def initialize (options)
    @options    = options
    build_host_list
  end

  # Adds to @host_list from groups specified in @options.groups
  def add_groups(group)
    File.readlines(@options.group_path + group).each {|line| @host_list << line.chomp}
  end

  # Adds groups of groups to @host_list
  def add_group_of_groups (group)
    File.readlines(@options.group_path + group).each do |line|
      add_groups(line)
    end
  end

  # Adds a list of individual host to @host_list
  def add_hosts
    @host_list |= @options.hosts
  end

  # This will give us the variable @host_list. These are the hosts that we want
  # to run commmands on
  def build_host_list
    @host_list = []
    @options.groups.each do |group|
      # Group files ending in .g will be processed as a groups of groups
      if group =~ /\.g$/
        add_group_of_groups(group)
      else
        add_groups(group)
      end
    end
    add_hosts
    clean_host_list
    p @host_list
  end

  # Sort and remove dupes from the @host_list
  def clean_host_list 
    @host_list.sort!
    @host_list.uniq!
  end

  # Remove 
  def exclude_servers (exclude)
    exclude.each {|item| @host_list.delete(item)}
  end

  def traverse_servers
  end

  def run_commands (commands = @options.commands)
    @output = Array.new
    @host_list.each do |server|
      puts "---=== #{server} ===---"
      Net::SSH.start(server, @user, :password => password) do |ssh|
        commands.each { |command| ssh.exec(command) }
      end
    end
  end

  def self.parse_flags
    options = OpenStruct.new

    options.banner     = true
    options.commands   = []
    options.exclude    = []
    options.group_path = File.expand_path('~/.nsh/groups') + '/'
    options.groups     = []
    options.hosts      = []
    options.script     = ''
    options.wait       = 0

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} blah blah"
      opts.separator ""
      opts.separator "Specific options:"

      opts.on( '-h', '--help', 'Display this screen') do
        puts opts
        exit
      end

      opts.on('-c', '--command COMMAND', 'Select groups seperated by commas') do |command|
        options.commands << command
      end

      opts.on('-g', '--groups x,y,z', Array, 'Select groups seperated by commas') do |groups|
        options.groups = groups
      end

      opts.on('-H', '--hosts x,y,z', Array, 'List of individual hosts to iterate') do |hosts|
        options.hosts = hosts
      end

      opts.on('-l', '--list GROUP', "List hosts in GROUP") do |group|
        options.list = group
      end

      opts.on('-p', '--group-path PATH', "Set path to group files") do |path|
        options.group_path = path
      end

      opts.on('-s', '--script SCRIPT', 'Execute local script on remote hosts') do |script|
        options.exclude = script
      end

      opts.on('-w', '--wait SEC', 'Time to wait between executing on hosts') do |sec|
        options.wait = seconds
      end

      opts.on('-x', '--exclude x,y,z', 'Exclude specific hosts from listed groups') do |hosts|
        options.exclude = hosts
      end

    end
    opts.parse!

    options
  end

end

if __FILE__ == $0
  nsh = Nsh.new(Nsh.parse_flags)
  nsh.ssh_user = 't-9nburg'
  nsh.run_commands
end

