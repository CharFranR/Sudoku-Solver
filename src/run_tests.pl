#!/usr/bin/env swipl
%% Test runner for Sudoku Solver project
%% Runs all plunit test suites

:- use_module(library(plunit)).
:- use_module(library(pce)).
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

%% Helpers for GUI handler regression tests
cell_name(Prefix, Row, Col, NameAtom) :-
    atomic_list_concat([Prefix, '_cell_', Row, '_', Col], NameAtom).

create_test_dialog(Dialog) :-
    new(Dialog, dialog('GUI Handler Test')),
    forall(between(1, 9, Row),
           forall(between(1, 9, Col),
                  ( cell_name(input, Row, Col, InName),
                    new(InCell, text_item(InName, '')),
                    send(InCell, label, ''),
                    send(Dialog, append, InCell),
                    cell_name(result, Row, Col, OutName),
                    new(OutCell, text_item(OutName, '')),
                    send(OutCell, label, ''),
                    send(Dialog, append, OutCell)
                  ))),
    new(StatusLabel, text_item(status_label, '')),
    send(StatusLabel, label, ''),
    send(StatusLabel, editable, @off),
    send(Dialog, append, StatusLabel).

create_practice_controls_dialog(Dialog) :-
    create_test_dialog(Dialog),
    send(Dialog, display, button('Resolver', message(@prolog, true)), point(10, 10)),
    send(Dialog, display, button('Limpiar Todo', message(@prolog, true)), point(10, 10)),
    send(Dialog, display, button('Practicar', message(@prolog, true)), point(10, 10)),
    send(Dialog, display, button('Save', message(@prolog, true)), point(10, 10)),
    send(Dialog, display, button('Open', message(@prolog, true)), point(10, 10)),
    send(Dialog, display, button('Easy', message(@prolog, true)), point(10, 10)),
    send(Dialog, display, button('Medium', message(@prolog, true)), point(10, 10)),
    send(Dialog, display, button('Hard', message(@prolog, true)), point(10, 10)),
    forall(between(1, 5, N),
           send(Dialog, display, button(N, message(@prolog, true)), point(10, 10))),
    send(Dialog, display, new(LblEx, text('Ejercicios:')), point(10, 10)),
    send(LblEx, name, 'EjerciciosLabel'),
    send(Dialog, display, new(LblNew, text('Nuevo Puzzle:')), point(10, 10)),
    send(LblNew, name, 'NuevoPuzzleLabel'),
    send(Dialog, display, new(LblInput, text('Custom input title')), point(10, 10)),
    send(LblInput, name, 'IngresarLabel'),
    send(Dialog, display, new(LblResult, text('Custom result title')), point(10, 10)),
    send(LblResult, name, 'ResultadosLabel'),
    send(Dialog, display, button('Comprobar', message(@prolog, true)), point(10, 10)),
    send(Dialog, display, button('Volver', message(@prolog, true)), point(10, 10)),
    send(Dialog, display, new(PracticeTimer, text_item(practice_timer, '00:00')), point(10, 10)),
    send(PracticeTimer, displayed, @off).

dialog_cell_value(Dialog, Prefix, Row, Col, Value) :-
    cell_name(Prefix, Row, Col, NameAtom),
    get(Dialog, member, NameAtom, CellItem),
    get(CellItem, selection, Sel0),
    (   Sel0 == @nil
    ->  Value = 0
    ;   Sel0 == ''
    ->  Value = 0
    ;   atom(Sel0)
    ->  atom_number(Sel0, Value)
    ;   string(Sel0)
    ->  number_string(Value, Sel0)
    ;   catch(get(Sel0, value, RawVal), _, RawVal = ''),
        (   RawVal == ''
        ->  Value = 0
        ;   atom(RawVal)
        ->  atom_number(RawVal, Value)
        ;   number_string(Value, RawVal)
        )
    ).

assert_grid_matches_board(Dialog, Prefix, Board) :-
    forall((between(1, 9, Row), between(1, 9, Col)),
           ( nth1(Row, Board, BoardRow),
             nth1(Col, BoardRow, Expected),
             dialog_cell_value(Dialog, Prefix, Row, Col, Actual),
             Actual =:= Expected
           )).

assert_grid_empty(Dialog, Prefix) :-
    forall((between(1, 9, Row), between(1, 9, Col)),
           ( dialog_cell_value(Dialog, Prefix, Row, Col, Value),
             Value =:= 0
           )).

dialog_board(Dialog, Prefix, Board) :-
    findall(RowCells,
            ( between(1, 9, Row),
              findall(Cell,
                      ( between(1, 9, Col),
                        dialog_cell_value(Dialog, Prefix, Row, Col, Cell)
                      ),
                      RowCells)
            ),
            Board).

clue_count(Board, Count) :-
    flatten(Board, Cells),
    exclude(==(0), Cells, Clues),
    length(Clues, Count).

assert_displayed(Dialog, MemberName, Expected) :-
    get(Dialog, member, MemberName, Item),
    get(Item, displayed, Actual),
    Actual == Expected.

%% GUI Load/Generate Tests - directly exercise GUI handlers
:- begin_tests(sudoku_gui_load).

test(load_exercise_handler_populates_input_grid,
     [setup(create_test_dialog(Dialog)), cleanup(send(Dialog, destroy))]) :-
    exercise(1, ExpectedBoard),
    load_exercise(Dialog, 1),
    assert_grid_matches_board(Dialog, input, ExpectedBoard),
    assert_grid_empty(Dialog, result).

test(on_new_puzzle_click_handler_generates_easy_puzzle,
     [setup(create_test_dialog(Dialog)), cleanup(send(Dialog, destroy))]) :-
    % Baseline: dirty result grid so we verify the handler clears it.
    cell_name(result, 1, 1, ResultName),
    get(Dialog, member, ResultName, ResultCell),
    send(ResultCell, selection, '9'),

    sudoku_gui:on_new_puzzle_click(Dialog, easy),

    dialog_board(Dialog, input, Puzzle),
    length(Puzzle, 9),
    forall(member(Row, Puzzle),
           (is_list(Row), length(Row, 9))),
    forall(member(Row, Puzzle),
           forall(member(Cell, Row), (integer(Cell), Cell >= 0, Cell =< 9))),
    clue_count(Puzzle, NumClues),
    NumClues >= 35, NumClues =< 40,
    assert_grid_empty(Dialog, result).

test(practice_controls_toggle_uses_named_labels,
     [setup(create_practice_controls_dialog(Dialog)), cleanup(send(Dialog, destroy))]) :-
    sudoku_gui:show_practice_controls(Dialog),
    assert_displayed(Dialog, 'IngresarLabel', @off),
    assert_displayed(Dialog, 'ResultadosLabel', @off),
    assert_displayed(Dialog, 'Comprobar', @on),
    assert_displayed(Dialog, 'Volver', @on),
    assert_displayed(Dialog, practice_timer, @on),

    sudoku_gui:hide_practice_controls(Dialog),
    assert_displayed(Dialog, 'IngresarLabel', @on),
    assert_displayed(Dialog, 'ResultadosLabel', @on),
    assert_displayed(Dialog, 'Comprobar', @off),
    assert_displayed(Dialog, 'Volver', @off),
    assert_displayed(Dialog, practice_timer, @off).

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
