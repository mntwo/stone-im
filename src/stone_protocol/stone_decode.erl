%% Deserialize binary format back into Node tuples.
%%
%% Returns: {ok, [Node], RestBinary} | {error, Reason}

-module(stone_decode).

-export([node/1, decode_string/1]).

-include("stone_protocol.hrl").

node(Bin) ->
    node_acc(Bin, []).

node_acc(<<>>, Acc) ->
    {ok, lists:reverse(Acc), <<>>};
node_acc(Bin, Acc) ->
    case decode_node(Bin) of
        {nil, Rest} -> {ok, lists:reverse(Acc), Rest};
        {Node, Rest} -> node_acc(Rest, [Node|Acc])
    end.

% [Tag][Len][Content]
decode_node(Bin) ->
    case decode_list_size(Bin) of
        {0, _Rest} -> 
            {nil, _Rest};
        {Size, Rest1} ->
            {Desc, Rest2} = decode_string(Rest1),
            {Attrs, Rest3} = decode_attrs((Size - 1) div 2, Rest2),
            HasContent = (Size rem 2) =:= 0,
            {Content, Rest4} = case HasContent of
                true -> decode_content(Rest3);
                false -> {nil, Rest3}
            end,
            {{Desc, Attrs, Content}, Rest4}
    end.

decode_content(<<?LIST_EMPTY, Rest/binary>>) ->
    {nil, Rest};
decode_content(<<?BINARY_8, _/binary>> = Bin) ->
    decode_binary(Bin);
decode_content(<<?BINARY_20, _/binary>> = Bin) ->
    decode_binary(Bin);
decode_content(<<?BINARY_32, _/binary>> = Bin) ->
    decode_binary(Bin);
decode_content(Bin) ->
    {N, Rest1} = decode_list_size(Bin),
    decode_nodes_n(N, Rest1).

decode_nodes_n(0, Bin) ->
    {[], Bin};
decode_nodes_n(N, Bin) ->
    {Child, Rest1} = decode_node(Bin),
    {Children, Rest2} = decode_nodes_n(N - 1, Rest1),
    {[Child | Children], Rest2}.

decode_attrs(0, Bin) ->
    {[], Bin};
decode_attrs(N, Bin) ->
    {Key, Rest1} = decode_string(Bin),
    {Val, Rest2} = decode_attr_value(Rest1),
    {More, Rest3} = decode_attrs(N - 1, Rest2),
    {[{Key, Val} | More], Rest3}.

decode_attr_value(<<?JID_PAIR, _/binary>> = Bin) ->
    decode_jid(Bin);
decode_attr_value(Bin)->
    decode_string(Bin).

decode_list_size(<<?LIST_EMPTY, Rest/binary>>) ->
    {0, Rest};
decode_list_size(<<?LIST_8, N:8, Rest/binary>>) ->
    {N, Rest};
decode_list_size(<<?LIST_16, Hi:8, Lo:8, Rest/binary>>) ->
    N = (Hi bsl 8) bor Lo,
    {N, Rest}.

decode_string(<<Token, Rest/binary>>) ->
    case stone_token:to_string(Token) of
        undefined -> decode_binary(<<Token, Rest/binary>>); % Not a token, treat as binary
        Str -> {Str, Rest}
    end.

decode_binary(<<?BINARY_8, Len:8, Data:Len/binary, Rest/binary>>) ->
    {Data, Rest};
decode_binary(<<?BINARY_20, L2, L1, L0, Rest0/binary>>) ->
    Len = (L2 bsl 16) bor (L1 bsl 8) bor L0,
    <<Data:Len/binary, Rest/binary>> = Rest0,
    {Data, Rest};
decode_binary(<<?BINARY_32, Len:32, Data:Len/binary, Rest/binary>>) ->
    {Data, Rest}.

decode_jid(Bin) ->
     {UserNibble, Rest1} = decode_nibble_raw(Bin),
     {Server, Rest2} = decode_string(Rest1),
     JID = stone_jid:decode(UserNibble, Server),
     {{jid, JID}, Rest2}.

decode_nibble_raw(<<?JID_PAIR, Len, Data:Len/binary, Rest/binary>>) ->
    {<<?JID_PAIR, Len, Data/binary>>, Rest}.
