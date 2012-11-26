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

	attr_accessor :password, :group_path, :server_list

	def initialize (targets, type, user = 't-9nburg')
		@targets = Array.new
		@targets |= targets
		@group_path = "~/.nsh/groups/"
		@user = user
		@type = set_type(type)

		if @type =~ /^gs?$/
			build_server_list
		end
	end

	def set_type (type)
		if type =~ /^(gs\?|s)$/
			print "Error! Type must be \"g\", \"gs\" or \"s\".\n"
			return 1
		else
			type
		end
	end

	def build_server_list ()
		@server_list = Array.new
		@targets.each do |group|
			regroup = File.expand_path(@group_path + group)
			@server_list |= File.readlines(regroup)
			@server_list.sort!
			@server_list.uniq!
		end
		@server_list.each_with_index {|line, index| @server_list[index]=line.chomp!}
	end

	def exclude_servers (exclude)
		exclude.each {|item| @server_list.delete(item)}
	end

	def run_command (commands)
		@output = Array.new
		Net::SSH.start(host, user, :password => password) do |ssh|
			commands.each do |command|
				ssh.exec!(command)
			end
		end
	end

end

def parse_flags ()
end

if __FILE__ == $0
	options = {}
	optparse = OptionParser.new do |opts|

		opts.banner = "Usage: #{$0} [options] domain /doc/root/path"

		options[:commands] = nil
		opts.on('-c', '--command', 'Command to run') do |commands|
			options[:commands] = commands
		end

		options[:script] = nil
		opts.on('-x', '--script', 'Run a local bash script on the remote machine') do |script|
			options[:script] = script
		end

		options[:list] = false
		opts.on('-l', '--list-groups', 'List server groups') do 
			options[:list] = true
		end

		options[:commands] = nil
		opts.on('-w', '--wait', 'Time to wait between execution on each server (seconds)') do |commands|
			options[:commands] = commands
		end

		options[:groups] = nil
		opts.on('-g', '--groups', 'Select groups seperated by commas') do  |groups|
			options[:groups] = groups
		end
	end
	optparse.parse!

	if ARGV.empty? && options[:groups].empty?
		puts 'You gots to pick a group sucka!'
		exit 1
	else
		options[:groups] = ARGV[1] 
	end

	#parse_flags
	groups = options[:groups].split(',')
	nsh = Nsh.new(groups, 'g')
	nsh.server_list.each do |server|
	nsh.run_command(optioins[:commands]
	p nsh.server_list
end

