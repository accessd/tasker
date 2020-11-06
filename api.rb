require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'json'
require 'securerandom'
require './queue'
Dir['./workers/*.rb'].each { |file| require file }

set :bind, '0.0.0.0'
set :port, 3000
$stdout.sync = true

post '/tasks' do
  return [409, 'task_name is not present'] if params[:task_name].nil?
  return [404, 'task not found'] unless Object.const_defined?(params[:task_name])

  task_class = Object.const_get(params[:task_name])
  queue = Queue.new(redis_host: ENV['REDIS_HOST'])
  job_id = SecureRandom.urlsafe_base64(32)
  payload = JSON.generate(
    {
      job_id: job_id,
      worker: params[:task_name],
      serial: task_class.serial?,
      timestamp: Time.now.to_i
    }
  )
  queue.push(payload)

  [200, nil]
end

get '/tasks' do
  queue = Queue.new(redis_host: ENV['REDIS_HOST'])
  json queue.workers_eta
end

######################################################

template :index do
<<EOF
<style>
.ascii-art {
    font-family: monospace;
    white-space: pre;
    width:100%;
    height:100%;
    display:flex;
    justify-content:center;
    align-items:center;
}
</style>
<div class="ascii-art">
 @@@@@@@  @@@@@@   @@@@@@ @@@  @@@ @@@@@@@@ @@@@@@@
   @@!   @@!  @@@ !@@     @@!  !@@ @@!      @@!  @@@
   @!!   @!@!@!@!  !@@!!  @!@@!@!  @!!!:!   @!@!!@!
   !!:   !!:  !!!     !:! !!: :!!  !!:      !!: :!!
    :     :   : : ::.: :   :   ::: : :: :::  :   : :
</div>
EOF
end

get '/' do
  erb :index
end
