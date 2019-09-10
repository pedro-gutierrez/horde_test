defmodule HordeTest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do

    {:ok, nodes} = Application.fetch_env(:horde_test, :nodes)

    topologies = [
      example: [
        strategy: Cluster.Strategy.Epmd,
        config: [hosts: nodes]
      ]
    ]
    
    children = [
      {Cluster.Supervisor, [topologies, [name: HordeTest.ClusterSupervisor]]},
      {HordeTest.NodeListener, [name: HordeTest.NodeListener]},
      {Horde.Registry, [name: HordeTest.DistRegistry, keys: :unique]},
      {HordeTest.DistSup, [name: HordeTest.DistSup, 
        shutdown: 1000, 
        strategy: :one_for_one 
        #distribution_strategy: Horde.UniformQuorumDistribution 
      ]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HordeTest.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    HordeTest.add_inspector()
    {:ok, pid}
  end
end
