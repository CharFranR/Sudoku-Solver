#!/usr/bin/env swipl
%% Test runner for Sudoku Solver project
%% Runs all plunit test suites

:- use_module(library(plunit)).
:- use_module(sudoku_solver).
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

%% GUI Score Tests - calculate_score/4
:- begin_tests(sudoku_gui_score).

test(score_no_empty_cells) :-
    % Fully solved board with no empty cells
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
    % TotalEmpty = 0 should return 0%, not fail
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
    % All correct = 100%
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

:- end_tests(sudoku_gui_score).

%% GUI Load/Generate Tests - ensure load_exercise and on_new_puzzle_click work
:- begin_tests(sudoku_gui_load).

test(load_exercise_returns_valid_board) :-
    % exercise/1 should return a valid 9x9 board with some clues
    exercise(1, Board),
    is_list(Board),
    length(Board, 9),
    forall(member(Row, Board),
           (is_list(Row), length(Row, 9))),
    % Board should have valid values 0-9
    forall(member(Row, Board),
           forall(member(Cell, Row),
                  (integer(Cell), Cell >= 0, Cell =< 9))).

test(generate_puzzle_returns_valid) :-
    % generate_puzzle/2 should return a valid puzzle
    generate_puzzle(easy, Puzzle),
    is_list(Puzzle),
    length(Puzzle, 9),
    forall(member(Row, Puzzle),
           (is_list(Row), length(Row, 9))),
    % Should have between 35-40 clues for easy
    flatten(Puzzle, Cells),
    exclude(==(0), Cells, Clues),
    length(Clues, NumClues),
    NumClues >= 35, NumClues =< 40.

:- end_tests(sudoku_gui_load).
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
    run_tests([sudoku_validate, sudoku_solver, sudoku_persistence, sudoku_gui_practice, sudoku_gui_score, sudoku_gui_load]).

%% Main entry point
main :-
    run_all_tests,
    halt.

%% If run directly from command line
:- run_all_tests, halt.
