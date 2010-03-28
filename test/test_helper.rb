require 'rubygems'
require 'active_support'
require 'action_controller'
require 'active_support/test_case'
require 'test/unit'
require 'shoulda'
require 'rr'
require 'ruby-debug'
require 'hpricot'
require File.dirname(__FILE__) + '/../init.rb'

if defined?(ActionView)
  require 'haml/helpers/action_view_mods'
  require 'haml/helpers/action_view_extensions'
  require 'haml/template'
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
old = $stdout
$stdout = StringIO.new

ActiveRecord::Schema.define(:version => 1) do
  create_table :comment_topics do |t|
    t.column :name, :string
  end

  create_table :comments do |t|
    t.column :content, :text
    t.column :topic_id, :integer
  end
end


$stdout = old

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end
