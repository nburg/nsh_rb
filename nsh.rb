#!/usr/bin/ruby
# TODO
# exclude servers from group lists
# allow domain suffix


class Nsh
	require 'net/ssh'
	require 'optparse'
	require 'rubygems'
	attr_accessor :password, :group_path

	# Set some defaults

	def initialize (targets, type)
		@targets = Array.new
		@targets |= targets
		@group_path = "~/.nsh/groups/"
		set_type(type)

		if @type =~ /^gs?$/
			build_server_list
		end
	end

	def set_type (type)
		if type =~ /^(gs\?|s)$/
			print "Error! Type must be \"g\", \"gs\" or \"s\".\n"
			return 1
		else
			@type = type
		end
	end

	def build_server_list ()
		@server_list = Array.new
		@targets.each do |group|
			regroup = File.expand_path(@group_path + group)
			@server_list |= File.readlines(regroup)
			@server_list.sort!
			@server_list.
		end
		p @server_list
	end

	def parse_flags ()
	end

	def run_command (command)
	end

end

conn = Nsh.new(['ksplit', 'ksplit_dev'], 'g')

