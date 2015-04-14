require 'spec_helper'

describe 'Base Consul Client' do
  include Consul::Client::Base

  before :all do
    # Create a temporary directory that will be cleaned up
    # dir = Dir.mktmpdir('consul-client4r-test', Dir.tmpdir)
    # @pid = Process.spawn("consul agent --server -data-dir=#{dir}")
  end

  after :all do
    # Detach process and then kill it.
    # Process.detach(@pid)
    # Process.kill(:SIGINT, @pid)
  end

  class BaseApiImpl
    include Consul::Client::Base
  end

  it 'should be reachable' do
    expect(BaseApiImpl.new.is_reachable).to eq(true)
  end


end