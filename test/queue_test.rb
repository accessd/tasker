require_relative 'minitest_helper'

describe Queue do
  before do
    @queue = Queue.new(redis_host: 'localhost')
    @queue.clear_all
    @redis = @queue.redis
    @redis.del(Queue::LOCK_SERIAL_KEY)
    @redis.del(Queue::TASK_EXECUTION_TIME_KEY)
    @task = JSON.generate(
      {
        job_id: 'test',
        worker: 'FakeTask',
        serial: false,
        timestamp: Time.now.to_i
      }
    )

    @serial_task = JSON.generate(
      {
        job_id: 'serial',
        worker: 'LongRunningTask',
        serial: true,
        timestamp: Time.now.to_i
      }
    )
  end

  describe '#push' do
    it 'pushes new task to queue' do
      @queue.push(@task)

      expect_task_in_queue
    end
  end

  describe '#process' do
    it 'processes task' do
      @queue.push(@task)
      expect_task_in_queue
      process_tasks
      expect_task_not_in_queue
    end

    it 'locks for processing serial task' do
      @queue.push(@serial_task)
      process_tasks
      expect_serial_lock_exists
    end

    it 'saves execution time of task' do
      @queue.push(@serial_task)
      process_tasks(true)
      expect_execution_time_saved
    end
  end

  describe '#workers_eta' do
    it 'returns tasks with eta' do
      @queue.push(@task)
      @queue.push(@serial_task)

      process_tasks(true)

      current_time = Time.now

      @queue.push(@task)
      @queue.push(@serial_task)

      expect_eta_for_task('FakeTask', current_time)
      expect_eta_for_task('LongRunningTask', current_time)
    end
  end

  begin 'Helper methods'
    def process_tasks(long_running = false)
      processor_pid = fork { @queue.process }
      sleep(long_running ? 3 : 0.1)
      Process.kill('INT', processor_pid)
    end

    def expect_task_in_queue
      task_from_queue = @redis.lindex('tasks', -1)
      task_from_queue.must_equal @task
    end

    def expect_task_not_in_queue
      task_from_queue = @redis.lindex('tasks', -1)
      task_from_queue.must_equal nil
    end

    def expect_serial_lock_exists
      lock_timeout = @redis.get(Queue::LOCK_SERIAL_KEY)
      assert(lock_timeout.to_i > Time.now.to_i)
    end

    def expect_execution_time_saved
      workers_exec_time = @redis.hget(Queue::TASK_EXECUTION_TIME_KEY, 'LongRunningTask').to_i
      workers_exec_time.must_equal LongRunningTask::EXECUTION_TIME
    end

    def expect_eta_for_task(task_name, time)
      eta = @queue.workers_eta.find { |t| t['worker'] == task_name }['eta']
      assert(eta > time)
    end
  end
end
