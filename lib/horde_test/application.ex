defmodule HordeTest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    topologies = [
      example: [
        strategy: Cluster.Strategy.Epmd,
        config: [hosts: [:"node1@127.0.0.1", :"node2@127.0.0.1", :"node3@127.0.0.1"]],
      ]
    ]
    
    children = [
      {Cluster.Supervisor, [topologies, [name: HordeTest.ClusterSupervisor]]},
      {HordeTest.NodeListener, [name: HordeTest.NodeListener]},
      {Horde.Registry, [name: HordeTest.DistRegistry, keys: :unique]},
      {HordeTest.DistSup, [name: HordeTest.DistSup, shutdown: 1000, strategy: :one_for_one]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HordeTest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
