module Nanite
  class Actor
    def self.default_prefix
      to_s.to_const_path
    end

    def self.expose(*meths)
      @exposed ||= []
      meths.each do |meth|
        @exposed << meth
      end
    end

    def self.provides_for(prefix)
      return [] unless @exposed
      @exposed.map {|meth| "/#{prefix}/#{meth}".squeeze('/')}
    end

    def self.on_exception(proc = nil, &blk)
      raise 'No callback provided for on_exception' unless proc || blk
      if Nanite::Actor == self
        raise 'Method name callbacks cannot be used on the Nanite::Actor superclass' if Symbol === proc || String === proc
        @superclass_exception_callback = proc || blk
      else
        @instance_exception_callback = proc || blk
      end
    end

    def self.superclass_exception_callback
      @superclass_exception_callback
    end

    def self.instance_exception_callback
      @instance_exception_callback
    end
  end

  class ActorRegistry
    attr_reader :actors, :log

    def initialize(log)
      @log = log
      @actors = {}
    end

    def register(actor, prefix)
      raise ArgumentError, "#{actor.inspect} is not a Nanite::Actor subclass instance" unless Nanite::Actor === actor
      log.info("Registering #{actor.inspect} with prefix #{prefix.inspect}")
      prefix ||= actor.class.default_prefix
      actors[prefix.to_s] = actor
    end

    def services
      actors.map {|prefix, actor| actor.class.provides_for(prefix) }.flatten.uniq
    end

    def actor_for(prefix)
      actor = actors[prefix]
    end
  end
end