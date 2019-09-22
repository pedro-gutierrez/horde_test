import Config

config :horde_test,
  nodes: [
    :"node1@127.0.0.1",
    :"node2@127.0.0.1"
  ]

config :logger,
  level: :debug,
  truncate: 4096
