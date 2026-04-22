#!/usr/bin/env swipl
%% Test runner for Sudoku Solver project
%% Runs all plunit test suites

:- use_module(library(plunit)).
:- use_module(sudoku_gui).

%% GUI Practice Tests
:- begin_tests(sudoku_gui_practice).

test(mistakes) :-
    RawBoard = [
        ['a', 0, 0, 0, 0, 0, 0, 0, 0],
        [0, '15', 0, 0, 0, 0, 0, 0, 0],
        [0, 0, '3', 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0]
    ],
    Solution = [
        [7, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 7, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0]
    ],
    InitialSnapshot = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0]
    ],
    find_mistakes(RawBoard, Solution, InitialSnapshot, Mistakes),
    % Check if the errors are identified (Row, Col)
    member((1,1), Mistakes),
    member((2,2), Mistakes),
    member((3,3), Mistakes).

test(show_result) :-
    TimeStr = '00:10',
    ScorePercent = 50,
    Mistakes = [
        'Fila 1, Columna 1',
        'Fila 2, Columna 2'
    ],
    format(atom(MainMsg), 'Tiempo: ~w~nRendimiento: ~w%', [TimeStr, ScorePercent]),
    (   Mistakes = []
    ->  FinalMsg = MainMsg
    ;   Mistakes = [no_input]
    ->  concat(MainMsg, '\n\nSin ingresos realizados', FinalMsg)
    ;   length(Mistakes, NumErrors),
        format(atom(ErrMsg), '~n~nErrores (~d):~n', [NumErrors]),
        atomic_list_concat(Mistakes, '\n', AllErrors),
        concat(ErrMsg, AllErrors, FullErrMsg),
        concat(MainMsg, FullErrMsg, FinalMsg)
    ),
    % Basic check that FinalMsg contains the expected content
    sub_atom(FinalMsg, _, _, _, 'Tiempo: 00:10'),
    sub_atom(FinalMsg, _, _, _, 'Rendimiento: 50%'),
    sub_atom(FinalMsg, _, _, _, 'Errores (2):').

:- end_tests(sudoku_gui_practice).

%% Load all test modules and run tests
run_all_tests :-
    format('~n~n=== Running Sudoku Solver Test Suite ===~n~n', []),
    
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
    run_tests([sudoku_validate, sudoku_solver, sudoku_persistence, sudoku_gui_practice]).

%% Main entry point
main :-
    run_all_tests,
    halt.

%% If run directly from command line
:- run_all_tests, halt.
