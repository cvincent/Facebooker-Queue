require 'test_helper'
require 'queue_adapters/beanstalked_adapter'

class BeanstalkedAdapterTest < ActiveSupport::TestCase
  context 'a BeanstalkedAdapter instance' do
    setup do
      @pool = mock
      Beanstalk::Pool.expects(:new).with('localhost:11300').returns(@pool)
      @adapter = BeanstalkedAdapter.new('localhost:11300')
    end
    
    should 'delegate #puts to the Beanstalk::Pool instance' do
      params = { :method => 'a.method', :params => { :key => 'value' }, :use_session => true }
      @pool.expects(:yput).with(params)
      @adapter.put(params)
    end
    
    should 'delegate #get to the Beanstalk::Pool instance #reserve, #delete the job, and return its #ybody' do
      job = mock
      @pool.expects(:stats).returns('current-jobs-ready' => 1)
      @pool.expects(:reserve).returns(job)
      job.expects(:delete)
      job.expects(:ybody).returns(:key => 'value')
      assert_equal @adapter.get, { :key => 'value' }
    end
  end
end