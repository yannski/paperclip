require "paperclip/options"
require "paperclip/interpolations"
require "paperclip/uploaded_file"
require "paperclip/processor"
require "paperclip/attachment"

module Paperclip
  VERSION = "3.0.0"

  class PaperclipError < StandardError; end
  class InfiniteInterpolationError < PaperclipError; end
  class InvalidOptionError < PaperclipError; end

  def self.included(base)
    File.send(:include, UploadedFile)
    StringIO.send(:include, UploadedFile)
  end

  def has_attached_file(name, options = {})
    include InstanceMethods
    cattr_accessor :paperclip_definitions

    self.paperclip_definitions ||= {}
    self.paperclip_definitions[name] = Options.new(options)

    define_method(name) do
      attachment_for(name)
    end

    define_method("#{name}=") do |file|
      attachment_for(name).assign(file)
    end

    after_save     :flush_attachments
    before_destroy :destroy_attachment
    before_destroy :flush_attachments
  end

  module InstanceMethods
    def destroy_attachment
      self.class.paperclip_definitions.keys.each do |name|
        attachment_for(name).clear
      end
    end

    def flush_attachments
      self.class.paperclip_definitions.keys.each do |name|
        attachment_for(name).save
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
