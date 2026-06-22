%% Deserialize binary format back into Node tuples.
%%
%% Returns: {ok, [Node], RestBinary} | {error, Reason}

-module(stone_decode).

-export([node/1, node/2, decode_string/1]).

-include("stone_protocol.hrl").

-define(DEFAULT_MAX_DEPTH, 32).
-define(DEFAULT_MAX_ATTRS, 64).
-define(DEFAULT_MAX_CHILDREN, 256).
-define(DEFAULT_MAX_BINARY_SIZE, 1048576).

node(Bin) ->
    node(Bin, []).

node(Bin, Opts) when is_binary(Bin), is_list(Opts) ->
    Limits = limits(Opts),
    node_acc(Bin, [], Limits, 0).

decode_string(Bin) ->
    decode_string(Bin, limits([])).

node_acc(<<>>, Acc, _Limits, _Depth) ->
    {ok, lists:reverse(Acc), <<>>};
node_acc(Bin, Acc, Limits, Depth) ->
    case decode_node(Bin, Limits, Depth) of
        {ok, nil, Rest} ->
            {ok, lists:reverse(Acc), Rest};
        {ok, Node, Rest} ->
            node_acc(Rest, [Node | Acc], Limits, Depth);
        {error, Reason} ->
            {error, Reason}
    end.

