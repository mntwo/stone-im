-module(stone_token).
-export([to_string/1, from_string/1]).

%% Single-byte token → string
to_string(16#01) -> <<"message">>;
to_string(16#02) -> <<"from">>;
to_string(16#03) -> <<"to">>;
to_string(16#04) -> <<"cmd">>;
to_string(16#05) -> <<"id">>;
to_string(16#06) -> <<"@s.im">>;
to_string(16#07) -> <<"@g.im">>;
to_string(_)     -> undefined.

%% string → single-byte token (reverse lookup)
from_string(<<"message">>)        -> {ok, 16#01};
from_string(<<"from">>)           -> {ok, 16#02};
from_string(<<"to">>)             -> {ok, 16#03};
from_string(<<"cmd">>)            -> {ok, 16#04};
from_string(<<"id">>)             -> {ok, 16#05};
from_string(<<"@s.im">>)          -> {ok, 16#06};
from_string(<<"@g.im">>)          -> {ok, 16#07};
from_string(_)                    -> not_found.