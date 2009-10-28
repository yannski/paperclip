require 'test/helper'

class ProcessorTest < Test::Unit::TestCase
  should "turn an underscored symbol into a class name with constantize" do
    assert_equal "ClassName", Paperclip::Processor.constantize(:class_name)
  end

  should "provide a targetted Processor subclass with Processor.for" do
    class Paperclip::Processor; class DummyProcessor < Paperclip::Processor; end; end
    processor = Paperclip::Processor.for(:dummy_processor)
    assert_equal Paperclip::Processor::DummyProcessor, processor
    assert processor.ancestors.include?(Paperclip::Processor)
  end

  should "raise a Paperclip error when a processor backend is not found" do
    assert_raises(Paperclip::ProcessorNotFound){ Paperclip::Processor.for(:nothing) }
  end

  should "define a make method on the class that takes 3 arguments with 1 optional" do
    assert_equal -3, Paperclip::Processor.method(:make).arity
  end

  should "define a make instance method that does not take any arguments" do
    assert Paperclip::Processor.instance_methods.include?('make')
  end

  should "define a :file accessor" do
    assert Paperclip::Processor.instance_methods.include?('file')
    assert Paperclip::Processor.instance_methods.include?('file=')
  end

  should "define an :options accessor" do
    assert Paperclip::Processor.instance_methods.include?('options')
    assert Paperclip::Processor.instance_methods.include?('options=')
  end

  should "define an :attachment accessor" do
    assert Paperclip::Processor.instance_methods.include?('attachment')
    assert Paperclip::Processor.instance_methods.include?('attachment=')
  end
end
