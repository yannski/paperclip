require 'rubygems'

gem 'sqlite3-ruby'
gem 'jferris-mocha'

require 'test/unit'
require 'shoulda'
require 'tempfile'
require 'mocha'
require 'active_record'
require 'mime/types'
require 'fakefs/safe'

ROOT       = File.join(File.dirname(File.dirname(__FILE__)))
RAILS_ROOT = ROOT
RAILS_ENV  = "test"

$LOAD_PATH << File.join(ROOT, 'lib')
require 'paperclip'

FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures") 
config = YAML::load(IO.read(File.dirname(__FILE__) + '/config/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config['test'])

def temporary_rails_env(new_env)
  old_env = Object.const_defined?("RAILS_ENV") ? RAILS_ENV : nil
  silence_warnings do
    Object.const_set("RAILS_ENV", new_env)
  end
  yield
  silence_warnings do
    Object.const_set("RAILS_ENV", old_env)
  end
end

def silence_warnings
  old_verbose, $VERBOSE = $VERBOSE, nil
  yield
ensure
  $VERBOSE = old_verbose
end

def define_attachment! klass, attachment, options = {}
  ActiveRecord::Base.connection.create_table klass.tableize, :force => true do |table|
    table.column :other, :string
    table.column :"#{attachment}_file_name", :string
    table.column :"#{attachment}_content_type", :string
    table.column :"#{attachment}_file_size", :integer
    table.column :"#{attachment}_updated_at", :datetime
  end
  ActiveRecord::Base.send(:include, Paperclip)
  silence_warnings do
    new_klass = Object.const_set(klass, Class.new(ActiveRecord::Base))
    new_klass.class_eval do
      extend Paperclip
      has_attached_file attachment, options
    end
    new_klass
  end
end

def fixture_file(name)
  File.new(File.join(FIXTURES_DIR, name))
end

def fake_storage
  storage = stub
  storage.stubs(:attachment=)
  storage.stubs(:attachment)
  storage.stubs(:write)
  storage.stubs(:delete)
  storage.stubs(:rename)
  storage
end

class Paperclip::Null < Paperclip::Processor
  def make
    dst = Tempfile.new(@basename)
    dst.binmode
    dst.write(@file.read)

    @file.rewind
    dst.rewind

    dst
  end
end

FakeFS.activate!
FakeFS::FileSystem.clone(FIXTURES_DIR)
