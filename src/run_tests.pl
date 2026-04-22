#!/usr/bin/env swipl
%% Test runner for Sudoku Solver project
%% Runs all plunit test suites

:- use_module(library(plunit)).

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
    
    format('~nRunning tests...~n~n', []),
    
    %% Run all test suites
    run_tests([sudoku_validate, sudoku_solver, sudoku_persistence]).

%% Main entry point
main :-
    run_all_tests,
    halt.

%% If run directly from command line
:- run_all_tests, halt.
