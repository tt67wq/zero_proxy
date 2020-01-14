defmodule Client do
  @moduledoc """
  Documentation for Client.
  """

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Client.SockStore},
      Client.Tunnel,
      {Task.Supervisor, name: Client.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Client.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
