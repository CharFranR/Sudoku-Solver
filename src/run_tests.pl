#!/usr/bin/env swipl
%% Test runner for Sudoku Solver project
%% Runs all plunit test suites

:- use_module(library(plunit)).
:- use_module(sudoku_solver).
:- use_module(sudoku_gui).

%% GUI Practice Tests — calculate_score/4 & format_elapsed_time/2
:- begin_tests(sudoku_gui_practice).

test(score_no_empty_cells) :-
    % Fully solved board — no empty cells initially
    UserBoard = [
        [5,3,4,6,7,8,9,1,2],
        [6,7,2,1,9,5,3,4,8],
        [1,9,8,3,4,2,5,6,7],
        [8,5,9,7,6,1,4,2,3],
        [4,2,6,8,5,3,7,9,1],
        [7,1,3,9,2,4,8,5,6],
        [9,6,1,5,3,7,2,8,4],
        [2,8,7,4,1,9,6,3,5],
        [3,4,5,2,8,6,1,7,9]
    ],
    Solution = [
        [5,3,4,6,7,8,9,1,2],
        [6,7,2,1,9,5,3,4,8],
        [1,9,8,3,4,2,5,6,7],
        [8,5,9,7,6,1,4,2,3],
        [4,2,6,8,5,3,7,9,1],
        [7,1,3,9,2,4,8,5,6],
        [9,6,1,5,3,7,2,8,4],
        [2,8,7,4,1,9,6,3,5],
        [3,4,5,2,8,6,1,7,9]
    ],
    InitialSnapshot = [
        [5,3,4,6,7,8,9,1,2],
        [6,7,2,1,9,5,3,4,8],
        [1,9,8,3,4,2,5,6,7],
        [8,5,9,7,6,1,4,2,3],
        [4,2,6,8,5,3,7,9,1],
        [7,1,3,9,2,4,8,5,6],
        [9,6,1,5,3,7,2,8,4],
        [2,8,7,4,1,9,6,3,5],
        [3,4,5,2,8,6,1,7,9]
    ],
    calculate_score(UserBoard, Solution, InitialSnapshot, Percent),
    Percent = 0.

test(score_all_correct) :-
    UserBoard = [
        [5,3,4,6,7,8,9,1,2],
        [6,7,2,1,9,5,3,4,8],
        [1,9,8,3,4,2,5,6,7],
        [8,5,9,7,6,1,4,2,3],
        [4,2,6,8,5,3,7,9,1],
        [7,1,3,9,2,4,8,5,6],
        [9,6,1,5,3,7,2,8,4],
        [2,8,7,4,1,9,6,3,5],
        [3,4,5,2,8,6,1,7,9]
    ],
    Solution = [
        [5,3,4,6,7,8,9,1,2],
        [6,7,2,1,9,5,3,4,8],
        [1,9,8,3,4,2,5,6,7],
        [8,5,9,7,6,1,4,2,3],
        [4,2,6,8,5,3,7,9,1],
        [7,1,3,9,2,4,8,5,6],
        [9,6,1,5,3,7,2,8,4],
        [2,8,7,4,1,9,6,3,5],
        [3,4,5,2,8,6,1,7,9]
    ],
    InitialSnapshot = [
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0]
    ],
    calculate_score(UserBoard, Solution, InitialSnapshot, Percent),
    Percent = 100.

