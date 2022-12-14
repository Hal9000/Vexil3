defmodule Vexil.Bot do
  alias Vexil.{Bot, Comms, Grid, Referee}

  defstruct team: nil, kind: nil, move: nil, see: nil,
            defend: nil, attack: nil, range: nil,
            x: nil, y: nil

  def defender(team, x, y) do
    %Bot{team: team, kind: :defender, move: 2, see: 3, defend: 6, attack: 4, range: 2, x: x, y: y}
  end

  def fighter(team, x, y) do
    %Bot{team: team, kind: :fighter, move: 4, see: 6, defend: 6, attack: 6, range: 4, x: x, y: y}
  end

  def scout(team, x, y) do
    %Bot{team: team, kind: :scout, move: 5, see: 8, defend: 3, attack: 2, range: 1, x: x, y: y}
  end

  def flag(team, x, y) do
    %Bot{team: team, kind: :flag, move: 0, see: 0, defend: 0, attack: 0, range: 0, x: x, y: y}
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

# Move most of this to Referee...

  def within(game, bot, n) do
#   IO.puts "grid = #{inspect game.grid}"
#   IO.puts "bot = #{inspect bot}"
    _found = []
    grid = game.grid
    team = bot.team
    {x, y} = {bot.x, bot.y}
    {x0, y0, x1, y1} = {x-n, x+n, y-n, y+n}
    {xr, yr} = {x0..x1, y0..y1}
    
    filter = &(&1 == nil or Bot.where(&1) == Bot.where(bot))
    list = for x <- xr, y <- yr do
      _piece = Grid.get(grid, {team, x, y})
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
    _list = within(game, me, me.range)
#   list = list.reject {|x| x.is_a? Flag }
  end

  def seek_flag(game, me) do  # FIXME!!
    _stuff = can_see(game, me)
#   IO.puts "seek_flag: #{inspect stuff}"
    :timer.sleep 1000
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


  def move(%Referee{status: :over} = game, bot, _dx, _dy), do: {game, bot, false}

  def move(game, bot, dx, dy) do
    x2 = bot.x + dx
    y2 = bot.y + dy

    # send msg to referee
# IO.puts "game pid in bot = #{inspect game.pid}"
  IO.puts "  msg to referee from #{show_bot(bot)}: #{{bot.team, bot.x, bot.y, x2, y2}}"
    {game, result} = Comms.sendrecv(game.pid, {self(), game, :move, bot.team, bot.x, bot.y, x2, y2})
# IO.puts "---- AFTER sendrecv"
    bot2 = if result do
      Referee.record(game, :move, bot)  # $game.record("#{self.who} moves to #@x,#@y")
      b2 = %Bot{bot | x: x2}
# Huh??
      _b3 = %Bot{b2  | y: y2}
    else
      bot
    end

    {game, bot2, result}
  end

  def try_moves(game, bot, dx, dy) do
# IO.puts "In #try_moves"
    deltas = [{dx, dy}, {dx-1, dy+1}, {dx+1, dy-1}, {dx-2, dy+2}, {dx+2, dy-2}]
    {game, bot} = attempt_move(game, bot, deltas)
    {game, bot}
  end

  def attempt_move(game, bot, []), do: {game, bot}

  def attempt_move(game, bot, [dest | rest]) do
#    IO.puts "Attempting move - #{inspect bot} to #{inspect dest}"
    {dx, dy} = dest
    {game, bot, result} = move(game, bot, dx, dy)
    if result do
      {game, bot}
    else
#      IO.puts "  Recursive - Attempting move - #{inspect bot} to #{inspect dest}"
      attempt_move(game, bot, rest)
    end
  end

## credit mononym

#  def turn(_kind, bot, game) when game.playing?, do: {game, bot}

  def turn(:fighter, bot, game) do
# IO.puts "Calling #turn (fighter)"
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
# IO.puts "Calling #turn (defender)"
    # FIXME will call move, attack
##    @strength = @attack
##    victims = can_attack
##    victims.each {|enemy| try_attack(3, enemy) || break }
    {game, bot}
  end

  def turn(:scout, bot, game) do
# IO.puts "Calling #turn (scout)"
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

  def show_bot(bot) do
    pid = self()
    letter = bot.kind |> Kernel.to_string |> String.first |> String.capitalize
    "Bot: #{Bot.to_string(bot)}@#{bot.x},#{bot.y}  pid = #{inspect pid}"
  end

# Thoughts:
#   Don't pass the game to the bot-- just the referee pid
#   Bot must query referee for everything: game status, what is nearby, ...
#   Maybe make that a single exchange?
#     - bot queries referee
#     - bot gets game status, nearby bots
#     - bot requests a move
#     - bot gets success/fail re move
# 

  def query_referee(bot, refpid) do
    send(refpid, bot)
    response = receive do  # hmm, how verify it's from ref??
      
    end
  end

  def mainloop(bot, refpid) do
    # the bot lives its life -- run, attack, whatever
    # see 'turn' in Ruby version
  end

  def old_mainloop(bot, game) do
    # the bot lives its life -- run, attack, whatever
    # see 'turn' in Ruby version
IO.puts "Bot mainloop:  status = #{game.status}"
    status = Comms.ask_game_state(game.pid)
    if status == :playing do
      {game, bot} = turn(bot.kind, bot, game)
    else
      :timer.sleep 2000
    end
    mainloop(bot, game)
  end

  def awaken(bot, game) do
    :timer.sleep 100
  IO.puts "Awaken: #{show_bot(bot)}"
    spawn_link Bot, :mainloop, [bot, game]
  end

end
