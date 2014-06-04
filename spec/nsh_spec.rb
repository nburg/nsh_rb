$: << File.join('../', [File.dirname(__FILE__), "lib"])
require_relative './spec_helper.rb'

describe Nsh do
  let(:nsh) { Nsh.new(commands: ['uptime']) }
  let(:group) { 'group1' }
  let(:groups) { groups = %w(group1 group2 group3) }
  let(:hostpool) { %w(host1 host2 host3 host4 host5 host6) }
  let(:expected_hosts) { %w(host1 host2 host3 host4 host5 host6) }

  describe '.add_group' do
    it 'should add the contents of a group file to @host_list' do
      groupfile = File.expand_path("~/.nsh/groups/#{group}")
      File.expects(:readlines).with(groupfile).returns(hostpool)
      nsh.add_group(group)
      nsh.host_list.must_equal expected_hosts
    end
  end

  describe '.add_groups' do
    it 'should add the contents of multiple group files to @host_list' do
      groups.each do |group|
        groupfile = File.expand_path("~/.nsh/groups/#{group}")
        File.expects(:readlines).with(groupfile).returns(hostpool.shift(2))
      end
      nsh.add_groups(groups).must_equal expected_hosts
    end
  end

  describe '.add_hosts' do
    it 'should return a merged list of hosts' do
      nsh.host_list = hostpool.shift(2)
      hosts_add = hostpool.shift(4)
      nsh.add_hosts(hosts_add).must_equal expected_hosts
    end
  end

  describe '.add_suffix' do
    it 'should add a suffix to every entry in @host_list' do
      nsh.host_list = hostpool.shift(2)
      nsh.add_suffix('example.com').must_equal %w(host1.example.com host2.example.com)
    end
  end

  describe '.build_host_list' do
    it 'it should add all hosts from a group file and those specified on the command line' do
      nsh.opts[:hosts] = hostpool.shift(2)
      nsh.opts[:groups] = groups.shift(2)
      nsh.opts[:groups].each do |group|
        groupfile = File.expand_path("~/.nsh/groups/#{group}")
        File.expects(:readlines).with(groupfile).returns(hostpool.shift(2))
      end
      nsh.opts[:excludes] = %w(host3)
      expected_hosts.delete('host3')
      nsh.build_host_list.must_equal expected_hosts
    end

    it 'it should exclude hosts list in @opt[:excludes]' do
      nsh.opts[:hosts] = hostpool
      nsh.opts[:excludes] = %w(host3)
      expected_hosts.delete('host3')
      nsh.build_host_list.must_equal expected_hosts
    end
  end
end
