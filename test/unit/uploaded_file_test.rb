require 'test/helper'

class UploadedFileTest < Test::Unit::TestCase
  context "Including UploadedFile into File" do
    setup do
      File.send(:include, Paperclip::UploadedFile)
      @file = fixture_file("image.jpg")
    end

    should "return the file name from #original_filename" do
      assert_equal "./test/fixtures/image.jpg", @file.original_filename
    end

    should "return the content type from #content_type" do
      assert_equal "image/jpeg", @file.content_type
    end

    should "return the size of the file from #size" do
      assert_equal 900, @file.size
    end
  end

  context "Including UploadedFile into StringIO" do
    setup do
      StringIO.send(:include, Paperclip::UploadedFile)
      @file = StringIO.new("Image!")
    end

    should "return the file name from #original_filename" do
      assert_equal "default.txt", @file.original_filename
    end

    should "return the content type from #content_type" do
      assert_equal "text/plain", @file.content_type
    end

    should "return the size of the file from #size" do
      assert_equal 6, @file.size
    end
  end
end

