-module(stone_frame).

-export([encode/1, decode/1]).

decode(<<FlagLen:24/big, Payload/binary>>) ->
    _Flag = (FlagLen bsr 23) band 1,
    Len = FlagLen band 16#7FFFFF,
    <<Data:Len/binary, _Rest/binary>> = Payload,
    {ok, [Node], <<>>} = stone_decode:node(Data),
    Node;
decode(TooShort) ->
    {error, {too_short, byte_size(TooShort)}}.

encode(Node) ->
    Payload = stone_encode:node(Node),
    Len     = byte_size(Payload),
    Header  = (0 bsl 23) bor Len,
    <<Header:24/big, Payload/binary>>.