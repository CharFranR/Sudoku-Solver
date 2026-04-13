:- begin_tests(sudoku_solver).

:- use_module('sudoku_solver').
:- use_module('sudoku_validate').

% Board with unique solution (exercise 1)
unique_board([
    [5,3,0,0,7,0,0,0,0],
    [6,0,0,1,9,5,0,0,0],
    [0,9,8,0,0,0,0,6,0],
    [8,0,0,0,6,0,0,0,3],
    [4,0,0,8,0,3,0,0,1],
    [7,0,0,0,2,0,0,0,6],
    [0,6,0,0,0,0,2,8,0],
    [0,0,0,4,1,9,0,0,5],
    [0,0,0,0,8,0,0,7,9]]).

% Board with no solution (consistent but unsolvable)
no_solution_board([
    [0,0,5,9,1,0,0,0,0],
    [0,0,0,0,0,2,0,0,0],
    [0,3,0,0,0,0,6,0,0],
    [0,0,0,0,0,0,0,7,2],
    [1,0,0,0,6,0,0,0,8],
    [6,4,0,0,0,0,0,0,0],
    [0,0,9,0,0,0,0,1,0],
    [0,0,0,8,0,0,0,0,0],
    [0,0,0,0,3,5,2,0,0]]).

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

% Board with multiple solutions (very few clues)
multi_solution_board([
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0]]).

%% === solve_status/3 ===

test(solve_status_solved) :-
    unique_board(B),
    solve_status(B, Status, Solution),
    Status = solved,
    is_complete_board(Solution).

test(solve_status_no_solution) :-
    no_solution_board(B),
    solve_status(B, Status, Solution),
    Status = no_solution,
    Solution == [].

test(solve_status_already_solved) :-
    solved_board(B),
    solve_status(B, Status, Solution),
    Status = already_solved,
    Solution == B.

test(solve_status_multiple_solutions) :-
    multi_solution_board(B),
    solve_status(B, Status, Solution),
    Status = multiple_solutions,
    is_complete_board(Solution).

test(solve_status_invalid_input) :-
    solve_status([[1,2],[3,4]], Status, Solution),
    Status = invalid_input(_),
    Solution == [].

test(solve_status_inconsistent) :-
    solve_status([
        [1,1,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0]], Status, Solution),
    Status = inconsistent(_),
    Solution == [].

%% === solve_one/2 ===

test(solve_one_success) :-
    unique_board(B),
    once(solve_one(B, Solution)),
    is_complete_board(Solution).

test(solve_one_fails_on_unsolvable) :-
    no_solution_board(B),
    \+ solve_one(B, _).

%% === has_multiple_solutions/2 ===

test(has_multiple_solutions_unique, [true(Result == false)]) :-
    unique_board(B),
    has_multiple_solutions(B, Result).

test(has_multiple_solutions_solved, [true(Result == false)]) :-
    solved_board(B),
    has_multiple_solutions(B, Result).

test(has_multiple_solutions_many, [true(Result == true)]) :-
    multi_solution_board(B),
    has_multiple_solutions(B, Result).

%% === exercise/2 ===

test(exercise_1_is_valid) :-
    exercise(1, B),
    validate_board(B, ok).

test(exercise_2_is_valid) :-
    exercise(2, B),
    validate_board(B, ok).

test(exercise_3_is_valid) :-
    exercise(3, B),
    validate_board(B, ok).

test(exercise_4_is_valid) :-
    exercise(4, B),
    validate_board(B, ok).

test(exercise_5_is_valid) :-
    exercise(5, B),
    validate_board(B, ok).

test(exercise_0_fails) :-
    \+ exercise(0, _).

test(exercise_6_fails) :-
    \+ exercise(6, _).

test(exercise_1_resolves) :-
    exercise(1, B),
    solve_status(B, solved, _).

test(exercise_2_resolves) :-
    exercise(2, B),
    solve_status(B, solved, _).

test(exercise_3_resolves) :-
    exercise(3, B),
    solve_status(B, solved, _).

test(exercise_4_resolves) :-
    exercise(4, B),
    solve_status(B, solved, _).

test(exercise_5_resolves) :-
    exercise(5, B),
    solve_status(B, solved, _).

%% === generate_puzzle/2 ===

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

%% Helper: checks that a board is fully filled (no zeros)
is_complete_board(Board) :-
    forall(
        member(Row, Board),
        forall(
            member(Cell, Row),
            (integer(Cell), Cell >= 1, Cell =< 9)
        )
    ).

%% Helper: count non-zero cells (clues)
count_clues(Board, Count) :-
    flatten(Board, Cells),
    exclude(=(0), Cells, Clues),
    length(Clues, Count).

:- end_tests(sudoku_solver).
