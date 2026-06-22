-module(stone_session).

-behaviour(gen_server).

-export([start_link/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
    user_id :: binary(),
    conn_pid :: pid()
}).

-define(SCOPE, user).

start_link(UserId, ConnPid) ->
    gen_server:start_link(?MODULE, [UserId, ConnPid], []).

init([UserId, ConnPid]) ->
    stone_log:info("Starting session process.", #{user_id => UserId, conn_pid => ConnPid}),
    pg:join({?SCOPE, UserId}, self()),
    {ok, #state{
        user_id = UserId,
        conn_pid = ConnPid
    }}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.
handle_cast(_Msg, State) ->
    {noreply, State}.
handle_info(_Info, State) ->
    {noreply, State}.
terminate(_Reason, #state{user_id = UserId}=State) ->
    stone_log:info("Terminating session process.", #{reason => _Reason, state => State}),
    pg:leave({?SCOPE, UserId}, self()),
    ok.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.