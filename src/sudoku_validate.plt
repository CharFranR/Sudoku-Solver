%% Sudoku Validate Tests
%% Unit tests for the sudoku_validate module

:- begin_tests(sudoku_validate).

:- use_module('sudoku_validate.pl').

%% Test helper: verify board validation works
test(validate_empty_board) :-
    Board = [[0,0,0,0,0,0,0,0,0],
              [0,0,0,0,0,0,0,0,0],
              [0,0,0,0,0,0,0,0,0],
              [0,0,0,0,0,0,0,0,0],
              [0,0,0,0,0,0,0,0,0],
              [0,0,0,0,0,0,0,0,0],
              [0,0,0,0,0,0,0,0,0],
              [0,0,0,0,0,0,0,0,0],
              [0,0,0,0,0,0,0,0,0]],
    validate_board(Board, ok).

test(validate_valid_puzzle) :-
    Board = [[5,3,0,0,7,0,0,0,0],
             [6,0,0,1,9,5,0,0,0],
             [0,9,8,0,0,0,0,6,0],
             [8,0,0,0,6,0,0,0,3],
             [4,0,0,8,0,3,0,0,1],
             [7,0,0,0,2,0,0,0,6],
             [0,6,0,0,0,0,2,8,0],
             [0,0,0,4,1,9,0,0,5],
             [0,0,0,0,8,0,0,7,9]],
    validate_board(Board, ok).

test(invalid_wrong_shape) :-
    Board = [[1,2,3], [4,5,6]],
    validate_board(Board, invalid_input('Debe ser una lista de 9 filas, cada una con 9 columnas')).

test(invalid_out_of_range) :-
    Board = [[15,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    validate_board(Board, invalid_input('Las celdas deben ser enteros entre 0 y 9')).

test(inconsistent_duplicate_in_row) :-
    Board = [[5,5,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    validate_board(Board, inconsistent('Hay duplicados en filas/columnas/bloques 1..9')).

test(inconsistent_duplicate_in_col) :-
    Board = [[5,0,0,0,0,0,0,0,0],
             [5,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    validate_board(Board, inconsistent('Hay duplicados en filas/columnas/bloques 1..9')).

test(inconsistent_duplicate_in_block) :-
    Board = [[5,5,5,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    validate_board(Board, inconsistent('Hay duplicados en filas/columnas/bloques 1..9')).

test(check_shape_valid) :-
    Board = [[1,2,3,4,5,6,7,8,9],
             [1,2,3,4,5,6,7,8,9],
             [1,2,3,4,5,6,7,8,9],
             [1,2,3,4,5,6,7,8,9],
             [1,2,3,4,5,6,7,8,9],
             [1,2,3,4,5,6,7,8,9],
             [1,2,3,4,5,6,7,8,9],
             [1,2,3,4,5,6,7,8,9],
             [1,2,3,4,5,6,7,8,9]],
    check_shape(Board, ok).

test(check_range_valid) :-
    Board = [[1,2,3,4,5,6,7,8,9],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    check_range(Board, ok).

test(check_consistency_valid) :-
    %% This is a valid Sudoku solution from exercise 1
    Board = [[5,3,4,6,7,8,9,1,2],
             [6,7,2,1,9,5,3,4,8],
             [1,9,8,3,4,2,5,6,7],
             [8,5,9,7,6,1,4,2,3],
             [4,2,6,8,5,3,7,9,1],
             [7,1,3,9,2,4,8,5,6],
             [9,6,1,5,3,7,2,8,4],
             [2,8,7,4,1,9,6,3,5],
             [3,4,5,2,8,6,1,7,9]],
    check_consistency(Board, ok).

%% === Tests for is_cell_valid/3 ===
%% is_cell_valid(+Board, +Position, -Status)
%% Position is Row-Col (1-indexed)
%% Status = valid | invalid_row | invalid_col | invalid_block | empty

%% Empty cell (value 0) always returns empty
test(is_cell_valid_empty_cell) :-
    Board = [[0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    is_cell_valid(Board, 1-1, empty).

%% Valid cell with no conflicts
test(is_cell_valid_valid) :-
    Board = [[5,3,0,0,7,0,0,0,0],
             [6,0,0,1,9,5,0,0,0],
             [0,9,8,0,0,0,0,6,0],
             [8,0,0,0,6,0,0,0,3],
             [4,0,0,8,0,3,0,0,1],
             [7,0,0,0,2,0,0,0,6],
             [0,6,0,0,0,0,2,8,0],
             [0,0,0,4,1,9,0,0,5],
             [0,0,0,0,8,0,0,7,9]],
    %% Cell at (1,1) has value 5, no duplicate in row 1, col 1, or block (1-3, 1-3)
    is_cell_valid(Board, 1-1, valid).

%% Invalid due to duplicate in same row
test(is_cell_valid_invalid_row) :-
    Board = [[5,5,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    %% Cell at (1,2) has value 5, duplicate with (1,1)
    is_cell_valid(Board, 1-2, invalid_row).

%% Invalid due to duplicate in same column
test(is_cell_valid_invalid_col) :-
    Board = [[5,0,0,0,0,0,0,0,0],
             [5,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    %% Cell at (2,1) has value 5, duplicate with (1,1)
    is_cell_valid(Board, 2-1, invalid_col).

%% Invalid due to duplicate in same 3x3 block
test(is_cell_valid_invalid_block) :-
    Board = [[5,0,0,0,0,0,0,0,0],
             [0,5,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    %% Cell at (2,2) has value 5, duplicate with (1,1) in same block
    is_cell_valid(Board, 2-2, invalid_block).

%% === Tests for conflicts_in_board/3 ===
%% conflicts_in_board(+Board, +Position, -Conflicts)
%% Returns list of conflicting cell positions (Row-Col) for a given cell

test(conflicts_in_board_row_conflict) :-
    Board = [[5,5,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    %% Cell at (1,2) conflicts with (1,1)
    conflicts_in_board(Board, 1-2, Conflicts),
    Conflicts = [1-1].

test(conflicts_in_board_col_conflict) :-
    Board = [[5,0,0,0,0,0,0,0,0],
             [5,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    %% Cell at (2,1) conflicts with (1,1)
    conflicts_in_board(Board, 2-1, Conflicts),
    Conflicts = [1-1].

test(conflicts_in_board_block_conflict) :-
    Board = [[5,0,0,0,0,0,0,0,0],
             [0,5,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    %% Cell at (2,2) conflicts with (1,1) in same block
    conflicts_in_board(Board, 2-2, Conflicts),
    Conflicts = [1-1].

test(conflicts_in_board_no_conflicts) :-
    Board = [[5,3,0,0,7,0,0,0,0],
             [6,0,0,1,9,5,0,0,0],
             [0,9,8,0,0,0,0,6,0],
             [8,0,0,0,6,0,0,0,3],
             [4,0,0,8,0,3,0,0,1],
             [7,0,0,0,2,0,0,0,6],
             [0,6,0,0,0,0,2,8,0],
             [0,0,0,4,1,9,0,0,5],
             [0,0,0,0,8,0,0,7,9]],
    %% Cell at (1,3) has value 0 (empty), no conflicts expected
    conflicts_in_board(Board, 1-3, Conflicts),
    Conflicts = [].

test(conflicts_in_board_multiple_conflicts) :-
    Board = [[5,5,0,0,0,0,0,0,0],
             [5,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    %% Cell at (1,1) has value 5, conflicts with (1,2) and (2,1)
    conflicts_in_board(Board, 1-1, Conflicts),
    sort(Conflicts, Sorted),
    Sorted = [1-2, 2-1].

:- end_tests(sudoku_validate).
