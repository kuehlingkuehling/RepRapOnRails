require 'test_helper'

class PrintjobsControllerTest < ActionController::TestCase
  setup do
    @printjob = printjobs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:printjobs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create printjob" do
    assert_difference('Printjob.count') do
      post :create, printjob: { gcode: @printjob.gcode, name: @printjob.name, note: @printjob.note, uploaded_at: @printjob.uploaded_at }
    end

    assert_redirected_to printjob_path(assigns(:printjob))
  end

  test "should show printjob" do
    get :show, id: @printjob
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @printjob
    assert_response :success
  end

  test "should update printjob" do
    put :update, id: @printjob, printjob: { gcode: @printjob.gcode, name: @printjob.name, note: @printjob.note, uploaded_at: @printjob.uploaded_at }
    assert_redirected_to printjob_path(assigns(:printjob))
  end

  test "should destroy printjob" do
    assert_difference('Printjob.count', -1) do
      delete :destroy, id: @printjob
    end

    assert_redirected_to printjobs_path
  end
end
