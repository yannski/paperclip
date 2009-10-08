module Paperclip
  class Attachment
    attr_accessor :name, :options, :model

    def initialize(name, model, options = Options.new)
      @name = name
      @model = model
      @options = options
      set_existing_paths
    end

    def assign(file)
      @queue_for_save   = {}
      @queue_for_delete = []

      self.clear
      return if file.nil?

      write_model_attribute(:file_name,    File.basename(file.original_filename))
      write_model_attribute(:content_type, file.content_type)
      write_model_attribute(:file_size,    file.size)

      @queue_for_save = {}
      options.styles.keys.each do |style|
        @queue_for_save[style] = file
      end
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

    def path(style = :original)
      Paperclip::Interpolations.interpolate(options[:path], self, style)
    end

    def url(style = :original)
      if present?
        Paperclip::Interpolations.interpolate(options[:url], self, style)
      else
        Paperclip::Interpolations.interpolate(options[:default_url], self, style)
      end
    end

    def clear
      if present?
        @queue_for_delete = options.styles.keys.map{|key| path(key) }
      end
      write_model_attribute(:file_name,    nil)
      write_model_attribute(:content_type, nil)
      write_model_attribute(:file_size,    nil)
    end

    def set_existing_paths
      @existing_paths = {}
      return unless present?
      @existing_paths = options.styles.keys.inject({}) do |hash, key|
        hash[key] = path(key)
        hash
      end
    end

    def save
      flush_renames
      flush_writes
      flush_deletes
      set_existing_paths
    end

    def flush_writes
      @queue_for_save.each do |style, file|
        write(path(style), file)
      end
      @queue_for_save = []
    end

    def flush_deletes
      @queue_for_delete.each do |path|
        delete(path)
      end
      @queue_for_delete = []
    end

    def flush_renames
      return unless present?
      @existing_paths.each do |style, existing_path|
        rename(existing_path, path(style))
      end
    end

    def write(path, file)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "w" ) do |f|
        file.rewind
        f.write(file.read)
      end
    end

    def delete(path)
      File.delete(path)
    end

    def rename(src, dst)
      if src != dst
        write(dst, File.new(src))
        delete(src)
      end
    end
  end
end
