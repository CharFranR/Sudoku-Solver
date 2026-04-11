%% Sudoku Solver Tests
%% Unit tests for the sudoku_solver module

:- begin_tests(sudoku_solver).

:- use_module('sudoku_solver.pl').

%% Test: solve a simple valid puzzle
test(solve_exercise_1) :-
    exercise(1, Board),
    solve_status(Board, Status, Solution),
    Status = solved,
    is_list(Solution),
    length(Solution, 9).

%% Test: already solved board
test(already_solved) :-
    %% This is the solved board from exercise 1
    Board = [[5,3,4,6,7,8,9,1,2],
             [6,7,2,1,9,5,3,4,8],
             [1,9,8,3,4,2,5,6,7],
             [8,5,9,7,6,1,4,2,3],
             [4,2,6,8,5,3,7,9,1],
             [7,1,3,9,2,4,8,5,6],
             [9,6,1,5,3,7,2,8,4],
             [2,8,7,4,1,9,6,3,5],
             [3,4,5,2,8,6,1,7,9]],
    solve_status(Board, Status, _Solution),
    Status = already_solved.

%% Test: no solution exists
test(no_solution) :-
    Board = [[5,5,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0,0]],
    solve_status(Board, Status, _Solution),
    Status = inconsistent(_).

%% Test: solve exercise 2 (medium difficulty)
test(solve_exercise_2) :-
    exercise(2, Board),
    solve_status(Board, Status, Solution),
    Status = solved,
    is_list(Solution),
    length(Solution, 9).

%% Test: solve exercise 3 (hard difficulty)
test(solve_exercise_3) :-
    exercise(3, Board),
    solve_status(Board, Status, Solution),
    Status = solved,
    is_list(Solution),
    length(Solution, 9).

%% Test: solve_one returns correct solution
test(solve_one_returns_solution) :-
    exercise(1, Board),
    solve_one(Board, Solution),
    is_list(Solution),
    length(Solution, 9).

%% Test: has_multiple_solutions returns false for unique puzzle
test(unique_puzzle_has_no_multiple_solutions) :-
    exercise(1, Board),
    has_multiple_solutions(Board, false).

%% === generate_puzzle/2 tests ===

%% Test: generate_puzzle returns 9x9 matrix
test(generate_puzzle_returns_9x9_matrix) :-
    generate_puzzle(easy, Puzzle),
    is_list(Puzzle),
    length(Puzzle, 9),
    forall(member(Row, Puzzle),
           (is_list(Row), length(Row, 9))).

%% Test: generate_puzzle returns valid values (0-9)
test(generate_puzzle_values_in_range) :-
    generate_puzzle(easy, Puzzle),
    forall(member(Row, Puzzle),
           forall(member(Cell, Row),
                  between(0, 9, Cell))).

%% Test: easy puzzle has 35-40 clues
test(easy_puzzle_has_35_to_40_clues) :-
    generate_puzzle(easy, Puzzle),
    count_clues(Puzzle, Count),
    Count >= 35,
    Count =< 40.

%% Test: medium puzzle has 27-32 clues
test(medium_puzzle_has_27_to_32_clues) :-
    generate_puzzle(medium, Puzzle),
    count_clues(Puzzle, Count),
    Count >= 27,
    Count =< 32.

%% Test: hard puzzle has 22-27 clues
test(hard_puzzle_has_22_to_27_clues) :-
    generate_puzzle(hard, Puzzle),
    count_clues(Puzzle, Count),
    Count >= 22,
    Count =< 27.

%% Test: generated puzzle has exactly one solution
test(generated_puzzle_has_one_solution) :-
    generate_puzzle(easy, Puzzle),
    has_multiple_solutions(Puzzle, false).

%% Test: generated puzzle is consistent (no duplicate non-zero values in row/col/block)
test(generated_puzzle_is_consistent) :-
    generate_puzzle(easy, Puzzle),
    validate_board(Puzzle, ok).

%% Helper: count non-zero cells (clues)
count_clues(Board, Count) :-
    flatten(Board, Cells),
    exclude(=(0), Cells, Clues),
    length(Clues, Count).

:- end_tests(sudoku_solver).
