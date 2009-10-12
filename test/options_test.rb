 require 'test/helper'

 class OptionsTest < Test::Unit::TestCase
   should "convert a hash of expected parameters into methods" do
     expected = { :url => :url_value, :path => :path_value, :default_url => :default_url_value }
     options = Paperclip::Options.new(expected)
     expected.each do |key, value|
       assert_equal value, options.send(key)
     end
   end

   should "be able to access its values with hash syntax" do
     expected = { :url => :url_value, :path => :path_value, :default_url => :default_url_value }
     options = Paperclip::Options.new(expected)
     expected.each do |key, value|
       assert_equal value, options[key]
     end
   end
 end
