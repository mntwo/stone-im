%% Serialize a Node tree into binary format.
%%
%% Node = {Desc, Attrs, Content}
%%   Desc    :: binary()
%%   Attrs   :: [{binary(), binary() | jid}]
%%   Content :: [Node] | binary() | nil

-module(stone_encode).

-export([node/1, encode_string/1]).

-include("stone_protocol.hrl").

% Encode a Node into binary format.
% Desc is encoded as a string (with token optimization).
% Attrs are encoded as pairs of strings (with token optimization).
% Content can be nil, a binary, or a list of child nodes.
% 
node({Desc, Attrs, Content}) ->
    Len = length(Attrs),
    DescBin = encode_string(Desc),
    AttrsBin = encode_attrs(Attrs),
    ContentBin = case Content of
        nil -> <<>>;
        _ -> encode_content(Content)
    end,
    ContentFlag = case Content of
        nil -> 0;
        _ -> 1
    end,
    ListSize = 1 + Len * 2 + ContentFlag,
    iolist_to_binary([encode_list_size(ListSize), DescBin, AttrsBin, ContentBin]).

encode_content(nil) ->
    <<?LIST_EMPTY>>;
encode_content(Bin) when is_binary(Bin) ->
    encode_binary(Bin);
encode_content(Nodes) when is_list(Nodes) ->
    N = length(Nodes),
    H = encode_list_size(N),
    T = [stone_encode:node(Node) || Node <- Nodes],
    [H | T].

% [Tag 0xF8][Len 1B] for list size ≤ 255
% [Tag 0xF9][High 1B][Low 1B] for list size ≤ 65535
encode_list_size(0) ->
    <<?LIST_EMPTY>>;
encode_list_size(N) when N =< 16#FF ->
    <<?LIST_8, N:8>>;
encode_list_size(N) when N =< 16#FFFF ->
    Hi = (N bsr 8) band 16#FF,
    Lo = N band 16#FF,
    <<?LIST_16, Hi:8, Lo:8>>.

encode_attrs([]) ->
    <<>>;
encode_attrs(Attrs) ->
    iolist_to_binary([encode_attr(K, V) || {K, V} <- Attrs]).

encode_attr(Key, {jid, JID}) ->
    [encode_string(Key), stone_jid:encode(JID)];
encode_attr(Key, Value) ->
    [encode_string(Key), encode_string(Value)].

encode_string(Str) when is_binary(Str) ->
    case stone_token:from_string(Str) of
        {ok, Token} -> <<Token>>;
        not_found -> encode_binary(Str)
    end.

% [Tag 0xFA][Len 1B][Data] for binary data ≤ 255
% [Tag 0xFB][Len 3B][Data] for binary data ≤ 1048575
% [Tag 0xFC][Len 4B][Data] for binary data > 1048575
encode_binary(Bin) when is_binary(Bin) ->
    Len = byte_size(Bin),
    if
        Len =< 16#FF    ->  <<?BINARY_8, Len:8, Bin/binary>>;
        Len =< 16#FFFFF ->  L2 = (Len bsr 16) band 16#FF,
                            L1 = (Len bsr 8) band 16#FF,
                            L0 = Len band 16#FF,
                            <<?BINARY_20, L2:8, L1:8, L0:8, Bin/binary>>;
        true ->             <<?BINARY_32, Len:32, Bin/binary>>
    end.
