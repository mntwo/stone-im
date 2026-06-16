%%%-------------------------------------------------------------------
%% @markdown stone_im top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(stone_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 3,
        period => 5
    },
    ChildSpecs = [
        #{
            id => stone_listener_sup,
            start => {stone_listener_sup, start_link, []},
            restart => permanent,
            shutdown => infinity,
            type => supervisor,
            modules => [stone_listener_sup]
        }
    ],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions
