:- begin_tests(sudoku_game_flow).

:- use_module('sudoku_game_flow').

unique_board([
    [5,3,0,0,7,0,0,0,0],
    [6,0,0,1,9,5,0,0,0],
    [0,9,8,0,0,0,0,6,0],
    [8,0,0,0,6,0,0,0,3],
    [4,0,0,8,0,3,0,0,1],
    [7,0,0,0,2,0,0,0,6],
    [0,6,0,0,0,0,2,8,0],
    [0,0,0,4,1,9,0,0,5],
    [0,0,0,0,8,0,0,7,9]
]).

solved_board([
    [5,3,4,6,7,8,9,1,2],
    [6,7,2,1,9,5,3,4,8],
    [1,9,8,3,4,2,5,6,7],
    [8,5,9,7,6,1,4,2,3],
    [4,2,6,8,5,3,7,9,1],
    [7,1,3,9,2,4,8,5,6],
    [9,6,1,5,3,7,2,8,4],
    [2,8,7,4,1,9,6,3,5],
    [3,4,5,2,8,6,1,7,9]
]).

no_solution_board([
    [0,0,5,9,1,0,0,0,0],
    [0,0,0,0,0,2,0,0,0],
    [0,3,0,0,0,0,6,0,0],
    [0,0,0,0,0,0,0,7,2],
    [1,0,0,0,6,0,0,0,8],
    [6,4,0,0,0,0,0,0,0],
    [0,0,9,0,0,0,0,1,0],
    [0,0,0,8,0,0,0,0,0],
    [0,0,0,0,3,5,2,0,0]
]).

multi_solution_board([
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0]
]).

test(manual_check_incomplete_consistent) :-
    unique_board(Board),
    manual_check_status(Board, Status),
    Status = incomplete_consistent.

test(manual_check_solved_correctly) :-
    solved_board(Board),
    manual_check_status(Board, Status),
    Status = solved_correctly.

test(manual_check_incorrect_inconsistent) :-
    Board = [
        [1,1,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0]
    ],
    manual_check_status(Board, Status),
    Status = incorrect(inconsistent(_)).

test(manual_check_invalid_input) :-
    manual_check_status([[1,2],[3,4]], Status),
    Status = incorrect(invalid_input(_)).

test(practice_start_unique_solution_ready) :-
    unique_board(Board),
    practice_start_status(Board, Status, TargetSolution),
    Status = practice_ready,
    is_complete_board(TargetSolution).

test(practice_start_rejects_non_unique) :-
    multi_solution_board(Board),
    practice_start_status(Board, Status, _TargetSolution),
    Status = non_unique.

test(practice_start_rejects_no_solution) :-
    no_solution_board(Board),
    practice_start_status(Board, Status, _TargetSolution),
    Status = no_solution.

test(practice_start_rejects_invalid_input) :-
    practice_start_status([[1,2],[3,4]], Status, _TargetSolution),
    Status = invalid_input(_).

test(practice_start_rejects_inconsistent) :-
    Board = [
        [1,1,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0]
    ],
    practice_start_status(Board, Status, _TargetSolution),
    Status = inconsistent(_).

test(practice_start_blocks_already_solved_board) :-
    solved_board(Board),
    practice_start_status(Board, Status, _TargetSolution),
    Status = already_solved.

test(practice_check_solved) :-
    unique_board(InitialBoard),
    practice_start_status(InitialBoard, practice_ready, TargetSolution),
    practice_check_status(TargetSolution, InitialBoard, TargetSolution, Result),
    Result = solved.

test(practice_check_incomplete) :-
    unique_board(InitialBoard),
    practice_start_status(InitialBoard, practice_ready, TargetSolution),
    practice_check_status(InitialBoard, InitialBoard, TargetSolution, Result),
    Result = incomplete.

test(practice_check_incorrect_only_editable_cells) :-
    unique_board(InitialBoard),
    practice_start_status(InitialBoard, practice_ready, TargetSolution),
    set_editable_cell(InitialBoard, 1, 3, 9, UserBoard),
    practice_check_status(UserBoard, InitialBoard, TargetSolution, Result),
    Result = incorrect(Mistakes),
    Mistakes == [(1,3)].

set_editable_cell(Board, Row, Col, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    replace_nth(OldRow, Col, Value, NewRow),
    replace_nth(Board, Row, NewRow, NewBoard).

replace_nth(List, Index, Value, NewList) :-
    same_length(List, NewList),
    append(Prefix, [_|Suffix], List),
    length(Prefix, PrefixLen),
    Index is PrefixLen + 1,
    append(Prefix, [Value|Suffix], NewList).

is_complete_board(Board) :-
    forall(member(Row, Board),
           forall(member(Cell, Row),
                  ( integer(Cell),
                    Cell >= 1,
                    Cell =< 9
                  ))).

:- end_tests(sudoku_game_flow).
