require_relative 'minitest_helper'
require_relative '../api'

describe 'API' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe 'GET /tasks' do
    before do
      get '/tasks'
    end

    it 'responds successfully' do
      last_response.status.must_equal 200
    end
  end

  describe 'POST /tasks' do
    before do
      @queue = Queue.new(redis_host: 'localhost')
      @queue.clear_all
      @redis = @queue.redis
    end

    describe 'without task_name param' do
      it 'responds with 409' do
        post '/tasks'
        last_response.status.must_equal 409
      end
    end

    describe 'task name is unknown' do
      it 'responds with 404' do
        post '/tasks', task_name: 'UnknownTask'
        last_response.status.must_equal 404
      end
    end

    it 'push task to the queue' do
      post '/tasks', task_name: 'FakeTask'
      last_response.status.must_equal 200
      expect_task_in_queue
    end
  end

  begin 'Helper methods'
    def expect_task_in_queue
      task_from_queue = JSON.parse(@redis.lindex('tasks', -1))
      task_from_queue['worker'].must_equal 'FakeTask'
    end
  end
end
