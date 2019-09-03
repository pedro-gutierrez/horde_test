defmodule HordeTest.Inspector do
  use GenServer
  require Logger

  
  def node?() do
    GenServer.call(via_tuple(__MODULE__), :node)
  end
  
  def count_by_node() do
    GenServer.call(via_tuple(__MODULE__), :count_by_node)
  end

  def track_node(node, pid) do
    GenServer.cast(via_tuple(__MODULE__), {:track, node, pid})
  end
 
  def start_link() do
    case GenServer.start_link(__MODULE__, [], name: via_tuple(__MODULE__)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("#{__MODULE__} already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end
  
  def init(_args) do
    Process.flag(:trap_exit, true)
    {:ok, %{}, {:continue, :load_state}}
  end

  def handle_call(:node, _, data) do
    {:reply, Node.self(), data}
  end

  def handle_call(:count_by_node, _, data) do
    count_by_node = data 
      |> Enum.reduce(%{}, fn {_, node}, acc -> 
        Map.put(acc, node, Map.get(acc, node, 0)+1)
      end)
    {:reply, count_by_node, data}
  end

  def handle_continue(:load_state, data) do
    {:noreply, data}
  end

  def handle_info({:EXIT, _, {:name_conflict, {key, value}, _registry, _pid}}, state) do
    Logger.info("name conflict #{key}, #{value}")
    {:stop, :normal, state}
  end
  
  def handle_cast({:track, node, server_name}, data) do
    {:noreply, Map.put(data, server_name, node)}
  end

  def terminate(reason, state) do
    Logger.info("Terminated server with reason #{reason}")
    state 
  end

  def via_tuple(name), do: {:via, Horde.Registry, {HordeTest.DistRegistry, name}}
end
