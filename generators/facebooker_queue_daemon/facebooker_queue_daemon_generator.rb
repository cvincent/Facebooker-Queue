class FacebookerQueueDaemonGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.directory "lib/daemons"
      m.file "daemons", "script/daemons", :chmod => 0755
      m.template "facebooker_queue.rb", "lib/daemons/facebooker_queue.rb", :chmod => 0755
      m.template "facebooker_queue_ctl", "lib/daemons/facebooker_queue_ctl", :chmod => 0755
      m.file "daemons.yml", "config/daemons.yml"
    end
  end
end