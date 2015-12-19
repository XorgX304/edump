-module('edump_stack').

%% API exports
-export([parse/1
        ,heap_ptrs/1
        ]).
-compile(export_all).

%%====================================================================
%% API functions
%%====================================================================

parse(Data) ->
    Lines = binary:split(Data, <<"\n">>, [global]),
    [parse_line(Line) || Line <- Lines].

heap_ptrs(Stack) ->
    heap_ptrs(Stack, []).

heap_ptrs([], Acc) ->
    lists:usort(Acc);
heap_ptrs([{{var, _}, {heap, _} = H} | Rest], Acc) ->
    heap_ptrs(Rest, [H | Acc]);
heap_ptrs([{{var, _}, V} | Rest], Acc) ->
    heap_ptrs(Rest, process_mem:heap_ptrs(V, Acc));
heap_ptrs([_|Rest], Acc) ->
    heap_ptrs(Rest, Acc).

%%====================================================================
%% Internal functions
%%====================================================================

parse_line(Line) ->
    case binary:split(Line, <<":">>) of
        [<<"y",Num/binary>>, Rest] ->
            parse_var(binary_to_integer(Num), Rest);
        [<<"0x", Addr:16/binary>>, Rest] ->
            parse_addr(binary_to_integer(Addr, 16), Rest)
    end.

parse_var(VarNum, <<"SCatch 0x", Addr2:8/binary, " ", Info/binary>>) ->
    {{var, VarNum}, {'catch', Addr2, Info}};
parse_var(VarNum, Rest) ->
    {{var, VarNum}, edump_mem:parse(Rest)}.

parse_addr(Addr, <<"SReturn addr 0x", Addr2:8/binary, " ", Info/binary>>) ->
    {{ptr, Addr}, {return_to, Addr2, Info}}.
