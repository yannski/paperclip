require 'test/helper'

class ActiveRecordAdapterTest < Test::Unit::TestCase
  def setup
    Paperclip::Storage.stubs(:for).returns(@storage = fake_storage)
    Paperclip::Processor.stubs(:for).returns(@processor = fake_processor)
    @file = fixture_file("image.jpg")
  end

  context "An ActiveRecord-based model without adapter in place" do
    setup do
      define_active_record_attachment! "Dummy", :avatar, :path => "/:class/:name/:filename"
      @dummy = Dummy.new
      @dummy.avatar = @file
      @dummy.name = "12345"
    end

    should "not automatically save the attachment on #save" do
      @dummy.save
      assert_received(@storage, :write){|s| s.never }
    end

    should "not automatically delete the attachment on #destroy" do
      @dummy.save
      @dummy.destroy
      assert_received(@storage, :delete){|s| s.never }
    end

    should "not automatically rename the attachment on #save" do
      @dummy.save
      @dummy.name = "54321"
      @dummy.save
      assert_received(@storage, :rename){|s| s.never }
    end
  end

  context "An ActiveRecord-based model with the adapter in place" do
    setup do
      define_active_record_attachment! "Dummy", :avatar
      Dummy.class_eval do
        include Paperclip::Adapter::ActiveRecord
        has_attached_file :avatar, :path => "/:class/:name/:filename"
      end
      @dummy = Dummy.new
      @dummy.avatar = @file
      @dummy.name = "12345"
    end

    should "automatically save the attachment on #save" do
      @dummy.save
      assert_received(@storage, :write){|s| s.with(@dummy.avatar.path, @file) }
    end

    should "automatically delete the attachment on #destroy" do
      @dummy.save
      expected_path = @dummy.avatar.path
      @dummy.destroy
      assert_received(@storage, :delete){|s| s.with(expected_path) }
    end

    should "automatically rename the attachment on #save" do
      @dummy.save
      source_path = @dummy.avatar.path
      @dummy.name = "54321"
      destination_path = @dummy.avatar.path
      @dummy.save
      assert_received(@storage, :rename){|s| s.with(source_path, destination_path) }
    end
  end
end
