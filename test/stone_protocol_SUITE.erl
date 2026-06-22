-module(stone_protocol_SUITE).

-export([all/0, init_per_suite/1, end_per_suite/1, groups/0]).

-export([desc_with_empty/1, desc_with_non_binary/1, desc_with_normal/1]).
-export([attrs_with_empty/1, attrs_with_single/1, attrs_with_multi/1]).
-export([content_with_nil/1, content_with_binary/1, content_with_token_binary/1, content_with_single_node/1, content_with_multi_node/1, content_with_nest_node/1]).
-export([jid_good/1, jid_bad/1]).
-export([frame_good/1, frame_bad/1, frame_short/1]).
-export([semantic_handshake_auth/1, semantic_ack_retry/1, semantic_offline_error/1]).
-export([limit_depth/1, limit_children/1, limit_binary/1]).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

all() ->
    [{group, desc},
    {group, attrs},
    {group, content},
    {group, jid},
    {group, frame},
    {group, semantics},
    {group, limits}].

groups() ->
    [{desc, [sequence], [desc_with_empty, desc_with_non_binary, desc_with_normal]},
    {attrs, [sequence], [attrs_with_empty, attrs_with_single, attrs_with_multi]},
    {content, [sequence], [content_with_nil, content_with_binary, content_with_token_binary, content_with_single_node, content_with_multi_node, content_with_nest_node]},
    {jid, [sequence], [jid_good, jid_bad]},
    {frame, [sequence], [frame_good, frame_bad, frame_short]},
    {semantics, [sequence], [semantic_handshake_auth, semantic_ack_retry, semantic_offline_error]},
    {limits, [sequence], [limit_depth, limit_children, limit_binary]}].

init_per_suite(Config) ->
    application:ensure_all_started([stone_im]),
    Config.

end_per_suite(Config) ->
    application:stop(stone_im),
    Config.

frame_good(_Config) ->
    Nodes = [{<<"message">>,
        [{<<"id">>,   <<"id-1">>},
        {<<"from">>, {jid, <<"123@s1.im">>}},
        {<<"to">>,   {jid, <<"456@g1.im">>}},
        {<<"type">>, <<"chat">>}],
    <<"hello world~">>}],
    assert_roundtrip(Nodes),
    ok.

frame_bad(_Config) ->
    ?assertEqual({error, bad_frame}, stone_frame:decode(<<0:24>>)),
    ?assertEqual({error, unsupported_flag}, stone_frame:decode(<<1:1, 0:23>>)),
    ok.

frame_short(_Config) ->
    ?assertMatch({more, 3}, stone_frame:decode(<<"">>)),
    ok.

jid_good(_Config) ->
    Nodes = [{<<"message">>,
        [{<<"id">>,   <<"id-1">>},
        {<<"from">>, {jid, <<"123@s1.im">>}},
        {<<"to">>,   {jid, <<"456@g1.im">>}},
        {<<"type">>, <<"chat">>}],
    nil}],
    assert_roundtrip(Nodes),
    ok.

jid_bad(_Config) ->
    Node = {<<"message">>,
        [{<<"id">>,   <<"id-1">>},
        {<<"from">>, {jid, <<"a@s1.im">>}},
        {<<"to">>,   {jid, <<"123">>}},
        {<<"type">>, <<"chat">>}],
    nil},
    ?assertException(error, {badmatch, false}, stone_encode:node(Node)),
    ok.

content_with_nil(_Config) ->
    Nodes = [{<<"message">>,
        [{<<"id">>,   <<"id-1">>},
        {<<"from">>, <<"alice">>},
        {<<"to">>,   <<"bob">>},
        {<<"type">>, <<"chat">>}],
    nil}],
    assert_roundtrip(Nodes),
    ok.

content_with_binary(_Config) ->
    Nodes = [{<<"message">>,
        [{<<"id">>,   <<"id-1">>},
        {<<"from">>, <<"alice">>},
        {<<"to">>,   <<"bob">>},
        {<<"type">>, <<"chat">>}],
    <<"hello world~">>}],
    assert_roundtrip(Nodes),
    ok.

content_with_token_binary(_Config) ->
    Nodes = [{<<"message">>,
        [{<<"id">>,   <<"id-1">>},
        {<<"from">>, <<"alice">>},
        {<<"to">>,   <<"bob">>},
        {<<"type">>, <<"chat">>}],
    <<"message">>}],
    assert_roundtrip(Nodes),
    ok.

content_with_single_node(_Config) ->
    Nodes = [{<<"message">>,
        [{<<"id">>,   <<"id-1">>},
        {<<"from">>, <<"alice">>},
        {<<"to">>,   <<"bob">>},
        {<<"type">>, <<"chat">>}],
    [{<<"body">>, [], <<"hello world~">>}]}],
    assert_roundtrip(Nodes),
    ok.

