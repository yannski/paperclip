require 'test/helper'

class PaperclipTest < Test::Unit::TestCase
  def setup
    @now = Time.now
    Time.stubs(:now).returns(@now)
  end

  should "include UploadedFile into File" do
  end

  should "include UploadedFile into StringIO" do
  end

end

