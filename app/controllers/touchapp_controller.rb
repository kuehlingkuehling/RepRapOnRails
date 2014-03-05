class TouchappController < ApplicationController
  
  # Serve touchapp layout html for angularJS app
  def index
    render :layout => 'touchapp'
  end
  
end