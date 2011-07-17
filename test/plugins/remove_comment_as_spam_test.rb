require "test_helper"
require "action_controller/test_process"

class TestController < ActionController::Base
  attr_accessor :delegate_attr
  def delegate_method() end
  def rescue_action(e) raise end
end

ActiveRecord::Schema.define(:version => 2) do
  add_column :comments, :status, :string, :default => '', :null => false
end

class RemoveCommentTest < ActiveSupport::TestCase
  context "#widgets" do
    should "render one link if comment is clean" do
      @view = ActionView::Base.new
      @view.controller = TestController.new
      @view.controller.request = ActionController::TestRequest.new
      @view.controller.response = ActionController::TestResponse.new

      Comments::ViewManager::set_view(@view)
      Comments::ViewManager.current_comment = Comments::Comment.create! :content => "<Test>"

      stub(@view).t('remove comment as spam') { 'remove comment as spam' }
      stub(@view).link_to('remove comment as spam', :update_comment_status =>  Comments::ViewManager.current_comment.id, :status => 'spam')

      resp = @view.render :partial => '/widgets/remove_comment_as_spam_link', :locals => { :current_comments_template => :comment, :comment => Comments::ViewManager.current_comment }
    end

    should "render two links if comment is possibly spam" do
      @view = ActionView::Base.new
      @view.controller = TestController.new
      @view.controller.request = ActionController::TestRequest.new
      @view.controller.response = ActionController::TestResponse.new

      Comments::ViewManager::set_view(@view)
      Comments::ViewManager.current_comment = Comments::Comment.create! :content => "<Test>", :status => 'possibly_spam'

      # First link
      stub(@view).t('remove comment as spam') { 'remove comment as spam' }
      stub(@view).link_to('remove comment as spam', :update_comment_status =>  Comments::ViewManager.current_comment.id, :status => 'spam')

      # Second link
      stub(@view).t('mark comment as checked') { 'mark comment as checked' }
      stub(@view).link_to('mark comment as checked', :update_comment_status =>  Comments::ViewManager.current_comment.id, :status => 'not_spam')

      resp = @view.render :partial => '/widgets/remove_comment_as_spam_link', :locals => { :current_comments_template => :comment, :comment => Comments::ViewManager.current_comment }
    end
  end
end
