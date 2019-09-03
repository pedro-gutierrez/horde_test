defmodule HordeTest.Server do
  use GenServer
  require Logger

  def node?(name) do
    GenServer.call(via_tuple(name), :node)
  end

  def node?() do
    node?(__MODULE__)
  end

  
  def pid?(name) do
    case Horde.Registry.lookup(HordeTest.DistRegistry, {Server, name}) do
      [{pid, _}] -> pid
      other ->
        {:error, other}
    end
  end

  def pid?() do
    pid?(__MODULE__)
  end

  def start_link(name) do
    case GenServer.start_link(__MODULE__, [name], name: via_tuple(name)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("#{name} already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end
  
  def init([name]) do
    Process.flag(:trap_exit, true)
    {:ok, name, {:continue, :load_state}}
  end

  def handle_call(:node, _, data) do
    {:reply, Node.self(), data}
  end
  
  def handle_continue(:load_state, name) do
    Logger.info("continue loading in #{Node.self()}")
    HordeTest.Inspector.track_node(Node.self(), name)
    {:noreply, name}
  end

  def handle_info({:EXIT, _, {:name_conflict, {key, value}, _registry, _pid}}, state) do
    Logger.info("name conflict #{key}, #{value}")
    {:stop, :normal, state}
  end

  def terminate(reason, name) do
    Logger.info("Terminated #{name} with reason #{reason}")
    name 
  end

  def via_tuple(name), do: {:via, Horde.Registry, {HordeTest.DistRegistry, {Server, name}}}
end
