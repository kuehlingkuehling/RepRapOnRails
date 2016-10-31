require 'matrix'

class FakeRepRap
  
  def initialize(port, baud, p1, p2, p3)
    @response_queue = Array.new
    @dtr = 0
    @start_thread = nil
    @targets = {
      0 => 0,
      1 => 0,
      2 => 0,
      :B => 0
    }

    @last_coord = nil
    @new_coord = [ 0, 0, 0 ]
    @feedrate = nil
 
    puts " "
    puts "    *********** WARNING *************"
    puts "    ***                           ***"
    puts "    ***  Fake RepRap initialized  ***"
    puts "    ***                           ***"
    puts "    *********************************"
    puts " "

    @start_thread = Thread.new{
      sleep 1 
      @response_queue.push("start")
    }
  end

  def write(line)
    gcode = Gcode.new(line)
    
    @feedrate = gcode.f if gcode.f
      
    if gcode.g?(1) and @feedrate
      @new_coord[0] = gcode.x if gcode.x
      @new_coord[1] = gcode.y if gcode.y
      @new_coord[2] = gcode.z if gcode.z

      if @last_coord
        segment = Vector.elements([
          @new_coord[0] - @last_coord[0],
          @new_coord[1] - @last_coord[1],
          @new_coord[2] - @last_coord[2]])
     
        segment_duration = segment.norm / (@feedrate / 60)
        sleep segment_duration # imitate mechanical move by delaying the "ok"
      end
      @last_coord = @new_coord.dup
    end
    

    if gcode.m?(105)
      @response_queue.push("T:#{ randstr(19) } /#{ @targets[0] } B:#{ randstr(@targets[:B]) } /#{ @targets[:B] } B@:0 @:0 T0:#{ randstr(@targets[0]) } /#{ @targets[0] } @0:0 T1:#{ randstr(20) } /#{ @targets[1] } @1:0 T2:#{ randstr(21) } /#{ @targets[2] } @2:0") 
    end

    if gcode.m?(115)
      @response_queue.push("FIRMWARE_NAME:Repetier_0.91 FIRMWARE_URL:https://github.com/repetier/Repetier-Firmware/ PROTOCOL_VERSION:1.0 MACHINE_TYPE:Mendel EXTRUDER_COUNT:3 REPETIER_PROTOCOL:2 KUEHLINGKUEHLING_FIRMWARE_VERSION:0.92-ht500-1.4.0-01")
    end

    if gcode.m?(119)
      @response_queue.push("x_min:H y_max:H z_max:L")
    end  

    if gcode.g?(999)
      @response_queue.push("RequestPause:Extruder Jam Detected!")
    end    

    if gcode.m?(104) and gcode.s and gcode.t
      #@response_queue.push("TargetExtr#{ gcode.t.to_i }:#{ gcode.s }")
      @targets[gcode.t.to_i] = gcode.s.to_i
    end

    if gcode.m?(140) and gcode.s
      #@response_queue.push("TargetBed:#{ gcode.s }")
      @targets[:B] = gcode.s.to_i
    end

    @response_queue.push("ok")

    if gcode.m?(205)
      @response_queue.push("EPR:3 446 0.000 Extr.3 advance L [0=off]")
      @response_queue.push("EPR:0 454 255 Extr.3 extruder cooler speed [0-255]")
      @response_queue.push("EPR:1 452 0 Extr.3 distance to retract when heating [mm]")
      @response_queue.push("EPR:1 450 150 Extr.3 temp. for retraction when heating [C]")
      @response_queue.push("EPR:1 439 1 Extr.3 temp. stabilize time [s]")
      @response_queue.push("EPR:2 435 0 Extr.3 Y-offset [steps]")
      @response_queue.push("EPR:2 431 0 Extr.3 X-offset [steps]")
      @response_queue.push("EPR:0 430 255 Extr.3 PID max value [0-255]")
      @response_queue.push("EPR:3 426 58.3200 Extr.3 PID D-gain")
      @response_queue.push("EPR:3 422 1.6400 Extr.3 PID I-gain")
      @response_queue.push("EPR:3 418 19.5600 Extr.3 PID P-gain/dead-time")
      @response_queue.push("EPR:0 445 60 Extr.3 PID drive min")
      @response_queue.push("EPR:0 417 255 Extr.3 PID drive max")
      @response_queue.push("EPR:0 416 0 Extr.3 heat manager [0-3]")
      @response_queue.push("EPR:3 412 10000.000 Extr.3 acceleration [mm/s^2]")
      @response_queue.push("EPR:3 408 5.000 Extr.3 start feedrate [mm/s]")
      @response_queue.push("EPR:3 404 45.000 Extr.3 max. feedrate [mm/s]")
      @response_queue.push("EPR:3 400 1.000 Extr.3 steps per mm")
      @response_queue.push("EPR:3 346 0.000 Extr.2 advance L [0=off]")
      @response_queue.push("EPR:0 354 255 Extr.2 extruder cooler speed [0-255]")
      @response_queue.push("EPR:1 352 0 Extr.2 distance to retract when heating [mm]")
      @response_queue.push("EPR:1 350 150 Extr.2 temp. for retraction when heating [C]")
      @response_queue.push("EPR:1 339 3 Extr.2 temp. stabilize time [s]")
      @response_queue.push("EPR:2 335 -21 Extr.2 Y-offset [steps]")
      @response_queue.push("EPR:2 331 2078 Extr.2 X-offset [steps]")
      @response_queue.push("EPR:0 330 255 Extr.2 PID max value [0-255]")
      @response_queue.push("EPR:3 326 58.3200 Extr.2 PID D-gain")
      @response_queue.push("EPR:3 322 1.6400 Extr.2 PID I-gain")
      @response_queue.push("EPR:3 318 2.8000 Extr.2 PID P-gain/dead-time")
      @response_queue.push("EPR:0 345 60 Extr.2 PID drive min")
      @response_queue.push("EPR:0 317 140 Extr.2 PID drive max")
      @response_queue.push("EPR:0 316 3 Extr.2 heat manager [0-3]")
      @response_queue.push("EPR:3 312 10000.000 Extr.2 acceleration [mm/s^2]")
      @response_queue.push("EPR:3 308 5.000 Extr.2 start feedrate [mm/s]")
      @response_queue.push("EPR:3 304 45.000 Extr.2 max. feedrate [mm/s]")
      @response_queue.push("EPR:3 300 500.690 Extr.2 steps per mm")
      @response_queue.push("EPR:3 246 0.000 Extr.1 advance L [0=off]")
      @response_queue.push("EPR:0 254 255 Extr.1 extruder cooler speed [0-255]")
      @response_queue.push("EPR:1 252 0 Extr.1 distance to retract when heating [mm]")
      @response_queue.push("EPR:1 250 150 Extr.1 temp. for retraction when heating [C]")
      @response_queue.push("EPR:1 239 3 Extr.1 temp. stabilize time [s]")
      @response_queue.push("EPR:2 235 0 Extr.1 Y-offset [steps]")
      @response_queue.push("EPR:2 231 0 Extr.1 X-offset [steps]")
      @response_queue.push("EPR:0 230 255 Extr.1 PID max value [0-255]")
      @response_queue.push("EPR:3 226 58.3200 Extr.1 PID D-gain")
      @response_queue.push("EPR:3 222 1.6400 Extr.1 PID I-gain")
      @response_queue.push("EPR:3 218 2.8000 Extr.1 PID P-gain/dead-time")
      @response_queue.push("EPR:0 245 60 Extr.1 PID drive min")
      @response_queue.push("EPR:0 217 140 Extr.1 PID drive max")
      @response_queue.push("EPR:0 216 3 Extr.1 heat manager [0-3]")
      @response_queue.push("EPR:3 212 10000.000 Extr.1 acceleration [mm/s^2]")
      @response_queue.push("EPR:3 208 5.000 Extr.1 start feedrate [mm/s]")
      @response_queue.push("EPR:3 204 45.000 Extr.1 max. feedrate [mm/s]")
      @response_queue.push("EPR:3 200 500.690 Extr.1 steps per mm")
      @response_queue.push("EPR:0 120 255 Bed PID max value [0-255]")
      @response_queue.push("EPR:3 116 389.420 Bed PID D-gain")
      @response_queue.push("EPR:3 112 3.230 Bed PID I-gain")
      @response_queue.push("EPR:3 108 4.200 Bed PID P-gain")
      @response_queue.push("EPR:0 124 80 Bed PID drive min")
      @response_queue.push("EPR:0 107 255 Bed PID drive max")
      @response_queue.push("EPR:0 106 3 Bed Heat Manager [0-3]")
      @response_queue.push("EPR:3 71 200.000 Z-axis travel acceleration [mm/s^2]")
      @response_queue.push("EPR:3 67 200.000 Y-axis travel acceleration [mm/s^2]")
      @response_queue.push("EPR:3 63 200.000 X-axis travel acceleration [mm/s^2]")
      @response_queue.push("EPR:3 59 200.000 Z-axis acceleration [mm/s^2]")
      @response_queue.push("EPR:3 55 200.000 Y-axis acceleration [mm/s^2]")
      @response_queue.push("EPR:3 51 200.000 X-axis acceleration [mm/s^2]")
      @response_queue.push("EPR:3 165 0.000 Z backlash [mm]")
      @response_queue.push("EPR:3 161 0.270 Y backlash [mm]")
      @response_queue.push("EPR:3 157 0.120 X backlash [mm]")
      @response_queue.push("EPR:3 153 288.000 Z max length [mm]")
      @response_queue.push("EPR:3 149 305.000 Y max length [mm]")
      @response_queue.push("EPR:3 145 300.000 X max length [mm]")
      @response_queue.push("EPR:3 141 0.000 Z home pos [mm]")
      @response_queue.push("EPR:3 137 0.000 Y home pos [mm]")
      @response_queue.push("EPR:3 133 0.000 X home pos [mm]")
      @response_queue.push("EPR:3 47 0.400 Max. Z-jerk [mm/s]")
      @response_queue.push("EPR:3 39 25.000 Max. jerk [mm/s]")
      @response_queue.push("EPR:3 35 40.000 Z-axis homing feedrate [mm/s]")
      @response_queue.push("EPR:3 31 80.000 Y-axis homing feedrate [mm/s]")
      @response_queue.push("EPR:3 27 80.000 X-axis homing feedrate [mm/s]")
      @response_queue.push("EPR:3 23 40.000 Z-axis max. feedrate [mm/s]")
      @response_queue.push("EPR:3 19 200.000 Y-axis max. feedrate [mm/s]")
      @response_queue.push("EPR:3 15 200.000 X-axis max. feedrate [mm/s]")
      @response_queue.push("EPR:3 11 320.0000 Z-axis steps per mm")
      @response_queue.push("EPR:3 7 53.3334 Y-axis steps per mm")
      @response_queue.push("EPR:3 3 35.5555 X-axis steps per mm")
      @response_queue.push("EPR:2 83 0 Stop stepper after inactivity [ms,0=off]")
      @response_queue.push("EPR:2 79 0 Max. inactive time [ms,0=off]")
      @response_queue.push("EPR:2 125 0 Printer active [s]")
      @response_queue.push("EPR:3 129 0.000 Filament printed [m]")
      @response_queue.push("EPR:2 75 115200 Baudrate ")

      # software reset
      if gcode.m?(112)
        @response_queue = Array.new
        @targets = {
          0 => 0,
          1 => 0,
          2 => 0,
          :B => 0
        }
        Thread.kill(@start_thread) if @start_thread
        @start_thread = Thread.new{
          sleep 1 
          @response_queue.push("start")
        }
      end
    end
  end

  def randstr(val)
    ( val + rand() ).round(2)
  end

  def readline 
    count = 0
    while @response_queue.empty?
      sleep 0.1
      count += 1
      if count == 20
        @response_queue.push("wait")
        break
      end
    end

    line = @response_queue.shift
    
    line
  end

  def close
    @response = nil
  end

  def dtr=(newval)
    if @dtr == 1 and newval == 0
      @response_queue = Array.new
      @targets = {
        0 => 0,
        1 => 0,
        2 => 0,
        :B => 0
      }
      Thread.kill(@start_thread) if @start_thread
      @start_thread = Thread.new{
        sleep 1 
        @response_queue.push("start")
      }
    end
    @dtr = newval
  end

end