module Paperclip
  module Adapter
    module ActiveRecord

      def self.included(base)
        base.extend(self)
      end

      def install_attachment_callbacks
        after_save     :flush_attachments
        before_destroy :clear_attachment
        after_destroy  :flush_attachments
      end

    end
  end
end
