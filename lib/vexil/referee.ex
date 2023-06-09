defmodule Vexil.Referee do
  @empty {}
  alias Vexil.{Bot, Grid, Referee}

  defstruct [:grid, :bots, :pid, status: :starting, whose_turn: :blue]

  def new do 
    {grid, bots} = setup(%{})
    %Referee{grid: grid, whose_turn: :blue, bots: bots, pid: nil, status: :playing}
  end

  def verify(where, sig1, sig2) do
    IO.puts "#{where}: #{Base.encode16(sig1)} -> #{Base.encode16(sig2)}"
    if sig1 == sig2 do
      IO.puts "  grid has NOT changed"
    else
      IO.puts "  grid has changed"
    end
  end

  def place(grid, bots, team, kind, x, y) do
    x2 = if match?(_a.._b, x), do: rand(x), else: x
    y2 = if match?(_a.._b, y), do: rand(y), else: y
    
    bot = Bot.make(self(), kind, team, x2, y2)
    {grid, bots} = 
      if Grid.cell_empty?(grid, {team, x2, y2}) do
        {Grid.put(grid, {team, x2, y2}, bot), bots}
      else
        place(grid, bots, team, kind, x, y)
      end
    bots = [bot] ++ bots
    {grid, bots}
  end

  def rand(n) when is_integer(n), do: :rand.uniform(n)
  def rand(n1..n2), do: :rand.uniform(n2 - n1 + 1) + n1 - 1

  def setup(grid) do
    {grid, redbots}  = setup(grid, :red)
    {grid, bluebots} = setup(grid, :blue)
    bots = redbots ++ bluebots
    {grid, bots}
  end

  def setup(grid, team) do
    bots = []
    {grid, bots} = place(grid, bots, team, :defender, 5, 5)
    {grid, bots} = place(grid, bots, team, :defender, 5, 1..4)
    {grid, bots} = place(grid, bots, team, :defender, 1..4, 5)

    {grid, bots} = place(grid, bots, team, :fighter, 6, 1..5) 
    {grid, bots} = place(grid, bots, team, :fighter, 6, 1..5) 
    {grid, bots} = place(grid, bots, team, :fighter, 6, 1..5) 
    {grid, bots} = place(grid, bots, team, :fighter, 6, 1..5) 
    {grid, bots} = place(grid, bots, team, :fighter, 1..5, 6) 
    {grid, bots} = place(grid, bots, team, :fighter, 1..5, 6) 
    {grid, bots} = place(grid, bots, team, :fighter, 1..5, 6) 
    {grid, bots} = place(grid, bots, team, :fighter, 1..5, 6) 

    {grid, bots} = place(grid, bots, team, :scout, 8..9, 1..9)
    {grid, bots} = place(grid, bots, team, :scout, 8..9, 1..9)
    {grid, bots} = place(grid, bots, team, :scout, 8..9, 1..9)
    {grid, bots} = place(grid, bots, team, :scout, 8..9, 1..9)
    {grid, bots} = place(grid, bots, team, :scout, 1..9, 8..9)
    {grid, bots} = place(grid, bots, team, :scout, 1..9, 8..9)
    {grid, bots} = place(grid, bots, team, :scout, 1..9, 8..9)
    {grid, bots} = place(grid, bots, team, :scout, 1..9, 8..9)

    {grid, bots} = place(grid, bots, team, :flag, 1..4, 1..4)

    {grid, bots}
  end

  def display(game) do
    Grid.display(game.grid)
  end

  def move(game, team, x0, y0, x1, y1) do
    grid = game.grid
    piece = Grid.get(grid, {team, x0, y0})
    dest = Grid.get(grid, {team, x1, y1})
