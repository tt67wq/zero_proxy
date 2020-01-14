defmodule Server.Tunnel do
  @moduledoc """
  隧道
  """

  @port 5555
  @base_id "xyz"

  use GenServer
  require Logger

  def start_link(args) do
    name = Keyword.get(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def recv() do
    socket = Server.SockStore.lookup(@base_id)
    {:ok, [data]} = :chumak.recv_multipart(socket)
    <<sid::size(16), data::binary>> = data
    {<<sid::size(16)>>, <<data::binary>>}
  end

  def send2(sid, port, data) do
    GenServer.cast(__MODULE__, {:send, sid <> <<port::size(16)>> <> data})
  end

  #### callback

  def init(_args) do
    {:ok, socket} = :chumak.socket(:pair)
    {:ok, _} = :chumak.bind(socket, :tcp, '0.0.0.0', @port)
    Process.send_after(self(), :register, 1000)
    {:ok, %{socket: socket}}
  end

  def handle_info(:register, state) do
    Server.SockStore.register(@base_id, state.socket)
    Logger.info("start listening on port #{@port}")
    Server.Receiver.start_loop()
    {:noreply, state}
  end

  def handle_cast({:send, data}, state) do
    :ok = :chumak.send_multipart(state.socket, [data])
    {:noreply, state}
  end
end
