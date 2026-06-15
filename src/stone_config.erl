-module(stone_config).

-export([get/1]).

get(Key) ->
    case application:get_env(stone_im, Key) of
        {ok, Value} ->
            resolve(Value);
        undefined ->
            error({config_not_found, Key})
    end.


resolve({env, Name, Default}) when is_integer(Default) ->
    resolve_integer(Name, Default);
resolve({env, Name, Default}) when is_boolean(Default) ->
    resolve_boolean(Name, Default);
resolve({env, Name, Default}) when is_list(Default) ->
    os:getenv(Name, Default);
resolve(Value) ->
    Value.

resolve_integer(Name, Default) ->
    case os:getenv(Name) of
        false ->
            Default;
        Value ->
            case string:to_integer(Value) of
                {Int, []} ->
                    Int;
                _ ->
                    Default
            end
    end.

resolve_boolean(Name, Default) ->
    Value = string:lowercase(
        os:getenv(Name, atom_to_list(Default))
    ),

    case Value of
        "true"  -> true;
        "1"     -> true;
        "yes"   -> true;
        "false" -> false;
        "0"     -> false;
        "no"    -> false;
        _       -> Default
    end.
