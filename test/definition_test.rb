require 'test/helper'

class DefinitionTest < Test::Unit::TestCase
  context "A definition" do
    [:url, :path, :default_url, :default_style, :whiny_processing].each do |field|
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
    should "return a Style object corresponding to the style key merged with the all_styles values" do
      d = Paperclip::Definition.new(:all_styles => {:three => :four},
                                    :styles => {:thumb => {:one => :two}})
      assert_equal :two, d.style(:thumb).one
      assert_equal :four, d.style(:thumb).three
    end
    should "return a Style object corresponding to the style key with the right values" do
      d = Paperclip::Definition.new(:styles => {:thumb => {:one => :two}})
      assert_equal :two, d.style(:thumb).one
    end
    context "returning a Storage object on call to #storage" do
      setup{ @definition = Paperclip::Definition.new }
      should "return a Storage object" do
        assert_kind_of Paperclip::Definition::Storage, @definition.storage
      end
      should "return the default method" do
        assert_equal :filesystem, @definition.storage.method
      end
    end
    context "returning a Storage object configured for S3" do
      setup{ @definition = Paperclip::Definition.new :storage => :s3,
                                                     :s3_permissions => StringIO.new("key: value"),
                                                     :s3_options => {:one => :two},
                                                     :s3_protocol => "https",
                                                     :s3_headers => {'Content-type' => 'text/plain'},
                                                     :s3_host_alias => "test.example.com",
                                                     :bucket => "bucket" }
      should "return a Storage object with an S3 method" do
        assert_equal :s3, @definition.storage.method
      end
      should "return the bucket when asked" do
        assert_equal "bucket", @definition.storage.bucket
      end
      should "return the headers when asked" do
        assert_equal({'Content-type' => 'text/plain'}, @definition.storage.headers)
      end
      should "return the host_alias when asked" do
        assert_equal "test.example.com", @definition.storage.host_alias
      end
      should "return the protocol when asked" do
        assert_equal "https", @definition.storage.protocol
      end
      should "return the credentials when asked" do
        assert_equal({'key' => 'value'}, @definition.storage.credentials)
      end
    end

    context "created with no options" do
      setup { @definition = Paperclip::Definition.new }
      [:url, :path, :default_url, :default_style, :whiny_processing].each do |field|
        should "have the right default value of #{field}" do
          assert_equal Paperclip::Definition.default_options[field], @definition.send(field)
        end
      end
    end

    context "created with no options and different defaults" do
      setup do
        Paperclip::Definition.default_options[:path]             = 1
        Paperclip::Definition.default_options[:url]              = 2
        Paperclip::Definition.default_options[:default_style]    = 3
        Paperclip::Definition.default_options[:default_url]      = 4
        Paperclip::Definition.default_options[:whiny_processing] = 5
        @definition = Paperclip::Definition.new
      end
      [:url, :path, :default_url, :default_style, :whiny_processing].each do |field|
        should "have the right default value of #{field}" do
          assert_equal Paperclip::Definition.default_options[field], @definition.send(field)
        end
      end
    end
  end

  context "An Options object" do
    setup{ @options = Paperclip::Definition::Options.new }
    should "create an accessor when unknown setters are called" do
      assert ! @options.respond_to?(:non_method)
      @options.non_method = "123"
      assert_equal "123", @options.non_method
    end
    should "create an accessor when blocks are passed to unknown methods" do
      block = lambda{ puts "Hi!" }
      assert ! @options.respond_to?(:non_method)
      @options.non_method &block
      assert_equal block, @options.non_method
    end
    should "return nil when unknown getters are called" do
      assert ! @options.respond_to?(:non_method)
      assert_nil @options.non_method
    end
    should "merge with other options instances" do
      options2 = Paperclip::Definition::Options.new
      options2.key = "value"
      @options.something = "something"
      result = @options.merge(options2)
      assert_equal "value", result.key
      assert_equal "something", result.something
    end
  end

  context "An Options object being initialized" do
    setup{ @options = Paperclip::Definition::Options.new(:one => :two, :three => :four) }
    should "have methods named after the keys in the argument hash" do
      assert_equal :two, @options.one
      assert_equal :four, @options.three
    end
  end

  context "A Storage" do
    should "return an S3 subclass when asked with #for" do
      assert Paperclip::Definition::Storage.for(:s3).is_a?(Paperclip::Definition::Storage::S3)
    end
    should "return a Filesystem subclass when asked with #for" do
      assert Paperclip::Definition::Storage.for(:filesystem).is_a?(Paperclip::Definition::Storage::Filesystem)
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

  context "A style accepting a hash" do
    setup{ @style = Paperclip::Definition::Style.new(:geometry => "100x100", :format => :png) }
    should "set the format to the argument" do
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
end
