require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'json'
Dir['./workers/*.rb'].each { |file| require file }

class Queue

  attr_reader :redis

  SERIAL_TASK_MATCH = /serial":true/
  LOCK_SERIAL_KEY = 'lock:serial'
  LOCK_TIMEOUT = 10
  TASK_EXECUTION_TIME_KEY = 'task_execution_time'

  def initialize(redis_host: 'redis')
    @redis = Redis.new(host: redis_host)
    @queue_name = 'tasks'
    @process_queue = "#{@queue_name}-processing"
  end

  def clear_all
    redis.del @queue_name
    redis.del @process_queue
  end

  def fetch_tasks
    redis.lrange(@queue_name, 0, -1)
  end

  def fetch_processing
    redis.lrange(@process_queue, 0, -1)
  end

  def workers_eta
    tasks = fetch_tasks
    workers_exec_time = redis.hscan_each(TASK_EXECUTION_TIME_KEY).to_h

    total_execution_time = 0

    result = tasks.map do |task|
      next if task.nil? || task.empty?

      parsed_task = JSON.parse(task)
      worker_exec_time = workers_exec_time[parsed_task['worker']]
      next unless worker_exec_time

      total_execution_time += worker_exec_time.to_i
      parsed_task['eta'] = Time.at(Time.now.to_i + total_execution_time)
      parsed_task
    end.compact
  end

  def push(task)
    redis.lpush(@queue_name, task)
  end

  def process
    loop do
      lock_serial_processing do
        task = redis.rpoplpush(@queue_name, @process_queue)
        next if task.nil? || task.empty?

        puts "#{'-' * 30} [#{Time.now.iso8601(6)}] #{'-' * 30}"
        execute_task(task)

        redis.lrem(@process_queue, 0, task)
      end
      sleep 0.1
    end
  end

  private

  def execute_task(task)
    current_time = Time.now.to_i
    parsed_task = JSON.parse(task)
    puts "[#{Time.now.iso8601(6)}] #{parsed_task}"
    worker_class = Object.const_get(parsed_task['worker'])
    worker = worker_class.new
    worker.job_id = parsed_task['job_id']
    worker.execute
    save_elapsed_time(current_time, parsed_task['worker'])
  end

  def save_elapsed_time(current_time, worker_name)
    elapsed = Time.now.to_i - current_time
    redis.hset(TASK_EXECUTION_TIME_KEY, worker_name, elapsed)
  end

  def lock_serial_processing
    task = redis.lindex(@queue_name, -1)
    puts task
    unless task =~ SERIAL_TASK_MATCH
      yield
      return
    end

    puts 'serial task'
    check_for_lock_ttl

    locked = redis.setnx(LOCK_SERIAL_KEY, Time.now.to_i + LOCK_TIMEOUT + 1)
    return if locked

    puts 'lock'
    yield
    redis.del LOCK_SERIAL_KEY
  end

  def check_for_lock_ttl
    lock_ttl = redis.get(LOCK_SERIAL_KEY)
    redis.del LOCK_SERIAL_KEY if lock_ttl && lock_ttl.to_i < Time.now.to_i
  end

end