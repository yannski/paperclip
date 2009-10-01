module Paperclip
  class Attachment
    attr_accessor :name, :options, :model

    def initialize(name, model, options = {})
      @name = name
      @model = model
      @options = options
    end

    def assign(file)
      @queue_for_save   = []
      @queue_for_delete = []

      @queue_for_delete = [path] if present?
      write_model_attribute(:file_name,    nil)
      write_model_attribute(:content_type, nil)
      write_model_attribute(:file_size,    nil)

      return if file.nil?

      write_model_attribute(:file_name,    File.basename(file.original_filename))
      write_model_attribute(:content_type, file.content_type)
      write_model_attribute(:file_size,    file.size)
      @queue_for_save = [file]
    end

    def present?
      not file_name.nil?
    end

    def file_name
      read_model_attribute(:file_name)
    end

    def content_type
      read_model_attribute(:content_type)
    end

    def file_size
      read_model_attribute(:file_size)
    end

    def read_model_attribute(attribute)
      @model.send(:"#{name}_#{attribute}")
    end

    def write_model_attribute(attribute, data)
      @model.send(:"#{name}_#{attribute}=", data)
    end

    def path
      Paperclip::Interpolations.interpolate(options[:path], self, :original)
    end

    def url
      Paperclip::Interpolations.interpolate(options[:url], self, :original)
    end

    def flush_writes
      @queue_for_save.each do |file|
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, "w" ) do |f|
          f.write(file.read)
        end
      end
    end

    def flush_deletes
      @queue_for_delete.each do |file|
        File.unlink(file)
      end
    end
  end
end
