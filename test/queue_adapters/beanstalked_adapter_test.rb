require 'test_helper'
require 'queue_adapters/beanstalked_adapter'

class BeanstalkedAdapterTest < ActiveSupport::TestCase
  context 'a BeanstalkedAdapter instance' do
    setup do
      Beanstalk::Pool.expects(:new).with([arg='localhost:11300'], 'facebooker-queue').returns(@pool = mock)
      @adapter = BeanstalkedAdapter.new(arg)
    end
    
    should 'delegate #puts to the Beanstalk::Pool instance' do
      params = { :method => 'a.method', :params => { :key => 'value' }, :use_session => true }
      @pool.expects(:yput).with(params)
      @adapter.put(params)
    end
    
    should 'delegate #get to the Beanstalk::Pool instance #reserve, #delete the job, and return its #ybody' do
      @pool.expects(:reserve).returns(mock(:delete => true, :ybody => { :key => 'value' }))
      stats_tube = mock
      stats_tube.expects(:[]).with('current-jobs-ready').returns(1)
      @pool.expects(:stats_tube).with('facebooker-queue').returns(stats_tube)
      assert_equal @adapter.get, { :key => 'value' }
    end
  end
end