require 'test/helper'

class StorageTest < Test::Unit::TestCase
  context "A Storage object" do
    context "configured as filesystem" do
      setup do
        @config = Paperclip::Definition::Storage.new
        @storage = Paperclip::Storage.for @config
        @path = File.join(File.dirname(__FILE__), "tmp", "storage.txt")
        @file = Tempfile.new("paperclip-test")
        @file.puts "..."
        @file.rewind
        @attachment = mock
      end
      should "save a file when given a file and a path" do
        @storage.write(@path, @file, @attachment)
        assert_equal "...\n", IO.read(@path)
      end
      should "delete the file when given the path" do
        File.open(@path, "w"){|f| f.puts "TATFT" }
        assert File.exists?(@path)
        @storage.delete(@path)
        assert ! File.exists?(@path)
      end
      should "return true when the file exists" do
        File.stubs(:exists?).returns(true)
        assert @storage.exists?(@path)
      end
      should "return false when the file doesn't exist" do
        File.stubs(:exists?).returns(false)
        assert ! @storage.exists?(@path)
      end
      should "return something that can be returned to #assign from to_file" do
        file = @storage.to_file(File.join(File.dirname(__FILE__), "fixtures", "hello_world.txt"))
        assert_equal "hello_world.txt", file.original_filename
        assert_equal "text/plain", file.content_type
      end
    end

    context "configured as S3" do
      setup do
        Paperclip::Storage::S3.setup_s3
        @config = Paperclip::Definition::Storage::S3.new(
          :bucket => "bucket",
          :s3_credentials => File.join(File.dirname(__FILE__), "fixtures", "s3.yml")
        )
        @path = File.join(File.dirname(__FILE__), "fixtures", "hello_world.txt")
        @file = Tempfile.new("paperclip-test")
        @file.puts "Hello, World!"
        @file.rewind
        Paperclip::Storage::S3::Container.stubs(:establish_connection!)
        @attachment = mock
        @storage = Paperclip::Storage.for @config
      end
      should "save a file when given a file and a path" do
        Paperclip::Storage::S3::Container.
          expects(:store).
          with(@path, "Hello, World!\n", "bucket", {:content_type => "text/plain"})
        @attachment.expects(:content_type).returns("text/plain")
        @storage.write(@path, @file, @attachment)
      end
      should "delete a file when given a path" do
        Paperclip::Storage::S3::Container.expects(:delete).with(@path, "bucket")
        @storage.delete(@path)
      end
      should "return true when the file exists" do
        Paperclip::Storage::S3::Container.expects(:exists?).with(@path, "bucket").returns(true)
        assert @storage.exists?(@path)
      end
      should "return false when the file doesn't exist" do
        Paperclip::Storage::S3::Container.expects(:exists?).with(@path, "bucket").returns(false)
        assert ! @storage.exists?(@path)
      end
      should "return something that can be returned to #assign from to_file" do
        Paperclip::Storage::S3::Container.expects(:stream).with(@path, "bucket").yields(".")
        file = @storage.to_file(@path)
        assert_equal "hello_world.txt", file.original_filename
        assert_equal "text/plain", file.content_type
      end
    end
  end
end
