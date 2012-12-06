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

  attr_accessor :password, :group_path, :host_list, :host, :ssh_user

  def initialize (options)
    @options    = options
    @groups     = groups
    @hosts      = hosts
    @group_path = File.expand_path("~/.nsh/groups") + "/"
    build_host_list
  end

  def add_groups
    @groups.each do |group|
      if group =~ /\.g$/
        group_groups(group)
      else
        File.readlines(@group_path + group).each {|line| @host_list << line.chomp}
      end
    end
  end

  def group_groups (group)
    File.readlines(@group_path + group).each do |line|
      File.readlines(@group_path + line.chomp).each {|line| @host_list << line.chomp}
    end
  end

  def add_hosts
    @host_list |= @hosts
  end

  def build_host_list
    @host_list = []
    add_groups
    add_hosts
    clean_host_list
    p @host_list
  end

  def clean_host_list 
    @host_list.sort!
    @host_list.uniq!
  end

  def exclude_servers (exclude)
    exclude.each {|item| @host_list.delete(item)}
  end

  def traverse_servers
  end

  def run_commands (commands)
    @output = Array.new
    @host_list.each do |server|
      puts "---=== #{server} ===---"
      Net::SSH.start(server, @user, :password => password) do |ssh|
        commands.each { |command| ssh.exec(command) }
      end
    end
  end

  def parse_flags ()
    options = OpenStruct.new

    options.banner     = true
    options.commands   = []
    options.group_path = '~/.nsh/groups'
    options.groups     = []
    options.hosts      = []
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

      opts.on('-l', '--list GROUP', "List hosts in GROUP") do |group|
        options.list = group
      end

      opts.on('-p', '--group-path PATH', "Set path to group files") do |path|
        options.group_path = path
      end

      opts.on('-h', '--hosts x,y,z', Array, 'List of individual hosts to iterate') do |hosts|
        options.hosts = hosts
      end

      opts.on('-w', '--wait SEC', 'Time to wait between executing on hosts') do |sec|
        options.wait = seconds
      end

    end
    opts.parse!

    options
  end

end

if __FILE__ == $0
  options = parse_flags
  nsh = Nsh.new(Nsh.parse_flags)
  nsh.ssh_user = 't-9nburg'
  nsh.run_commands(options.commands)
end

