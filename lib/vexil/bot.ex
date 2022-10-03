defmodule Vexil.Bot do
  alias Vexil.{Bot, Comms, Grid, Referee}

  defstruct refpid: nil, mypid: nil, team: nil, kind: nil, move: nil, see: nil,
            defend: nil, attack: nil, range: nil,
            x: nil, y: nil

  def defender(refpid, team, x, y) do
    %Bot{refpid: refpid, mypid: self(), team: team, kind: :defender, move: 2, see: 3, defend: 6, attack: 4, range: 2, x: x, y: y}
  end

  def fighter(refpid, team, x, y) do
    %Bot{refpid: refpid, mypid: self(), team: team, kind: :fighter, move: 4, see: 6, defend: 6, attack: 6, range: 4, x: x, y: y}
  end

  def scout(refpid, team, x, y) do
    %Bot{refpid: refpid, mypid: self(), team: team, kind: :scout, move: 5, see: 8, defend: 3, attack: 2, range: 1, x: x, y: y}
  end

  def flag(refpid, team, x, y) do
    %Bot{refpid: refpid, mypid: self(), team: team, kind: :flag, move: 0, see: 0, defend: 0, attack: 0, range: 0, x: x, y: y}
  end

  def make(refpid, kind, team, x, y) do
    apply(Bot, kind, [refpid, team, x, y])
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

  def where(bot) do
    {bot.x, bot.y}
  end

  def enemy?(me, piece) do
    me.team != piece.team
  end

  def can_see(_me) do
    # within(game, me, me.see)
  end

  def can_attack(_me) do  # Things I can attack
#   _list = within(game, me, me.range)
#   list = list.reject {|x| x.is_a? Flag }
  end

  def seek_flag(me) do  # FIXME!!
    _stuff = can_see(me)
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


  # def move(%Referee{status: :over} = game, bot, _dx, _dy), do: {game, bot, false}

  def move(bot, dx, dy) do
    x2 = bot.x + dx
    y2 = bot.y + dy

    # send msg to referee
# IO.puts "game pid in bot = #{inspect game.pid}"
  IO.puts "  msg to referee from #{show_bot(bot)}: #{{bot.team, bot.x, bot.y, x2, y2}}"
    result = Comms.sendrecv(bot.refpid, {self(), 'game', :move, bot.team, bot.x, bot.y, x2, y2})
# IO.puts "---- AFTER sendrecv"
    bot2 = if result do
      Referee.record(:move, bot.x, bot.y)  # $game.record("#{self.who} moves to #@x,#@y")
      b2 = %Bot{bot | x: x2}
# Huh??
      _b3 = %Bot{b2  | y: y2}
    else
      bot
    end

    {bot2, result}
  end

  def try_moves(bot, dx, dy) do
# IO.puts "In #try_moves"
    deltas = [{dx, dy}, {dx-1, dy+1}, {dx+1, dy-1}, {dx-2, dy+2}, {dx+2, dy-2}]
    bot = attempt_move(bot, deltas)
    bot
  end

  def attempt_move(bot, []), do: {bot}

  def attempt_move(bot, [dest | rest]) do
#    IO.puts "Attempting move - #{inspect bot} to #{inspect dest}"
    {dx, dy} = dest
    {bot, result} = move(bot, dx, dy)
    if result do
      {bot}
    else
#      IO.puts "  Recursive - Attempting move - #{inspect bot} to #{inspect dest}"
      attempt_move(bot, rest)
    end
  end

## credit mononym + Ken L

  def turn(:defender, bot, _visible) do
# IO.puts "Calling #turn (defender)"
    # FIXME will call move, attack
##    @strength = @attack
##    victims = can_attack
##    victims.each {|enemy| try_attack(3, enemy) || break }
    {bot}
  end

  def turn(:scout, bot, _visible) do
# IO.puts "Calling #turn (scout)"
    # FIXME will call move, attack
    try_moves(bot, 3, 3)
##    seek_flag
##
##    @strength = @attack
##    victims = can_attack
##    victims.each {|enemy| try_attack(1, enemy) || break }
##    move!(3, 3)
    {bot}
  end

  def turn(:flag, bot, _visible), do: {bot}

  def show_bot(bot) do
    pid = self()
    # bot.kind |> Kernel.to_string |> String.first |> String.capitalize
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
    receive do  # hmm, how verify it's from ref??
      :starting -> nil;
      :over     -> nil;
      {:playing, visible} -> Bot.turn(bot.kind, bot, visible)
    end
  end

  def mainloop(bot, refpid) do
    # the bot lives its life -- run, attack, whatever
    # see 'turn' in Ruby version
    if bot.mypid == nil, do: bot = %Bot{bot | mypid: self(), refpid: refpid}  # returned
    query_referee(bot, refpid)
    mainloop(bot, refpid)
  end

  def awaken(bot, refpid) do
    :timer.sleep 100
  IO.puts "Awaken: #{show_bot(bot)}"
    spawn_link Bot, :mainloop, [bot, refpid]
  end

end
