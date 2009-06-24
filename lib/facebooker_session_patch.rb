module Facebooker
  class QueueServiceAdapterNotFound < Exception; end
  class QueueServiceAdapterPoolNotFound < Exception; end
  
  class Session
    def post_with_async(method, params = {}, use_session = true, &proc)
      never_queue = ['facebook.auth.getSession', 'facebook.auth.createToken']
      if never_queue.include?(method) || batch_request? || !queue? || !(qsa = self.queue_service_adapter)
        self.post_without_async(method, params, use_session, &proc)
      else
        qsa.put(
          :method => method, :params => params, :use_session => use_session,
          :session_key => (use_session ? self.session_key : nil),
          :uid => (use_session ? uid : nil),
          :expires => @expires
        )
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
        Facebooker.logger.warn { "No queue_service_adapter defined in facebooker.yml, Facebooker Queue will be turned off!" } and return if (adapter = Facebooker.facebooker_config['queue_service_adapter']).blank?
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