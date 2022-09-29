defmodule Vexil.Comms do

  def sendrecv(pid, data) do
# IO.inspect(data, label: "sending to #{inspect(pid)}")
# IO.puts("#{inspect data}")
    send(pid, data)      # send move to referee
#   raise "hell - #{inspect pid} data = #{inspect data}"
    result = receive do  # receive new grid and return val from referee
      {grid, ret} ->
        {grid, ret}
      other -> IO.inspect other, label: "sendrecv got OTHER"
      after 15000 -> IO.puts "sendrecv - timeout 15 sec"
        {:error, :timeout}
    end
    result
  end

  def ask_game_state(refpid) do
    send(refpid, "check_status")
    result = receive do 
      :starting  -> :starting
      :playing   -> :playing
      :over      -> :over
      other      -> IO.puts "Received #{inspect other} instead of status"; nil
      after 1000 -> IO.puts "Timeout checking game status"; nil
    end
    result
  end

end
