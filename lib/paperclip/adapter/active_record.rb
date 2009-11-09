module Paperclip
  module Adapter
    module ActiveRecord

      def self.included(base)
        base.extend(self)
      end

      def install_attachment_callbacks(attachment, styles)
        after_save     :flush_attachments
        before_destroy :clear_attachment
        after_destroy  :flush_attachments

        define_callback :"before_#{attachment}_process"
        define_callback :"after_#{attachment}_process"

        styles.each do |style|
          define_callback :"before_#{attachment}_#{style}_process"
          define_callback :"after_#{attachment}_#{style}_process"
        end
      end

    end
  end
end
