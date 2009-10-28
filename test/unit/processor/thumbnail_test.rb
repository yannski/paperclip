require 'test/helper'

class ThumbnailTest < Test::Unit::TestCase
  context "A thumbnail processor set to make a 100x100 thumbnail" do
    setup do
      @file = fixture_file("image.jpg")
      @processor = Paperclip::Processor::Thumbnail.new(@file, {:geometry => "100x100"})
      Paperclip.stubs(:run)
    end

    should "have the right scale geometry" do
      assert_equal "100x100", @processor.scale_geometry.to_s
    end

    should "not have a crop geometry" do
      assert_nil @processor.crop_geometry
    end

    should "not have a source geometry" do
      assert_nil @processor.source_geometry
    end

    should "produce the right transformation" do
      assert_equal '-resize "100x100"', @processor.transformation
    end
  end

  context "A thumbnail processor set to make a 50x50 square thumbnail" do
    setup do
      @file = fixture_file("image.jpg")
      Paperclip::Geometry.stubs(:from_file).returns(Paperclip::Geometry.new(300, 100))
      @processor = Paperclip::Processor::Thumbnail.new(@file, {:geometry => "50x50#"})
    end

    should "have the right scale geometry" do
      assert_equal "x50", @processor.scale_geometry.to_s
    end

    should "have the right crop geometry" do
      assert_equal "50x50+50+0", @processor.crop_geometry.to_s
    end

    should "have the right source geometry" do
      assert "300x100", @processor.source_geometry
    end

    should "produce the right transformation" do
      assert_equal '-resize "x50" -crop "50x50+50+0" +repage', @processor.transformation
    end

    should "have gotten its source geometry from 'identify'" do
      assert_received(Paperclip::Geometry, :from_file){|p| p.with(@file) }
    end
  end

  should "generate the right transformation when destination_options are specified" do
    @file = fixture_file("image.jpg")
    @processor = Paperclip::Processor::Thumbnail.new(@file, {:geometry => "50x50", :destination_options => "-rotate 90"})
    assert_equal '-resize "50x50" -rotate 90', @processor.transformation
  end

  should "generate the right transformation when source_options are specified" do
    @file = fixture_file("image.jpg")
    @processor = Paperclip::Processor::Thumbnail.new(@file, {:geometry => "50x50", :source_options => "-rotate 90"})
    assert_equal '-rotate 90 -resize "50x50"', @processor.transformation
  end
end
