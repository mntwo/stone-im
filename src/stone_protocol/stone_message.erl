-module(stone_message).

-compile({no_auto_import, [error/3]}).

-export([
    hello/3, hello_ack/3,
    auth/4, auth_ok/2, auth_fail/3,
    message/4, message/5,
    ack/3, nack/4, retry/3,
    offline_pull/2, offline_batch/2,
    receipt/3, presence/1, ping/0, pong/0,
    error/3
]).

-define(PROTOCOL_VERSION, <<"1">>).

%% Client opens protocol negotiation with its supported version and capabilities.
hello(DeviceId, ClientVersion, Capabilities) ->
    {<<"hello">>,
        [{<<"min_version">>, ?PROTOCOL_VERSION},
        {<<"max_version">>, ?PROTOCOL_VERSION},
        {<<"device">>, DeviceId},
        {<<"client">>, ClientVersion}],
    capability_nodes(Capabilities)}.

%% Server replies with the selected version, session id and enabled capabilities.
hello_ack(SessionId, SelectedVersion, Capabilities) ->
    {<<"hello_ack">>,
        [{<<"version">>, SelectedVersion},
        {<<"session">>, SessionId}],
    capability_nodes(Capabilities)}.

%% Authentication is only valid after hello/hello_ack completes.
auth(SessionId, UserId, DeviceId, Token) ->
    {<<"auth">>,
        [{<<"session">>, SessionId},
        {<<"user">>, UserId},
        {<<"device">>, DeviceId}],
    [{<<"token">>, [], Token}]}.

auth_ok(UserId, LastSeq) ->
    {<<"auth_ok">>,
        [{<<"user">>, UserId},
        {<<"last_seq">>, LastSeq}],
    nil}.

auth_fail(Code, Id, Detail) ->
    {<<"auth_fail">>,
        [{<<"code">>, Code},
        {<<"id">>, Id}],
    [{<<"detail">>, [], Detail}]}.

% Text message Node
message(ID, From, To, Body) ->
    message(ID, From, To, undefined, Body).

message(ID, From, To, Seq, Body) ->
    Attrs0 = [{<<"id">>,   ID},
        {<<"from">>, From},
        {<<"to">>,   To},
        {<<"type">>, <<"chat">>}],
    Attrs = maybe_attr(<<"seq">>, Seq, Attrs0),
    {<<"message">>,
        Attrs,
    [{<<"body">>, [], Body}]}.

%% Ack means the receiver has durably accepted a frame or message.
ack(ID, To, Seq) ->
    {<<"ack">>,
        [{<<"id">>, ID},
        {<<"to">>, To},
        {<<"seq">>, Seq}],
    nil}.

%% Nack is retryable when the error code is transient.
nack(ID, To, Code, Detail) ->
    {<<"nack">>,
        [{<<"id">>, ID},
        {<<"to">>, To},
        {<<"code">>, Code}],
    [{<<"detail">>, [], Detail}]}.

retry(ID, To, Attempt) ->
    {<<"retry">>,
        [{<<"id">>, ID},
        {<<"to">>, To},
        {<<"attempt">>, Attempt}],
    nil}.

offline_pull(AfterSeq, Limit) ->
    {<<"offline_pull">>,
        [{<<"after_seq">>, AfterSeq},
        {<<"limit">>, Limit}],
    nil}.

offline_batch(More, Messages) ->
    {<<"offline_batch">>, [{<<"more">>, More}], Messages}.

%% Read receipt Node
receipt(ID, From, To) ->
    {<<"receipt">>,
        [{<<"id">>,   ID},
        {<<"from">>, From},
        {<<"to">>,   To},
        {<<"type">>, <<"read">>}],
    nil}.

%% User presence Node
%%   Type = <<"available">> | <<"unavailable">> | <<"composing">> | <<"paused">>
presence(Type) ->
    {<<"presence">>, [{<<"type">>, Type}], nil}.

ping() ->
    {<<"ping">>, [], nil}.
 
pong() ->
    {<<"pong">>, [], nil}.

error(Code, Id, Detail) ->
    {<<"error">>,
        [{<<"code">>, Code},
        {<<"id">>, Id}],
    [{<<"detail">>, [], Detail}]}.

capability_nodes(Capabilities) ->
    [{<<"cap">>, [{<<"name">>, Capability}], nil} || Capability <- Capabilities].

maybe_attr(_Key, undefined, Attrs) ->
    Attrs;
maybe_attr(Key, Value, Attrs) ->
    Attrs ++ [{Key, Value}].
