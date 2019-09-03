defmodule HordeTest do
  @moduledoc """
  Documentation for HordeTest.
  """

  def add_server() do 
    Horde.Supervisor.start_child(HordeTest.DistSup, HordeTest.Server)
  end

  def server_info() do
    node = HordeTest.Server.node?()
    pid = HordeTest.Server.pid?()
    {node, pid}
  end
end
