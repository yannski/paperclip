require 'test/helper'

class ProcessorTest < Test::Unit::TestCase
  should "turn an underscored symbol into a class name with constantize" do
    assert_equal "ClassName", Paperclip::Processor.constantize(:class_name)
  end

  should "provide a targetted Processor subclass with Processor.for" do
    class Paperclip::Processor; class DummyProcessor < Paperclip::Processor; end; end
    processor = Paperclip::Processor.for(:dummy_processor)
    assert_equal Paperclip::Processor::DummyProcessor, processor.class
    assert processor.class.ancestors.include?(Paperclip::Processor)
  end

  should "raise a Paperclip error when a processor backend is not found" do
    assert_raises(Paperclip::ProcessorNotFound){ Paperclip::Processor.for(:nothing) }
  end

  should "define a make method that takes 3 arguments with 1 optional" do
    assert_equal -3, Paperclip::Processor.new.method(:make).arity
  end
end
