class BackendappController < ApplicationController
  
  # Serve backendapp layout html for angularJS app
  def index
    if params[:togglelock]
      WebsocketRails[:lockscreen].trigger(:toggle, true)
    end
    
    render :layout => 'backendapp'
  end
  
  def logfile
    @lines = LogEntry.order("created_at DESC").limit(20000)
    logfile = ""
    @lines.each do |l|
      logfile += "[#{l.created_at.utc.to_s}] (#{l.level}) #{l.line}\n"
    end    
    send_data logfile, :filename => "RepRapIndustrial_logfile.txt"
  end
  
  def upload
    @printjob = Printjob.new(printjob_params)

    if @printjob.save
      render json: @printjob, status: :created, location: @printjob
    else
      render json: @printjob.errors, status: :unprocessable_entity 
    end
  end
  
  
private
    # Using a private method to encapsulate the permissible parameters is
    # just a good pattern since you'll be able to reuse the same permit
    # list between create and update. Also, you can specialize this method
    # with per-user checking of permissible attributes.
    def printjob_params
      params.permit(:name, :note, :gcodefile)
    end  
end
