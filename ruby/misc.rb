class String
  def red
    "\e[31m#{self}\e[0m"
  end

  def blue
    "\e[34m#{self}\e[0m"
  end
end

GridSize = 21

Red, Blue = :red, :blue
RedFlag  = Flag.new(Red, rand(1..4), rand(1..4))
BlueFlag = Flag.new(Blue, rand(1..4), rand(1..4))
Empty = nil

Strings = {::Empty => " -", ::RedFlag => " X".red, ::BlueFlag => " X".blue}
