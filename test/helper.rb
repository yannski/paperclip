require 'rubygems'
require 'test/unit'
gem 'thoughtbot-shoulda', ">= 2.9.0"
require 'shoulda'
require 'mocha'
require 'tempfile'

gem 'sqlite3-ruby'

require 'active_record'
require 'active_support'
begin
  require 'ruby-debug'
rescue LoadError
  puts "ruby-debug not loaded"
end

ROOT       = File.join(File.dirname(__FILE__), '..')
RAILS_ROOT = ROOT
RAILS_ENV  = "test"

$LOAD_PATH << File.join(ROOT, 'lib')
$LOAD_PATH << File.join(ROOT, 'lib', 'paperclip')

require File.join(ROOT, 'lib', 'paperclip.rb')

require 'shoulda_macros/paperclip'

ENV['RAILS_ENV'] ||= 'test'

FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures") 
config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config['test'])

def force_table table_name, &block
  block ||= lambda{ true }
  ActiveRecord::Base.connection.create_table table_name, {:force => true}, &block
end

def rebuild_table table_name, attachment_name
  force_table table_name do |table|
    table.column :other, :string
    table.column :"#{attachment_name}_file_name", :string
    table.column :"#{attachment_name}_content_type", :string
    table.column :"#{attachment_name}_file_size", :integer
    table.column :"#{attachment_name}_updated_at", :datetime
  end
end

def rebuild_class class_name
  ActiveRecord::Base.send(:include, Paperclip)
  Object.send(:remove_const, class_name) rescue nil
  Object.const_set(class_name, Class.new(ActiveRecord::Base))
  Object.const_get(class_name).class_eval do
    include Paperclip
  end
end

def rebuild_model options = {}
  rebuild_table :models, :avatar unless table_exists?(:models)
  rebuild_class "Model"
  Model.has_attached_file :avatar, options
end

def table_exists? name
  @exists ||= ActiveRecord::Base.connection.table_exists?(name)
end

def temporary_rails_env(new_env)
  old_env = defined?(RAILS_ENV) ? RAILS_ENV : nil
  silence_warnings do
    Object.const_set("RAILS_ENV", new_env)
  end
  yield
  silence_warnings do
    Object.const_set("RAILS_ENV", old_env)
  end
end

def fixture_file filename, &blk
  File.open(File.join(File.dirname(__FILE__), "fixtures", filename), "rb", &blk)
end

def mock_instance attachment
  instance = mock
  klass = mock
  klass.stubs(:column_names).returns(["#{attachment}_file_name"])
  instance.stubs(:class).returns(klass)
  instance.stubs(:errors).returns([])
  instance.stubs(:run_callbacks)
  (class << instance; self; end).class_eval do
    attr_accessor :"#{attachment}_file_name"
  end
  instance
end

def mock_attachment attachment, options
  model = mock_instance :avatar
  definition = Paperclip::Definition.new options
  attachment = Paperclip::Attachment.new attachment, model, definition
end
