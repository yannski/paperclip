module Paperclip

  class ProcessorNotFound < PaperclipError; end

  class Processor
    def self.for(processor_name)
      Paperclip::Processor.const_get(constantize(processor_name))
    rescue NameError => e
      raise Paperclip::ProcessorNotFound.new(e.message)
    end

    def self.constantize(string)
      string.to_s.gsub(%r{(?:^|_)[a-z]}){|m| m[-1..-1].upcase }
    end

    def self.make(file, options, attachment = nil)
      new(file, options, attachment).make
    end

    attr_accessor :file, :options, :attachment

    def initialize(file, options, attachment = nil)
      @file = file
      @options = options
      @attachment = attachment
    end

    def make
      file
    end

    class Null < Processor; end
  end
end
