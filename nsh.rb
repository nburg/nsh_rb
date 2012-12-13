#!/usr/bin/ruby

require 'optparse'
require 'net/ssh'
require 'io/console'
  
class Nsh

  attr_accessor :host_list, :opts
  
  def initialize (opts = {})
    @opts   = {
      :banner     => true,
      :change_user => false,
      :commands   => [],
      :confirm    => false,
      :excludes   => [],
      :group_path => File.expand_path('~/.nsh/groups') + '/',
      :groups     => [],
      :hosts      => [],
      :script     => '',
      :user       => nil,
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
      add_group(line.chomp)
    end
  end

  # Adds a list of individual host to @host_list
  def add_hosts
    @host_list |= @opts[:hosts]
  end

  def add_suffix
    @host_list.collect! {|x| x + @opts[:suffix]}
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
    if @opts[:sort]
      @host_list.sort!
    end
    @host_list.uniq!
  end

  def confirmed?
    puts 'Run the commands:'
    p @opts[:commands]
    puts 'On:'
    p @host_list
    print '[y/n]: '
    confirmation = gets.chomp
    if confirmation == 'y'
      true
    else
      false
    end
  end

  # Remove 
  def exclude_hosts (exclude = @opts[:excludes])
    exclude.each {|item| @host_list.delete(item)}
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
      op.on('-l', '--list GROUP', "List hosts in GROUP") do |group|
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
      op.on('-u', '--user USER', 'Set user to connect with. Defaults to current user.') do |user|
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

  if nsh.opts[:suffix] != nil
    nsh.add_suffix
  end

  confirmation = true
  confirmation = nsh.confirmed? if nsh.opts[:confirm]
  if nsh.opts[:set_pass]
    print 'Password: '
    nsh.set_password 
  end
  if confirmation
    nsh.run_commands
  end
end
