HOSTNAME=$(shell hostname)

start:
	MIX_ENV=dev iex --erl '-kernel inet_dist_listen_min 9100' --erl '-kernel inet_dist_listen_min 9155' --name node@${HOSTNAME}.public --cookie asdf -S mix