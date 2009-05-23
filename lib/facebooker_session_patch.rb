module Facebooker
  class QueueServiceAdapterNotFound < Exception; end
  class QueueServiceAdapterPoolNotFound < Exception; end
  
  class Session
    def post_with_async(method, params = {}, use_session = true, &proc)
      if batch_request?
        self.post_without_async(method, params, use_session)
      else
        if queue?
          self.queue_service_adapter.put(:method => method, :params => params, :use_session => use_session, :session_key => self.session_key, :uid => uid, :expires => @expires)
        else
          self.post_without_async(method, params, use_session, &proc)
        end
      end
    end
    
    alias_method :post_without_async, :post
    alias_method :post, :post_with_async
    
    def sync(&block)
      @queueing = false
      yield
      @queueing = true
    end
    
    def queue_service_adapter
      if !@queue_service_adapter
        raise QueueServiceAdapterNotFound, "You must define queue_service_adapter in your facebooker.yml!" unless adapter = Facebooker.facebooker_config['queue_service_adapter']
        require "queue_adapters/#{adapter}_adapter"
        @queue_service_adapter = "#{adapter}_adapter".camelize.constantize.new(Facebooker.facebooker_config['queue_pool_address'])
      else
        @queue_service_adapter
      end
    rescue MissingSourceFile
      raise QueueServiceAdapterNotFound, "Could not find queue service adapter '#{adapter}'."
    end
    
    protected
    
    def queue?
      @queueing.nil? ? true : @queueing
    end
  end
end