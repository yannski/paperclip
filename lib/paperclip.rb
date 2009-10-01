require "paperclip/interpolations"
require "paperclip/uploaded_file"
require "paperclip/processor"
require "paperclip/attachment"

module Paperclip
  VERSION = "3.0.0"

  class PaperclipError < StandardError; end
  class InfiniteInterpolationError < PaperclipError; end

  def self.included(base)
    File.send(:include, UploadedFile)
    StringIO.send(:include, UploadedFile)
  end

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

    after_save     :flush_attachments
    before_destroy :flush_attachments
  end

  module InstanceMethods
    def flush_attachments
      self.class.paperclip_definitions.keys.each do |name|
        attachment_for(name).flush_deletes
        attachment_for(name).flush_writes
      end
    end

    def attachment_for(name)
      @attachment ||= Attachment.new(name, self, attachment_options(name))
    end

    def attachment_options(name)
      self.class.paperclip_definitions[name]
    end
  end
end
