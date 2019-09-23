defmodule HordeTestTest do
  use ExUnit.Case
  doctest HordeTest
  @await_millis 100
  @await_retries 50

  @cluster HordeTest.Cluster

  test "should support a node going down" do
    [n1, n2, n3] = nodes = setup_cluster(3)

    count = 100

    count |> add_servers(n1)

    nodes |> Enum.each(&wait_for_servers(count, &1))

    assert 0 < count |> servers_in_node(n3, n1)

    p = [n3]
    LocalCluster.stop_nodes(p)

    rem_nodes = nodes -- p
    rem_nodes |> Enum.each(&wait_for_quorum(&1))
    rem_nodes |> Enum.each(&wait_for_servers(count, &1))

    assert 0 == servers_in_node(count, n3, n1) |> Enum.count()
    assert 0 == servers_in_node(count, n3, n2) |> Enum.count()

    assert 100 ==
             Enum.count(servers_in_node(count, n1, n1)) +
               Enum.count(servers_in_node(count, n2, n1))

    assert 100 ==
             Enum.count(servers_in_node(count, n1, n2)) +
               Enum.count(servers_in_node(count, n2, n2))
  end

  test "should support partition" do
    [n1, n2, n3] = nodes = setup_cluster(3)

    count = 100

    count |> add_servers(n1)

    nodes |> Enum.each(&wait_for_servers(count, &1))

    assert 0 < count |> servers_in_node(n3, n1)

    p = [n3]
    Schism.partition(p)

    rem_nodes = nodes -- p
    rem_nodes |> Enum.each(&wait_for_quorum(&1))
    rem_nodes |> Enum.each(&wait_for_servers(count, &1))

    assert 0 == servers_in_node(count, n3, n1) |> Enum.count()
    assert 0 == servers_in_node(count, n3, n2) |> Enum.count()

    assert 100 ==
             Enum.count(servers_in_node(count, n1, n1)) +
               Enum.count(servers_in_node(count, n2, n1))

    assert 100 ==
             Enum.count(servers_in_node(count, n1, n2)) +
               Enum.count(servers_in_node(count, n2, n2))
  end

  test "name conflict" do
    [n1, n2, n3] = nodes = setup_cluster(3, Horde.UniformDistribution)

    p = [n3]
    Schism.partition(p)

    nodes |> Enum.each(&wait_for_quorum(&1))

    count = 1

    count |> add_servers(n1)
    count |> add_servers(n3)

    nodes |> Enum.each(&wait_for_servers(count, &1))

    {:ok, n, pid1} = info(1, n1)
    {:ok, ^n, ^pid1} = info(1, n2)
    {:ok, ^n3, pid2} = info(1, n3)

    assert Enum.member?([n1, n2], n)
    assert pid2 != pid1

    Process.monitor(pid1)
    Process.monitor(pid2)

    Schism.heal(p)

    nodes |> Enum.each(&wait_for_quorum(&1))

    assert_receive({:DOWN, _, :process, dead, :normal}, 2_000)
    assert Enum.member?([pid1, pid2], dead)

    {:ok, n, pid} = info(1, n1)
    {:ok, ^n, ^pid} = info(1, n2)
    {:ok, ^n, ^pid} = info(1, n3)
  end

  defp setup_cluster(size, dist \\ Horde.UniformQuorumDistribution) do
    Application.stop(:horde_test)
    Application.ensure_all_started(:horde_test)

    nodes = LocalCluster.start_nodes("horde", size)

    cluster = [
      nodes: nodes,
      dist: dist
    ]

    nodes |> Enum.each(&wait_for_cluster_available(&1))
    nodes |> Enum.each(&stop_cluster(&1))
    nodes |> Enum.each(&start_cluster(cluster, &1))
    nodes |> Enum.each(&wait_for_cluster_running(&1))
    nodes |> Enum.each(&wait_for_quorum(&1))
    nodes
  end

  defp await(_, 0, message, _) when is_binary(message) do
    flunk(message)
  end

  defp await(_, 0, fun, _) do
    message = fun.()
    flunk(message)
  end

  defp await(millis, retries, message, condition) do
    case condition.() do
      true ->
        :ok

      false ->
        Process.sleep(millis)
        await(millis, retries - 1, message, condition)
    end
  end

  defp await(message, condition) do
    await(@await_millis, @await_retries, message, condition)
  end

  defp wait_for_cluster_available(n) do
    await(
      fn ->
        "Cluster not available in #{n}"
      end,
      fn ->
        cluster_available?(n)
      end
    )
  end

  defp wait_for_cluster_running(n) do
    await(
      fn ->
        "Cluster not running in #{n}"
      end,
      fn ->
        cluster_running?(n)
      end
    )
  end

  defp wait_for_cluster_stopped(n) do
    await(
      fn ->
        "Cluster still running in #{n}"
      end,
      fn ->
        !cluster_running?(n)
      end
    )
  end

  defp cluster_available?(n) do
    n |> call(@cluster, :available?, [])
  end

  defp cluster_running?(n) do
    n |> call(@cluster, :running?, [])
  end

  defp wait_for_quorum(n) do
    n |> call(@cluster, :quorum!, [])
  end

  defp stop_cluster(n) do
    n |> call(@cluster, :stop, [])
  end

  defp start_cluster(spec, n) do
    n |> call(@cluster, :start, [spec])
  end

  defp add_servers(count, n) do
    n |> call(HordeTest, :add_many, [count])
  end

  defp info(name, node) do
    case node |> call(HordeTest, :info, [name]) do
      :not_found ->
        IO.inspect(
          not_found: name,
          node: node
        )

        :not_found

      info ->
        info
    end
  end

  defp wait_for_servers(count, n) do
    await(
      fn ->
        "All #{count} servers not ready in #{n}"
      end,
      fn ->
        servers_ready?(count, n)
      end
    )
  end

  defp servers_ready?(count, n) do
    1..count
    |> Enum.reduce_while(true, fn num, _ ->
      case info(num, n) do
        {:error, :not_found} ->
          {:halt, false}

        {:ok, _, _} ->
          {:cont, true}
      end
    end)
  end

  defp servers_in_node(count, node, n) do
    1..count
    |> Enum.filter(&in_node?(&1, node, n))
  end

  defp in_node?(num, node, n) do
    case info(num, n) do
      {:ok, ^node, _} ->
        true

      _ ->
        false
    end
  end

  defp call(node, m, f, a) do
    case Node.self() do
      ^node ->
        apply(m, f, a)

      _ ->
        case :rpc.call(node, m, f, a) do
          {:badrpc, reason} ->
            flunk(
              "Error calling #{m}, #{f}, #{a |> inspect()} on node #{node}: #{reason |> inspect})"
            )

          other ->
            other
        end
    end
  end
end
