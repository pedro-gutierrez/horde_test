defmodule HordeTest.Monitor do
  use GenServer
  require Logger

  def start_link(name: name, nodes: nodes) do
    GenServer.start_link(__MODULE__, nodes, name: name)
  end

  def init(nodes) do
    :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, {nodes, nil}, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    {:noreply, connect(state)}
  end

  def handle_info(:connect, state) do
    {:noreply, connect(state)}
  end

  def handle_info({:nodeup, node, _}, state) do
    Logger.info("#{Node.self()} saw #{node} come up")
    {:noreply, state}
  end

  def handle_info({:nodedown, node, _}, state) do
    Logger.warn("#{Node.self()} saw #{node} come down. Reconnecting...")
    Node.connect(node)
    {:noreply, state}
  end

  defp connect({nodes, nil}) do
    for n <- nodes, do: n |> connect_node()
    {nodes, Process.send_after(self(), :connect, 50)}
  end

  defp connect({nodes, timer_ref}) do
    Process.cancel_timer(timer_ref)
    connect({nodes, nil})
  end

  defp connect_node(n) when n == node() do
    :ok
  end

  defp connect_node(n) do
    if !Node.connect(n) do
      Logger.warn("#{Node.self()} could not connect with #{n}")
    end
  end
end
