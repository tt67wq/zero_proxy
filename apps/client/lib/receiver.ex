defmodule Client.Receiver do
  @moduledoc """
  doc
  """

  def start_loop() do
    Task.Supervisor.start_child(Client.TaskSupervisor, fn -> loop_receive() end)
  end

  defp loop_receive() do
    {sid, port, data} = Client.Tunnel.recv()
    sock = get_socket(sid, port)
    Socket.Stream.send(sock, data)
    loop_receive()
  end

  defp get_socket(sid, port) do
    case Client.SockStore.lookup(sid) do
      nil ->
        {:ok, sock} = Socket.TCP.connect("localhost", port)
        Client.SockStore.register(sid, sock)
        Task.Supervisor.start_child(Client.TaskSupervisor, fn -> serve(sid, sock) end)
        sock

      sock ->
        sock
    end
  end

  defp serve(sid, sock) do
    case Socket.Stream.recv(sock) do
      {:ok, data} when data != nil ->
        Client.Tunnel.send2(sid, data)
        serve(sid, sock)

      _ ->
        Socket.Stream.close(sock)
        Client.SockStore.unregister(sid)
    end
  end
end
