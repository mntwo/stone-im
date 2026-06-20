-module(stone_frame).

-export([decode/1]).

decode(<<FlagLen:24/big, Payload/binary>>) ->
    _Flag = (FlagLen bsr 23) band 1,
    Len = FlagLen band 16#7FFFFF,
    <<Data:Len/binary, _Rest/binary>> = Payload,
    {ok, [Node], _} = stone_decode:node(Data),
    Node;
decode(TooShort) ->
    {error, {too_short, byte_size(TooShort)}}.