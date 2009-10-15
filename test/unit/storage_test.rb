require 'test/helper'

class StorageTest < Test::Unit::TestCase
  should "turn an underscored symbol into a class name with constantize" do
    assert_equal "ClassName", Paperclip::Storage.constantize(:class_name)
  end

  should "provide a targetted Storage subclass with Storage.for" do
    class Paperclip::Storage; class DummyStore < Paperclip::Storage; end; end
    storage = Paperclip::Storage.for(:dummy_store)
    assert_equal Paperclip::Storage::DummyStore, storage.class
    assert storage.class.ancestors.include?(Paperclip::Storage)
  end

  should "raise a Paperclip error when a storage backend is not found" do
    assert_raises(Paperclip::StorageBackendNotFound){ Paperclip::Storage.for(:nothing) }
  end

  should "have an attachment accessor" do
    class Paperclip::Storage; class DummyStore < Paperclip::Storage; end; end
    storage = Paperclip::Storage.for(:dummy_store)

    storage.attachment = "12345"
    assert_equal "12345", storage.attachment
  end

  should "define a write method" do
    assert Paperclip::Storage.instance_methods.include?("write")
  end

  should "define a delete method" do
    assert Paperclip::Storage.instance_methods.include?("delete")
  end

  should "define a rename method" do
    assert Paperclip::Storage.instance_methods.include?("rename")
  end
end
