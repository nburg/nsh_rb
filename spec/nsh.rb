$: << File.join('../', [File.dirname(__FILE__), "lib"])
require './spec_helper.rb'

describe Nsh do
  before do
    @nsh = Nsh.new(commands: ['uptime'],
                   hosts: ['host1', 'host2'],
                   groups: ['group1', 'group2']
                  )
  end

  describe '.add_group' do
    it 'should add the contents of a groups file to @host_list' do
    end
  end

  describe '.add_hosts' do
    it 'should return a merged list of hosts and set @host_list' do
      hosts_add = ['host3', 'host4']
      @nsh.add_hosts(hosts_add).must_equal ['host1', 'host2', 'host3', 'host4']
      @nsh.host_list.must_equal ['host1', 'host2', 'host3', 'host4']
    end
  end

end
