require 'test_helper'

class RecordNameTest < ActiveSupport::TestCase
  context "#widgets" do
    should "return correct tag" do
      @view = ActionView::Base.new
      Comments::ViewManager::set_view(@view)
      resp = @view.render :partial => '/widgets/record_name', :locals => { :record_name => 'test' }
      el = Hpricot(resp).at('input')

      assert_equal el[:value], 'test'
      assert_equal el[:type], 'hidden'
      assert_equal el[:name], 'comment[record_name]'
    end
  end
end
