-module(m8ball).
-behaviour(application).
-export([start/2, stop/1]).
-export([ask/1]).

%%%%%%%%%%%%%%%%%
%%% CALLBACKS %%%
%%%%%%%%%%%%%%%%%

%% start({failover, Node}, Args) is only called
%% when a start_phase key is defined.
start(normal, []) ->
    %% print out the io module's details
    io:format("ABOUT TO nnormal~n"),
    io:format("poopin:~n"),
    % sys:trace(sup, true),
    m8ball_sup:sup_poop(),
    % io:format("the io module's deatils: ~p~n", [m8ball_sup:module_info()]),
    io:format("Starting m8ball...~n"),
    m8ball_sup:start_link();
    % io:format("DONe m8ball...~n");
start({takeover, _OtherNode}, []) ->
    io:format("takover starting~n"),
    % io:format("sssss poopin:~n"),
    m8ball_sup:sup_poop(),
    % io:format("the io module's deatils: ~p~n", [m8ball_sup:module_info()]),
    % io:format("Starting m8ball...~n"),
    m8ball_sup:start_link(),
    io:format("done takoever~n").

stop(_State) ->
    ok.

%%%%%%%%%%%%%%%%%
%%% INTERFACE %%%
%%%%%%%%%%%%%%%%%
ask(Question) ->
    m8ball_server:ask(Question).
