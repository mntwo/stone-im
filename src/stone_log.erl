-module(stone_log).


-export([debug/1, debug/2, info/1, info/2, warning/1, warning/2, error/1, error/2]).


debug(Msg) -> 
    logger:debug(Msg).
debug(Msg, Meta) when is_map(Meta) -> 
    logger:debug(#{msg => Msg, data => Meta}).

info(Msg) -> 
    logger:info(Msg).
info(Msg, Meta) when is_map(Meta) -> 
    logger:info(#{msg => Msg, data => Meta}).

warning(Msg) -> 
    logger:warning(Msg).
warning(Msg, Meta) when is_map(Meta) -> 
    logger:warning(#{msg => Msg, data => Meta}).

error(Msg) -> 
    logger:error(Msg).
error(Msg, Meta) when is_map(Meta) -> 
    logger:error(#{msg => Msg, data => Meta}).