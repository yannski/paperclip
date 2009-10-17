require 'test/helper'

class ValdiationsTest < Test::Unit::TestCase
  context "A model with no validations" do
    setup do
      define_attachment! "Dummy", :avatar
      @dummy = Dummy.new
    end

    should "be fine with no attachment" do
      assert @dummy.save
    end

    should "be fine with an attchment of 1025 bytes" do
      @dummy.avatar = StringIO.new("." * 1025)
      assert @dummy.save
    end

    should "be fine with an attachment with a content_type of 'text/x-totally-wrong'" do
      file = StringIO.new("." * 1025)
      file.content_type = 'text/x-totally-wrong'
      @dummy.avatar = file
      assert @dummy.save
    end
  end

  context "An ActiveRecord model with validations available" do
    setup do
      define_attachment! "Dummy", :avatar
      Dummy.class_eval do
        include Paperclip::Validations::ActiveRecord
      end
      @dummy = Dummy.new
    end

    should "be invalid if there's no attachment and we want one" do
      Dummy.class_eval{ validates_attachment_presence :avatar }
      assert ! @dummy.valid?
      assert_equal "must be present", @dummy.errors.on(:avatar)
    end

    should "contain the specified message when a presence validation fails" do
      Dummy.class_eval{ validates_attachment_presence :avatar, :message => "not here!" }
      assert ! @dummy.valid?
      assert_equal "not here!", @dummy.errors.on(:avatar)
    end

    should "be valid if there's no attachment and we want one" do
      Dummy.class_eval{ validates_attachment_presence :avatar }
      @dummy.avatar = StringIO.new("data")
      assert @dummy.valid?
    end

    should "be invalid if the size of the file is bigger than :max" do
      Dummy.class_eval{ validates_attachment_size :avatar, :max => 1024 }
      @dummy.avatar = StringIO.new("." * 1025)
      assert ! @dummy.valid?
      assert_equal "must be between 0 and 1024 bytes", @dummy.errors.on(:avatar)
    end

    should "be invalid if the size of the file is smaller than :min" do
      Dummy.class_eval{ validates_attachment_size :avatar, :min => 1024 }
      @dummy.avatar = StringIO.new("." * 1023)
      assert ! @dummy.valid?
      assert_equal "must be between 1024 and Infinity bytes", @dummy.errors.on(:avatar)
    end

    should "contain the specified message when a size validation fails" do
      Dummy.class_eval{ validates_attachment_size :avatar, :min => 1024, :message => "[:min .. :max]" }
      @dummy.avatar = StringIO.new("." * 1023)
      assert ! @dummy.valid?
      assert_equal "[1024 .. Infinity]", @dummy.errors.on(:avatar)
    end

    should "be valid if the size of the file is inside :min and :max" do
      Dummy.class_eval{ validates_attachment_size :avatar, :min => 1, :max => 1024 }
      @dummy.avatar = StringIO.new("." * 512)
      assert @dummy.valid?
    end

    should "be invalid if the content type is not in the approved list" do
      Dummy.class_eval{ validates_attachment_content_type :avatar, :in => [%r{image/.*}] }
      file = StringIO.new(".")
      file.content_type = "text/plain"
      @dummy.avatar = file
      assert ! @dummy.valid?
      assert_equal "must be one of the allowed content types", @dummy.errors.on(:avatar)
    end

    should "contain the specified message when a content_type validation fails" do
      Dummy.class_eval{ validates_attachment_content_type :avatar, :in => [%r{image/.*}], :message => "not :content_type" }
      file = StringIO.new("." * 1023)
      file.content_type = "text/wrong"
      @dummy.avatar = file
      assert ! @dummy.valid?
      assert_equal "not text/wrong", @dummy.errors.on(:avatar)
    end

    should "be valid if the content type is in the approved list" do
      Dummy.class_eval{ validates_attachment_content_type :avatar, :in => [%r{image/.*}] }
      file = StringIO.new("PNG!")
      file.content_type = "image/png"
      @dummy.avatar = file
      assert @dummy.valid?
    end

    should "be doubly invalid if wrong size and content type" do
      Dummy.class_eval do
        validates_attachment_size         :avatar, :max => 1024
        validates_attachment_content_type :avatar, :in  => [%r{image/.*}]
      end
      file = StringIO.new("." * 1025)
      file.content_type = "text/plain"
      @dummy.avatar = file
      assert ! @dummy.valid?
      assert_equal 2, @dummy.errors.on(:avatar).length
    end
  end
end
