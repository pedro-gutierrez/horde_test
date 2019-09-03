# HordeTest

A simple Elixir demo app that combines Horde and libcluster. For testing purposes.


## Usage 

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
HordeTest.add_server()
```

Then you get its location and pid:

```
iex(node1@127.0.0.1)4> HordeTest.server_info()
{:"node3@127.0.0.1", #PID<17345.3591.0>}
```

Finally, you can start trying to add more servers, disconnecting, killing nodes or reconnecting nodes and see how Horde behaves.

