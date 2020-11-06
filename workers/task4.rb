require_relative 'worker'

class Task4 < Worker

  TAGS = %w[foo]

  def self.serial?
    true
  end

end
