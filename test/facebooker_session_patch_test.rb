require 'test_helper'

class FacebookerSessionPatchTest < ActiveSupport::TestCase
  context 'A patched Facebooker Session' do
    setup do
      @session_key = '2._krsT8qbb7IxdYWW1BYGIw__.86400.1242284400-205300220'
      @uid = '205300220'
      @expires = 0
      
      @session = Facebooker::CanvasSession.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
      @session.secure_with!(@session_key, @uid, @expires)
    end
    
    context 'calling #queue_service_adapter' do
      should 'work ok if no adapter class has been set' do
        Facebooker.stubs(:facebooker_config).returns({})
        assert_nothing_raised do
          @session.queue_service_adapter
        end
        assert_nil @session.queue_service_adapter
      end
      
      should 'fail if adapter class cannot be found' do
        Facebooker.stubs(:facebooker_config).returns('queue_service_adapter' => 'no_such_thing')
        assert_raise Facebooker::QueueServiceAdapterNotFound do
          @session.queue_service_adapter
        end
      end
      
      should 'return a BeanstalkedAdapter instance' do
        Facebooker.stubs(:facebooker_config).returns('queue_service_adapter' => 'beanstalked', 'queue_pool_address' => 'localhost:11300')
        assert_equal @session.queue_service_adapter.class, BeanstalkedAdapter
      end
    end
    
    context 'calling #queue?' do
      should 'return true if called outside a #sync block and false if called inside a #sync block' do
        assert @session.send(:queue?)
        @session.sync do
          assert !@session.send(:queue?)
          assert !@session.send(:queue?)
        end
        assert @session.send(:queue?)
      end
    end
    
    context 'calling #post' do
      setup do
        @method = 'some.facebookCall'
        @params = { :param => 'value' }
        @use_session = true
      end
      
      should 'delegate to #post_without_async if #queue? returns false' do
        @session.expects(:post_without_async).with(@method, @params, @use_session)
        @session.stubs(:queue?).returns(false)
        @session.post(@method, @params, @use_session)
      end
      
      should "delegate to #post_without_async if it's a never-queued method" do
        @method = 'facebook.application.getPublicInfo'
        @session.expects(:post_without_async).with(@method, @params, @use_session)
        @session.post(@method, @params, @use_session)
      end
      
      should 'pass a hash of the params to #queue_service_adapter if #queue? returns true' do
        mock_adapter = mock
        mock_adapter.expects(:put).with(:method => @method, :params => @params, :use_session => @use_session, :session_key => @session_key, :uid => @uid.to_i, :expires => @expires)
        @session.stubs(:queue_service_adapter).returns(mock_adapter)
        @session.post(@method, @params, @use_session)
      end
      
      context 'within a batch request' do
        should 'only queue the final batch request' do
          mock_adapter = mock
          mock_adapter.expects(:put) # Should only be called once, for facebook.batch.run
          @session.stubs(:queue_service_adapter).returns(mock_adapter)
          
          @session.batch do
            2.times { @session.post(@method, @params, @use_session) }
          end
        end
      end
      
      context "no queue_service_adapter specified" do
        setup do
          @session.stubs(:queue_service_adapter).returns(nil)
        end
        
        should "post with queueing disabled" do
          @session.expects(:post_without_async).with(@method, @params, @use_session)
          @session.post(@method, @params, @use_session)
        end
      end
    end
  end
end