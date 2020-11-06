require_relative 'worker'

class Task1 < Worker

  TAGS = %w[foo bar]

  def self.serial?
    true
  end

end
