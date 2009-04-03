module Paperclip
  class Definition
    attr_accessor :url, :path, :default_style, :default_url, :whiny_processing,
                  :storage, :storage_method

    def self.default_options
      @default_options ||= {}
    end

    def initialize options = {}
      defaults          = self.class.default_options
      @url              = options[:url]              || defaults[:url]
      @path             = options[:path]             || defaults[:path]
      @default_style    = options[:default_style]    || defaults[:default_style]
      @default_url      = options[:default_url]      || defaults[:default_url]
      @whiny_processing = options[:whiny_processing] || defaults[:whiny_processing]
      @storage_method   = options[:storage]          || :filesystem
      @all_styles       = options[:all_styles]       || {}
      @style_hashes     = options[:styles]
      @styles           = {}
      @storage          = Storage.for(@storage_method, options)
    end

    def style name
      @styles[name] ||= Style.new(@all_styles.merge(@style_hashes[name]))
    end

    class Options
      def initialize options = {}
        @methods ||= []
        options.each do |key, value|
          methodize(key, value)
        end
      end

      def option_methods
        @methods
      end

      def methodize method, value
        (@methods ||= []) << method.to_sym
        (class << self; self; end).class_eval do
          attr_accessor method
        end
        instance_variable_set("@#{method}", value)
      end

      def method_missing method, *args, &block
        method, assign = method.to_s.split(/(=)/)
        if assign
          methodize(method, args.first)
        elsif block
          methodize(method, block)
        else
          nil
        end
      end

      def merge other
        result = self.class.new
        option_methods.each do |method|
          result.send("#{method}=", self.send(method))
        end
        other.option_methods.each do |method|
          result.send("#{method}=", other.send(method))
        end
        result
      end
    end

    class Storage < Options
      def self.for(method, options = {})
        self.const_get(method.to_s.camelize).new(options)
      end

      class Filesystem < Storage
        def initialize options = {}
          self.storage_method = :filesystem
          super(options)
        end
      end

      class S3 < Storage
        attr_reader :permissions, :credentials
        def initialize options = {}
          self.storage_method = :s3
          self.bucket             = options.delete(:bucket)
          self.credentials        = options.delete(:s3_credentials)
          self.permissions        = options.delete(:s3_permissions)        || 'public-read'
          self.headers            = options.delete(:s3_headers)            || {}
          self.connection_options = options.delete(:s3_connection_options) || {}
          self.host_alias         = options.delete(:s3_host_alias)
          self.protocol           = options.delete(:s3_protocol)           || (permissions == 'public-read' ? 'http' : 'https')
          super(options)
        end

        def credentials= yaml
          yaml ||= {}
          if yaml.is_a? String
            @credentials = YAML.load_file(yaml)
          elsif yaml.respond_to? :read
            @credentials = YAML.load(yaml.read)
          else
            @credentials = yaml
          end
          
          if Object.const_defined?("RAILS_ENV") && @credentials.key?(RAILS_ENV)
            @credentials = @credentials[RAILS_ENV]
          end
          @credentials = {:access_key_id => @credentials['access_key_id'] || @credentials[:access_key_id],
                          :secret_access_key => @credentials['secret_access_key'] || @credentials[:secret_access_key]}
        end
      end
    end

    class Style < Options
      def initialize options = {}, format = nil
        if options.is_a? String
          geometry = options
          options = {}
        end
        self.geometry         = options.delete(:geomtry) || geometry
        self.format           = options.delete(:format) || format
        self.processors       = options.delete(:processors) || [:thumbnail]
        self.convert_options  = options.delete(:convert_options)
        self.whiny_processing = options.delete(:whiny_processing)
        self.whiny_processing = whiny_processing.nil? ? true : whiny_processing
        super(options)
      end
    end
  end
end
