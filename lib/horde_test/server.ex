defmodule HordeTest.Server do
  use GenServer
  require Logger

  @cluster HordeTest.Cluster

  def info(pid) when is_pid(pid) do
    GenServer.call(pid, :info)
  end

  def info(num) when is_number(num) do
    num |> name() |> info()
  end

  def info(name) when is_binary(name) do
    case @cluster.whereis(__MODULE__, name) do
      {:ok, pid} ->
        info(pid)

      {:error, _} = e ->
        e
    end
  end

  def name(num) when is_number(num), do: "s#{num}"

  def start_link(name) do
    case GenServer.start_link(__MODULE__, [name], name: @cluster.via_tuple(__MODULE__, name)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info(
          "Trying to start #{name} in node #{Node.self()}, but already started with pid #{
            inspect(pid)
          }. "
        )

        :ignore
    end
  end

  def init([name]) do
    Process.flag(:trap_exit, true)
    Logger.info("Server #{name} came alive in #{Node.self()}")
    {:ok, name}
  end

  def handle_call(:info, _, name) do
    node = Node.self()
    {:reply, {:ok, node, self()}, name}
  end

  def handle_info({:EXIT, _, {:name_conflict, {{_, name}, _}, _registry, _pid}}, name) do
    Logger.warn("name conflict #{name} in node #{Node.self()}")
    {:stop, :normal, name}
  end

  def terminate(reason, name) do
    Logger.warn("Server #{name} (#{self() |> inspect}) terminated with reason #{reason}")
    name
  end
end
