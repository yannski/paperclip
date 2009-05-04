require 'test/helper'

class ValidateAttachmentPresenceMatcherTest < Test::Unit::TestCase
  context "validate_attachment_presence" do
    setup do
      force_table("models"){|d| d.string :avatar_file_name }
      @model_class = rebuild_class "Model"
      @model_class.has_attached_file :avatar
      @matcher     = self.class.validate_attachment_presence(:avatar)
    end

    should "reject a class with no validation" do
      assert_rejects @matcher, @model_class
    end

    should "accept a class with a validation" do
      @model_class.validates_attachment_presence :avatar
      assert_accepts @matcher, @model_class
    end
  end
end
