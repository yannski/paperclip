module Paperclip
  class Definition
    attr_accessor :url, :path, :default_url, :default_path

    def initialize options = {}
      @url = options[:url]
      @path = options[:path]
      @default_url = options[:default_url]
      @default_path = options[:default_path]
    end
  end
end
