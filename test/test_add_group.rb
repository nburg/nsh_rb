#!/usr/bin/ruby

require '../nsh.rb'
require 'test/unit'

class TestNsh < Test::Unit::TestCase
  def setup
    @nsh = Nsh.new(:group_path => File.expand('./') + '/')
  end

  must 'return lines from the file' do
    @nsh = Nsh.new(:group_path => File.expand('./') + '/')
    @nsh.add_group('testgroup')
  end

end
