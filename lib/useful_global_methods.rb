module UsefulGlobalMethods
  def self.timespan_in_words (seconds)
    if seconds
      mm, ss = seconds.divmod(60)
      hh, mm = mm.divmod(60)
      dd, hh = hh.divmod(24)
      units = Array.new
      
      units.push( "%d day" % [dd] ) if dd == 1
      units.push( "%d days" % [dd] ) if dd > 1        
      
      units.push( "%d hour" % [hh] ) if hh == 1
      units.push( "%d hours" % [hh] ) if hh > 1
      
      units.push( "%d minute" % [mm] ) if mm == 1             
      units.push( "%d minutes" % [mm] ) if mm > 1     
      
      units.push( "less than a minute" )  if units.length == 0
  
      units.join(", ")
    else
      '(no time specified)'
    end
  end

end