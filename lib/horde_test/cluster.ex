defmodule HordeTest.Cluster do
  @moduledoc false

  @registry HordeTest.DistReg
  @supervisor HordeTest.DistSup
  @monitor HordeTest.Monitor
  @libcluster_supervisor HordeTest.LibClusterSupervisor

  use DynamicSupervisor
  require Logger

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start() do
    start(
      nodes: [node()],
      dist: Horde.UniformQuorumDistribution
    )
  end

  def start(opts) do
    opts
    |> specs()
    |> Enum.each(&start_child!(&1))

    :ok
  end

  defp start_child!(spec) do
    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, _} ->
        Logger.info("Started #{spec[:id]} in #{Node.self()}")

      {:error, {:already_started, pid}} ->
        Logger.warn(
          "#{spec[:id]} in #{Node.self()} is already started with #{pid |> inspect()}. Killing and restarting..."
        )

        stop_child(pid)
        start_child!(spec)
    end
  end

  defp stop_child(pid) do
    :ok = DynamicSupervisor.terminate_child(__MODULE__, pid)
    Logger.warn("Terminated remaining #{pid |> inspect()} in #{Node.self()}")
  end

  def start_worker(
        id: id,
        start: start
      ) do
    Horde.DynamicSupervisor.start_child(@supervisor, %{
      id: id,
      start: start,
      shutdown: 10_000,
      restart: :transient
    })
  end

  def stop() do
    [
      {Horde.Registry, @registry},
      {Horde.DynamicSupervisor, @supervisor}
    ]
    |> Enum.each(&stop_gracefully(&1))

    for {_, pid, _, _} <- DynamicSupervisor.which_children(__MODULE__) do
      stop_child(pid)
    end
  end

  def stop_gracefully({mod, name}) do
    case Process.whereis(name) do
      nil ->
        :ok

      _ ->
        :ok = mod.stop(name)
        Logger.warn("Stopped #{name} in #{Node.self()}")
    end
  end

  defp members(nodes, module) do
    nodes
    |> Enum.map(&{module, &1})
  end

  def specs(nodes: nodes, dist: dist) do
    [monitor_spec(nodes), registry_spec(nodes, dist), supervisor_spec(nodes, dist)]
  end

  defp registry_spec(nodes, dist) do
    %{
      id: @registry,
      restart: :transient,
      start:
        {Horde.Registry, :start_link,
         [
           [
             name: @registry,
             keys: :unique,
             members: nodes |> members(@registry),
             distribution_strategy: dist
           ]
         ]}
    }
  end

  defp supervisor_spec(nodes, dist) do
    %{
      id: @supervisor,
      restart: :transient,
      start:
        {Horde.DynamicSupervisor, :start_link,
         [
           [
             name: @supervisor,
             members: nodes |> members(@supervisor),
             strategy: :one_for_one,
             max_restarts: 10_000,
             max_seconds: 1,
             distribution_strategy: dist
           ]
         ]}
    }
  end

  defp monitor_spec(nodes) do
    %{
      id: @monitor,
      restart: :transient,
      start:
        {@monitor, :start_link,
         [
           [
             name: @monitor,
             nodes: nodes
           ]
         ]}
    }
  end

  ## defp libcluster_spec(nodes, strategy \\ Cluster.Strategy.Epmd) do
  ##  %{
  ##    id: @libcluster_supervisor,
  ##    restart: :transient,
  ##    start:
  ##      {Cluster.Supervisor, :start_link,
  ##       [
  ##         [
  ##           [
  ##             horde_test: [
  ##               strategy: strategy,
  ##               config: [
  ##                 hosts: nodes
  ##               ]
  ##             ]
  ##           ],
  ##           [name: @libcluster_supervisor]
  ##         ]
  ##       ]}
  ##  }
  ## end

  def available?() do
    Process.whereis(__MODULE__) != nil
  end

  def running?() do
    count() == 3
  end

  def count() do
    case available?() do
      false ->
        0

      true ->
        %{active: count} = DynamicSupervisor.count_children(__MODULE__)
        count
    end
  end

  def quorum!(timeout \\ 10_000) do
    Horde.DynamicSupervisor.wait_for_quorum(@supervisor, timeout)
  end

  def via_tuple(kind, name) do
    {:via, Horde.Registry, {@registry, {kind, name}}}
  end

  def whereis(kind, name) do
    lookup(@registry, {kind, name})
  end

  defp lookup(registry, key) do
    case Horde.Registry.lookup(registry, key) do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        {:error, :not_found}

      other ->
        {:error, other}
    end
  end
end
