defmodule Server do
  @moduledoc """
  Documentation for Server.
  """

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Server.SockStore},
      Server.Tunnel,
      {Task.Supervisor, name: Server.TaskSupervisor}
    ]

    children = children ++ listeners()
    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp listeners() do
    [
      {Server.Listener, [out: 8080, in: 80]}
    ]
  end
end
