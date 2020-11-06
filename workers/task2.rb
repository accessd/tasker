require_relative 'worker'

class Task2 < Worker

  TAGS = %w[bar]

  def self.serial?
    true
  end

end
