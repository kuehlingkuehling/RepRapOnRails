class Gcode
  attr_reader :m, :g, :t,
              :x, :y, :z, :e,
              :f, :p, :s, :t

  def initialize(line)

    # scan for commands
    @m = line.scan(/^M(\d+)/).first
    @g = line.scan(/^G(\d+)/).first
    @t = line.scan(/^T(\d+)/).first

    # convert codes from to integer
    @m = @m.first.to_i if @m
    @g = @g.first.to_i if @g
    @t = @t.first.to_i if @t

    # remove command from start of line
    line.sub!(/^[MTG]\d+\s*/, "")

    # scan for coordinates
    @x = line.scan(/X(\d+(\.\d+)?)/).first
    @y = line.scan(/Y(\d+(\.\d+)?)/).first
    @z = line.scan(/Z(\d+(\.\d+)?)/).first
    @z = line.scan(/E(\d+(\.\d+)?)/).first

    # scan for additional parameters
    @f = line.scan(/F(\d+(\.\d+)?)/).first
    @p = line.scan(/P(\d+(\.\d+)?)/).first
    @s = line.scan(/S(\d+(\.\d+)?)/).first
    @t = line.scan(/T(\d+(\.\d+)?)/).first


    # convert numbers from strings to float or int
    @x = @x.first.to_f if @x
    @y = @y.first.to_f if @y
    @z = @z.first.first.to_f if @z
    @e = @e.first.to_f if @e
    @f = @f.first.to_f if @f
    @p = @p.first.to_f if @p
    @s = @s.first.to_f if @s
    @t = @t.first.to_i if @t
  end

  def m?(num)
    @m == num
  end

  def g?(num)
    @g == num
  end

  def t?(num)
    @t == num
  end

 end