-module(stone_session).

-behaviour(gen_server).

-export([start_link/4]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
    tenant_id :: binary(),
    user_id :: binary(),
    device_id :: binary(),
    conn_id :: pid()
}).

-define(SCOPE, tenant).

start_link(TenantId, UserId, DeviceId, ConnPid) ->
    gen_server:start_link(?MODULE, [TenantId, UserId, DeviceId, ConnPid], []).

init([TenantId, UserId, DeviceId, ConnPid]) ->
    stone_log:info("Starting session process.", #{tenant_id => TenantId, user_id => UserId, device_id => DeviceId, conn_id => ConnPid}),
    pg:join({{?SCOPE, TenantId}, UserId}, self()),
    {ok, #state{
        tenant_id = TenantId,
        user_id = UserId,
        device_id = DeviceId,
        conn_id = ConnPid
    }}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.
handle_cast(_Msg, State) ->
    {noreply, State}.
handle_info(_Info, State) ->
    {noreply, State}.
terminate(_Reason, #state{tenant_id = TenantId, user_id = UserId}=State) ->
    stone_log:info("Terminating session process.", #{reason => _Reason, state => State}),
    pg:leave({{?SCOPE, TenantId}, UserId}, self()),
    ok.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.