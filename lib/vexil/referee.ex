defmodule Vexil.Referee do
  alias Vexil.{Bot, Grid, Referee}

  defstruct [:grid, :bots, :pid, status: :starting]

  def new do 
    {grid, bots} = setup(%{})
    %Referee{grid: grid, bots: bots, pid: nil, status: :starting}
  end

  def new(grid, bots) do
    %Referee{grid: grid, bots: bots, pid: nil, status: :starting}
  end

  def start! do
    game = %Referee{status: :playing}
    who = :red
    spawn_link Referee, :mainloop, [game, who]
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
    
    bot = Bot.make(kind, team, x2, y2)
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

  def start_link(game) do
    Enum.each(game.bots, fn(bot) -> Bot.awaken(bot, game) end)
IO.puts "start_link: sleeping 10 sec"
:timer.sleep 10000
IO.puts "    spawn_link()..."
#    pid = spawn_link Referee, :mainloop, [game, who]
     pid = start!()
IO.puts "    Marking game status PLAYING"
    game = %Referee{game | pid: pid, status: :playing}
    game
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

# FIXME Bot should receive game from referee??

  def bot_message do
    receive do
      {sender, _bot_game, :move, team, x0, y0, x1, y1} ->
        {sender, team, x0, y0, x1, y1}
      {sender, "check_status"} -> "FIXME"  # brain stopped here
      other -> 
        IO.puts "Got: #{inspect(other)}"
        :timer.sleep 2000
        {nil, nil, nil, nil, nil, nil} 
      after 5000 -> 
        IO.puts "referee Timeout 5 sec"
        {nil, nil, nil, nil, nil, nil} 
    end
  end

  def mainloop(game, who) do
IO.puts "Mainloop: status = #{game.status}"
IO.puts "Mainloop: sleep 3 secs"
:timer.sleep 3000
IO.puts "Mainloop: NOW status = #{game.status}"
    who = take_turn(who)
IO.puts "-- referee mainloop: It's #{who |> to_string |> String.upcase}'s turn"
:timer.sleep 3000
 
    {sender, team, x0, y0, x1, y1} = bot_message()
    g2 = case team do
      :red -> 
        if who == team, do: handle_move(sender, game, team, x0, y0, x1, y1), else: game
      :blue -> 
        if who == team, do: handle_move(sender, game, team, x0, y0, x1, y1), else: game
      true -> game
    end

    if ! Game.over?(g2) do
      :timer.sleep 2000
IO.puts "recursing!\n\n "
:timer.sleep 2000
      mainloop(g2, who) # tail recursion
    end
IO.puts "exiting!"
  end

end
