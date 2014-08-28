class FakeRepRap
  
  def initialize(port, baud, p1, p2, p3)
    @response_queue = Array.new
    @dtr = 0
    @start_thread = nil
 
    puts " "
    puts "    *********** WARNING *************"
    puts "    ***                           ***"
    puts "    ***  Fake RepRap initialized  ***"
    puts "    ***                           ***"
    puts "    *********************************"
    puts " "
  end

  def write(line)
    gcode = Gcode.new(line)
    @response_queue.push("ok")


    if gcode.m?(105)
      @response_queue.push("T:#{ randstr(19) } T0:#{ randstr(20) } T1:#{ randstr(21) } T2:#{ randstr(22) } B:#{ randstr(23) }") 
    end

    if gcode.m?(104) and gcode.s and gcode.t
      @response_queue.push("TargetExtr#{ gcode.t.to_i }:#{ gcode.s }")
    end

    if gcode.m?(140) and gcode.s
      @response_queue.push("TargetBed:#{ gcode.s }")
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
      Thread.kill(@start_thread) if @start_thread
      @start_thread = Thread.new{
        sleep 1 
        @response_queue.push("start")
      }
    end
    @dtr = newval
  end
end