decode_node(_Bin, #{max_depth := MaxDepth}, Depth) when Depth >= MaxDepth ->
    {error, {limit_exceeded, max_depth}};
decode_node(Bin, Limits, Depth) ->
    case decode_list_size(Bin) of
        {ok, 0, Rest} ->
            {ok, nil, Rest};
        {ok, Size, Rest1} ->
            decode_node_body(Size, Rest1, Limits, Depth);
        {error, Reason} ->
            {error, Reason}
    end.

decode_node_body(Size, Rest1, Limits, Depth) ->
    AttrCount = (Size - 1) div 2,
    case ensure_limit(AttrCount, max_attrs, Limits) of
        ok ->
            decode_node_body_checked(Size, AttrCount, Rest1, Limits, Depth);
        {error, Reason} ->
            {error, Reason}
    end.

decode_node_body_checked(Size, AttrCount, Rest1, Limits, Depth) ->
    case decode_string(Rest1, Limits) of
        {ok, Desc, Rest2} ->
            case decode_attrs(AttrCount, Rest2, Limits) of
                {ok, Attrs, Rest3} ->
                    decode_node_content(Size, Desc, Attrs, Rest3, Limits, Depth);
                {error, Reason} ->
                    {error, Reason}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

decode_node_content(Size, Desc, Attrs, Rest3, Limits, Depth) ->
    HasContent = (Size rem 2) =:= 0,
    case HasContent of
        true ->
            case decode_content(Rest3, Limits, Depth + 1) of
                {ok, Content, Rest4} ->
                    {ok, {Desc, Attrs, Content}, Rest4};
                {error, Reason} ->
                    {error, Reason}
            end;
        false ->
            {ok, {Desc, Attrs, nil}, Rest3}
    end.

decode_content(<<?LIST_EMPTY, Rest/binary>>, _Limits, _Depth) ->
    {ok, nil, Rest};
decode_content(<<?BINARY_8, _/binary>> = Bin, Limits, _Depth) ->
    decode_binary(Bin, Limits);
decode_content(<<?BINARY_20, _/binary>> = Bin, Limits, _Depth) ->
    decode_binary(Bin, Limits);
decode_content(<<?BINARY_32, _/binary>> = Bin, Limits, _Depth) ->
    decode_binary(Bin, Limits);
decode_content(Bin, Limits, Depth) ->
    case decode_list_size(Bin) of
        {ok, N, Rest1} ->
            case ensure_limit(N, max_children, Limits) of
                ok -> decode_nodes_n(N, Rest1, Limits, Depth);
                {error, Reason} -> {error, Reason}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

decode_nodes_n(0, Bin, _Limits, _Depth) ->
    {ok, [], Bin};
decode_nodes_n(N, Bin, Limits, Depth) ->
    case decode_node(Bin, Limits, Depth) of
        {ok, Child, Rest1} ->
            case decode_nodes_n(N - 1, Rest1, Limits, Depth) of
                {ok, Children, Rest2} -> {ok, [Child | Children], Rest2};
                {error, Reason} -> {error, Reason}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

decode_attrs(0, Bin, _Limits) ->
    {ok, [], Bin};
decode_attrs(N, Bin, Limits) ->
    case decode_string(Bin, Limits) of
        {ok, Key, Rest1} ->
            case decode_attr_value(Rest1, Limits) of
                {ok, Val, Rest2} ->
                    case decode_attrs(N - 1, Rest2, Limits) of
                        {ok, More, Rest3} -> {ok, [{Key, Val} | More], Rest3};
                        {error, Reason} -> {error, Reason}
                    end;
                {error, Reason} ->
                    {error, Reason}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

decode_attr_value(<<?JID_PAIR, _/binary>> = Bin, Limits) ->
    decode_jid(Bin, Limits);
decode_attr_value(Bin, Limits)->
    decode_string(Bin, Limits).

decode_list_size(<<?LIST_EMPTY, Rest/binary>>) ->
    {ok, 0, Rest};
decode_list_size(<<?LIST_8, N:8, Rest/binary>>) ->
    {ok, N, Rest};
decode_list_size(<<?LIST_16, Hi:8, Lo:8, Rest/binary>>) ->
    N = (Hi bsl 8) bor Lo,
    {ok, N, Rest};
decode_list_size(<<>>) ->
    {error, truncated_list};
decode_list_size(<<Tag, _/binary>>) ->
    {error, {unexpected_list_tag, Tag}}.

decode_string(<<Token, Rest/binary>>, Limits) ->
    case stone_token:to_string(Token) of
        undefined -> decode_binary(<<Token, Rest/binary>>, Limits);
        Str -> {ok, Str, Rest}
    end;
decode_string(<<>>, _Limits) ->
    {error, truncated_string}.

decode_binary(<<?BINARY_8, Len:8, Rest0/binary>>, Limits) ->
    decode_binary_data(Len, Rest0, Limits);
decode_binary(<<?BINARY_20, L2, L1, L0, Rest0/binary>>, Limits) ->
    Len = (L2 bsl 16) bor (L1 bsl 8) bor L0,
    decode_binary_data(Len, Rest0, Limits);
decode_binary(<<?BINARY_32, Len:32, Rest0/binary>>, Limits) ->
    decode_binary_data(Len, Rest0, Limits);
decode_binary(<<Tag, _/binary>>, _Limits) ->
    {error, {unexpected_binary_tag, Tag}};
decode_binary(<<>>, _Limits) ->
    {error, truncated_binary}.

decode_binary_data(Len, Rest0, Limits) ->
    case ensure_limit(Len, max_binary_size, Limits) of
        ok when byte_size(Rest0) >= Len ->
            <<Data:Len/binary, Rest/binary>> = Rest0,
            {ok, Data, Rest};
        ok ->
            {error, {truncated_binary, Len, byte_size(Rest0)}};
        {error, Reason} ->
            {error, Reason}
    end.

decode_jid(Bin, Limits) ->
    case decode_nibble_raw(Bin) of
        {ok, UserNibble, Rest1} ->
            case decode_string(Rest1, Limits) of
                {ok, Server, Rest2} ->
                    try stone_jid:decode(UserNibble, Server) of
                        JID -> {ok, {jid, JID}, Rest2}
                    catch
                        _:_ -> {error, invalid_jid}
                    end;
                {error, Reason} ->
                    {error, Reason}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

decode_nibble_raw(<<?JID_PAIR, Len, Rest0/binary>>) when byte_size(Rest0) >= Len ->
    <<Data:Len/binary, Rest/binary>> = Rest0,
    {ok, <<?JID_PAIR, Len, Data/binary>>, Rest};
decode_nibble_raw(<<?JID_PAIR, Len, Rest0/binary>>) ->
    {error, {truncated_jid, Len, byte_size(Rest0)}};
decode_nibble_raw(_) ->
    {error, invalid_jid}.

limits(Opts) ->
    #{
        max_depth => proplists:get_value(max_depth, Opts, ?DEFAULT_MAX_DEPTH),
        max_attrs => proplists:get_value(max_attrs, Opts, ?DEFAULT_MAX_ATTRS),
        max_children => proplists:get_value(max_children, Opts, ?DEFAULT_MAX_CHILDREN),
        max_binary_size => proplists:get_value(max_binary_size, Opts, ?DEFAULT_MAX_BINARY_SIZE)
    }.

ensure_limit(Value, Key, Limits) ->
    case Value =< maps:get(Key, Limits) of
        true -> ok;
        false -> {error, {limit_exceeded, Key}}
    end.
