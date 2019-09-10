import Config

config :horde_test,
  nodes: [
    :"node@a0.public",
    :"node@a1.public",
    :"node@a2.public"
  ]

config :logger,
  level: :warn,
  truncate: 4096
