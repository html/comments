# Comments
require 'digest/md5'
require 'haml'

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

    def self.comments_response(obj, options = {})
      m = manager(options)

      CommentsResponse.new(
        :template => '/comments',
        :comment_template => '/comment',
        :comment_add_form_template => '/comment_add_form',
        :assign_variables => m.assign_variables
      )
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

    def method_name
      
    end

    def self.last_record_name
      @@record && @@record.name
    end

    def self.create_comment(data)
        record = CommentTopic.record_for(data.delete('record_name'))
        com = record.comments.new(data)

        com.save || com
      rescue 
        false
    end

    def assign_variables
      @plugin_manager.each_plugin_collect(:widgets)
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
      each_plugin_collect(:search_options)
    end

    #Returns all plugin classes with their names
    def self.plugins
      plugins = {}

      Plugins.constants.each do |const|
        plugin = Plugins.const_get(const)

        if plugin_superclass_is_abstract_plugin?(plugin)
          plugins[plugin.plugin_name] = plugin
        end
      end

      plugins.merge(@@plugins)
    end

    def self.plugin_superclass_is_abstract_plugin?(plugin)
      plugin.respond_to?(:ancestors) && plugin.ancestors.include?(AbstractPlugin)
    end

    def self.add_plugin(plugin)
      @@plugins[plugin.plugin_name] = plugin
    end

    def each_plugin &block
      @plugins.each &block
    end
    
    def each_plugin_collect(m)
      items = {}

      each_plugin do |key, plugin|
        items.merge!(plugin.send(m))
      end

      items
    end
  end

  class ViewManager
    # Used just as static variables
    cattr_accessor :current_comments_template
    cattr_accessor :current_comment

    @@view = nil

    def self.set_view(view)
      views_path = Pathname.new(File.join(File.dirname(__FILE__), '../views/')).realpath.to_s
      @@view = view
      @@view.view_paths << views_path
    end

    def self.template(name, options = {})
      @@view.render(:partial => name, :locals => options)
    end
  end

  class CommentsResponse
    def initialize(opts = {})
      reset_called_variables
      opts.each do |key, val|
        self.class.send(:attr_accessor, key)
        self.instance_variable_set("@#{key}", val)
      end
    end

    def reset_called_variables
      @called_variables = []
    end

    def get_assigned_variable(key)
      @called_variables << key
      assign_variables[key]
    end

    def check_for_not_rendered_widgets
      not_rendered = assign_variables.keys - @called_variables
      raise "Following widgets are not rendered: #{not_rendered.map(&:inspect).join ','}" unless not_rendered.empty?
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

    def widgets
      {}
    end
  end

  module Plugins
    class RecordName < AbstractPlugin
      def self.initially_enabled
        true
      end

      def self.plugin_name
        'record_name'
      end

      def widgets
        { :record_name => ViewManager::template('widgets/record_name', :record_name => Comments::Manager.last_record_name ) }
      end
    end

    class RemoveComment < AbstractPlugin
      def self.initially_enabled
        false
      end

      def self.plugin_name
        'remove_comment'
      end


      def widgets
        { :remove_comment_link => (lambda do ViewManager::template('widgets/remove_comment_link', :comment => ViewManager.current_comment) end) }
      end

      def self.reserved_options
        [:remove_comment_enabled]
      end
    end

    class SimpleCaptcha < AbstractPlugin 
      def initialize(opts = {})
        Comments::Comment.class_eval do |cl|
          cl.apply_simple_captcha :message => "Код captcha неправильний", :add_to_base => true
          alias :save :save_with_captcha
        end
      end

      def widgets
        { :simple_captcha => ViewManager::template('widgets/simple_captcha') }
      end

      def self.plugin_name
        'simple_captcha'
      end

      def self.initially_enabled
        defined?(::SimpleCaptcha)
      end
    end

    class RemoveCommentAsSpam < AbstractPlugin
      def self.initially_enabled
        false
      end

      def self.plugin_name
        'remove_comment_as_spam'
      end

      def self.reserved_options
        [:remove_comment_as_spam_enabled]
      end

      def search_options
        { :conditions => { :status => ['', 'possibly_spam', 'not_spam'] }}
      end

      def widgets
        { :remove_comment_as_spam_link => (lambda do ViewManager::template('widgets/remove_comment_as_spam_link', :comment => ViewManager.current_comment) end) }
      end
    end

    class Field < AbstractPlugin
      def self.initially_enabled
        false
      end

      def self.plugin_name
        'field'
      end
    end

    class ContentField < Field
      def self.initially_enabled
        true
      end

      def self.plugin_name
        'content_field'
      end

      def widgets
        { :content_field => (lambda do ViewManager::template("widgets/content_field", :comment => ViewManager.current_comment) end) }
      end
    end
  end

  module ViewHelpers
    def comments_for(item, args = {})
      Comments::ViewManager::set_view(self)
      
      actually_comments = Comments::Manager::list_comments_for(item, args)
      response = Comments::Manager::comments_response(item, args)
      @comment_partial = response.comment_template
      @comment_add_form_partial = response.comment_add_form_template
      @comments_response = response

      response.assign_variables.each do |key, val|
        instance_eval <<-INSTANCE_EVAL
          def #{key.to_s}(&block)
            if block_given?
              @comments_response.get_assigned_variable(#{key.inspect})
              block.call
            else
              var = @comments_response.get_assigned_variable(#{key.inspect})
              if var.respond_to?(:call)
                var.call
              else
                var
              end
            end
          end
        INSTANCE_EVAL
      end

      out = render :partial => response.template, :locals => { :items => actually_comments }

      unless actually_comments.empty?
        response.check_for_not_rendered_widgets
      end

      out
    end

    def count_comments_for(item, args = {})
      Comments::Manager::list_comments_for(item, args).count
    end

    def display_comments(args = {})
      comments_template :comments do
        comments_for(@controller, args)
      end
    end

    def display_comment(comment)
      ViewManager.current_comment = comment
      comments_template :comment do
        render :partial => @comment_partial, :locals => { :comment => comment }
      end
    end

    def comment_add_form
      comments_template :add_comment do
        render :partial => @comment_add_form_partial
      end
    end

    def comments_template(name, &block)
      old_template = ViewManager.current_comments_template
      ViewManager.current_comments_template = name
      return_value = yield
      ViewManager.current_comments_template = old_template
      return_value
    end

    def current_comments_template
      ViewManager.current_comments_template
    end
  end
end
