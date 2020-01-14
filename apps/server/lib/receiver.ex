defmodule Server.Receiver do
  @moduledoc """
  doc
  """
  require Logger

  def start_loop() do
    Task.Supervisor.start_child(Server.TaskSupervisor, fn -> run() end)
  end

  def run() do
    {sid, data} = Server.Tunnel.recv()

    Logger.debug("recv from tunnel: #{inspect(data)}")

    case Server.SockStore.lookup(sid) do
      nil ->
        Logger.warn("ignored msg: #{inspect(data)}")

      client ->
        Socket.Stream.send(client, data)
    end

    run()
  end
end
