defmodule HordeTestTest do
  use ExUnit.Case
  #use ExUnit.ClusteredCase
  doctest HordeTest
  
  test "should register servers" do
    LocalCluster.start_nodes("node", 2)

    {:ok, pid} = HordeTest.add_server("pedro")
    node = GenServer.call(pid, :node)
    
    ## wait for crdts to propagate
    :timer.sleep(200)

    {^node, ^pid} = :rpc.call(:"manager@127.0.0.1", HordeTest, :server_info, ["pedro"])
    {^node, ^pid} = :rpc.call(:"node1@127.0.0.1", HordeTest, :server_info, ["pedro"])
    {^node, ^pid} = :rpc.call(:"node2@127.0.0.1", HordeTest, :server_info, ["pedro"])

  end
end
