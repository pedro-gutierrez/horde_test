# HordeTest

A simple Elixir demo app that combines Horde and libcluster. For testing purposes.


## Simple Usage 

Git clone this repo, run `mix deps.get` and then start three nodes:

```
make node1
make node2
make node3
```

Libcluster is configured to listen to EPMD on those three names, check it is working:

```
iex(node1@127.0.0.1)4> Node.list()
[:"node3@127.0.0.1", :"node2@127.0.0.1"]
```
## Adding servers

It is possible to add multiple instances of the same GenServer: 

```
iex(node1@127.0.0.1)4> HordeTest.add_server("1")
{:ok, #PID<0.4191.0>}

iex(node1@127.0.0.1)5>HordeTest.add_server("2")
{:ok, #PID<0.4241.0>}
```

Or we can add many instances in one go. The following call will create 1000 GenServers:

```
iex(node1@127.0.0.1)6> HordeTest.add_servers(10)
```

## Inspector

A simple inspector module is provided in order to track how server process are balanced across the cluster. The following call returns the node where the Inspector lives:

```
iex(node1@127.0.0.1)13> HordeTest.inspect()

%{
  inspector: {:"node2@127.0.0.1", #PID<0.231.0>},
  servers_by_node: %{"node2@127.0.0.1": 10},
  supervisor_children: %{
    active: 11,
    specs: 11,
    supervisors: 0,
    workers: 11
  }
}

```
