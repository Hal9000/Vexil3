defmodule Vexil.Referee do
  alias Vexil.{Bot, Grid, Referee}

  defstruct [:grid, :bots, :pid, :over?]

  def new do 
    {grid, bots} = setup(%{})
    %Referee{grid: grid, bots: bots, pid: nil, over?: false}
  end

  def new(grid, bots) do
    %Referee{grid: grid, bots: bots, pid: nil, over?: false}
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
    x2 = if Range.range?(x), do: rand(x), else: x
    y2 = if Range.range?(y), do: rand(y), else: y
    
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
    {grid, redbots} = setup(grid, :red)
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
    {grid, ret} = 
      cond do 
        dest == nil ->
#         IO.puts "move: normal case"
          g = Grid.put(grid, {team, x1, y1}, piece)
          g = Grid.put(g, {team, x0, y0}, nil)
          {g, true}
        dest in [:redflag, :blueflag] ->
          g = Grid.put(grid, {team, x1, y1}, piece)
          g = Grid.put(g, {team, x0, y0}, nil)
          # FIXME mark game as over
          IO.puts "Moved onto #{dest} - game over - FIXME"
          {g, false}  # logic??
        true ->
#         IO.puts "SOMETHING WRONG? Can't move #{inspect piece} onto #{inspect dest}"
          {grid, false}
      end
    game = %Referee{game | grid: grid}
    {game, ret}
  end

  def over?(game), do: game.over?

  def record(_x, _y, _z), do: nil  # FIXME

  def start_link(game) do
    pid = spawn_link Referee, :mainloop, [game]
    game = %Referee{game | pid: pid}
    Enum.each(game.bots, fn(bot) -> Bot.awaken(bot, game) end)
    game
  end

  def simulate(game) do 
    pid = spawn Referee, :mainloop, [game]
    %Referee{game | pid: pid}
  end

  def mainloop(game) do
#   IO.puts "game pid in REF = #{inspect game.pid}"
#   IO.puts "REF pid = #{inspect self()}"
#   IO.puts "Referee is listening..."
    g = receive do
      {caller, _bot_game, :move, team, x0, y0, x1, y1} ->
#       IO.puts "mainloop: #{team} moves from #{inspect {x0, y0}} to #{inspect {x1, y1}}"
        {g2, ret} = move(game, team, x0, y0, x1, y1)
        if ret do
          send(caller, {g2, ret})
        end
        g2
      other -> IO.puts "Got: #{inspect(other)}"
      after 5000 -> IO.puts "referee Timeout 5 sec"
    end
#   IO.puts "debugging..."
    :timer.sleep 200
    mainloop(g) # tail recursion
  end

end
