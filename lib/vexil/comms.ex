defmodule Vexil.Comms do

  def sendrecv(pid, data) do
#   IO.inspect(data, label: "sending to #{inspect(pid)}")
#   IO.puts("#{inspect data}")
    send(pid, data)      # send move to referee
#   raise "hell - #{inspect pid} data = #{inspect data}"
    result = receive do  # receive new grid and return val from referee
      {grid, ret} ->
        {grid, ret}
      other -> IO.inspect other, label: "sendrecv got this"
      after 5000 -> IO.puts "sendrecv Timeout 5 sec"
        {:error, :timeout}
    end
    result
  end

end
