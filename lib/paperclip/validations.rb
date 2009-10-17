module Paperclip
  module Validations
    module ActiveRecord
      def self.included(base)
        base.extend(self)
      end

      def validates_attachment_presence(name, options = {})
        message = options[:message] || "must be present"
        validates_each("#{name}_file_name") do |record, attr, value|
          record.errors.add(name, message) if value.blank?
        end
      end

      def validates_attachment_size(name, options = {})
        min     = options[:min] || 0
        max     = options[:max] || (1.0/0)
        message = options[:message] || "must be between #{min} and #{max} bytes"
        validates_each("#{name}_file_size") do |record, attr, value|
          full_message = message.gsub(/:min/, min.to_s).gsub(/:max/, max.to_s)
          record.errors.add(name, full_message) unless (min..max).include?(value)
        end
      end

      def validates_attachment_content_type(name, options = {})
        content_types = [options[:in] || options[:content_type] || []].flatten
        message       = options[:message] || "must be one of the allowed content types"
        validates_each("#{name}_content_type") do |record, attr, value|
          full_message = message.gsub(/:content_type/, value)
          record.errors.add(name, full_message) unless (content_types).any?{|type| type === value }
        end
      end
    end
  end
end
