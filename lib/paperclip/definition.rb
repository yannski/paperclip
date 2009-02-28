module Paperclip
  class Definition
    attr_accessor :url, :path, :default_style, :default_path, :whiny_processing

    def initialize options = {}
      @url = options[:url]
      @path = options[:path]
      @default_style = options[:default_style]
      @default_path = options[:default_path]
      @whiny_processing = options[:whiny_processing]
      @styles = options[:styles]
    end

    def style name
      Style.new
    end

    class Style
      attr_accessor :processors, :convert_options, :whiny_processing, :format, :geometry
      def initialize options = {}, format = nil
        if options.is_a? String
          geometry = options
          options = {}
        end
        @geometry         = options.delete(:geomtry) || geometry
        @format           = options.delete(:format) || format
        @processors       = options.delete(:processors) || [:thumbnail]
        @convert_options  = options.delete(:convert_options)
        @whiny_processing = options.delete(:whiny_processing)
        @whiny_processing = @whiny_processing.nil? ? true : @whiny_processing

        @methods = []
        methodize(options)
      end

      def option_methods
        @methods
      end

      def methodize options = {}
        @methods.concat(options.keys)
        (class << self; self; end).class_eval do
          attr_accessor *options.keys
        end
        options.each do |key, value|
          self.send("#{key}=", value)
        end
      end

      def merge other
        options = {
          :geometry => @geometry,
          :format => @format,
          :processors => @processors,
          :convert_options => @convert_options,
          :whiny_processing => @whiny_processing
        }
        other.option_methods.each do |method|
          options[method] = other.send(method)
        end

        Style.new(options)
      end
    end
  end
end
