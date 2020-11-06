require_relative 'worker'

class Task5 < Worker

  TAGS = %w[wat baz]

  def self.serial?
    true
  end

end
