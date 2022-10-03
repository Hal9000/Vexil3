defmodule Vexil.Referee do
  alias Vexil.{Bot, Grid, Referee}

  defstruct [:grid, :bots, :pid, status: :starting]

  def new do 
    {grid, bots} = setup(%{})
    ref = %Referee{grid: grid, bots: bots, pid: nil, status: :starting}
    ref
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
    who = :red
    refpid = spawn_link Referee, :mainloop, [game, who]
    Enum.each(game.bots, &(Bot.awaken(&1, refpid)))
  end

  def take_turn(who) do
    if who == :red do
      :blue
    else
      :red
    end
  end

  def handle_move(sender, game, team, x0, y0, x1, y1) do
    display(game)
    IO.puts "    handle_move: calling #move (#{inspect {team, x0, y0, x1, y1}})"
    {g2, ret} = move(game, team, x0, y0, x1, y1)
    IO.puts "    move() returned #{ret}"
    if ret, do: send(sender, {g2, ret})
    g2
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
    {_kind, _bx, _by} = {bot.kind, bot.x, bot.y}
    visible = within(game, bot)      
    expected = bot.mypid
    send(expected, visible)    # parallel to #1, #2
    # let bot take a turn
    receive do 
      %Bot{} = bot2        -> send(bot2.mypid, :noreply)
      {%Bot{mypid: ^expected} = _bot, :move, :tox, :toy} -> nil
    end
  end

  def handle_bot_message(bot, game) do
    sender = bot.mypid
    case game.status do
      :starting -> send(sender, :starting)   # case #1
      :over     -> send(sender, :over)       # case #2
      :playing  -> get_bot_move(bot, game)   # case #3
    end
  end

# FIXME Bot should receive game from referee??

  def bot_message(game) do
    receive do
      %Bot{} = bot -> 
        handle_bot_message(bot, game)         
      after 5000 -> 
        IO.puts "referee Timeout 5 sec"
        {nil, nil, nil, nil, nil, nil} 
    end
  end

  def mainloop(game, who) do
    _refpid = self()
    who = take_turn(who)
    {sender, team, x0, y0, x1, y1} = bot_message(game)
IO.inspect {sender, team, x0, y0, x1, y1}
    g2 = case team do
      :red -> 
        if who == team, do: handle_move(sender, game, team, x0, y0, x1, y1), else: game
      :blue -> 
        if who == team, do: handle_move(sender, game, team, x0, y0, x1, y1), else: game
      nil  -> game
      true -> game
    end

    if ! Referee.over?(g2) do
      :timer.sleep 2000
IO.puts "recursing!\n\n "
:timer.sleep 2000
      mainloop(g2, who) # tail recursion
    end
IO.puts "exiting!"
  end

end