test(score_partial) :-
    UserBoard = [
        [5,3,0,0,7,0,0,0,0],
        [6,0,0,1,9,5,0,0,0],
        [0,9,8,0,0,0,0,6,0],
        [8,0,0,0,6,0,0,0,3],
        [4,0,0,8,0,3,0,0,1],
        [7,0,0,0,2,0,0,0,6],
        [0,6,0,0,0,0,2,8,0],
        [0,0,0,4,1,9,0,0,5],
        [0,0,0,0,8,0,0,7,9]
    ],
    Solution = [
        [5,3,4,6,7,8,9,1,2],
        [6,7,2,1,9,5,3,4,8],
        [1,9,8,3,4,2,5,6,7],
        [8,5,9,7,6,1,4,2,3],
        [4,2,6,8,5,3,7,9,1],
        [7,1,3,9,2,4,8,5,6],
        [9,6,1,5,3,7,2,8,4],
        [2,8,7,4,1,9,6,3,5],
        [3,4,5,2,8,6,1,7,9]
    ],
    InitialSnapshot = [
        [5,3,0,0,7,0,0,0,0],
        [6,0,0,1,9,5,0,0,0],
        [0,9,8,0,0,0,0,6,0],
        [8,0,0,0,6,0,0,0,3],
        [4,0,0,8,0,3,0,0,1],
        [7,0,0,0,2,0,0,0,6],
        [0,6,0,0,0,0,2,8,0],
        [0,0,0,4,1,9,0,0,5],
        [0,0,0,0,8,0,0,7,9]
    ],
    calculate_score(UserBoard, Solution, InitialSnapshot, Percent),
    integer(Percent),
    Percent >= 0, Percent =< 100.

test(format_elapsed_time_zero) :-
    format_elapsed_time(0, '00:00').

test(format_elapsed_time_seconds) :-
    format_elapsed_time(5, '00:05').

test(format_elapsed_time_minutes) :-
    format_elapsed_time(65, '01:05').

test(format_elapsed_time_hours) :-
    format_elapsed_time(3661, '61:01').

test(count_clues_known_board) :-
    Board = [
        [5,3,0,0,7,0,0,0,0],
        [6,0,0,1,9,5,0,0,0],
        [0,9,8,0,0,0,0,6,0],
        [8,0,0,0,6,0,0,0,3],
        [4,0,0,8,0,3,0,0,1],
        [7,0,0,0,2,0,0,0,6],
        [0,6,0,0,0,0,2,8,0],
        [0,0,0,4,1,9,0,0,5],
        [0,0,0,0,8,0,0,7,9]
    ],
    count_clues(Board, Count),
    Count = 30.

:- end_tests(sudoku_gui_practice).

%% Load all test modules and run tests
run_all_tests :-
    format('~n~n=== Running Sudoku Solver Test Suite ===~n~n', []),
    
    %% Load test files using load_files/1 (not use_module for .plt files)
    format('Loading test suites...~n', []),
    (   catch(load_files('src/sudoku_validate.plt'), E1, true)
    ->  (var(E1) -> format('  ✓ sudoku_validate.plt loaded~n', []) 
                  ; format('  ✗ sudoku_validate.plt error: ~w~n', [E1]))
    ;   format('  ✗ sudoku_validate.plt not found~n', [])
    ),
    
    (   catch(load_files('src/sudoku_solver.plt'), E2, true)
    ->  (var(E2) -> format('  ✓ sudoku_solver.plt loaded~n', []) 
                  ; format('  ✗ sudoku_solver.plt error: ~w~n', [E2]))
    ;   format('  ✗ sudoku_solver.plt not found~n', [])
    ),
    
    (   catch(load_files('src/sudoku_persistence.plt'), E3, true)
    ->  (var(E3) -> format('  ✓ sudoku_persistence.plt loaded~n', []) 
                  ; format('  ✗ sudoku_persistence.plt error: ~w~n', [E3]))
    ;   format('  ✗ sudoku_persistence.plt not found~n', [])
    ),
    
    (   catch(load_files('src/sudoku_game_flow.plt'), E4, true)
    ->  (var(E4) -> format('  ✓ sudoku_game_flow.plt loaded~n', []) 
                  ; format('  ✗ sudoku_game_flow.plt error: ~w~n', [E4]))
    ;   format('  ✗ sudoku_game_flow.plt not found~n', [])
    ),
    
    format('~nRunning tests...~n~n', []),
    
    %% Run all test suites
    run_tests([sudoku_validate, sudoku_solver, sudoku_persistence, sudoku_game_flow, sudoku_gui_practice]).

%% Main entry point
main :-
    run_all_tests,
    halt.

%% If run directly from command line
:- run_all_tests, halt.
