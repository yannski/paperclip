require 'test/helper'

class Model
  # This is a model class
end

class AttachmentTest < Test::Unit::TestCase
  context "An attachment with similarly named interpolations" do
    setup do
      @attachment = mock_attachment :avatar, :path => ":id.omg/:id-bbq/:idwhat/:id_partition.wtf"
      @attachment.instance.stubs(:id).returns(1024)
      @attachment.assign StringIO.new(".")
    end

    should "make sure that they are interpolated correctly" do
      assert_equal "1024.omg/1024-bbq/1024what/000/001/024.wtf", @attachment.path
    end
  end

  context "An attachment with a :rails_env interpolation" do
    setup do
      @attachment = mock_attachment :avatar, :path => ":rails_env/no.png"
      @attachment.assign StringIO.new(".")
    end

    should "return the proper path" do
      temp_env = "blah"
      temporary_rails_env(temp_env) do
        assert_equal "#{temp_env}/no.png", @attachment.path
      end
    end
  end
  
  should "An attachment with :path that is a proc should return the correct path" do
    @model = mock_instance :avatar
    @model.expects(:other).returns("a")
    @definition = Paperclip::Definition.new :path => lambda{|a| "path/#{a.instance.other}.:extension" }
    @attachment = Paperclip::Attachment.new :avatar, @model, @definition
    @attachment.stubs(:original_filename).returns("file.png")
    assert_equal "path/a.png", @attachment.path
  end
 
  should "An attachment with :url that is a proc should return the correct path" do
    @model = mock_instance :avatar
    @model.expects(:other).returns("a")
    @definition = Paperclip::Definition.new :url => lambda{ |a| "path/#{a.instance.other}.:extension" }
    @attachment = Paperclip::Attachment.new :avatar, @model, @definition
    @attachment.stubs(:original_filename).returns("file.png")
    assert_equal "path/a.png", @attachment.url
  end

  context "An attachment with erroring processor" do
    setup do
      @attachment = mock_attachment :avatar, :processors => [:thumbnail],
                                             :styles => { :small => '' },
                                             :whiny_processing => true
      @model = @attachment.instance
      Paperclip::Thumbnail.expects(:make).raises(Paperclip::PaperclipError, "cannot be processed.")
      @file = StringIO.new("...")
      @file.stubs(:to_tempfile).returns(@file)
      @attachment.assign @file
      @attachment.valid?
    end

    should "have a validation error" do
      assert_equal( {:processing => ["cannot be processed."]}, @attachment.errors )
    end
  end

  context "An attachment with multiple processors" do
    setup do
      class Paperclip::Test < Paperclip::Processor; end
      @style_params = { :once => {:one => 1, :two => 2} }
      @attachment = mock_attachment :avatar, :processors => [:thumbnail, :test],
                                             :styles => @style_params
      @file = StringIO.new("...")
      @file.stubs(:to_tempfile).returns(@file)
      Paperclip::Test.stubs(:make).returns(@file)
      Paperclip::Thumbnail.stubs(:make).returns(@file)
    end

    context "when assigned" do
      setup { @attachment.assign @file }

      before_should "call #make on all specified processors" do
        expected_params = @attachment.definition.style(:once)
        Paperclip::Thumbnail.expects(:make).with(@file, expected_params, @attachment).returns(@file)
        Paperclip::Test.expects(:make).with(@file, expected_params, @attachment).returns(@file)
      end
      
      before_should "call #make with attachment passed as third argument" do
        expected_params = @attachment.definition.style(:once)
        Paperclip::Test.expects(:make).with(@file, expected_params, @attachment).returns(@file)
      end
    end
  end

  context "An attachment with no processors defined" do
    setup do
      @attachment = mock_attachment :avatar, :processors => [], :styles => {:something => {}}
      @model = Model.new
      @file = StringIO.new("...")
    end
    should "raise when assigned to" do
      assert_raises(RuntimeError){ @attachment.assign @file }
    end
  end

  context "Assigning an attachment with post_process hooks" do
    setup do
      rebuild_model :styles => { :something => "100x100#" }
      Model.class_eval do
        before_avatar_post_process :do_before_avatar
        after_avatar_post_process :do_after_avatar
        before_post_process :do_before_all
        after_post_process :do_after_all
        def do_before_avatar; end
        def do_after_avatar; end
        def do_before_all; end
        def do_after_all; end
      end
      @file  = StringIO.new(".")
      @file.stubs(:to_tempfile).returns(@file)
      @model = Model.new
      Paperclip::Thumbnail.stubs(:make).returns(@file)
      @attachment = @model.avatar
    end

    should "call the defined callbacks when assigned" do
      @model.expects(:do_before_avatar).with()
      @model.expects(:do_after_avatar).with()
      @model.expects(:do_before_all).with()
      @model.expects(:do_after_all).with()
      Paperclip::Thumbnail.expects(:make).returns(@file)
      @model.avatar = @file
    end

    should "not cancel the processing if a before_post_process returns nil" do
      @model.expects(:do_before_avatar).with().returns(nil)
      @model.expects(:do_after_avatar).with()
      @model.expects(:do_before_all).with().returns(nil)
      @model.expects(:do_after_all).with()
      Paperclip::Thumbnail.expects(:make).returns(@file)
      @model.avatar = @file
    end

    should "cancel the processing if a before_post_process returns false" do
      @model.expects(:do_before_avatar).never
      @model.expects(:do_after_avatar).never
      @model.expects(:do_before_all).with().returns(false)
      @model.expects(:do_after_all).never
      Paperclip::Thumbnail.expects(:make).never
      @model.avatar = @file
    end

    should "cancel the processing if a before_avatar_post_process returns false" do
      @model.expects(:do_before_avatar).with().returns(false)
      @model.expects(:do_after_avatar).never
      @model.expects(:do_before_all).with().returns(true)
      @model.expects(:do_after_all).never
      Paperclip::Thumbnail.expects(:make).never
      @model.avatar = @file
    end
  end

  context "Assigning an attachment" do
    setup do
      @attachment = mock_attachment :avatar, :styles => { :something => "100x100#" }
      @file  = StringIO.new(".")
      @file.expects(:original_filename).returns("5k.png\n\n")
      @file.expects(:content_type).returns("image/png\n\n")
      @file.stubs(:to_tempfile).returns(@file)
      @model = @attachment.instance
      Paperclip::Thumbnail.expects(:make).returns(@file)
      @model.expects(:run_callbacks).with(:before_avatar_post_process, {:original => @file})
      @model.expects(:run_callbacks).with(:before_post_process, {:original => @file})
      @model.expects(:run_callbacks).with(:after_avatar_post_process, {:original => @file, :something => @file})
      @model.expects(:run_callbacks).with(:after_post_process, {:original => @file, :something => @file})
      @attachment.assign @file
    end

    should "strip whitespace from original_filename field" do
      assert_equal "5k.png", @attachment.original_filename
    end

    should "strip whitespace from content_type field" do
      assert_equal "image/png", @attachment.instance_read(:content_type)
    end
  end

  context "Attachment with strange letters" do
    setup do
      @instance = mock_instance(:avatar)
      @attachment = Paperclip::Attachment.new(:avatar, @instance, Paperclip::Definition.new)
      @file = StringIO.new(".")
      @file.expects(:original_filename).returns("sheep_say_bæ.png\r\n")
      @attachment.assign(@file)
    end
    should "remove strange letters and replace with underscore (_)" do
      assert_equal "sheep_say_b_.png", @attachment.original_filename
    end
  end

  context "An attachment" do
    setup do
      @def = Paperclip::Definition.new :path => ":rails_root/tmp/:attachment/:class/:style/:id/:basename.:extension"
      FileUtils.rm_rf("tmp")
      rebuild_model
      @instance = Model.new
      @attachment = Paperclip::Attachment.new(:avatar, @instance, @def)
      @file = StringIO.new(".")
    end

    should "raise if there are not the correct columns when you try to assign" do
      @other_attachment = Paperclip::Attachment.new(:not_here, @instance, @def)
      assert_raises(Paperclip::PaperclipError) do
        @other_attachment.assign(@file)
      end
    end

    should "return its default_url when no file assigned" do
      assert @attachment.to_file.nil?
      assert_equal "/avatars/original/missing.png", @attachment.url
      assert_equal "/avatars/blah/missing.png", @attachment.url(:blah)
    end
    
    should "return nil as path when no file assigned" do
      assert @attachment.to_file.nil?
      assert_equal nil, @attachment.path
      assert_equal nil, @attachment.path(:blah)
    end
    
    context "with a file assigned in the database" do
      setup do
        @attachment.stubs(:instance_read).with(:file_name).returns("5k.png")
        @attachment.stubs(:instance_read).with(:content_type).returns("image/png")
        @attachment.stubs(:instance_read).with(:file_size).returns(12345)
        now = Time.now
        Time.stubs(:now).returns(now)
        @attachment.stubs(:instance_read).with(:updated_at).returns(Time.now)
      end

      should "return a correct url even if the file does not exist" do
        assert_nil @attachment.to_file
        assert_match %r{^/system/avatars/#{@instance.id}/blah/5k\.png}, @attachment.url(:blah)
      end

      should "make sure the updated_at mtime is in the url if it is defined" do
        assert_match %r{#{Time.now.to_i}$}, @attachment.url(:blah)
      end
 
      should "make sure the updated_at mtime is NOT in the url if false is passed to the url method" do
        assert_no_match %r{#{Time.now.to_i}$}, @attachment.url(:blah, false)
      end

      context "with the updated_at field removed" do
        setup do
          @attachment.stubs(:instance_read).with(:updated_at).returns(nil)
        end

        should "only return the url without the updated_at when sent #url" do
          assert_match "/avatars/#{@instance.id}/blah/5k.png", @attachment.url(:blah)
        end
      end

      should "return the proper path when filename has a single .'s" do
        assert_equal "./test/../tmp/avatars/models/original/#{@instance.id}/5k.png", @attachment.path
      end

      should "return the proper path when filename has multiple .'s" do
        @attachment.stubs(:instance_read).with(:file_name).returns("5k.old.png")      
        assert_equal "./test/../tmp/avatars/models/original/#{@instance.id}/5k.old.png", @attachment.path
      end

      context "when expecting three styles" do
        setup do
          styles = Paperclip::Definition.new :styles => { :large  => ["400x400", :png],
                                                          :medium => ["100x100", :gif],
                                                          :small => ["32x32#", :jpg]}
          @attachment = Paperclip::Attachment.new(:avatar,
                                                  @instance,
                                                  styles)
        end

        context "and assigned a file" do
          setup do
            now = Time.now
            Time.stubs(:now).returns(now)
            @attachment.assign(@file)
          end

          should "be dirty" do
            assert @attachment.dirty?
          end

          context "and saved" do
            setup do
              @attachment.save
            end

            should "return the real url" do
              file = @attachment.to_file
              assert file
              assert_match %r{^/system/avatars/#{@instance.id}/original/5k\.png}, @attachment.url
              assert_match %r{^/system/avatars/#{@instance.id}/small/5k\.jpg}, @attachment.url(:small)
              file.close
            end

            should "commit the files to disk" do
              [:large, :medium, :small].each do |style|
                io = @attachment.to_io(style)
                assert File.exists?(io)
                assert ! io.is_a?(::Tempfile)
                io.close
              end
            end

            should "save the files as the right formats and sizes" do
              [[:large, 400, 61, "PNG"],
               [:medium, 100, 15, "GIF"],
               [:small, 32, 32, "JPEG"]].each do |style|
                cmd = %Q[identify -format "%w %h %b %m" "#{@attachment.path(style.first)}"]
                out = `#{cmd}`
                width, height, size, format = out.split(" ")
                assert_equal style[1].to_s, width.to_s 
                assert_equal style[2].to_s, height.to_s
                assert_equal style[3].to_s, format.to_s
              end
            end

            should "still have its #file attribute not be nil" do
              assert ! (file = @attachment.to_file).nil?
              file.close
            end

            context "and trying to delete" do
              setup do
                @existing_names = @attachment.styles.keys.collect do |style|
                  @attachment.path(style)
                end
              end

              should "delete the files after assigning nil" do
                @attachment.expects(:instance_write).with(:file_name, nil)
                @attachment.expects(:instance_write).with(:content_type, nil)
                @attachment.expects(:instance_write).with(:file_size, nil)
                @attachment.expects(:instance_write).with(:updated_at, nil)
                @attachment.assign nil
                @attachment.save
                @existing_names.each{|f| assert ! File.exists?(f) }
              end

              should "delete the files when you call #clear and #save" do
                @attachment.expects(:instance_write).with(:file_name, nil)
                @attachment.expects(:instance_write).with(:content_type, nil)
                @attachment.expects(:instance_write).with(:file_size, nil)
                @attachment.expects(:instance_write).with(:updated_at, nil)
                @attachment.clear
                @attachment.save
                @existing_names.each{|f| assert ! File.exists?(f) }
              end

              should "delete the files when you call #delete" do
                @attachment.expects(:instance_write).with(:file_name, nil)
                @attachment.expects(:instance_write).with(:content_type, nil)
                @attachment.expects(:instance_write).with(:file_size, nil)
                @attachment.expects(:instance_write).with(:updated_at, nil)
                @attachment.destroy
                @existing_names.each{|f| assert ! File.exists?(f) }
              end
            end
          end
        end
      end

    end

    context "when trying a nonexistant storage type" do
      setup do
        rebuild_model :storage => :not_here
      end

      should "not be able to find the module" do
        assert_raise(NameError){ Model.new.avatar }
      end
    end
  end

  context "An attachment with only a avatar_file_name column" do
    setup do
      ActiveRecord::Base.connection.create_table :models, :force => true do |table|
        table.column :avatar_file_name, :string
      end
      rebuild_class "Model"
      @model = Model.new
      @file = StringIO.new(".")
    end

    should "not error when assigned an attachment" do
      assert_nothing_raised { @model.avatar = @file }
    end

    should "return the time when sent #avatar_updated_at" do
      now = Time.now
      Time.stubs(:now).returns(now)
      @attachment.assign @file
      assert now, @model.avatar.updated_at
    end

    should "return nil when reloaded and sent #avatar_updated_at" do
      @model.save
      @model.reload
      assert_nil @model.avatar.updated_at
    end

    should "return the right value when sent #avatar_file_size" do
      @attachment.assign @file
      assert_equal @file.size, @model.avatar.size
    end

    context "and avatar_updated_at column" do
      setup do
        ActiveRecord::Base.connection.add_column :models, :avatar_updated_at, :timestamp
        rebuild_class
        @model = Model.new
      end

      should "not error when assigned an attachment" do
        assert_nothing_raised { @model.avatar = @file }
      end

      should "return the right value when sent #avatar_updated_at" do
        now = Time.now
        Time.stubs(:now).returns(now)
        @attachment.assign @file
        assert_equal now.to_i, @model.avatar.updated_at
      end
    end

    context "and avatar_content_type column" do
      setup do
        ActiveRecord::Base.connection.add_column :models, :avatar_content_type, :string
        rebuild_class
        @model = Model.new
      end

      should "not error when assigned an attachment" do
        assert_nothing_raised { @model.avatar = @file }
      end

      should "return the right value when sent #avatar_content_type" do
        @attachment.assign @file
        assert_equal "image/png", @model.avatar.content_type
      end
    end

    context "and avatar_file_size column" do
      setup do
        ActiveRecord::Base.connection.add_column :models, :avatar_file_size, :integer
        rebuild_class
        @model = Model.new
      end

      should "not error when assigned an attachment" do
        assert_nothing_raised { @model.avatar = @file }
      end

      should "return the right value when sent #avatar_file_size" do
        @attachment.assign @file
        assert_equal @file.size, @model.avatar.size
      end

      should "return the right value when saved, reloaded, and sent #avatar_file_size" do
        @model.avatar = @file
        @model.save
        @model = Model.find(@model.id)
        assert_equal @file.size, @model.avatar.size
      end
    end
  end
end
