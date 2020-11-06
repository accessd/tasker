class Worker

  attr_accessor :job_id

  def execute
    number = rand(100..100000)
    log "calc fib #{number}"
    fib(number)

    log 'done!'
  end

  private

  def log(msg)
    puts "[#{Time.now.iso8601(6)}] [#{job_id}] #{msg}"
  end

  def fib(n)
    first_num, second_num = [0, 1]
    (n - 1).times do
      first_num, second_num = second_num, first_num + second_num
    end
    first_num
  end

end
