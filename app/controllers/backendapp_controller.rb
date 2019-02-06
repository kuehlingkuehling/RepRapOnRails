class BackendappController < ApplicationController
  
  # Serve backendapp layout html for angularJS app
  def index
    if lockscreen_params.has_key? :togglelock
      WebsocketRails[:lockscreen].trigger(:toggle, true)
      Rails.logger.debug "TOGGLING LOCK SCREEN!"
    end
    
    render :layout => 'backendapp'
  end
  
  def logfile
    @lines = LogEntry.order("id DESC").limit(20000)
    logfile = ""
    @lines.each do |l|
      logfile += "#{l.id}\t[#{l.created_at.utc.to_s}]\t(#{l.level})\t#{l.line}\n"
    end    
    timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    send_data logfile, :filename => "RepRapOnRails_#{timestamp}.log"
  end
  
  def upload
    @printjob = Printjob.new(printjob_params)

    if @printjob.save
      render json: @printjob, status: :created, location: @printjob
    else
      render json: @printjob.errors.full_messages, status: :unprocessable_entity
    end
  end
  
  def firmware
    require 'fileutils'
    FileUtils.mv( firmware_params[:hexfile].tempfile,
                  Rails.application.config.arduino_hexfile,
                  {:force => true} )
    render :nothing => true, :status => :ok
  end
  
  
private
    # Using a private method to encapsulate the permissible parameters is
    # just a good pattern since you'll be able to reuse the same permit
    # list between create and update. Also, you can specialize this method
    # with per-user checking of permissible attributes.
    def printjob_params
      params.permit(:name, :note, :gcodefile)
    end  
    
    def firmware_params
      params.permit(:hexfile)
    end

    def lockscreen_params
      params.permit(:togglelock)
    end
end
