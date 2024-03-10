-module(m8ball_sup).
-behaviour(supervisor).
-export([start_link/0, init/1, sup_poop/0]).

sup_poop() ->
    % application:start("crypto"),
    io:format("poop~n").

start_link() ->
    io:format("starting link...~n"),
    supervisor:start_link({global, ?MODULE}, ?MODULE, []).

init([]) ->
    io:format("initing...~n"),
    {ok,
        {{one_for_one, 1, 10}, [
            {m8ball, {m8ball_server, start_link, []}, permanent, 5000, worker, [m8ball_server]}
        ]}}.
