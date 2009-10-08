require 'test/helper'

class AttachmentTest < Test::Unit::TestCase
  def setup
    @now = Time.now
    Time.stubs(:now).returns(@now)
  end

  context "No options on a basic attachment on the Dummy class" do
    setup do
      define_attachment! "Dummy", :avatar
    end

    should "define #avatar on Dummy" do
      assert Dummy.instance_methods.include?('avatar')
    end

    should "define #avatar= on Dummy" do
      assert Dummy.instance_methods.include?('avatar')
    end
  end

  context "Assigning a File to a standard attachment" do
    setup do
      define_attachment! "Dummy", :avatar
      @dummy = Dummy.new
      @dummy.avatar = fixture_file("image.jpg")
    end

    should "assign the file's name to avatar_file_name" do
      assert_equal "image.jpg", @dummy.avatar_file_name
    end

    should "assign the file's content type to avatar_content_type" do
      assert_equal "image/jpeg", @dummy.avatar_content_type
    end

    should "assign the file's size to avatar_file_size" do
      assert_equal File.size(fixture_file("image.jpg").path), @dummy.avatar_file_size
    end

    should "not store the file on the filesystem yet" do
      assert ! File.exist?(@dummy.avatar.path)
    end

    should "store the file on the filesystem after the model has been saved" do
      @dummy.save
      assert File.exist?(@dummy.avatar.path), @dummy.avatar.path
    end
  end

  context "Assigning a StringIO to a standard attachment" do
    setup do
      define_attachment! "Dummy", :avatar
      @dummy = Dummy.new
      @stringio = StringIO.new("This is a file")
      @dummy.avatar = @stringio
    end

    should "assign the file's name to avatar_file_name" do
      assert_equal "default.txt", @dummy.avatar_file_name
    end

    should "assign the file's content type to avatar_content_type" do
      assert_equal "text/plain", @dummy.avatar_content_type
    end

    should "assign the file's size to avatar_file_size" do
      assert_equal @stringio.length, @dummy.avatar_file_size
    end

    should "not store the file on the filesystem yet" do
      assert ! File.exist?(@dummy.avatar.path)
    end

    should "store the file on the filesystem after the model has been saved" do
      @dummy.save
      assert File.exist?(@dummy.avatar.path), @dummy.avatar.path
    end
  end

  context "An attachment on a saved model" do
    setup do
      define_attachment! "Dummy", :avatar, :path => "tmp/:class/:attachment/:id_partition/:filename"
      @dummy = Dummy.new
      @dummy.avatar = fixture_file("image.jpg")
      @dummy.save
      @current_path = @dummy.avatar.path
    end

    should "not delete the attachment when assigned nil" do
      @dummy.avatar = nil
      assert File.exists?(@current_path)
    end

    should "delete the file attachment when assigned nil and saved" do
      @dummy.avatar = nil
      @dummy.save
      assert ! File.exists?(@current_path)
    end

    should "delete the file attachment when the model is destroyed" do
      @dummy.destroy
      assert ! File.exists?(@current_path)
    end

    should "move the file if the destination path changes" do
      @dummy.id = @dummy.id + 1000
      @expected_path = @dummy.avatar.path
      @dummy.save
      assert ! File.exists?(@current_path)
      assert   File.exists?(@expected_path)
    end
  end

  context "An attachment with a small thumbnail" do
    setup do
      define_attachment! "Dummy", :avatar, :path => "tmp/:class/:attachment/:id_partition/:style/:filename",
                                           :styles => {:small => {:processors => [:null]}}
      @dummy = Dummy.new
      @dummy.avatar = fixture_file("image.jpg")
    end

    should "put the files in locations appropriate to the style after save" do
      @dummy.save

      assert File.exists?(@dummy.avatar.path(:original))
      assert File.exists?(@dummy.avatar.path(:small))
    end

    should "delete all associated files when the model is destroyed" do
      @dummy.save
      expected_path_original = @dummy.avatar.path(:original)
      expected_path_small    = @dummy.avatar.path(:small)
      
      @dummy.destroy

      assert ! File.exists?(expected_path_original)
      assert ! File.exists?(expected_path_small)
    end

    should "delete all associated files when the attachment is set to nil and saved" do
      @dummy.save
      expected_path_original = @dummy.avatar.path(:original)
      expected_path_small    = @dummy.avatar.path(:small)

      @dummy.avatar = nil
      @dummy.save

      assert ! File.exists?(expected_path_original)
      assert ! File.exists?(expected_path_small)
    end

    should "move all files if the destination path changes" do
      @dummy.save
      current_path_original = @dummy.avatar.path(:original)
      current_path_small    = @dummy.avatar.path(:small)
      @dummy.id = @dummy.id + 1000
      expected_path_original = @dummy.avatar.path(:original)
      expected_path_small    = @dummy.avatar.path(:small)

      @dummy.save
      
      assert ! File.exists?(current_path_original)
      assert ! File.exists?(current_path_small)
      assert   File.exists?(expected_path_original)
      assert   File.exists?(expected_path_small)
    end

    should "have the small style be different from the original style" do
      assert_not_equal @dummy.avatar.path(:original), @dummy.avatar.path(:small)
    end

    should "contain the style's name in the path" do
      assert_match %r{\bsmall\b}, @dummy.avatar.path(:small)
      assert_match %r{\boriginal\b}, @dummy.avatar.path(:original)
    end

    should "not contain the other styles' names in the path" do
      assert_no_match %r{\bsmall\b}, @dummy.avatar.path(:original)
      assert_no_match %r{\boriginal\b}, @dummy.avatar.path(:small)
    end
  end

  should "put the file in the right place when given a :path" do
    define_attachment! "Dummy", :avatar, :path => "tmp/:class/:attachment/:id_partition/:filename"
    @dummy = Dummy.new
    @dummy.avatar = fixture_file("image.jpg")
    @dummy.save
    assert_match %r{tmp/dummies/avatars/000/000/001/image.jpg}, @dummy.avatar.path
  end

  should "return a properly interpolated url from #url when given a :url option" do
    define_attachment! "Dummy", :avatar, :url => ":class/:attachment/:filename"
    @dummy = Dummy.new
    @dummy.avatar = fixture_file("image.jpg")
    assert_match %r{dummies/avatars/image.jpg}, @dummy.avatar.url
  end

  should "return a properly interpolated url from #url when there is no attachment" do
    define_attachment! "Dummy", :avatar, :default_url => ":class/:attachment/not_found"
    @dummy = Dummy.new
    assert_match %r{dummies/avatars/not_found}, @dummy.avatar.url
  end

  should "use the default url when there is no attachment and the real url when there is" do
    define_attachment! "Dummy", :avatar, :default_url => ":class/:attachment/not_found",
                                         :url         => ":class/:attachment/:filename"
    @dummy = Dummy.new
    assert_match %r{dummies/avatars/not_found}, @dummy.avatar.url
    @dummy.avatar = fixture_file("image.jpg")
    assert_match %r{dummies/avatars/image.jpg}, @dummy.avatar.url
  end
end
