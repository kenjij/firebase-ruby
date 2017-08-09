require 'logger'


module Firebase

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= NullLogger.new()
  end

  class NullLogger < Logger

    def initialize(*args)
    end

    def add(*args, &block)
    end

  end

end
