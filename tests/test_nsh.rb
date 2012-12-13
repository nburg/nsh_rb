#!/usr/bin/ruby

require '../nsh.rb'
require 'test/unit'
require "./test_helper.rb"

class TestNshGroups < Test::Unit::TestCase
  def setup
    @nsh = Nsh.new(:group_path => File.expand_path('./') + '/')
    @tg1 = %w(server1 server2)
    @tg2 = %w(server3 server4 server5)
    @tg3 = %w(server6)
  end

  must 'return lines from the testgroup1' do
    assert_equal @nsh.add_group('testgroup1'), @tg1
  end

  must 'return lines from testgroup 1 and 2' do
    assert_equal @nsh.add_group_of_groups('testgroup.g'), @tg1 + @tg2
  end

  must 'return lines from from testgroup 1 2 and 3' do
    assert_equal @nsh.add_groups(%w(testgroup.g testgroup3)), 
                 @tg1 + @tg2 + @tg3
  end

  must 'return lines from testgroup2' do
    assert_equal @nsh.add_groups(['testgroup2']), @tg2
  end

  must 'return lines from testgroup1 and 2' do
    assert_equal @nsh.add_groups(['testgroup.g']), @tg1 + @tg2
  end
end

class TestNshHosts < Test::Unit::TestCase
  def setup
    @nsh = Nsh.new(:group_path => File.expand_path('./') + '/')
  end

  must 'return server1 server6' do
    assert_equal @nsh.add_hosts(%w(server1 server6)), %w(server1 server6)
  end
  
  must 'return @host_list minus server3' do
    @nsh.host_list = %w(server1 server3 server6)
    assert_equal @nsh.exclude_hosts(['server3']), %w(server1 server6)
  end
end

class TestNshAddSuffix < Test::Unit::TestCase
  def setup
    @nsh = Nsh.new(:group_path => File.expand_path('./') + '/')
  end

  must 'return all items in @hosts_list with suffix added plus preceding dot' do
    @nsh.host_list = %w(server1 server3 server6)
    assert_equal @nsh.add_suffix('bonkers.com'), 
      %w(server1.bonkers.com server3.bonkers.com server6.bonkers.com)
  end
    
  must 'return all items in @hosts_list with suffix added' do
    @nsh.host_list = %w(server1 server3 server6)
    assert_equal @nsh.add_suffix('.bonkers.com'), 
      %w(server1.bonkers.com server3.bonkers.com server6.bonkers.com)
  end
end


