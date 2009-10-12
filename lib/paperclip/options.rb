module Paperclip
  class Options
    def self.default
      @defaults ||= {
        :path            => ":rails_root/public/:url",
        :url             => "system/:class/:attachment/:id_partition/:style/:filename",
        :default_url     => "system/:class/:attachment/default/:style.jpg",
        :default_style   => :original,
        :styles          => {},
        :storage         => {:backend => :filesystem}
      }
    end

    def initialize(options = {})
      @options = self.class.default.merge(options)
    end

    def [](key)
      self.send(key)
    end

    def styles
      @options[:styles][:original] ||= {}
      @options[:styles]
    end

    def default_style
      @options[:default_style]
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

    def storage
      @options[:storage]
    end
  end
end
