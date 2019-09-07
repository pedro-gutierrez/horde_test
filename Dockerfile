FROM elixir:alpine

RUN mix local.hex --force
RUN mix local.rebar -force

COPY mix.exs . 
COPY mix.lock . 
RUN mix deps.get && mix deps.compile 
COPY lib .
COPY test . 



