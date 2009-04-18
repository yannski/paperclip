module Paperclip
  class StorageError < Exception;
    attr_reader :exception
    def initialize exception_or_message
      if exception_or_message.is_a? String
        @message = exception_or_message
      else
        @exception = exception_or_message
        @message = @exception.message
      end
      super
    end
  end

  class Storage
    def self.for options
      storage_method = options.storage_method || :filesystem
      storage_method = storage_method.to_s.capitalize
      Paperclip::Storage.const_get(storage_method).new(options)
    end

    def initialize options
      @options = options
    end

    def write path, file, attachment = nil
    end

    def delete path
    end

    def exists? path
    end

    class Filesystem < Storage
      def write path, data, attachment = nil
        data.close if data.respond_to? :close
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.mv(data.path, path)
        FileUtils.chmod(0644, path)
      end

      def delete path
        begin
          FileUtils.rm(path) if File.exist?(path)
        rescue Errno::ENOENT => e
          # ignore file-not-found, let everything else bubble up.
        rescue SystemCallError => e
          Paperclip::StorageError.new(e)
        end
        begin
          while(true)
            path = File.dirname(path)
            FileUtils.rmdir(path)
          end
        rescue Errno::EEXIST, Errno::ENOTEMPTY, Errno::ENOENT, Errno::EINVAL, Errno::ENOTDIR
          # Stop trying to remove parent directories.
        rescue SystemCallError => e
          # Ignore it, we should stop anyway.
        end
      end

      def exists? path
        File.exists?(path)
      end

      def to_file path
        return nil if path.nil?
        File.new(path)
      end
    end

    class S3 < Storage
      attr_accessor :credentials, :options, :bucket, :headers
      def self.setup_s3
        require 'aws/s3'
        S3.const_set("Container", Class.new(AWS::S3::S3Object)) unless S3.const_defined?("Container")
      end

      def initialize options
        self.class.setup_s3
        @options     = options.options
        @credentials = options.credentials
        @bucket      = options.bucket
        @headers     = options.headers
        Container.establish_connection!(@options.merge(@credentials))
      end

      def write path, data, attachment = nil
        data.rewind if data.respond_to?(:rewind)
        s3_headers = attachment.nil? ? {} : {:content_type => attachment.content_type}
        s3_headers.merge!(headers)
        begin
          Container.store(path, data.read, bucket, s3_headers)
        rescue AWS::S3::ResponseError => e
          raise Paperclip::StorageError.new(e)
        end
      end

      def delete path
        begin
          Container.delete(path, bucket)
        rescue AWS::S3::ResponseError => e
          raise Paperclip::StorageError.new(e)
        end
      end

      def exists? path
        begin
          Container.exists?(path, bucket)
        rescue AWS::S3::ResponseError => e
          raise Paperclip::StorageError.new(e)
        end
      end

      def to_file path
        file = Tempfile.new(path)
        Container.stream(path, bucket) do |chunk|
          file.write(chunk)
        end
        file.rewind
        file.original_filename = File.basename(path)
        file
      end
    end
  end
end
