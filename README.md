# HordeTest

A simple Elixir demo app that combines Horde and libcluster. For testing purposes.


## Simple Usage 

Git clone this repo, run `mix deps.get` and then start three nodes:

```
iex --name node1@127.0.0.1 --cookie asdf -S mix
iex --name node2@127.0.0.1 --cookie asdf -S mix
iex --name node3@127.0.0.1 --cookie asdf -S mix
```

Libcluster is configured to listen to EPMD on those three names, check it is working:

```
iex(node1@127.0.0.1)4> Node.list()
[:"node3@127.0.0.1", :"node2@127.0.0.1"]
```

Once your cluster is ready, then you can start a new server:

```
HordeTest.add_singleton()
```

Then you can get its location and pid:

```
iex(node1@127.0.0.1)4> HordeTest.singleton_info()
{:"node3@127.0.0.1", #PID<17345.3591.0>}
```

Finally, you can start trying to add more servers, disconnecting, killing or reconnecting nodes and see how Horde behaves.

## Adding many servers

It is possible to add multiple instances of the same GenServer: 

```
iex(node1@127.0.0.1)4> HordeTest.add_server("1")
{:ok, #PID<0.4191.0>}

iex(node1@127.0.0.1)5>HordeTest.add_server("2")
{:ok, #PID<0.4241.0>}
```

Or we can add many instances in one go. The following call will create 1000 GenServers:

```
iex(node1@127.0.0.1)6> HordeTest.add_many(1000)
```

## Inspector

A simple inspector module is provided in order to track how server process are balanced across the cluster. The following call returns the node where the Inspector lives:

```
iex(node1@127.0.0.1)13> HordeTest.inspector_node()
:"node2@127.0.0.1"
```

The following call returns how processes are distributed accross nodes:

```
iex(node1@127.0.0.1)7>  HordeTest.distribution()
%{
  "node1@127.0.0.1": 29,
  "node2@127.0.0.1": 32,
  "node3@127.0.0.1": 39
}
```

If we kill node3, then we can confirm the above total count of 100 is redistributed across the two remaining nodes:

```
iex(node1@127.0.0.1)10> HordeTest.distribution()
%{
  "node1@127.0.0.1": 43,
  "node2@127.0.0.1": 57
}
```














