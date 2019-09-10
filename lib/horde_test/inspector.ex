defmodule HordeTest.Inspector do
  use GenServer
  require Logger

  
  def node?() do
    call(:node)
  end

  def ping() do
    cast(:ping_servers)
  end

  def count_by_node() do
    call(:count_by_node)
  end

  def track_node(node, pid) do
    call({:track, node, pid})
  end

  defp cast(msg) do
    with_inspector_pid(fn pid ->
      GenServer.cast(pid, msg)
    end)
  end

  defp call(msg) do
    with_inspector_pid(fn pid ->
      GenServer.call(pid, msg)
    end)
  end
  
  defp with_inspector_pid(next) do
    case Horde.Registry.lookup(HordeTest.DistRegistry, __MODULE__) do
      [{pid, _}] ->
        next.(pid)

      :undefined -> 
        Logger.error("No inspector pid registered")
        {:error, :no_pid}
    end
  end 
 
  def start_link() do
    case GenServer.start_link(__MODULE__, [], name: via_tuple(__MODULE__)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("Inspector already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end

  def via_tuple(name), do: {:via, Horde.Registry, {HordeTest.DistRegistry, name}}

  def init(_args) do
    :pg2.create(:servers)
    Process.flag(:trap_exit, true)
    {:ok, %{}, {:continue, :load_state}}
  end

  def handle_call(:node, _, data) do
    {:reply, {Node.self(), self()}, data}
  end

  def handle_call(:count_by_node, _, data) do
    count_by_node = data 
      |> Enum.reduce(%{}, fn {_, node}, acc -> 
        Map.put(acc, node, Map.get(acc, node, 0)+1)
      end)
    {:reply, count_by_node, data}
  end

  def handle_call({:track, node, name}, _, data) do
    Logger.info("Tracking server #{name} from #{node}")
    {:reply, :ok, Map.put(data, name, node)}
  end

  def handle_cast(:ping_servers, data) do
    data = data |> ping_servers()
    {:noreply, data}
  end

  def handle_continue(:load_state, data) do
    Logger.info("Inspector started on #{Node.self()}")
    data = data |> ping_servers()
    {:noreply, data}
  end

  def handle_info({:EXIT, _, {:name_conflict, {key, value}, _registry, _pid}}, state) do
    Logger.info("name conflict #{key}, #{value}")
    {:stop, :normal, state}
  end
  
  def terminate(reason, state) do
    Logger.info("Terminated inspector in #{Node.self()} with reason #{reason}")
    state 
  end

 
  defp ping_servers(data) do
    pids = :pg2.get_members(:servers)
    Logger.info("Inspector fetching info from #{length(pids)} existing servers")
    pids |> Enum.reduce(data, fn pid, acc ->
      {:ok, node, name} = HordeTest.Server.info(pid)
      Map.put(acc, name, node)
    end)
  end
end
