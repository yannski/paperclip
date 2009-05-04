module Paperclip
  class Definition
    def self.attr_latebind *fields
      fields.each do |field|
        attr_writer :field
        define_method field do
          value = instance_variable_get("@#{field}")
          value.respond_to?(:call) ? value.call(payload) : value
        end
      end
    end

    attr_latebind :url, :path, :default_style, :default_url, :whiny_processing
    attr_accessor :storage, :storage_method, :validations, :payload

    def self.default_options
      @default_options ||= {
        :url           => "/system/:attachment/:id/:style/:basename.:extension",
        :path          => ":rails_root/public/system/:attachment/:id/:style/:basename.:extension",
        :default_url   => "/:attachment/:style/missing.png",
        :default_style => :original,
        :validations   => {},
        :processors    => [:thumbnail],
        :storage       => :filesystem
      }
    end

    def initialize options = {}
      defaults          = self.class.default_options
      @url              = options[:url]              || defaults[:url]
      @path             = options[:path]             || defaults[:path]
      @default_style    = options[:default_style]    || defaults[:default_style]
      @default_url      = options[:default_url]      || defaults[:default_url]
      @validations      = options[:validations]      || defaults[:validations]
      @whiny_processing = options[:whiny_processing] || defaults[:whiny_processing]
      @storage_method   = options[:storage]          || :filesystem
      @all_styles       = options[:all_styles]       || {}
      @style_hashes     = options[:styles]           || {}
      @styles           = {}

      @options          = options

      @all_styles[:processors] = options[:processors]
      @all_styles       = Style.new(@all_styles)
      @style_hashes.each do |name, opts|
        @styles[name] = @all_styles.merge(Style.new(opts))
      end

      @styles.each do |name, style|
        style.processors ||= @all_styles.processors || defaults[:processors]
      end
    end

    def storage
      Storage.for(@storage_method, @options)
    end

    def style name
      @styles[name]
    end

    def styles
      @styles.keys
    end

    def each_style &block
      @styles.each(&block)
    end

    class Options
      def initialize options = {}
        @methods ||= []
        options.each do |key, value|
          methodize(key, value)
        end
      end

      attr_accessor :payload

      def option_methods
        @methods
      end

      def methodize method, value
        (@methods ||= []) << method.to_sym
        (class << self; self; end).class_eval do
          attr_accessor method
          define_method method do
            value = instance_variable_get("@#{method}")
            value.respond_to?(:call) ? value.call(payload) : value
          end
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
          self.bucket      = options.delete(:bucket)
          self.credentials = options.delete(:s3_credentials)
          self.permissions = options.delete(:s3_permissions) || 'public-read'
          self.headers     = options.delete(:s3_headers)     || {}
          self.options     = options.delete(:s3_options)     || {}
          self.host_alias  = options.delete(:s3_host_alias)
          self.protocol    = options.delete(:s3_protocol)    || (permissions == 'public-read' ? 'http' : 'https')
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
        case options
        when String
          geometry = options
          options = {}
        when Array
          geometry, format = options
          options = {}
        end
        self.geometry         = options.delete(:geomtry) || geometry
        self.format           = options.delete(:format) || format
        self.processors       = options.delete(:processors)
        self.convert_options  = options.delete(:convert_options)
        self.whiny_processing = options.delete(:whiny_processing)
        self.whiny_processing = whiny_processing.nil? ? true : whiny_processing
        super(options)
      end
    end
  end
end