IO.puts "move got: #{inspect {team, x0, y0, x1, y1}}"
    {grid, ret} = 
      cond do 
        dest == nil ->
          g = Grid.put(grid, {team, x1, y1}, piece)
          g = Grid.put(g, {team, x0, y0}, nil)
          {g, true}
        dest in [:redflag, :blueflag] ->
          g = Grid.put(grid, {team, x1, y1}, piece)
          g = Grid.put(g, {team, x0, y0}, nil)
          # FIXME mark game as over
          # Moved onto opponent's flag??
          IO.puts "Moved onto #{dest} - game over - FIXME"
          {g, false}  # logic??
        true ->
          {grid, false}
      end
    game = %Referee{game | grid: grid}
    {game, ret}
  end

  def over?(game), do: game.status == :over

  def record(_x, _y, _z), do: nil  # FIXME

  def start_link() do
    game = Referee.new   # game setup, start bots
    refpid = spawn_link Referee, :mainloop, [game]
    Enum.each(game.bots, &(Bot.awaken(&1, refpid)))
  end

  def take_turn(who) do
    if who == :red do
      :blue
    else
      :red
    end
  end

  def handle_move(_sender, game, _team, _x0, _y0, _x1, _y1) do
    display(game)
#    IO.puts "    handle_move: calling #move (#{inspect {team, x0, y0, x1, y1}})"
#    {g2, ret} = move(game, team, x0, y0, x1, y1)
#    IO.puts "    move() returned #{ret}"
#    if ret, do: send(sender, {g2, ret})
    game   # was: g2
  end

  def within(game, bot) do
#   IO.puts "grid = #{inspect game.grid}"
#   IO.puts "bot = #{inspect bot}"
    n = bot.see
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

  def get_bot_move(bot, game) do
    # ref sends info to bot, wants a "move" back
    visible = within(game, bot)
IO.puts "gbm: vis = #{inspect visible}"
    expected = bot.mypid
    # let bot take a turn
    response = receive do 
      %Bot{} = bot2 -> 
IO.puts "gbm: game.status = #{inspect game.status}"
IO.puts "gbm send: bot2 = #{inspect bot2} - sending to #{inspect bot2.mypid}"
        send(bot2.mypid, :noreply)
        @empty
      {%Bot{mypid: ^expected} = _bot, :move, :tox, :toy} -> 
        # send "visible" info
        send(expected, {:playing, visible})    # parallel to #1, #2
    end
  end

  def handle_bot_message(bot, game) do
    # ref replies to initial bot message
    sender = bot.mypid
IO.puts "hbm: status = #{game.status}"
    case game.status do
      :starting -> 
        IO.puts "  sending to #{inspect sender}"
        send(sender, :starting)   # case #1
        @empty
      :over     -> send(sender, :over)       # case #2
        @empty
      :playing  -> get_bot_move(bot, game)   # case #3
    end
  end

# FIXME Bot should receive game from referee??

  def bot_message(game) do
    # ref gets msg from bot
    receive do
      %Bot{} = bot -> 
        handle_bot_message(bot, game)         
      after 5000 -> 
        IO.puts "referee Timeout 5 sec"
        @empty
    end
  end

  def mainloop(game) do
IO.puts "Referee mainloop: self() = #{inspect self()}"
    who = take_turn(game.whose_turn)
    game = %Referee{game | whose_turn: who}
    msg = bot_message(game)
IO.puts "ref mainloop: GOT MSG #{inspect msg}"

   case msg do
     {sender, team, x0, y0, x1, y1} ->
       IO.puts "Got a 6-tuple"
     {} ->
       IO.puts "Got EMPTY tuple"
   end

# # FIXME BRAIN STOPPED HERE
# IO.puts "WE MADE IT!"
#     g2 = case team do
# # FIXME duh, first two cases are same??
#       :red -> 
# IO.puts "got RED"
# #       if who == team, do: handle_move(sender, game, team, x0, y0, x1, y1), else: game
#       :blue -> 
# IO.puts "got BLUE"
# #       if who == team, do: handle_move(sender, game, team, x0, y0, x1, y1), else: game
#       nil  -> game
#       true -> game
#     end

    if ! Referee.over?(game) do
      :timer.sleep 2000
IO.puts "recursing!\n\n "
:timer.sleep 2000
      mainloop(game) # tail recursion
    end
IO.puts "exiting!"
  end

end
