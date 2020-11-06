require_relative 'worker'

class Task3 < Worker

  TAGS = %w[baz]

  def self.serial?
    false
  end

end
