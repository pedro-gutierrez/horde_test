
unexport TMUX

#TODO = force only perform docker build / tag if a git hash is avalable and everything is checked in

tmux_panes:
	tmux \
		split-window  "iex --name node1@127.0.0.1 --cookie asdf -S mix; read" \; \
		split-window  "iex --name node2@127.0.0.1 --cookie asdf -S mix; read" \; \
		split-window  "iex --name node3@127.0.0.1 --cookie asdf -S mix; read" \; \
		select-layout even-vertical

docker_build:
	GIT_VER=$(shell git status 
	ifeq ($(shell uname),Darwin)
		docker build . 

	endif
	endif
	echo $CFLAGS $LDFLAGS
	#echo $( shell if $((git status | egrep -v "^")) ; do echo "bad/hash" ; else exit 1 ; fi ) 

docker_run:
	docker run 


