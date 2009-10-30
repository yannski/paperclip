require 'test/helper'

class TempfileTest < Test::Unit::TestCase
  context "A Paperclip Tempfile" do
    setup do
      @tempfile = Paperclip::Tempfile.new("file.jpg")
    end

    should "have its path contain a real extension" do
      assert_equal ".jpg", File.extname(@tempfile.path)
    end

    should "be a real Tempfile" do
      assert @tempfile.is_a?(::Tempfile)
    end
  end

  context "Another Paperclip Tempfile" do
    setup do
      @tempfile = Paperclip::Tempfile.new("file")
    end

    should "not have an extension if not given one" do
      assert_equal "", File.extname(@tempfile.path)
    end

    should "still be a real Tempfile" do
      assert @tempfile.is_a?(::Tempfile)
    end
  end
end
