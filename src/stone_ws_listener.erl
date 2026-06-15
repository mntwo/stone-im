-module(stone_ws_listener).

-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(LISTENER_NAME, stone_ws).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    Port = stone_config:get(ws_port),
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/ws", stone_ws_handler, []}
        ]}
    ]),
    {ok, _} = cowboy:start_clear(?LISTENER_NAME,
        [{port, Port}],
        #{env => #{dispatch => Dispatch}}
    ),
    stone_log:info("Websocket listener started.", #{listener => ?LISTENER_NAME, port => Port}),
    {ok, #{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    stone_log:info("Websocket listener terminated.", #{reason => _Reason}),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.