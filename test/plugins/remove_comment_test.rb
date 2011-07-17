require "test_helper"
require "action_controller/test_process"

class TestController < ActionController::Base
  attr_accessor :delegate_attr
  def delegate_method() end
  def rescue_action(e) raise end
end

class RemoveCommentTest < ActiveSupport::TestCase
  context "#widgets" do
    should "render link" do
      @view = ActionView::Base.new
      @view.controller = TestController.new
      @view.controller.request = ActionController::TestRequest.new
      @view.controller.response = ActionController::TestResponse.new

      Comments::ViewManager::set_view(@view)
      Comments::ViewManager.current_comment = Comments::Comment.create! :content => "<Test>"

      stub(@view).t('remove comment') { 'remove comment' }
      stub(@view).link_to('remove comment', :remove_comment =>  Comments::ViewManager.current_comment.id)

      resp = @view.render :partial => '/widgets/remove_comment_link', :locals => { :current_comments_template => :comment, :comment => Comments::ViewManager.current_comment }
    end
  end
end
