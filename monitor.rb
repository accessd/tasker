require './queue'

$stdout.sync = true
queue = Queue.new(redis_host: ENV['REDIS_HOST'])

loop do
  %w(INT TERM).each do |signal|
    Signal.trap(signal) do
      exit
    end
  end

  queue.retry_tasks
  sleep 60
end
