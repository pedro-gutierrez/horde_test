defmodule HordeTest.Server do
  use GenServer
  require Logger

  def node?() do
    GenServer.call(via_tuple(__MODULE__), :node)
  end
  
  def pid?() do
    case Horde.Registry.lookup(HordeTest.DistRegistry, __MODULE__) do
      [{pid, _}] -> pid
      other ->
        {:error, other}
    end
  end

  def child_spec(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    %{
      id: "#{__MODULE__}_#{name}",
      start: {__MODULE__, :start_link, [name]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  def start_link(name) do
    case GenServer.start_link(__MODULE__, [], name: via_tuple(name)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("#{name} already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end
  
  def init(_args) do
    IO.puts "starting server..."
    Process.flag(:trap_exit, true)
    {:ok, nil, {:continue, :load_state}}
  end

  def handle_call(:node, _, data) do
    {:reply, Node.self(), data}
  end
  
  def handle_continue(:load_state, arg) do
    IO.puts "handle continue with :load_state"
    IO.inspect arg
    {:noreply, arg}
  end

  def handle_info({:EXIT, _, {:name_conflict, {key, value}, _registry, _pid}}, state) do
    Logger.info("name conflict #{key}, #{value}")
    {:stop, :normal, state}
  end

  def terminate(reason, state) do
    Logger.info("Terminated server with reason #{reason}")
    state 
  end

  def via_tuple(name), do: {:via, Horde.Registry, {HordeTest.DistRegistry, name}}
end
