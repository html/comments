# Comments
require 'digest/md5'

module BelongsToAnything::Matchers
  def self.action_controller_matcher(obj)
    if defined?(ActionController::Base) && obj.is_a?(ActionController::Base) && obj.params
      [obj.params[:controller], obj.params[:action]]
    end
  end
end

module Comments
  class Comment < ActiveRecord::Base
  end

  class CommentTopic < ActiveRecord::Base
    belongs_to_anything
    has_many :comments, :foreign_key => 'topic_id'

    def get_comments(search_options)
      comments.find(:all, search_options)
    end
  end

  class Manager
    @@managers = {}
    @@record = nil

    def initialize(config)
      @config = config
      @plugin_manager = PluginManager.new(config)
    end

    def self.list_comments_for(obj, options = {})
      manager(options).comments(obj)
    end

    def self.manager(options)
      hash = hash4hash(options)

      unless @@managers[hash]
        @@managers[hash] = new(options)
      end

      @@managers[hash]
    end

    def self.hash4hash(hash)
      Digest::MD5.hexdigest(hash.value4hash)
    end

    def comments(obj)
      @@record = (CommentTopic.record_for(obj) || CommentTopic.create_record_for(obj))
      @@record.get_comments(@plugin_manager.search_options)
    end

    def self.last_record_name
      @@record && @@record.name
    end

    def self.create_comment(data)
        record = CommentTopic.record_for(data.delete('record_name'))
        com = record.comments.create!(data)
      rescue 
        false
    end
  end

  class PluginManager
    @@plugins = {}

    def initialize(config = {})
      @plugins = {}
      plugins =  self.class.plugins
      for i,p in plugins
        if p.initially_enabled || !(p.reserved_options & config.keys).empty?
          add(p) 
        end
      end
    end

    def add(plugin)
      if !@plugins[plugin.plugin_name]
        name = plugin.plugin_name
        plugin = plugin.new
        @plugins[name] = plugin
      end
    end

    def search_options
      @search_options = {}

      @plugins.each do |p|
        @search_options.merge(p.search_options)
      end

      @search_options
    end

    #Returns all plugin classes with their names
    def self.plugins
      plugins = {}

      Plugins.constants.each do |const|
        plugin = Plugins.const_get(const)

        if plugin.respond_to?(:superclass) && plugin.superclass == AbstractPlugin
          plugins[plugin.plugin_name] = plugin
        end
      end

      plugins.merge(@@plugins)
    end

    def self.add_plugin(plugin)
      @@plugins[plugin.plugin_name] = plugin
    end
  end

  class AbstractPlugin
    def self.plugin_name
      raise "Please name your plugin"
    end

    def self.initially_enabled
      false
    end

    def self.reserved_options
      []
    end

    def search_options
      {}
    end
  end

  module Plugins
  end
end
