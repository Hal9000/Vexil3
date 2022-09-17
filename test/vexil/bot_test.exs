defmodule Vexil.BotTest do
  use ExUnit.Case

  alias Vexil.{Bot, Grid}

  describe "where/1" do
    test "with red" do
      bob = Bot.scout(:red, 1, 5)
      assert Bot.where(bob) == {1, 5}
    end
    test "with blue" do
      bob = Bot.scout(:blue, 1, 5)
      assert Bot.where(bob) == {1, 5}
    end
  end

  test "enemy? true when two bots different colors" do
    bob = Bot.scout(:red, 1, 5)
    tom = Bot.scout(:blue, 2, 6)
    assert Bot.enemy?(bob, tom)
  end

  test "enemy? false when two bots same color" do
    bob = Bot.scout(:red, 1, 5)
    tom = Bot.scout(:red, 2, 6)
    refute Bot.enemy?(bob, tom)
  end
 
  # Next: Build partial grid, start referee, start ONE bot?

  test "create an empty game" do
    grid = Grid.new
    # bots = []
    rd = Bot.defender(:red, 3, 7)
    bs1 = Bot.scout(:blue, 3, 6)
    bs2 = Bot.scout(:blue, 3, 8)
    bf  = Bot.fighter(:blue, 3, 10)
    bd  = Bot.fighter(:blue, 3, 12)
    bots = [rd, bs1, bs2, bf, bd]
    grid = Grid.put(grid, rd)
    grid = Grid.put(grid, bs1)
    grid = Grid.put(grid, bs2)
    grid = Grid.put(grid, bf)
    grid = Grid.put(grid, bd)
    # Referee.new(grid, bots)
    # game = Referee.new(grid, bots)
    # IO.inspect Bot.can_see(game, rd)
  end

end
