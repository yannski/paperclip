require 'test/helper'

class DefinitionTest < Test::Unit::TestCase
  context "A definition" do
    should "accept a :url a parameter and be able to return it" do
      d = Paperclip::Definition.new(:url => "my_url")
      assert_equal "my_url", d.url
    end

    should "accept a :path a parameter and be able to return it" do
      d = Paperclip::Definition.new(:path => "my_path")
      assert_equal "my_path", d.path
    end

    should "accept a :default_path a parameter and be able to return it" do
      d = Paperclip::Definition.new(:default_path => "my_default_path")
      assert_equal "my_default_path", d.default_path
    end

    should "accept a :default_url a parameter and be able to return it" do
      d = Paperclip::Definition.new(:default_url => "my_default_url")
      assert_equal "my_default_url", d.default_url
    end
  end
end
