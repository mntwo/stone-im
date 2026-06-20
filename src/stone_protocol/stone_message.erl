-module(stone_message).

-export([message/4, receipt/3, presence/1, ping/0, pong/0]).

% Text message Node
message(ID, From, To, Body) ->
    {~"message",
        [{~"id",   ID},
        {~"from", From},
        {~"to",   To},
        {~"type", ~"chat"}],
    [{~"body", [], Body}]}.

%% Read receipt Node
receipt(ID, From, To) ->
    {~"receipt",
        [{~"id",   ID},
        {~"from", From},
        {~"to",   To},
        {~"type", ~"read"}],
    nil}.

%% User presence Node
%%   Type = <<"available">> | <<"unavailable">> | <<"composing">> | <<"paused">>
presence(Type) ->
    {~"presence", [{~"type", Type}], nil}.

ping() ->
    {~"ping", [], nil}.
 
pong() ->
    {~"pong", [], nil}.