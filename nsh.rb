#!/usr/bin/ruby
# TODO
# exclude servers from group lists
# allow domain suffix
# allow for username per host


class Nsh
	require 'net/ssh'
	require 'optparse'
	require 'rubygems'
	attr_accessor :password, :group_path

	# Set some defaults

	def initialize (targets, type, user)
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
		p @server_list
	end

	def exclude_servers (exclude)
		exclude.each {|item| @server_list.delete(item)}
	end

	def run_command (commands)
		@output = Array.new
		Net::SSH.start('host', 'user', :password => 'password') do |ssh|
			commands.each do |command|
				ssh.exec!(command)
			end
		end
	end

end

def parse_flags ()
	options = {}
	optparse = OptionParser.new do |opts|
		opts.banner = "Usage: #{$0} [options] domain /doc/root/path"
		options[:drupal] = false
		opts.on('-d', '--drupal', 'Add options for drupal') do 
			options[:drupal] = true
		end
	end
	optparse.parse!
end

if __FILE__ == $0
	conn = Nsh.new(['ksplit', 'ksplit_dev'], 'g')
end

