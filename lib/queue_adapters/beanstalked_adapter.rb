require 'beanstalk-client'

class BeanstalkedAdapter
  def initialize(*args)
    @beanstalk = Beanstalk::Pool.new(args, 'facebooker-queue')
  end
  
  def put(params)
    @beanstalk.yput(params)
  end
  
  def get
    if @beanstalk.stats_tube('facebooker-queue')['current-jobs-ready'] > 0
      job = @beanstalk.reserve
      job.delete
      job.ybody
    end
  end
end