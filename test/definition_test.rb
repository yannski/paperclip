require 'test/helper'

class DefinitionTest < Test::Unit::TestCase
  context "A definition" do
    [:url, :path, :default_path, :default_style, :whiny_processing].each do |field|
      should "accept a #{field.inspect} a parameter and be able to return it" do
        d = Paperclip::Definition.new(field => "my_#{field}")
        assert_equal "my_#{field}", d.send(field)
      end
    end

    should "accept a :styles hash and make its keys available via #style and return Style objects" do
      d = Paperclip::Definition.new(:styles => {:thumb => {}})
      assert_kind_of Paperclip::Definition::Style, d.style(:thumb)
    end

    should "normalize hashes passed as styles to a standard format" do
      d = Paperclip::Definition.new(:styles => {:thumb => {}})
      assert_equal [:thumbnail], d.style(:thumb).processors
    end
  end

  context "A style accepting an non-empty hash" do
    setup do
      @style = Paperclip::Definition::Style.new({
        :key => "value",
        :convert_options => "123",
        :processors => [:none],
        :whiny_processing => false
      })
    end
    should "access the :key key with a accessor" do
      assert_equal "value", @style.key
    end
    should "not set the default processors" do
      assert_equal [:none], @style.processors
    end
    should "not set the default convert_options" do
      assert_equal "123", @style.convert_options
    end
    should "not set the default whiny value" do
      assert_equal false, @style.whiny_processing
    end
  end

  context "A style accepting an empty hash" do
    setup{ @style = Paperclip::Definition::Style.new({}) }
    should "set the default processors" do
      assert_equal [:thumbnail], @style.processors
    end
    should "set the default convert_options" do
      assert_equal nil, @style.convert_options
    end
    should "set the default whiny value" do
      assert_equal true, @style.whiny_processing
    end
  end

  context "A style accepting a geometry string and format" do
    setup{ @style = Paperclip::Definition::Style.new("100x100", :png) }
    should "set the format to png" do
      assert_equal :png, @style.format
    end
    should "set the geometry to the argument" do
      assert_equal "100x100", @style.geometry
    end
    should "set the default processors" do
      assert_equal [:thumbnail], @style.processors
    end
    should "set the default convert_options" do
      assert_equal nil, @style.convert_options
    end
    should "set the default whiny value" do
      assert_equal true, @style.whiny_processing
    end
  end

  context "A style accepting a geometry string" do
    setup{ @style = Paperclip::Definition::Style.new("100x100") }
    should "set the format to nil" do
      assert_nil @style.format
    end
    should "set the geometry to the argument" do
      assert_equal "100x100", @style.geometry
    end
    should "set the default processors" do
      assert_equal [:thumbnail], @style.processors
    end
    should "set the default convert_options" do
      assert_equal nil, @style.convert_options
    end
    should "set the default whiny value" do
      assert_equal true, @style.whiny_processing
    end
  end

  context "A style object" do
    setup{ @style = Paperclip::Definition::Style.new({}) }
    should "create accessors from keys when sent to #methodize" do
      @style.methodize(:one => "two")
      assert @style.respond_to?(:one)
      assert_equal "two", @style.one
    end
    should "merge another style when sent #merge!" do
      @style2 = Paperclip::Definition::Style.new({:one => "two"})
      @style3 = @style.merge(@style2)
      assert_equal "two", @style3.one
    end
  end
end
