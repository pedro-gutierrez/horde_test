HOSTNAME=$(shell hostname)

start:
	MIX_ENV=prod elixir --erl '-kernel inet_dist_listen_min 9100' --erl '-kernel inet_dist_listen_min 9155' --name node@${HOSTNAME} --cookie asdf -S mix run