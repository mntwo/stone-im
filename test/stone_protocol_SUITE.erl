-module(stone_protocol_SUITE).

-export([all/0, init_per_suite/1, end_per_suite/1, groups/0]).

-export([desc_with_empty/1, desc_with_non_binary/1, desc_with_normal/1]).
-export([attrs_with_empty/1, attrs_with_single/1, attrs_with_multi/1]).
-export([content_with_nil/1, content_with_binary/1, content_with_single_node/1, content_with_multi_node/1, content_with_nest_node/1]).
-export([jid_good/1, jid_bad/1]).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

all() ->
    [{group, desc},
    {group, attrs},
    {group, content},
    {group, jid}].

groups() ->
    [{desc, [sequence], [desc_with_empty, desc_with_non_binary, desc_with_normal]},
    {attrs, [sequence], [attrs_with_empty, attrs_with_single, attrs_with_multi]},
    {content, [sequence], [content_with_nil, content_with_binary, content_with_single_node, content_with_multi_node, content_with_nest_node]},
    {jid, [], [jid_good, jid_bad]}].

init_per_suite(Config) ->
    application:ensure_all_started([stone_im]),
    Config.

end_per_suite(Config) ->
    application:stop(stone_im),
    Config.

jid_good(_Config) ->
    Node = {~"message",
        [{~"id",   ~"id-1"},
        {~"from", {jid, ~"123@s1.im"}},
        {~"to",   {jid, ~"456@g1.im"}},
        {~"type", ~"chat"}],
    nil},
    Bin = stone_encode:node(Node),
    {ok, [Node1], _Rest} = stone_decode:node(Bin),
    ?assertEqual(Node, Node1),
    ok.

jid_bad(_Config) ->
    Node = {~"message",
        [{~"id",   ~"id-1"},
        {~"from", {jid, ~"a@s1.im"}},
        {~"to",   {jid, ~"123"}},
        {~"type", ~"chat"}],
    nil},
    Bin = stone_encode:node(Node),
    {ok, [Node1], _Rest} = stone_decode:node(Bin),
    ?assertNotEqual(Node, Node1),
    ok.

content_with_nil(_Config) ->
    Node = {~"message",
        [{~"id",   ~"id-1"},
        {~"from", ~"alice"},
        {~"to",   ~"bob"},
        {~"type", ~"chat"}],
    nil},
    Bin = stone_encode:node(Node),
    {ok, [Node1], _Rest} = stone_decode:node(Bin),
    ?assertEqual(Node, Node1),
    ok.

content_with_binary(_Config) ->
    Node = {~"message",
        [{~"id",   ~"id-1"},
        {~"from", ~"alice"},
        {~"to",   ~"bob"},
        {~"type", ~"chat"}],
    ~"hello world~"},
    Bin = stone_encode:node(Node),
    {ok, [Node1], _Rest} = stone_decode:node(Bin),
    ?assertEqual(Node, Node1),
    ok.

content_with_single_node(_Config) ->
    Node = {~"message",
        [{~"id",   ~"id-1"},
        {~"from", ~"alice"},
        {~"to",   ~"bob"},
        {~"type", ~"chat"}],
    [{~"body", [], ~"hello world~"}]},
    Bin = stone_encode:node(Node),
    {ok, [Node1], _Rest} = stone_decode:node(Bin),
    ?assertEqual(Node, Node1),
    ok.

content_with_multi_node(_Config) ->
    Node = {~"message",
        [{~"id",   ~"id-1"},
        {~"from", ~"alice"},
        {~"to",   ~"bob"},
        {~"type", ~"chat"}],
    [{~"body", [], ~"hello world~"},
    {~"header", [], ~"v1.0.0"}]},
    Bin = stone_encode:node(Node),
    {ok, [Node1], _Rest} = stone_decode:node(Bin),
    ?assertEqual(Node, Node1),
    ok.

content_with_nest_node(_Config) ->
    Node = {~"message",
        [{~"id",   ~"id-1"},
        {~"from", ~"alice"},
        {~"to",   ~"bob"},
        {~"type", ~"chat"}],
    [{~"body", [], 
        [{~"header", [], 
            [{~"version", [], ~"v1.0.1"}]
        }]
    }]},
    Bin = stone_encode:node(Node),
    {ok, [Node1], _Rest} = stone_decode:node(Bin),
    ?assertEqual(Node, Node1),
    ok.

attrs_with_empty(_Config) ->
    Node = {~"message", [], ~"hello world~"},
    Bin = stone_encode:node(Node),
    {ok, [Node1], _Rest} = stone_decode:node(Bin),
    ?assertEqual(Node, Node1),
    ok.

attrs_with_single(_Config) ->
    Node = {~"message", [{~"id", ~"id-1"}], ~"hello world~"},
    Bin = stone_encode:node(Node),
    {ok, [Node1], _Rest} = stone_decode:node(Bin),
    ?assertEqual(Node, Node1),
    ok.

attrs_with_multi(_Config) ->
    Node = {~"message",
        [{~"id",   ~"id-1"},
        {~"from", ~"alice"},
        {~"to",   ~"bob"},
        {~"type", ~"chat"}],
    [{~"body", [], ~"hello world~"}]},
    Bin = stone_encode:node(Node),
    {ok, [Node1], _Rest} = stone_decode:node(Bin),
    ?assertEqual(Node, Node1),
    ok.

desc_with_empty(_Config) ->
    Node = {~"", [], nil},
    Bin = stone_encode:node(Node),
    {ok, [Node1], _Rest} = stone_decode:node(Bin),
    ?assertEqual(Node, Node1),
    ok.

desc_with_non_binary(_Config) ->
    Node = {atom, [], nil},
    ?assertException(error, function_clause, stone_encode:node(Node)),
    ok.

desc_with_normal(_Config) ->
    Node = {~"desc", [], nil},
    Bin = stone_encode:node(Node),
    {ok, [Node1], _Rest} = stone_decode:node(Bin),
    ?assertEqual(Node, Node1),
    ok.