require 'test/helper'

class FilesystemTest < Test::Unit::TestCase
  def setup
    @storage = Paperclip::Storage.for(:filesystem)
    @file = fixture_file("image.jpg")
  end

  should "save the file to the specified path" do
    @storage.write("tmp/image.jpg", @file)
    @file.rewind
    assert_equal @file.read, File.open("tmp/image.jpg"){|f| f.read }
  end

  should "delete the file from the specified path" do
    File.open("tmp/text.txt", "w"){|f| f.puts "This is a text file." }
    @storage.delete("tmp/text.txt")
    assert ! File.exists?("tmp/text.txt")
  end

  should "rename a file from one thing to another" do
    File.open("tmp/text.txt", "w"){|f| f.puts "This is a text file." }
    @storage.rename("tmp/text.txt", "tmp/subdir/text.txt")
    assert ! File.exists?("tmp/text.txt")
    assert_equal "This is a text file.\n", File.open("tmp/subdir/text.txt"){|f| f.read }
  end
end
