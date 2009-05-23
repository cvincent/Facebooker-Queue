require 'test_helper'
require 'mocha'

class FacebookerQueueWorkerTest < ActiveSupport::TestCase
  context 'a FacebookerQueueWorker instance' do
    setup do
      @worker = FacebookerQueueWorker.new
    end
    
    context 'calling #facebooker_session' do
      should 'return a Facebooker::CanvasSession instance' do
        assert_equal @worker.send(:facebooker_session).class, Facebooker::CanvasSession
      end
    end
    
    context 'calling #queue_service_adapter' do
      should 'delegate to #facebooker_session' do
        session_mock = mock
        adapter_mock = mock
        session_mock.expects(:queue_service_adapter).returns(adapter_mock)
        @worker.stubs(:facebooker_session).returns(session_mock)
        assert_equal @worker.send(:queue_service_adapter), adapter_mock
      end
    end
    
    context 'calling #process_next!' do
      should 'delegate the next message to the #facebooker_session' do
        job = { :method => 'a.facebookMethod', :params => { :key => 'value' }, :use_session => true, :session_key => 'a key', :uid => 654654654, :expires => 0 }
        
        adapter_mock = mock
        adapter_mock.expects(:get).returns(job)
        @worker.stubs(:queue_service_adapter).returns(adapter_mock)
        
        session_mock = mock
        session_mock.expects(:secure_with!).with(job[:session_key], job[:uid], job[:expires])
        session_mock.expects(:post_without_async).with(job[:method], job[:params], job[:use_session])
        @worker.stubs(:facebooker_session).returns(session_mock)
        
        @worker.process_next!
      end
    end
  end
end