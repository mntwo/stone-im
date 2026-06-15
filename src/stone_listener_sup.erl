-module(stone_listener_sup).

-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 3,
        period => 5
    },
    ChildSpecs = [
        #{
            id => stone_ws_listener,
            start => {stone_ws_listener, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [stone_ws_listener]
        }
    ],
    {ok, {SupFlags, ChildSpecs}}.
