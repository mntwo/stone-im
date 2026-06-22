-module(stone_frame).

-export([encode/1, decode/1]).

-define(MAX_FRAME_SIZE, 16#7FFFFF).

decode(Bin) when byte_size(Bin) < 3 ->
    {more, 3 - byte_size(Bin)};
decode(<<FlagLen:24/big, Payload/binary>>) ->
    Flag = (FlagLen bsr 23) band 1,
    Len = FlagLen band ?MAX_FRAME_SIZE,
    case {Flag, byte_size(Payload) >= Len} of
        {1, _} ->
            {error, unsupported_flag};
        {0, false} ->
            {more, Len - byte_size(Payload)};
        {0, true} ->
            <<Data:Len/binary, Rest/binary>> = Payload,
            decode_payload(Data, Rest)
    end.

encode(Node) ->
    Payload = stone_encode:node(Node),
    Len     = byte_size(Payload),
    true    = Len =< ?MAX_FRAME_SIZE,
    Header  = (0 bsl 23) bor Len,
    <<Header:24/big, Payload/binary>>.

decode_payload(Data, Rest) ->
    case stone_decode:node(Data) of
        {ok, [Node], <<>>} ->
            {ok, Node, Rest};
        {ok, [], <<>>} ->
            {error, bad_frame};
        {ok, Nodes, NodeRest} ->
            {error, {bad_frame, {invalid_payload, Nodes, NodeRest}}};
        {error, Reason} ->
            {error, frame_error(Reason)}
    end.

frame_error(invalid_jid) ->
    invalid_jid;
frame_error(Reason) ->
    {bad_frame, Reason}.
