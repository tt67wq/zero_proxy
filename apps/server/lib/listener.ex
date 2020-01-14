defmodule Server.Listener do
  @moduledoc """
  doc
  """

  alias Server.Tunnel
  require Logger
  use Task

  def start_link(args) do
    Task.start_link(__MODULE__, :run, [args])
  end

  def run(args) do
    out_port = Keyword.get(args, :out)
    in_port = Keyword.get(args, :in)
    {:ok, listener} = Socket.TCP.listen(out_port)
    loop_accept(listener, in_port)
  end

  defp loop_accept(listener, inner_port) do
    {:ok, client} = Socket.TCP.accept(listener)

    sid = gen_socket_id()
    Server.SockStore.register(sid, client)

    serve(sid, client, inner_port)
    loop_accept(listener, inner_port)
  end

  defp serve(sid, client, inner_port) do
    case Socket.Stream.recv(client) do
      {:ok, data} when data != nil ->
        Tunnel.send2(sid, inner_port, data)
        serve(sid, client, inner_port)

      _ ->
        Socket.Stream.close(client)
        Server.SockStore.unregister(sid)
    end
  end

  defp gen_socket_id(), do: <<Enum.random(0..255), Enum.random(0..255)>>
end
