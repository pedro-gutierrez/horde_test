defmodule HordeTest do
  @moduledoc """
  Documentation for HordeTest.
  """
  def add_server(name) do
    Horde.Supervisor.start_child(HordeTest.DistSup, %{
      id: "HordeTest.Server_#{name}",
      start: {HordeTest.Server, :start_link, [name]},
      shutdown: 10_000,
      restart: :permanent
    })
  end

  def add_servers(num) do
    1..num 
      |> Enum.each( fn n -> 
        add_server("server#{n}")
      end)
  end

  def server_info(name) do
    node = HordeTest.Server.node?(name)
    pid = HordeTest.Server.pid?(name)
    {node, pid}
  end
  def add_inspector() do
    Horde.Supervisor.start_child(HordeTest.DistSup, %{
      id: "HordeTest.Inspector",
      start: {HordeTest.Inspector, :start_link, []},
      shutdown: 10_000,
      restart: :transient
    })
  end

  def ping() do
    HordeTest.Inspector.ping()
  end

  def inspect() do
    %{
      inspector: HordeTest.Inspector.node?(),
      supervisor_children: Horde.Supervisor.count_children(HordeTest.DistSup), 
      servers_by_node: HordeTest.Inspector.count_by_node()
    }
  end
end
