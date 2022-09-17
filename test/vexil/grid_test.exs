defmodule GridTest do
  use ExUnit.Case

  alias Vexil.{Bot, Grid}

  doctest Grid

  test "put and get" do
    grid = %{}
    where = {:red, 3, 5}
    val = "foo"
    grid = Grid.put(grid, where, val)
    assert Grid.get(grid, where) == val
  end

  test "empty cell as string" do
    grid = Grid.put(%{}, {:red, 1, 1}, nil)    
    assert Grid.cell(grid, 1, 2) == "-"
  end

  test "occupied cell as string" do
    bot = Bot.defender(:red, 3, 3)
    grid = Grid.put(%{}, {:red, 3, 3}, bot)    
    assert Grid.cell(grid, 3, 3) == "\e[31mD\e[0m"
  end



end
