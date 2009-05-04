require 'test/helper'

class ValidateAttachmentContentTypeMatcherTest < Test::Unit::TestCase
  context "validate_attachment_content_type" do
    setup do
      force_table("models") do |d|
        d.string :avatar_file_name
      end
      @model_class = rebuild_class "Model"
      @model_class.has_attached_file :avatar
      @matcher     = self.class.validate_attachment_content_type(:avatar).
                       allowing(%w(image/png image/jpeg)).
                       rejecting(%w(audio/mp3 application/octet-stream))
    end

    should "reject a class with no validation" do
      assert_rejects @matcher, @model_class
    end

    should "reject a class with a validation that doesn't match" do
      @model_class.validates_attachment_content_type :avatar, :content_type => %r{audio/.*}
      assert_rejects @matcher, @model_class
    end

    should "accept a class with a validation" do
      @model_class.validates_attachment_content_type :avatar, :content_type => %r{image/.*}
      assert_accepts @matcher, @model_class
    end
  end
end
