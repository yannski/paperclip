require "paperclip/interpolations"

module Paperclip
  VERSION = "3.0.0"

  class PaperclipError < StandardError; end
  class InfiniteInterpolationError < PaperclipError; end

  def has_attached_file(name, options = {})
    include InstanceMethods
    cattr_accessor :paperclip_definitions

    defaults = {
      :path => "public/:class/:attachment/:id_partition/:style/:filename"
    }

    self.paperclip_definitions ||= {}
    self.paperclip_definitions[name] = defaults.merge(options)

    define_method(name) do
      attachment_for(name)
    end

    define_method("#{name}=") do |file|
      attachment_for(name).assign(file)
    end

    after_save :flush_attachments
  end

  module InstanceMethods
    def flush_attachments
      self.class.paperclip_definitions.keys.each do |name|
        attachment_for(name).flush_on_save
      end
    end

    def attachment_for(name)
      @attachment ||= Attachment.new(name, self, attachment_options(name))
    end

    def attachment_options(name)
      self.class.paperclip_definitions[name]
    end
  end

  class Processor
  end

  class Attachment
    attr_accessor :name, :options, :model

    def initialize(name, model, options = {})
      @name = name
      @model = model
      @options = options
    end

    def assign(file)
      write_model_attribute(:file_name,    File.basename(file.path))
      write_model_attribute(:content_type, MIME::Types.of(file.path).to_s)
      write_model_attribute(:file_size,    File.size(file.path))
      @queue_for_save = [file]
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

    def flush_on_save
      @queue_for_save.each do |file|
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, "w" ) do |f|
          f.write(file.read)
        end
      end
    end
  end
end
