class Bot
  attr_reader   :team
  attr_accessor :defend

  def initialize(team, data, x, y)
    @move, @see, @defend, @attack, @range = *data
    @x, @y, @team = x, y, team
    @strength = @attack
  end

  def to_s
    initial = self.class == Flag ? "X" : self.class.to_s[0].downcase
    str = " " + initial
    str.send(@team)
  end

  def who
    # "#{('%8s' % self.class.to_s).send(@team)} @ #@x,#@y"
    "%-8s @ %-5s" % [self.class.to_s.send(@team), "#@x,#@y"]
  end

  def move(dx, dy)
    x2, y2 = @x + dx, @y + dy
    if $game.move(@team, @x, @y, x2, y2)
      return if $game.over?
      $game.record("#{self.who} moves to #@x,#@y")
      @x, @y = x2, y2
      return true
    end
    false
  end

  def move!(dx, dy)
    case   # Try successive moves
      when move(dx, dy)
      when move(dx-1, dy+1)
      when move(dx+1, dy-1)
      when move(dx-2, dy+2)
      when move(dx+2, dy-2)
    end
  end

  def where
    [@x, @y]
  end

  def enemy?(piece)
    piece.respond_to?(:team) && @team != piece.team
  end

  def within(n)
    x0, x1 = @x - n, @x + n
    y0, y1 = @y - n, @y + n
    list = []
    x0.upto(x1) do |xx|
      y0.upto(y1) do |yy|
        piece = $game[@team, xx, yy] 
        next if piece == Empty
        next if [xx, yy] == [@x, @y]
        list << piece.dup if enemy?(piece)  # for now
      end
    end
    list
  end

  def can_see
    within(@see)
  end

  def can_attack
    list = within(@range)
    list = list.reject {|x| x.is_a? Flag }
  end
  
  def turn
    return if $game.over?
    puts "#@team #{self.class} at #@x,#@y takes a turn"
  end

  def try_attack(qty, enemy)
    x, y = enemy.where
    @strength -= qty
    $game.attack(qty, team, x, y)
    return false if @strength <= 0
    $game.record("#{self.who} attacks #{enemy.who}")
    true
  end

  def seek_flag
    stuff = can_see
    flag = stuff.select {|x| x.is_a? Flag }.first
    unless flag.nil?  # Remember to tell others where flag is
      fx, fy = flag.where
      fx, fy = 22 - fx, 22 - fy  # native coordinates
      dx, dy = fx - @x, fy - @y
      $game.record "#{self.who} can see enemy flag at #{fx},#{fy}"
      if (dx.abs + dy.abs) <= @move  # we can get there
        $game.record "#{self.who} captures flag!"
        move(dx, dy)
      end
    end
  end

  def start_thread!
    @thread = Thread.new do
      loop { sleep 0.01; break if $game.started? }
      loop do 
        break if $game.over?
        $game.synchronize { turn }
        sleep 2.5
      end
    end
  end
end

class Defender < Bot
  def initialize(team, x, y)
    super(team, [2, 3, 6, 4, 2], x, y)
    # @move, @see, @defend, @attack, @range = *data
    start_thread!
  end

  def turn
    return if $game.over?
    @strength = @attack
    victims = can_attack
    victims.each {|enemy| try_attack(3, enemy) || break }
  end

end

class Fighter < Bot
  def initialize(team, x, y)
    super(team, [4, 6, 6, 6, 4], x, y)
    # @move, @see, @defend, @attack, @range = *data
    start_thread!
  end

  def turn
    return if $game.over?
    seek_flag

    @strength = @attack
    victims = can_attack
    victims.each {|enemy| try_attack(2, enemy) || break }
    move!(2, 2)
  end
end

class Scout < Bot
  def initialize(team, x, y)
    super(team, [5, 8, 3, 2, 1], x, y)
    # @move, @see, @defend, @attack, @range = *data
    start_thread!
  end

  def turn
    return if $game.over?
    seek_flag

    @strength = @attack
    victims = can_attack
    victims.each {|enemy| try_attack(1, enemy) || break }
    move!(3, 3)
  end
end

class Flag < Bot
  def initialize(team, x, y)
    super(team, [0, 0, 0, 0, 0], x, y)
  end
end
