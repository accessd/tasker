ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, :test)

require 'minitest/autorun'
require 'rack/test'

Dir["#{__dir__}/../workers/*.rb"].each { |file| require file }
require_relative '../queue'

class FakeTask
  attr_accessor :job_id

  def execute
    puts 'fake task!'
  end

  def self.serial?
    false
  end
end

class LongRunningTask
  attr_accessor :job_id
  EXECUTION_TIME = 2

  def execute
    puts 'long running task!'
    sleep EXECUTION_TIME
  end

  def self.serial?
    true
  end
end

