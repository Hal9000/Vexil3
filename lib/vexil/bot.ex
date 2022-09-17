defmodule Vexil.Bot do
  alias Vexil.{Bot, Comms, Grid, Referee}

  defstruct team: nil, kind: nil, move: nil, see: nil,
            defend: nil, attack: nil, range: nil,
            x: nil, y: nil

  def defender(team, x, y) do
    %Bot{team: team, kind: :defender, move: 2, see: 3, defend: 6, attack: 4, range: 2, x: x, y: y}
  end

  def fighter(team, x, y) do
    %Bot{team: team, kind: :fighter, move: 2, see: 3, defend: 6, attack: 4, range: 2, x: x, y: y} # FIXME
  end

  def scout(team, x, y) do
    %Bot{team: team, kind: :scout, move: 2, see: 3, defend: 6, attack: 4, range: 2, x: x, y: y} # FIXME
  end

  def flag(team, x, y) do
    %Bot{team: team, kind: :flag, move: 2, see: 3, defend: 6, attack: 4, range: 2, x: x, y: y} # FIXME
  end

  def make(kind, team, x, y) do
    apply(Bot, kind, [team, x, y])
  end

  def to_string(bot) do
    initial = bot.kind |> Atom.to_string |> String.capitalize |> String.first
    char = if bot.kind == :flag, do: "X", else: initial
    str =
    if bot.team == :red do
      "\e[31m#{char}\e[0m"
    else
      "\e[34m#{char}\e[0m"
    end
    str
  end

# Move to Grid??

  def within(game, bot, n) do
#   IO.puts "grid = #{inspect game.grid}"
#   IO.puts "bot = #{inspect bot}"
    found = []
    grid = game.grid
    team = bot.team
    {x, y} = {bot.x, bot.y}
    {x0, y0, x1, y1} = {x-n, x+n, y-n, y+n}
    {xr, yr} = {x0..x1, y0..y1}
    
    filter = &(&1 == nil or Bot.where(&1) == Bot.where(bot))
    list = for x <- xr, y <- yr do
      piece = Grid.get(grid, {team, x, y})
    end
    Enum.reject(list, filter)
  end

  def where(bot) do
    {bot.x, bot.y}
  end

  def enemy?(me, piece) do
    me.team != piece.team
  end

  def can_see(game, me) do
    within(game, me, me.see)
  end

  def can_attack(game, me) do  # Things I can attack
    list = within(game, me, me.range)
#   list = list.reject {|x| x.is_a? Flag }
  end

  def seek_flag(game, me) do  # FIXME!!
    stuff = can_see(game, me)
    IO.puts "seek_flag: #{inspect stuff}"
    :timer.sleep 3000
# Ruby code:
#   flag = stuff.select {|x| x.is_a? Flag }.first
#   unless flag.nil?  # Remember to tell others where flag is
#     fx, fy = flag.where
#     fx, fy = 22 - fx, 22 - fy  # native coordinates
#     dx, dy = fx - @x, fy - @y
#     $game.record "#{self.who} can see enemy flag at #{fx},#{fy}"
#     if (dx.abs + dy.abs) <= @move  # we can get there
#       $game.record "#{self.who} captures flag!"
#       move(dx, dy)
#     end
#   end
  end


  def move(game, true, bot, dx, dy), do: {game, bot, false}

  def move(game, false, bot, dx, dy) do
    x2 = bot.x + dx
    y2 = bot.y + dy

    # send msg to referee
#   IO.puts "game pid in bot = #{inspect game.pid}"
#   IO.puts "#{inspect self()} sends to referee"
    {g, result} = Comms.sendrecv(game.pid, {self(), game, :move, bot.team, bot.x, bot.y, x2, y2})
#   IO.puts "---- AFTER sendrecv"
    bot2 = if result do
      Referee.record(g, :move, bot)  # $game.record("#{self.who} moves to #@x,#@y")
      b2 = %Bot{bot | x: x2}
      b3 = %Bot{b2  | y: y2}
    else
      bot
    end

    {game, bot2, result}
  end

  def try_moves(game, bot, dx, dy) do
    deltas = [{dx, dy}, {dx-1, dy+1}, {dx+1, dy-1}, {dx-2, dy+2}, {dx+2, dy-2}]
    {game, bot} = attempt_move(game, bot, deltas)
    {game, bot}
  end

  def attempt_move(game, bot, []), do: {game, bot}

  def attempt_move(game, bot, [dest | rest]) do
    IO.puts "Attempting move - #{inspect bot} to #{inspect dest}"
    {dx, dy} = dest
    {game, bot, result} = move(game, Referee.over?(game), bot, dx, dy)
    if result do
      {game, bot}
    else
      IO.puts "  Recursive - Attempting move - #{inspect bot} to #{inspect dest}"
      attempt_move(game, bot, rest)
    end
  end

## credit mononym

  def turn(:fighter, bot, game) do
    # FIXME will call move, attack
    {game, bot} = try_moves(game, bot, 2, 2)
##    seek_flag
##
##    @strength = @attack
##    victims = can_attack
##    victims.each {|enemy| try_attack(2, enemy) || break }
##    move!(2, 2)
    {game, bot}
  end

  def turn(:defender, bot, game) do
    # FIXME will call move, attack
##    @strength = @attack
##    victims = can_attack
##    victims.each {|enemy| try_attack(3, enemy) || break }
    {game, bot}
  end

  def turn(:scout, bot, game) do
    # FIXME will call move, attack
    try_moves(game, bot, 3, 3)
##    seek_flag
##
##    @strength = @attack
##    victims = can_attack
##    victims.each {|enemy| try_attack(1, enemy) || break }
##    move!(3, 3)
    {game, bot}
  end

  def turn(:flag, bot, game), do: {game, bot}

  def mainloop(bot, game) do
    # the bot lives its life -- run, attack, whatever
    # see 'turn' in Ruby version
    {game, bot} = turn(bot.kind, bot, game)
    mainloop(bot, game)
  end

  def awaken(bot, game) do
    :timer.sleep 100
    spawn_link Bot, :mainloop, [bot, game]
  end

end
