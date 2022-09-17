defmodule Mix.Tasks.Vexil.Game do
  use Mix.Task
  alias Vexil.Referee

  @shortdoc "Run the Vexil Game"
  def run(_) do
    :rand.seed(:exsplus, {0,0,0})
    game = Referee.new
    Referee.display(game)
    game = Referee.start_link(game)
    :timer.sleep 400000 
    # Referee.display(game)
  end

end
