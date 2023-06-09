require 'thread'

class Referee

  HistorySize = 15

  def initialize
    @grid = Grid.new
    @pieces = {Red => [], Blue => []}
    @history = [""] * HistorySize
    @over = false
    @count = 1
    @mutex = Mutex.new
    @started = false
  end

  def synchronize
    @mutex.synchronize { yield }
  end

  def start!
    @started = true
  end

  def started?
    @started
  end

  def show_cell(xx, yy)
    obj = @grid[Red, xx, yy] 
#    strings = {Empty => " -", RedFlag => " X".red, BlueFlag => " X".blue}
#    print (strings[obj] || obj)
     print (Strings[obj] || obj)
  end

  def record(line)
    return if over?
    @history << "#{'%3d' % @count}. #{line}"
    @count += 1
  end

  def display
    system("clear")
    puts "\n "
    GridSize.downto(1) do |yy|
      1.upto(GridSize) {|xx| show_cell(xx, yy) }
      puts
    end
    puts
    @history[-HistorySize..-1].each {|hist| puts hist }
  end

  def [](team, x, y)
    @grid[team, x, y]
  end

  def setup
    teams = [Red, Blue]
    teams.each do |team|
      place(team, Defender, 5, 5)
      place(team, Defender, 5, rand(1..4))
      place(team, Defender, rand(1..4), 5)

      3.times { place(team, Fighter,  6, rand(1..5)) rescue retry }
      3.times { place(team, Fighter,  rand(1..5), 6) rescue retry }

      4.times { place(team, Scout,  rand(8..9), rand(1..9)) rescue retry }
      4.times { place(team, Scout,  rand(1..9), rand(8..9)) rescue retry }
    end
  end

  def turn
    return if $game.over?
    @pieces[Red] -= [RedFlag]
    @pieces[Blue] -= [BlueFlag]
    4.times do
      @pieces[Red].shuffle!
      @pieces[Blue].shuffle!
    end

    all = {Red => @pieces[Red].dup, Blue => @pieces[Blue].dup}
    pieces = []
    max = all[Red].size - 1
    (0..max).to_a.shuffle.each do |num|
      pieces << all[Red][num] << all[Blue][num]
    end
    pieces.compact!
    pieces.each.with_index do |piece, i| 
      break if $game.over?
      # $game.record("pieces = #{pieces.map(&:to_s)}") # ("-- Moving #{piece.inspect}")
      # $game.display
      piece.turn(i)
      $game.display
      break if $game.over?
    end
  end

  def move(team, x0, y0, x1, y1)
    return false unless x1.between?(1,GridSize) && y1.between?(1,GridSize)
    piece = @grid[team, x0, y0]
    dest = @grid[team, x1, y1]
    case
      when (dest == Empty)
        @grid[team, x1, y1] = piece 
        @grid[team, x0, y0] = Empty
        true
      when (dest.is_a? Flag)
        @grid[team, x1, y1] = piece 
        @grid[team, x0, y0] = Empty
        record("#{team.to_s.send(team)} wins!")
        over!
      else
        false
    end
  end

  def attack(qty, team, x, y)
    piece = @grid[team, x, y]
    return if piece.nil?        # BUG
    piece.defend -= qty
    if piece.defend <= 0
      record("#{piece.who} is dead!")
      @grid[Red, x, y] = Empty
      @pieces[team] -= [piece]
    end
  end

  def place(team, kind, x, y)
    raise "Can't place #{team} #{kind.to_s} at #{x},#{y} = #{@grid[team,x,y].inspect}" unless @grid[team,x,y] == Empty
    bot = kind.new(team, x, y)
    @grid[team, x, y] = bot
    @pieces[team] << bot
  end

  def over!
    @over = true
  end

  def over?
    @over
  end
end
