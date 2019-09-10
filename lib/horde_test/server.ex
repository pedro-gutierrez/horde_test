defmodule HordeTest.Server do
  use GenServer
  require Logger

  def info(pid) when is_pid(pid) do
    GenServer.call(pid, :info)
  end
  
  def info(name) do
    case pid?(name) do
      {:error, error} ->
        {:error, error}
      pid ->
        info(pid)
    end
  end

  def pid?(name) do
    case Horde.Registry.lookup(HordeTest.DistRegistry, {Server, name}) do
      [{pid, _}] -> pid
      other ->
        {:error, other}
    end
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
    Logger.info("Server #{name} came alive in #{Node.self()}")
    :pg2.join(:servers, self())
    Process.flag(:trap_exit, true)
    {:ok, name, {:continue, :register}}
  end

  def handle_continue(:register, name) do
    case HordeTest.Inspector.track_node(Node.self(), name) do
      :ok ->
        Logger.info("Server #{name} sent its node info to the inspector")
      {:error, e} ->
        Logger.error("Server #{name} could not send its node info to inspector: #{e}")
    end
    {:noreply, name}
  end

  def handle_call(:info, _, name) do
    node = Node.self()
    Logger.info("Server #{name} in node #{node} received ping from inspector")
    {:reply, {:ok, node, name}, name}
  end
  
  def handle_info({:EXIT, _, {:name_conflict, {key, value}, _registry, _pid}}, state) do
    Logger.info("name conflict #{key}, #{value}")
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _, other}, state) do
    Logger.info("trapped exit signal #{other}")
    {:stop, other, state}
  end

  def terminate(reason, name) do
    Logger.info("Terminated #{name} with reason #{reason}")
    name 
  end

  def via_tuple(name), do: {:via, Horde.Registry, {HordeTest.DistRegistry, {Server, name}}}
end
