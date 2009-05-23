#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"

$running = true
Signal.trap("TERM") do 
  $running = false
end

worker = FacebookerQueueWorker.new

while($running) do
  worker.process_next!
  sleep 1
end