content_with_multi_node(_Config) ->
    Nodes = [{<<"message">>,
        [{<<"id">>,   <<"id-1">>},
        {<<"from">>, <<"alice">>},
        {<<"to">>,   <<"bob">>},
        {<<"type">>, <<"chat">>}],
    [{<<"body">>, [], <<"hello world~">>},
    {<<"header">>, [], <<"v1.0.0">>}]}],
    assert_roundtrip(Nodes),
    ok.

content_with_nest_node(_Config) ->
    Nodes = [{<<"message">>,
        [{<<"id">>,   <<"id-1">>},
        {<<"from">>, <<"alice">>},
        {<<"to">>,   <<"bob">>},
        {<<"type">>, <<"chat">>}],
    [{<<"body">>, [], 
        [{<<"header">>, [], 
            [{<<"version">>, [], <<"v1.0.1">>}]
        }]
    }]}],
    assert_roundtrip(Nodes),
    ok.

attrs_with_empty(_Config) ->
    Nodes = [{<<"message">>, [], <<"hello world~">>}],
    assert_roundtrip(Nodes),
    ok.

attrs_with_single(_Config) ->
    Nodes = [{<<"message">>, [{<<"id">>, <<"id-1">>}], <<"hello world~">>}],
    assert_roundtrip(Nodes),
    ok.

attrs_with_multi(_Config) ->
    Nodes = [{<<"message">>,
        [{<<"id">>,   <<"id-1">>},
        {<<"from">>, <<"alice">>},
        {<<"to">>,   <<"bob">>},
        {<<"type">>, <<"chat">>}],
    [{<<"body">>, [], <<"hello world~">>}]}],
    assert_roundtrip(Nodes),
    ok.

desc_with_empty(_Config) ->
    Nodes = [{<<"">>, [], nil}],
    assert_roundtrip(Nodes),
    ok.

desc_with_non_binary(_Config) ->
    Node = {atom, [], nil},
    ?assertException(error, function_clause, stone_encode:node(Node)),
    ok.

desc_with_normal(_Config) ->
    Nodes = [{<<"desc">>, [], nil}],
    assert_roundtrip(Nodes),
    ok.

semantic_handshake_auth(_Config) ->
    Nodes = [
        stone_message:hello(<<"ios-1">>, <<"1.0.0">>, [<<"ack">>, <<"offline">>]),
        stone_message:hello_ack(<<"sess-1">>, <<"1">>, [<<"ack">>, <<"offline">>]),
        stone_message:auth(<<"sess-1">>, <<"1001">>, <<"ios-1">>, <<"token-1">>),
        stone_message:auth_ok(<<"1001">>, <<"42">>),
        stone_message:auth_fail(<<"auth_failed">>, <<"auth-1">>, <<"invalid token">>)
    ],
    assert_roundtrip(Nodes),
    ok.

semantic_ack_retry(_Config) ->
    Nodes = [
        stone_message:message(<<"msg-1">>, {jid, <<"1001@s.im">>}, {jid, <<"2002@s.im">>}, <<"43">>, <<"hello">>),
        stone_message:ack(<<"msg-1">>, {jid, <<"1001@s.im">>}, <<"43">>),
        stone_message:nack(<<"msg-2">>, {jid, <<"1001@s.im">>}, <<"rate_limited">>, <<"slow down">>),
        stone_message:retry(<<"msg-2">>, {jid, <<"2002@s.im">>}, <<"2">>)
    ],
    assert_roundtrip(Nodes),
    ok.

semantic_offline_error(_Config) ->
    Msg = stone_message:message(<<"msg-3">>, {jid, <<"1001@s.im">>}, {jid, <<"2002@s.im">>}, <<"44">>, <<"offline body">>),
    Nodes = [
        stone_message:offline_pull(<<"43">>, <<"50">>),
        stone_message:offline_batch(<<"false">>, [Msg]),
        stone_message:error(<<"state_violation">>, <<"">>, <<"auth required">>)
    ],
    assert_roundtrip(Nodes),
    ok.

limit_depth(_Config) ->
    Node = {<<"root">>, [], [{<<"child">>, [], <<"body">>}]},
    Bin = stone_encode:node(Node),
    ?assertEqual({error, {limit_exceeded, max_depth}}, stone_decode:node(Bin, [{max_depth, 1}])),
    ok.

limit_children(_Config) ->
    Node = {<<"root">>, [], [
        {<<"child1">>, [], nil},
        {<<"child2">>, [], nil}
    ]},
    Bin = stone_encode:node(Node),
    ?assertEqual({error, {limit_exceeded, max_children}}, stone_decode:node(Bin, [{max_children, 1}])),
    ok.

limit_binary(_Config) ->
    Node = {<<"root">>, [], <<"1234">>},
    Bin = stone_encode:node(Node),
    ?assertEqual({error, {limit_exceeded, max_binary_size}}, stone_decode:node(Bin, [{max_binary_size, 3}])),
    ok.

assert_roundtrip([]) ->
    ok;
assert_roundtrip([Node | Rest]) ->
    Bin = stone_encode:node(Node),
    {ok, [Node1], <<>>} = stone_decode:node(Bin),
    ?assertEqual(Node, Node1),
    assert_roundtrip(Rest).
