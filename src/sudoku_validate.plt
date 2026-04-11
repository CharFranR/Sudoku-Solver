:- begin_tests(sudoku_validate).

:- use_module('sudoku_validate').

% Valid board for reuse across tests
valid_board([
    [5,3,0,0,7,0,0,0,0],
    [6,0,0,1,9,5,0,0,0],
    [0,9,8,0,0,0,0,6,0],
    [8,0,0,0,6,0,0,0,3],
    [4,0,0,8,0,3,0,0,1],
    [7,0,0,0,2,0,0,0,6],
    [0,6,0,0,0,0,2,8,0],
    [0,0,0,4,1,9,0,0,5],
    [0,0,0,0,8,0,0,7,9]]).

% Fully solved valid board
solved_board([
    [5,3,4,6,7,8,9,1,2],
    [6,7,2,1,9,5,3,4,8],
    [1,9,8,3,4,2,5,6,7],
    [8,5,9,7,6,1,4,2,3],
    [4,2,6,8,5,3,7,9,1],
    [7,1,3,9,2,4,8,5,6],
    [9,6,1,5,3,7,2,8,4],
    [2,8,7,4,1,9,6,3,5],
    [3,4,5,2,8,6,1,7,9]]).

%% === validate_board/2 ===

test(validate_board_valid_with_zeros, [true(Status == ok)]) :-
    valid_board(B),
    validate_board(B, Status).

test(validate_board_solved, [true(Status == ok)]) :-
    solved_board(B),
    validate_board(B, Status).

test(validate_board_invalid_shape_rows) :-
    validate_board([[5,3,0],[6,0,0]], Status),
    Status = invalid_input(_).

test(validate_board_invalid_shape_cols) :-
    validate_board([
        [5,3],
        [6,0,0,1,9,5,0,0,0],
        [0,9,8,0,0,0,0,6,0],
        [8,0,0,0,6,0,0,0,3],
        [4,0,0,8,0,3,0,0,1],
        [7,0,0,0,2,0,0,0,6],
        [0,6,0,0,0,0,2,8,0],
        [0,0,0,4,1,9,0,0,5],
        [0,0,0,0,8,0,0,7,9]], Status),
    Status = invalid_input(_).

test(validate_board_invalid_range_negative) :-
    validate_board([
        [-1,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0]], Status),
    Status = invalid_input(_).

test(validate_board_invalid_range_over9) :-
    validate_board([
        [10,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0]], Status),
    Status = invalid_input(_).

test(validate_board_duplicate_in_row) :-
    validate_board([
        [5,3,5,0,7,0,0,0,0],
        [6,0,0,1,9,5,0,0,0],
        [0,9,8,0,0,0,0,6,0],
        [8,0,0,0,6,0,0,0,3],
        [4,0,0,8,0,3,0,0,1],
        [7,0,0,0,2,0,0,0,6],
        [0,6,0,0,0,0,2,8,0],
        [0,0,0,4,1,9,0,0,5],
        [0,0,0,0,8,0,0,7,0]], Status),
    Status = inconsistent(_).

test(validate_board_duplicate_in_column) :-
    validate_board([
        [5,3,0,0,7,0,0,0,0],
        [6,0,0,1,9,5,0,0,0],
        [5,9,8,0,0,0,0,6,0],
        [8,0,0,0,6,0,0,0,3],
        [4,0,0,8,0,3,0,0,1],
        [7,0,0,0,2,0,0,0,6],
        [0,6,0,0,0,0,2,8,0],
        [0,0,0,4,1,9,0,0,5],
        [0,0,0,0,8,0,0,7,0]], Status),
    Status = inconsistent(_).

test(validate_board_duplicate_in_block) :-
    validate_board([
        [5,3,0,0,7,0,0,0,0],
        [6,3,0,1,9,5,0,0,0],
        [0,9,8,0,0,0,0,6,0],
        [8,0,0,0,6,0,0,0,3],
        [4,0,0,8,0,3,0,0,1],
        [7,0,0,0,2,0,0,0,6],
        [0,6,0,0,0,0,2,8,0],
        [0,0,0,4,1,9,0,0,5],
        [0,0,0,0,8,0,0,7,0]], Status),
    Status = inconsistent(_).

%% === check_shape/2 ===

test(check_shape_valid, [true(Reason == ok)]) :-
    valid_board(B),
    check_shape(B, Reason).

test(check_shape_empty_list, [true(Reason \== ok)]) :-
    check_shape([], Reason).

test(check_shape_too_few_rows, [true(Reason \== ok)]) :-
    check_shape([[1,2,3],[4,5,6],[7,8,9]], Reason).

test(check_shape_too_few_cols, [true(Reason \== ok)]) :-
    check_shape([
        [1,2,3],[4,5,6],[7,8,9],
        [1,2,3],[4,5,6],[7,8,9],
        [1,2,3],[4,5,6],[7,8,9]], Reason).

%% === check_range/2 ===

test(check_range_valid, [true(Reason == ok)]) :-
    valid_board(B),
    check_range(B, Reason).

test(check_range_negative_value, [true(Reason \== ok)]) :-
    check_range([
        [-1,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0]], Reason).

test(check_range_over_9, [true(Reason \== ok)]) :-
    check_range([
        [10,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0]], Reason).

%% === check_consistency/2 ===

test(check_consistency_valid, [true(Reason == ok)]) :-
    valid_board(B),
    check_consistency(B, Reason).

test(check_consistency_solved, [true(Reason == ok)]) :-
    solved_board(B),
    check_consistency(B, Reason).

test(check_consistency_row_duplicate, [true(Reason \== ok)]) :-
    check_consistency([
        [1,1,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0]], Reason).

test(check_consistency_column_duplicate, [true(Reason \== ok)]) :-
    check_consistency([
        [1,0,0,0,0,0,0,0,0],
        [1,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0]], Reason).

test(check_consistency_block_duplicate, [true(Reason \== ok)]) :-
    check_consistency([
        [1,2,3,0,0,0,0,0,0],
        [4,5,6,0,0,0,0,0,0],
        [7,8,1,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0]], Reason).

:- end_tests(sudoku_validate).
