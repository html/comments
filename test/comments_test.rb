require 'test_helper'

class CommentsTest < ActiveSupport::TestCase
  context "ActionView::Base" do
    context "instance" do
      setup do
        @view = ActionView::Base.new
        stub(@view).protect_against_forgery? { false }
        stub(@view).url_for { '' }
      end

      should "be extended by Comments::ViewHelpers module" do
        assert_respond_to @view, :comments_for
        assert_respond_to @view, :display_comments
      end

      context "#comments_for" do
        should "return string when there are no comments" do
          output = @view.comments_for('some namespace')
          assert_instance_of String, output
        end

        should "return string when there are some comments" do
          Comments::Manager::create_comment({ 'record_name' => '^^' })

          output = @view.comments_for('^^')
          assert_instance_of String, output
        end
      end

      context "#count_comments_for" do
        should "return correct count" do
          assert_equal 0, @view.count_comments_for('xxx')
          Comments::CommentTopic::record_for('xxx').comments.create! :content => 'test'
          assert_equal 1, @view.count_comments_for('xxx')
        end
      end
    end
  end

  context "Comments::AbstractPlugin" do
    context "AbstractPlugin::plugin_name" do
      should "raise error" do
        assert_raise RuntimeError do
          Comments::AbstractPlugin::plugin_name
        end
      end

      context "instance" do
        should "return no widgets" do
          assert_equal({}, Comments::AbstractPlugin.new.widgets)
        end
      end
    end
  end

  context "Comments::Manager::hash_for_hash" do
    should "return an md5 hash" do
      str = Comments::Manager::hash4hash({})
      assert_not_nil str
      assert_equal 32, str.size 
    end

    should "return equal md5 hashes for hashes with different order" do
      assert_equal Comments::Manager::hash4hash({ :a => :b, :c => :d}), Comments::Manager::hash4hash({:c => :d, :a => :b})
    end
  end

  context "Comments::Manager::manager" do
    should "return Comments::Manager instance" do
      manager = Comments::Manager::manager({})
      assert manager.is_a?(Comments::Manager)
    end
  end

  context "given option for initially disabled plugin" do
    should "enable plugin" do
      
    end
  end

  context "Comments::PluginManager" do
    context "::plugins" do
      should "contain plugins from Comments::Plugins module" do
        module Comments::Plugins
          class TestPlugin < Comments::AbstractPlugin
            def self.plugin_name
              'test'
            end
          end
        end
         
        assert_equal Comments::Plugins::TestPlugin, Comments::PluginManager::plugins['test']
      end

      should "not contain object from Comments::Plugins module if object is does not inherit AbstractPlugin" do
        old_plugins = Comments::PluginManager::plugins

        module Comments::Plugins
          TEST = 'asdf'
        end

        assert_equal old_plugins, Comments::PluginManager::plugins
      end

      should "contain manually added classes" do
        class AnotherTestPlugin < Comments::AbstractPlugin
          def self.plugin_name
            'another_test_plugin'
          end
        end

        Comments::PluginManager::add_plugin(AnotherTestPlugin)

        assert_equal AnotherTestPlugin, Comments::PluginManager::plugins['another_test_plugin']
      end
    end
  end

  context "#new" do
    context "PluginManager" do
      should "create instances for initially_enabled" do
        class Test1 < Comments::AbstractPlugin
          def self.plugin_name;'test1';end
          def self.initially_enabled;true;end
        end
        class Test2 < Comments::AbstractPlugin
          def self.plugin_name;'test2';end
          def self.initially_enabled;false;end
        end

        stub(Comments::PluginManager).plugins do 
          { 'test1' => Test1, 'test2' => Test2 }
        end

        pm = Comments::PluginManager.new
        assert_equal pm.instance_variable_get('@plugins').keys, ['test1']
        assert pm.instance_variable_get('@plugins')['test1'].is_a?(Test1)
      end

      should "create instances if not initially_enabled but corresponding parameters were set" do
        class Test3 < Comments::AbstractPlugin
          def self.plugin_name;'test3';end
          def self.initially_enabled;true;end
        end
        class Test4
          def self.plugin_name;'test4';end
          def self.initially_enabled;false;end
          def self.reserved_options
            [:test4]
          end
        end

        stub(Comments::PluginManager).plugins do 
          { 'test3' => Test3, 'test4' => Test4 }
        end

        pm = Comments::PluginManager.new :test4 => true

        assert_equal pm.instance_variable_get('@plugins').keys, ['test3', 'test4']
        assert pm.instance_variable_get('@plugins')['test4'].is_a?(Test4)
      end
    end
  end

  context "Comments::Manager::list_comments_for" do
    should "return comments for some name" do
      assert_equal Comments::Manager::list_comments_for('test'), []
      comment = Comments::CommentTopic.record_for('test').comments.create! :content => 'test'
      assert_equal Comments::Manager::list_comments_for('test'), [comment]
    end

    should "return comments for some controller action" do
      controller = ActionController::Base.new
      stub(controller).params do { :action => 'test', :controller => 'test' } end

      assert_equal Comments::Manager::list_comments_for(controller), []
      comment = Comments::CommentTopic.record_for(controller).comments.create! :content => 'test'
      assert_equal Comments::Manager::list_comments_for(controller), [comment]
    end
  end

  context "Comments::Manager::last_record_name" do
    should "be false when no list_comments_for called" do
      #assert !Comments::Manager::last_record_name
    end

    should "be name of record for last used object" do
      Comments::Manager::list_comments_for('xxxx')
      assert_equal Comments::Manager::last_record_name, 'xxxx'
    end
  end

  context "Comments::Manager::create_comment" do
    should "not create comment if corresponding CommentTopic does not exist" do
      assert_no_difference 'Comments::Comment.count' do
        Comments::Manager::create_comment({ })
      end

      assert_no_difference 'Comments::Comment.count' do
        Comments::Manager::create_comment({ 'record_name' => 'x!@#!@#$@#$' })
      end
    end

    should "create comment for corresponding record" do
      Comments::Manager::list_comments_for('=) =) =)')

      assert_difference 'Comments::Comment.count', 1 do
        Comments::Manager::create_comment(
          'record_name' => '=) =) =)'
        )
      end
    end
  end

  context "Comments::Manager::comments_response" do
    should "return an instance of CommentsResponse" do
      Comments::ViewManager::set_view(ActionView::Base.new)
      resp = Comments::Manager::comments_response('xxxx')
      assert_instance_of Comments::CommentsResponse, resp
      assert_respond_to resp, :template 
      assert_respond_to resp, :comment_template 
      assert_respond_to resp, :assign_variables 
      assert_respond_to resp, :comment_add_form_template
      assert resp.assign_variables.has_key?(:record_name)
    end

    context "#check_for_not_rendered_widgets" do
      should "check for not rendered widgets" do
        Comments::ViewManager::set_view(ActionView::Base.new)
        resp = Comments::Manager::comments_response('xxxx')

        assert_equal [:record_name], resp.assign_variables.keys
        assert_raise RuntimeError do
          resp.check_for_not_rendered_widgets
        end
      end

      should "not raise anything if all is ok" do
        Comments::ViewManager::set_view(ActionView::Base.new)
        resp = Comments::Manager::comments_response('xxxx')
        assert_equal [:record_name], resp.assign_variables.keys
        resp.get_assigned_variable(:record_name)

        assert_equal [:record_name], resp.assign_variables.keys
        assert_nothing_raised do
          resp.check_for_not_rendered_widgets
        end
      end
    end
  end

  context "Comments::ViewManager::set_view" do
    should "change view paths" do
      @view = ActionView::Base.new
      old_paths = @view.view_paths.clone
      Comments::ViewManager::set_view(@view)
      assert_not_equal old_paths, @view.view_paths
    end

    should "not overwrite old paths" do
      @view = ActionView::Base.new
      @view.view_paths << 'testpath'
      Comments::ViewManager::set_view(@view)
      assert @view.view_paths.include?('testpath')
    end
  end

  context "Comments::ViewManager::template" do
    should "render to string given template" do
      @view = ActionView::Base.new
      Comments::ViewManager.set_view(@view)
      out = Comments::ViewManager.template('widgets/record_name.haml')
      assert_instance_of String, out
    end
  end
end
