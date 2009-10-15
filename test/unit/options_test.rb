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

   context "On creation of a new, empty options object" do
     setup do
       @options = Paperclip::Options.new
     end

     should "have a default path" do
       assert_equal ":rails_root/public/:url", @options[:path]
     end

     should "have a default url" do
       assert_equal "system/:class/:attachment/:id_partition/:style/:filename", @options[:url]
     end

     should "have a default default_url" do
       assert_equal "system/:class/:attachment/default/:style.jpg", @options[:default_url]
     end

     should "have a default default_style" do
       assert_equal :original, @options[:default_style]
     end

     should "have a default original style which does nothing" do
       assert_equal [:original], @options[:styles].keys
       assert_equal({}, @options[:styles][:original])
     end

     should "have a default storage backend and set of options" do
       assert_equal({:backend => :filesystem}, @options[:storage])
     end
   end
 end
