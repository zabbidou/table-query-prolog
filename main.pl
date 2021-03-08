:- use_module(check_predicates).
:- use_module(tables).


plus5(X, Y):- Y is X + 5.

make_format_str(MaxRowLen, Str) :- maplist(plus5, MaxRowLen, Rp), aux_format(Rp, Str).

aux_format([H], R) :- string_concat("~t~w~t~", H, R1), string_concat(R1, "+~n", R), !.
aux_format([H|T], R) :- string_concat("~t~w~t~", H, R1), string_concat(R1, "+ ", R2), aux_format(T, Rp), string_concat(R2, Rp, R).

get_nth_entry([H | _], 0, H) :- !.
get_nth_entry([_ | T], Pos, R) :- Posp is Pos - 1, get_nth_entry(T, Posp, R).

get_nth_column([], _, []). 
get_nth_column([TblH | TblT], Pos, [Rh | R]) :- get_nth_entry(TblH, Pos, Rh), get_nth_column(TblT, Pos, R).

trans(Tbl, R) :- transh(Tbl, 0, R).
transh([H | _], Pos, []) :- length(H, Pos), !.
transh(Tbl, Pos, [Rh | Rt]) :- get_nth_column(Tbl, Pos, Rh), Posp is Pos + 1, transh(Tbl, Posp, Rt).

get_max_len(Tbl, R) :- trans(Tbl, Transp), get_max_length_helper(Transp, LenList), maplist(max_list, LenList, R).

helper(Elem, Len) :- string_chars(Elem, Rez), length(Rez, Len).

get_max_length_helper([], []).
get_max_length_helper([H | Tbl], [Rh | Rt]) :- maplist(helper, H, Rh), get_max_length_helper(Tbl, Rt).

show_table([], _).
show_table([H | Tbl], Str) :- format(Str, H), show_table(Tbl, Str).

print_table_op(Tbl) :- get_max_len(Tbl, MaxRowLen), make_format_str(MaxRowLen, Str), show_table(Tbl, Str).

% TblH -> o coloana
filter_helper([], _, _, []).
filter_helper([TblH | TblT], V, Cond, R) :- not((V = TblH, Cond)), filter_helper(TblT, V, Cond, R), !.
filter_helper([Hr | TblT], V, Cond, [Hr | R]) :- filter_helper(TblT, V, Cond, R).

filter_op([H | Tbl], Vars, Cond, R) :- filter_helper(Tbl, Vars, Cond, Tail), append([H], Tail, R).

join_op(Op, NewHeader, [_ | T1], [_ | T2], R) :- maplist(Op, T1, T2, Rp), append([NewHeader], Rp, R).

select_op([Header | Table], H, R) :- trans([Header | Table], T), select_h(T, H, Trans), trans(Trans, R), !.
select_h(_, [], []).
select_h([Th | Tt], [H | Header], [Th | R]) :- nth0(0, Th, H), select_h(Tt, Header, R).
select_h([_ | Tt], Header, R) :- select_h(Tt, Header, R).

%eval
eval(table(Str), R) :- table_name(Str, R).
eval(tprint(Name), _) :- eval(Name, Tbl), print_table_op(Tbl).
eval(tfilter(S, G, Q), R) :- eval(Q, Tbl), filter_op(Tbl, S, G, R).
eval(join(Pred, Cols, Q1, Q2), R) :- eval(Q1, Tbl1), eval(Q2, Tbl2), join_op(Pred, Cols, Tbl1, Tbl2, R).
eval(select(Columns, Q), R) :- eval(Q, Tbl), select_op(Tbl, Columns, R).
eval(complex_query1(Q), R) :- eval(Q, Tbl), complex_query1(Tbl, R).
eval(complex_query2(G, Min, Max), R) :- table_name('movies', Tbl), complex_query2(G, Min, Max, Tbl, R).

are_escu(String) :- atom_concat(_, 'escu', String).

complex_query1(Tbl, R) :- filter_op(Tbl, [_,L,AA,PP,PC,PA,POO], ((AA + PP) / 2 > 6, (AA + PP + PC + PA + POO) / 5 > 5, are_escu(L)), R).

is_genre(G, Ref) :- sub_string(G, _, _, _, Ref), !.

append_ratings([],_,[]).
append_ratings([Hm | TblM], Rt, [Rh | R]) :- nth0(0, Hm, Id), 
                                             get_rating(Id, Rating, Rt), 
                                             append(Hm, [Rating], Rh), 
                                             append_ratings(TblM, Rt, R).

append_header(Tbl, R) :- append([["movie_id","title","genres","rating"]],Tbl, R).

complex_query2(RefG, MinR, MaxR, [_|T], R) :- table_name('ratings', [_ | RTbl]),
                                              append_ratings(T, RTbl, Tbl_noH),
                                              append_header(Tbl_noH, Tbl),
                                              filter_op(Tbl, [_,_,G,Rat], (is_genre(G, RefG), Rat =< MaxR, Rat >= MinR), R). 

get_rating(Id, Rating, [Line | _]) :- nth0(2, Line, Id), nth0(3, Line, Rating), !.
get_rating(Id, Rating, [_ | Table]) :- get_rating(Id, Rating, Table).