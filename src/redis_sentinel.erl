%%%-------------------------------------------------------------------
%%% @author Eman Calso
%%% @copyright (C) 2015, Emanuel Calso
%%% @doc
%%%
%%% @end
%%% Created : 2015-01-27 16:10:07.745141
%%%-------------------------------------------------------------------
-module(redis_sentinel).

%% API
-export([start/1, start_link/1]).

-define(DEFAULT_MASTER, <<"mymaster">>).


%%%===================================================================
%%% API
%%%===================================================================

start(SentinelOpts) ->
    start(start, SentinelOpts).

start_link(SentinelOpts) ->
    start(start_link, SentinelOpts).


%%%===================================================================
%%% Internal functions
%%%===================================================================
start(StartType, SentinelOpts) ->
    case redis:connect(SentinelOpts) of
        {ok, SentinelConn} ->
            case get_options_from_sentinel(SentinelConn, SentinelOpts) of
                {ok, RedisOpts} ->
                    redis:quit(SentinelConn),
                    redis_client:StartType(RedisOpts);
                {error, Err} ->
                    {error, Err}
            end;
        {error, Err} ->
            {error, Err}
    end.

get_options_from_sentinel(Conn, Opts) ->
    Master = proplists:get_value(master, Opts, ?DEFAULT_MASTER),
    case redis_client:request(Conn, {<<"sentinel">>,
            [<<"get-master-addr-by-name">>, Master]}) of
        {ok, Data} ->
            [Host, Port | _] = Data,
            {ok, [{host, binary_to_list(Host)}, {port, binary_to_integer(Port)}]};
        {error, Err} ->
            {error, Err}
    end.

