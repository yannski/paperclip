module Paperclip

  class ProcessorNotFound < PaperclipError; end

  class Processor
    def self.for(processor_name)
      Paperclip::Processor.const_get(constantize(processor_name)).new
    rescue NameError => e
      raise Paperclip::ProcessorNotFound.new(e.message)
    end

    def self.constantize(string)
      string.to_s.gsub(%r{(?:^|_)[a-z]}){|m| m[-1..-1].upcase }
    end

    def make(file, options, attachment = nil)
      file
    end

    class Null < Processor
    end
  end
end
