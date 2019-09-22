defmodule HordeTest do
  @moduledoc """
  Documentation for HordeTest.
  """

  @cluster HordeTest.Cluster

  def add_one(num) when is_number(num) do
    num
    |> HordeTest.Server.name()
    |> add_one()
  end

  def add_one(name) when is_binary(name) do
    @cluster.start_worker(
      id: name,
      start: {HordeTest.Server, :start_link, [name]}
    )
  end

  def add_many(count) do
    1..count
    |> Enum.each(&add_one(&1))
  end

  def info(name) do
    HordeTest.Server.info(name)
  end
end
