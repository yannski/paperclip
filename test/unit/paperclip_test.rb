require 'test/helper'

class PaperclipTest < Test::Unit::TestCase
  def setup
    @now = Time.now
    Time.stubs(:now).returns(@now)
  end

  should "include UploadedFile into File" do
    File.stubs(:include)
    silence_warnings do
      EmptyClass = Class.new
      EmptyClass.class_eval do
        include Paperclip
      end
    end

    assert_received(File, :include){|f| f.with(Paperclip::UploadedFile) }
  end

  should "include UploadedFile into StringIO" do
    StringIO.stubs(:include)
    silence_warnings do
      EmptyClass = Class.new
      EmptyClass.class_eval do
        include Paperclip
      end
    end

    assert_received(StringIO, :include){|f| f.with(Paperclip::UploadedFile) }
  end

  should "shell the command out with Paperclip.run" do
    Paperclip.options[:command_path] = nil
    return_value = Paperclip.run("echo", "Hello")
    assert_equal "Hello\n", return_value
  end

  context "Paperclip.run" do
    setup do
      Paperclip.stubs(:`)
      Paperclip.options[:command_path] = nil
      Paperclip.options[:swallow_stderr] = false
    end

    should "prepend Paperclip.options[:command_path] to commands if it is set" do
      Paperclip.options[:command_path] = "/bin"
      Paperclip.run("echo", "Hello")
      assert_received(Paperclip, :`){|s| s.with("/bin/echo Hello") }
    end

    should "not prepend Paperclip.options[:command_path] to commands if it is nil" do
      Paperclip.run("echo", "Hello")
      assert_received(Paperclip, :`){|s| s.with("echo Hello") }
    end

    should "raise Paperclip::CommandLineError if the result value is in the expected values list" do
      Paperclip.stubs(:run_result).returns(1)
      assert_nothing_raised{ Paperclip.run("echo", "Hello", 1) }
    end

    should "raise Paperclip::CommandLineError if the result value is not in the expected_values list" do
      Paperclip.stubs(:run_result).returns(1)
      assert_raises(Paperclip::CommandLineError){ Paperclip.run("echo", "Hello", 2) }
    end

    should "raise Paperclip::CommandNotFound if #run returns an exit code of 127" do
      Paperclip.stubs(:run_result).returns(127)
      assert_raises(Paperclip::CommandNotFound){ Paperclip.run("echo", "Hello") }
    end

    should "redirect stderr to /dev/null on unix systems when :swallow_stderr is true" do
      Paperclip.options[:swallow_stderr] = true
      File.stubs(:exists?).with("/dev/null").returns(true)
      Paperclip.run("echo", "Hello")
      assert_received(Paperclip, :`){|s| s.with("echo Hello 2>/dev/null") }
    end

    should "redirect stderr to NUL on non-unix systems when :swallow_stderr is true" do
      Paperclip.options[:swallow_stderr] = true
      File.stubs(:exists?).with("/dev/null").returns(false)
      Paperclip.run("echo", "Hello")
      assert_received(Paperclip, :`){|s| s.with("echo Hello 2>NUL") }
    end
  end
end

