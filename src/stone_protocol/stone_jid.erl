% JID format: numeric@domain
-module(stone_jid).

-export([encode/1, decode/2]).

-include("stone_protocol.hrl").

%% Encode a JID binary like <<"1234567890@s.im">>
%% Returns iolist:  [UserNibbles, ServerToken | ServerBin]
encode(JID) when is_binary(JID) ->
    case binary:split(JID, <<"@">>) of
        [User, Server] ->
            UserBytes   = encode_user(User),
            ServerBytes = encode_server(Server),
            [UserBytes, ServerBytes];
        [_Bare] ->
            stone_encode:encode_string(JID)
    end.

%% Decode a JID from binary stream.
%% Returns {JID :: binary(), RestBin}
decode(<<?JID_PAIR, _Len, Packed/binary>>, Server) ->
    UserNibble = unpack_nibbles(Packed),
    <<UserNibble/binary, "@", Server/binary>>.

encode_server(Server) ->
    case stone_token:from_string(Server) of
        {ok, Token} -> 
            <<Token>>;
        not_found   -> 
            stone_encode:encode_string(Server)
    end.

encode_user(Bin) ->
    true = valid_user(Bin),
    Digits = binary_to_list(Bin),
    Packed = pack_nibbles(Digits),
    Len    = byte_size(Packed),
    <<?JID_PAIR, Len, Packed/binary>>.

pack_nibbles([]) ->
    <<>>;
pack_nibbles([D]) ->
    %% odd digit: pad with 0xF in low nibble
    High = digit_to_nibble(D),
    <<(High bsl 4 bor 16#F)>>;
pack_nibbles([D1, D2 | Rest]) ->
    High = digit_to_nibble(D1),
    Low  = digit_to_nibble(D2),
    Byte = (High bsl 4) bor Low,
    Tail = pack_nibbles(Rest),
    <<Byte, Tail/binary>>.

digit_to_nibble(D) when D >= $0, D =< $9 -> D - $0;
digit_to_nibble($-) -> 10;
digit_to_nibble($.) -> 11.

valid_user(<<>>) ->
    false;
valid_user(Bin) ->
    lists:all(fun valid_user_char/1, binary_to_list(Bin)).

valid_user_char(D) when D >= $0, D =< $9 ->
    true;
valid_user_char($-) ->
    true;
valid_user_char($.) ->
    true;
valid_user_char(_) ->
    false.

unpack_nibbles(<<>>) ->
    <<>>;
unpack_nibbles(<<Byte, Rest/binary>>) ->
    High = (Byte bsr 4) band 16#F,
    Low  = Byte band 16#F,
    H = nibble_to_digit(High),
    case Low of
        16#F ->
            %% padding nibble, stop
            <<H>>;
        _ ->
            L    = nibble_to_digit(Low),
            Tail = unpack_nibbles(Rest),
            <<H, L, Tail/binary>>
    end.
 
nibble_to_digit(N) when N >= 0, N =< 9 -> $0 + N;
nibble_to_digit(10) -> $-;
nibble_to_digit(11) -> $.;
nibble_to_digit(N)  -> error({invalid_jid_nibble, N}).
