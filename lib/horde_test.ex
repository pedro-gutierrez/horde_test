defmodule HordeTest do
  @moduledoc """
  Documentation for HordeTest.
  """

  def add_singleton() do
    add_server(HordeTest.Server) 
  end

  def add_server(name) do
    Horde.Supervisor.start_child(HordeTest.DistSup, %{
      id: "HordeTest.Server_#{name}",
      start: {HordeTest.Server, :start_link, [name]},
      shutdown: 10_000,
      restart: :transient
    })
  end

  def add_many(num) do
    1..num 
      |> Enum.each( fn n -> 
        add_server("server#{n}")
      end)
  end

  def singleton_info() do
    server_info(HordeTest.Server)
  end

  def server_info(name) do
    node = HordeTest.Server.node?(name)
    pid = HordeTest.Server.pid?(name)
    {node, pid}
  end

  def distribution() do
    HordeTest.Inspector.count_by_node()
  end

  def add_inspector() do
    Horde.Supervisor.start_child(HordeTest.DistSup, %{
      id: "HordeTest.Inspector",
      start: {HordeTest.Inspector, :start_link, []},
      shutdown: 10_000,
      restart: :transient
    })
  end

  def inspector_node() do
    HordeTest.Inspector.node?()
  end
end
