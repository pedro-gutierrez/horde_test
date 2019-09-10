HOSTNAME=$(shell hostname)

node1:
	MIX_ENV=dev iex --name node1@127.0.0.1 --cookie asdf -S mix

node2:
	MIX_ENV=dev iex --name node2@127.0.0.1 --cookie asdf -S mix

node3:
	MIX_ENV=dev iex --name node3@127.0.0.1 --cookie asdf -S mix

prod:
	MIX_ENV=prod iex --erl '-kernel inet_dist_listen_min 9100' --erl '-kernel inet_dist_listen_min 9155' --name node@${HOSTNAME}.public --cookie asdf -S mix