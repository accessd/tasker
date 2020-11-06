require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'json'
require 'securerandom'
require './queue'
Dir['./workers/*.rb'].each { |file| require file }

queue = Queue.new
300.times do
  num = rand(1..5)
  task_name = "Task#{num}"
  job_id = SecureRandom.urlsafe_base64(32)

  task_class = Object.const_get(task_name)
  queue.push(JSON.generate({job_id: job_id, worker: task_name, serial: task_class.serial?, timestamp: Time.now.to_i}))
end
