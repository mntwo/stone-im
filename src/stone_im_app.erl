%%%-------------------------------------------------------------------
%% @markdown stone_im public API
%% @end
%%%-------------------------------------------------------------------

-module(stone_im_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    stone_im_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
