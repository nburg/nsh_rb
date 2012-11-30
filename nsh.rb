#!/usr/bin/ruby
# TODO
# exclude servers from group lists
# allow domain suffix
# allow for username per host
# groups of groups


class Nsh
	require 'optparse'
	require 'rubygems'
	require 'net/ssh'
	require 'ostruct'

	attr_accessor :password, :group_path, :host_list, :host, :ssh_user

	def initialize (groups, hosts)
		@groups = groups
		@hosts = hosts
		@group_path = "~/.nsh/groups/"
		build_host_list
	end

	def build_host_list ()
		@host_list = []
		@groups.each do |group|
			regroup = File.expand_path(@group_path + group)
			File.readlines(regroup).each {|line| @host_list << line.chomp}
		end
		@host_list |= @hosts
		@host_list.sort!
		@host_list.uniq!
	end

	def check_type (type)
		if type =~ /^(gs\?|s)$/
			print "Error! Type must be \"g\", \"gs\" or \"s\".\n"
			return 1
		else
			type
		end
	end

	def exclude_servers (exclude)
		exclude.each {|item| @host_list.delete(item)}
	end

	def traverse_servers
	end

	def run_commands (commands)
		@output = Array.new
		@host_list.each do |server|
			Net::SSH.start(server, @user, :password => password) do |ssh|
				puts "---=== #{server} ===---"
				commands.each { |command| ssh.exec(command) }
			end
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

if __FILE__ == $0
	options = parse_flags
	p options.commands
	nsh = Nsh.new(options.groups, options.hosts)
	nsh.ssh_user = 't-9nburg'
	nsh.run_commands(options.commands)
end

