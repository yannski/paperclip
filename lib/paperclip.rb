module Paperclip
  class PaperclipError < StandardError; end
end

require "paperclip/adapter/active_record"
require "paperclip/attachment"
require "paperclip/interpolations"
require "paperclip/options"
require "paperclip/processor"
require "paperclip/storage"
require "paperclip/storage/filesystem"
require "paperclip/uploaded_file"
require "paperclip/validations"

require "paperclip/geometry"

module Paperclip
  VERSION = "3.0.0"

  class CommandLineError < PaperclipError
    attr_accessor :result_code
    def initialize(message, result_code)
      super(message)
      @result_code = result_code
    end
  end
  class CommandNotFound < PaperclipError; end

  def self.run(command, arguments = nil, *expected_values)
    expected_values = [0] if expected_values.empty?
    full_command = [options[:command_path], command].compact.join(File::Separator)
    full_command << " #{arguments}"
    full_command << " 2>#{bit_bucket}" if options[:swallow_stderr]

    output = `#{full_command}`
    raise CommandNotFound.new(full_command)              if run_result == 127
    raise CommandLineError.new(full_command, run_result) unless expected_values.include?(run_result)

    output
  end

  def self.bit_bucket
    File.exists?("/dev/null") ? "/dev/null" : "NUL"
  end

  def self.run_result
    $?.exitstatus
  end

  def self.options
    @options ||= {
      :command_path => nil,
      :swallow_stderr => false
    }
  end

  def self.included(base)
    File.send(:include, UploadedFile)
    StringIO.send(:include, UploadedFile)
    base.extend(self)
  end

  def has_attached_file(name, options = {})
    include InstanceMethods
    self.class.class_eval do
      attr_accessor :paperclip_definitions
    end

    self.paperclip_definitions ||= {}
    self.paperclip_definitions[name] = Options.new(options)

    define_method(name) do
      attachment_for(name)
    end

    define_method("#{name}=") do |file|
      attachment_for(name).assign(file)
    end

    install_attachment_callbacks if respond_to?('install_attachment_callbacks')
  end

  module InstanceMethods
    def clear_attachment
      self.class.paperclip_definitions.keys.each do |name|
        attachment_for(name).clear
      end
    end

    def flush_attachments
      self.class.paperclip_definitions.keys.each do |name|
        attachment_for(name).commit
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
