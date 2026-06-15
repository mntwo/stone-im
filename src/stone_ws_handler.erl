-module(stone_ws_handler).

-export([init/2]).
-export([websocket_init/1, websocket_handle/2, websocket_info/2, terminate/3]).

init(Req, State) ->
    {cowboy_websocket, Req, State}.

websocket_init(State) ->
    stone_log:info("Websocket connection established.", #{state => State}),
    {ok, State}.

websocket_handle({binary, Msg}, State) ->
    stone_log:info("Received message from client.", #{message => Msg}),
    Reply = <<"echo: ", Msg/binary>>,
    {reply, {binary, Reply}, State};

websocket_handle(_Frame, State) ->
    {ok, State}.

websocket_info(_Info, State) ->
    stone_log:info("Received info message.", #{info => _Info}),
    {ok, State}.

terminate(_Reason, _Req, State) ->
    stone_log:info("Websocket connection terminated.", #{state => State}),
    ok.