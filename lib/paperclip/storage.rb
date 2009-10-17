module Paperclip

  class StorageBackendNotFound < PaperclipError; end

  class Storage
    attr_accessor :attachment

    def self.for(backend)
      Paperclip::Storage.const_get(constantize(backend)).new
    rescue NameError => e
      raise Paperclip::StorageBackendNotFound.new(e.message)
    end

    def self.constantize(string)
      string.to_s.gsub(%r{(?:^|_)[a-z]}){|m| m[-1..-1].upcase }
    end

    def write(path, file)
    end

    def delete(path)
    end

    def rename(old_path, new_path)
    end
  end
end
