-module(stone_ws_SUITE).

-export([all/0, init_per_suite/1, end_per_suite/1, connect_and_echo/1]).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

all() ->
    [connect_and_echo].

init_per_suite(Config) ->
    application:ensure_all_started([stone_im, gun]),
    Config.

end_per_suite(Config) ->
    application:stop(stone_im),
    application:stop(gun),
    Config.

connect_and_echo(_Config) ->
    {ok, ConnPid} = gun:open("localhost", stone_config:get(ws_port)),
    {ok, http} = gun:await_up(ConnPid),
    StreamRef = gun:ws_upgrade(ConnPid, "/ws"),
    receive
        {gun_upgrade, ConnPid, StreamRef, [<<"websocket">>], _Headers} ->
            ok
    after 1000 ->
        exit(websocket_upgrade_timeout)
    end,

    Msg = <<"Hello, Websocket!">>,
    gun:ws_send(ConnPid, StreamRef, {binary, Msg}),

    receive
        {gun_ws, ConnPid, StreamRef, {binary, Reply}} ->
            ?assertEqual(<<"echo: ", Msg/binary>>, Reply)
    after 1000 ->
        exit(websocket_reply_timeout)
    end,

    gun:close(ConnPid),
    ok.