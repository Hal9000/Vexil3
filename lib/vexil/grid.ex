# Also credit di4na mjadczak

defmodule Vexil.Grid do
  alias Vexil.{Bot, Grid}
  
  @doc """
  Translates from team coordinates to global coordinates.
  
      iex> g = Grid.new
      iex> g = Grid.put(g, {:blue, 3, 5}, "junk")
      iex> Grid.get(g, {:red, 3, 5})
      nil
      iex> Grid.get(g, {:blue, 3, 5})
      "junk"
      iex> Grid.get(g, {:red, 19, 17})
      "junk"
      
  """

  def get(grid, {:red, x, y}),  do: Map.get(grid, {:red, x, y})
  def get(grid, {:blue, x, y}), do: Map.get(grid, {:red, 22-x, 22-y})

  def put(grid, {:red, x, y}, piece),  do: Map.put(grid, {:red, x, y}, piece)
  def put(grid, {:blue, x, y}, piece), do: Map.put(grid, {:red, 22-x, 22-y}, piece)

  def put(grid, piece), do: Map.put(grid, {piece.team, piece.x, piece.y}, piece)

  def new do 
    %{}
  end

  def cell(grid, xx, yy) do
    bot = Grid.get(grid, {:red, xx, yy})
    if bot == nil, do: "-", else: Bot.to_string(bot)
  end

  def show_cell(grid, xx, yy) do
    char = cell(grid, xx, yy)
    IO.write "#{char} "
  end

  def cell_empty?(grid, triple) do
    bot = Grid.get(grid, triple)
    bot == nil
  end

  def display(grid) do
    IO.puts "\e[H\e[2J"  # clear screen
    IO.puts ""
    yrange = 21..1
    xrange = 1..21
    Enum.each yrange, fn(y) -> 
      Enum.each xrange, fn(x) -> show_cell(grid, x, y) end
      IO.puts ""
    end
  end

end
