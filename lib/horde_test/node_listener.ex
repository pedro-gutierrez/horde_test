defmodule HordeTest.NodeListener do
  use GenServer
  
  def start_link([name: name]) do
    GenServer.start_link(__MODULE__, [], name: name)
  end

  def init(_) do
    :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, nil}
  end

  def handle_info({:nodeup, _node, _}, state) do
    set_members(HordeTest.DistSup)
    set_members(HordeTest.DistRegistry)
    {:noreply, state}
  end

  def handle_info({:nodedown, _node, _}, state) do
    set_members(HordeTest.DistSup)
    set_members(HordeTest.DistRegistry)
    {:noreply, state}
  end

  defp set_members(name) do
    members = 
    [Node.self() | Node.list()]
    |> Enum.map(fn node -> {name, node} end)
    :ok = Horde.Cluster.set_members(name, members, 10000)
  end
end
