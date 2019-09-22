defmodule HordeTest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  @cluster HordeTest.Cluster

  def start(_type, _args) do
    {:ok, pid} =
      Supervisor.start_link(
        [
          @cluster
        ],
        strategy: :one_for_one,
        name: HordeTest.Supervisor
      )

    # Start the cluster by default
    # on the current node
    :ok = @cluster.start()
    {:ok, pid}
  end
end
