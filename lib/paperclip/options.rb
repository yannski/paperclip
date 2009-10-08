module Paperclip
  class Options
    def self.default
      @defaults ||= {
        :path        => "public/:url",
        :url         => "system/:class/:attachment/:id_partition/:style/:filename",
        :default_url => "system/:class/:attachment/default/:style.jpg"
      }
    end

    def initialize(options = {})
      @options = self.class.default.merge(options)
      @options.each do |key, value|
        raise Paperclip::InvalidOptionError.new unless respond_to?(key)
      end
    end

    def [](key)
      @options[key]
    end

    def url
      @options[:url]
    end

    def path
      @options[:path]
    end

    def default_url
      @options[:default_url]
    end
  end
end
