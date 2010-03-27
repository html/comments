# Include hook code here
require 'active_record'
require 'belongs_to_anything'
require 'hash4hash'

if defined?(ActiveRecord)
  ActiveRecord::Base::send :extend, BelongsToAnything::ActiveRecordExtension
end
require File.join(File.dirname(__FILE__), 'lib/comments')
