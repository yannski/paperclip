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

  should "define a write method that takes 2 arguments" do
    assert_equal 2, Paperclip::Storage.new.method(:write).arity
  end

  should "define a delete method that takes 1 argument" do
    assert_equal 1, Paperclip::Storage.new.method(:delete).arity
  end

  should "define a rename method that takes 2 arguments" do
    assert_equal 2, Paperclip::Storage.new.method(:rename).arity
  end
end
