require 'test/helper'

class HaveAttachedFileMatcherTest < Test::Unit::TestCase
  context "have_attached_file" do
    setup do
      force_table "models"
      @model_class = rebuild_class "Model"
      @matcher     = self.class.have_attached_file(:avatar)
    end

    should "reject a class with no attachment" do
      assert_rejects @matcher, @model_class
    end

    should "accept a class with an attachment" do
      modify_table("models"){|d| d.string :avatar_file_name }
      @model_class.has_attached_file :avatar
      assert_accepts @matcher, @model_class
    end
  end
end
