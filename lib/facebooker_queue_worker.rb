class FacebookerQueueWorker
  def initialize
    # Load the facebooker_parser_patch to disable post-processing
    # TODO: Re-enable facebooker's parsing and allow the developer to send a string of Ruby to evaluate against the result
    # Unfortunately, this will involve some reworking of Facebooker::BatchRun
    # because it relies on the in-memory record of the batch call which isn't available at queue processing time
    require 'facebooker_parser_patch'
  end
  
  def process_next!
    if job = queue_service_adapter.get
      facebooker_session.secure_with!(job[:session_key], job[:uid], job[:expires])
      facebooker_session.post_without_async(job[:method], job[:params], job[:use_session])
    end
  end
  
  protected
  
  def facebooker_session
    @session ||= Facebooker::CanvasSession.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
  end
  
  def queue_service_adapter
    @adapter ||= facebooker_session.queue_service_adapter
  end
end