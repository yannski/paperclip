require 'test/helper'

class AttachmentTest < Test::Unit::TestCase
  def setup
    @now = Time.now
    Time.stubs(:now).returns(@now)
    Paperclip::Storage.stubs(:for).returns(@storage = fake_storage)
    Paperclip::Processor.stubs(:for).returns(@processor = fake_processor)
    @file = fixture_file("image.jpg")
  end

  context "An :avatar attachment on a FakeModel class with no options" do
    setup do
      define_attachment!
    end

    should "define #avatar on FakeModel" do
      assert FakeModel.instance_methods.include?('avatar')
    end

    should "define #avatar= on FakeModel" do
      assert FakeModel.instance_methods.include?('avatar=')
    end
  end

  context "Assigning a File to an attachment" do
    setup do
      define_attachment! :path => "/:class/:attachment/:name/:filename"
      @fake = FakeModel.new
      @fake.avatar = @file
      @avatar = @fake.avatar
    end

    should "assign the file's name to avatar_file_name" do
      assert_equal "image.jpg", @fake.avatar_file_name
    end

    should "assign the file's content type to avatar_content_type" do
      assert_equal "image/jpeg", @fake.avatar_content_type
    end

    should "assign the file's size to avatar_file_size" do
      assert_equal File.size(@file.path), @fake.avatar_file_size
    end

    should "not store the file on the filesystem yet" do
      assert_received(@storage, :write){|s| s.never }
    end

    should "attempt to store the file on commit" do
      @avatar.commit
      assert_received(@storage, :write){|s| s.with(@avatar.path, @file) }
    end

    should "attempt to delete the stored file when assigned nil and committed" do
      @avatar.commit
      path = @avatar.path

      @avatar.assign(nil)
      @avatar.commit

      assert_received(@storage, :delete){|s| s.with(path) }
    end

    should "attempt to delete the old file and store the new file when a new file is assigned" do
      @avatar.commit
      path = @avatar.path
      new_file = fixture_file("image2.jpg")

      @avatar.assign(new_file)
      @avatar.commit

      assert_received(@storage, :delete){|s| s.with(path) }
      assert_received(@storage, :write){|s| s.with(@avatar.path, new_file) }
    end

    should "attempt to rename the file when the value of the path changes" do
      @avatar.commit
      original_path = @avatar.path

      @fake.name = "Something Else"
      @avatar.commit
      new_path = @avatar.path

      assert_received(@storage, :rename){|s| s.with(original_path, new_path) }
    end
  end

  context "Assigning a StringIO to a standard attachment" do
    setup do
      define_attachment!
      @fake = FakeModel.new
      @stringio = StringIO.new("This is a file")
      @fake.avatar = @stringio
      @avatar = @fake.avatar
    end

    should "assign the file's name to avatar_file_name" do
      assert_equal "default.txt", @fake.avatar_file_name
    end

    should "assign the file's content type to avatar_content_type" do
      assert_equal "text/plain", @fake.avatar_content_type
    end

    should "assign the file's size to avatar_file_size" do
      assert_equal @stringio.length, @fake.avatar_file_size
    end

    should "not store the file on the filesystem yet" do
      assert_received(@storage, :write){|s| s.never }
    end

    should "store the file on the filesystem on commit" do
      @avatar.commit
      assert_received(@storage, :write){|s| s.with(@avatar.path, @stringio) }
    end
  end

  context "An attachment storing a small thumbnail" do
    setup do
      define_attachment! :path => "/:class/:attachment/:name/:style/:filename",
                         :styles => {:small => {:geometry => "16x16"}}
      @fake = FakeModel.new
      @fake.avatar = @file
      @avatar = @fake.avatar
    end

    should "put the files in locations appropriate to the style after commit" do
      @avatar.commit
      assert_received(@storage, :write){|s| s.with(@avatar.path(:original), @file) }
      assert_received(@storage, :write){|s| s.with(@avatar.path(:small), @file) }
    end

    should "delete all associated files when the attachment is cleared" do
      @avatar.commit
      expected_path_original = @avatar.path(:original)
      expected_path_small    = @avatar.path(:small)
      
      @avatar.clear
      @avatar.commit

      assert_received(@storage, :delete){|s| s.with(expected_path_original) }
      assert_received(@storage, :delete){|s| s.with(expected_path_small) }
    end

    should "delete all associated files when the attachment is set to nil and committed" do
      @avatar.commit
      expected_path_original = @avatar.path(:original)
      expected_path_small    = @avatar.path(:small)

      @avatar.assign(nil)
      @avatar.commit

      assert_received(@storage, :delete){|s| s.with(expected_path_original) }
      assert_received(@storage, :delete){|s| s.with(expected_path_small) }
    end

    should "move all files if the destination path changes" do
      @avatar.commit
      current_path_original = @avatar.path(:original)
      current_path_small    = @avatar.path(:small)
      @fake.name = @fake.name + "123"
      expected_path_original = @avatar.path(:original)
      expected_path_small    = @avatar.path(:small)

      @avatar.commit

      assert_received(@storage, :rename){|s| s.with(current_path_original, expected_path_original) }
      assert_received(@storage, :rename){|s| s.with(current_path_small, expected_path_small) }
    end

    should "have the small style be different from the original style" do
      assert_not_equal @avatar.path(:original), @avatar.path(:small)
    end

    should "contain the style's name in the path" do
      assert_match %r{\bsmall\b}, @avatar.path(:small)
      assert_match %r{\boriginal\b}, @avatar.path(:original)
    end

    should "not contain the other styles' names in the path" do
      assert_no_match %r{\bsmall\b}, @avatar.path(:original)
      assert_no_match %r{\boriginal\b}, @avatar.path(:small)
    end
  end

  should "put the file in the right place when given a :path" do
    define_attachment! :path => "/:class/:attachment/:name/:filename"
    @fake = FakeModel.new
    @fake.avatar = @file
    assert_match %r{/fake_models/avatars/fake/image.jpg}, @fake.avatar.path
  end

  should "return a properly interpolated url from #url when given a :url option" do
    define_attachment! :url => ":class/:attachment/:filename"
    @fake = FakeModel.new
    @fake.avatar = fixture_file("image.jpg")
    assert_match %r{fake_models/avatars/image.jpg}, @fake.avatar.url
  end

  should "return a properly interpolated url from #url when there is no attachment" do
    define_attachment! :default_url => ":class/:attachment/not_found"
    @fake = FakeModel.new
    assert_match %r{fake_models/avatars/not_found}, @fake.avatar.url
  end

  should "use the default url when there is no attachment and the real url when there is" do
    define_attachment! :default_url => ":class/:attachment/not_found",
                       :url         => ":class/:attachment/:filename"
    @fake = FakeModel.new
    assert_match %r{fake_models/avatars/not_found}, @fake.avatar.url
    @fake.avatar = fixture_file("image.jpg")
    assert_match %r{fake_models/avatars/image.jpg}, @fake.avatar.url
  end

  should "override the default style when specified" do
    define_attachment! :default_style => :square, :path => "/:style/file.jpg"
    @fake = FakeModel.new
    assert_equal "/square/file.jpg", @fake.avatar.path
  end
end
