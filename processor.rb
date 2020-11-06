require './queue'

$stdout.sync = true
queue = Queue.new(redis_host: ENV['REDIS_HOST'])
queue.process { |r| puts r.inspect }
