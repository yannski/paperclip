module Paperclip
  module UploadedFile
    attr_accessor :original_filename, :content_type
    def original_filename
      (path if respond_to? :path) || 'default.txt'
    end

    def content_type
      @content_type ||= MIME::Types.of(original_filename).to_s
    end

    def size
      return File.size(path) if respond_to?(:path)
      return self.length if respond_to?(:length)
    end
  end
end
