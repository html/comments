require 'test_helper'

class ContentFieldTest < ActiveSupport::TestCase
  context "#widgets" do
    should "render comment content in comment show view" do
      @view = ActionView::Base.new
      Comments::ViewManager::set_view(@view)
      Comments::ViewManager.current_comment = Comments::Comment.create! :content => "<Test>"
      resp = @view.render :partial => '/widgets/content_field', :locals => { :current_comments_template => :comment, :comment => Comments::ViewManager.current_comment }

      assert_equal resp.strip, '&lt;Test&gt;'
    end

    should "render content textarea in comment add view" do
      @view = ActionView::Base.new
      Comments::ViewManager::set_view(@view)
      Comments::ViewManager.current_comment = Comments::Comment.create! :content => "<Test>"
      resp = @view.render :partial => '/widgets/content_field', :locals => { :current_comments_template => :add_comment, :comment => Comments::ViewManager.current_comment }

      text_area = Hpricot(resp).at('textarea')
      assert_not_nil text_area
      assert_equal 'comment[content]', text_area['name']
    end
    
  end
end
