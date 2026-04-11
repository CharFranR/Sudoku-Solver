:- module(sudoku_gui,
          [ open_gui/0,
            gui_read_board/3,
            gui_apply_solution/3,
            load_exercise/2
          ]).

:- use_module(library(pce)).
:- use_module(sudoku_solver).
:- use_module(sudoku_persistence).

cell_name(Prefix, Row, Col, NameAtom) :-
    atomic_list_concat([Prefix, '_cell_', Row, '_', Col], NameAtom).

cell_item(Dialog, Prefix, Row, Col, CellItem) :-
    cell_name(Prefix, Row, Col, NameAtom),
    get(Dialog, member, NameAtom, CellItem).

open_gui :-
    new(Dialog, dialog('Sudoku Solver')),
    send(Dialog, size, size(780, 580)),

    % === Grilla INPUT ===
    forall(between(1, 9, Row),
           forall(between(1, 9, Col),
                  create_cell(Dialog, input, Row, Col, 0))),
    draw_block_dividers(Dialog, 10, 40, 38, 0),

    % === Grilla RESULT ===
    forall(between(1, 9, Row),
           forall(between(1, 9, Col),
                  create_cell(Dialog, result, Row, Col, 400))),
    draw_block_dividers(Dialog, 10, 40, 38, 400),

    % Headers
    new(T1, text('Ingresar datos')),
    send(T1, font, font(pixels, bold, 14)),
    send(Dialog, display, T1, point(10, 10)),

    new(T2, text('Resultados')),
    send(T2, font, font(pixels, bold, 14)),
    send(Dialog, display, T2, point(410, 10)),

    % === Fila 1: Resolver + Limpiar ===
    BtnY = 405,
    send(Dialog, display, button('Resolver', message(@prolog, on_resolver_click, Dialog)), point(300, BtnY)),
    send(Dialog, display, button('Limpiar Todo', message(@prolog, on_clear_click, Dialog)), point(410, BtnY)),

    % === Fila 2: Ejercicios 1-5 ===
    ExY = 440,
    forall(between(1, 5, N),
           (  XX is 230 + (N - 1) * 65,
              send(Dialog, display, button(N, message(@prolog, load_exercise, Dialog, N)), point(XX, ExY))
           )),

    % === Fila 3: Puzzle (Easy/Med/Hard) ===
    PuY = 475,
    send(Dialog, display, new(TxtPu, text('Puzzle:')), point(175, PuY + 2)),
    send(TxtPu, font, font(pixels, bold, 12)),
    send(Dialog, display, button('Easy',   message(@prolog, on_new_puzzle_click, Dialog, easy)),   point(245, PuY)),
    send(Dialog, display, button('Medium', message(@prolog, on_new_puzzle_click, Dialog, medium)), point(325, PuY)),
    send(Dialog, display, button('Hard',   message(@prolog, on_new_puzzle_click, Dialog, hard)),   point(420, PuY)),

    % === Fila 4: Save + Open ===
    SvY = 510,
    send(Dialog, display, button('Save', message(@prolog, on_save_click, Dialog)), point(320, SvY)),
    send(Dialog, display, button('Open', message(@prolog, on_open_click, Dialog)), point(410, SvY)),

    % === Status bar ===
    StY = 545,
    new(StatusLabel, text_item(status_label, 'Listo')),
    send(StatusLabel, font, font(pixels, normal, 10)),
    send(StatusLabel, colour, colour(darkblue)),
    send(StatusLabel, editable, @off),
    send(StatusLabel, length, 50),
    send(Dialog, display, StatusLabel, point(10, StY)),

    send(Dialog, open, point(50, 50)).

%% create_cell(+Dialog, +Prefix, +Row, +Col, +OffsetX)
create_cell(Dialog, Prefix, Row, Col, OffsetX) :-
    cell_name(Prefix, Row, Col, NameAtom),
    new(CellItem, text_item(NameAtom, '')),
    send(CellItem, label, ''),
    send(CellItem, length, 1),
    send(CellItem, alignment, center),
    send(CellItem, size, size(34, 20)),
    send(CellItem, font, font(pixels, monospaced, 14)),
    get_row_y(Row, Y),
    get_col_x(Col, XBase),
    X is XBase + OffsetX,
    send(Dialog, display, CellItem, point(X, Y)).

get_row_y(Row, Y) :-
    Y is (Row - 1) * 38 + 40.

get_col_x(Col, X) :-
    X is (Col - 1) * 38 + 10.

%% draw_block_dividers(+Dialog, +OriginX, +OriginY, +Step, +OffsetX)
draw_block_dividers(Dialog, OX, OY, Step, OffX) :-
    VX1 is OX + 3 * Step - 2 + OffX,
    VX2 is OX + 6 * Step - 2 + OffX,
    VEnd is OY + 9 * Step,
    draw_line(Dialog, VX1, OY, VX1, VEnd),
    draw_line(Dialog, VX2, OY, VX2, VEnd),
    HY1 is OY + 3 * Step - 2,
    HY2 is OY + 6 * Step - 2,
    HEnd is OX + 9 * Step + OffX,
    draw_line(Dialog, OX + OffX, HY1, HEnd, HY1),
    draw_line(Dialog, OX + OffX, HY2, HEnd, HY2).

draw_line(Parent, X1, Y1, X2, Y2) :-
    new(L, line(X1, Y1, X2, Y2)),
    send(L, pen, 2),
    send(L, colour, colour('#666666')),
    send(Parent, display, L).

% Limpia la grilla result (establece todas las celdas a vacío).
clear_result_grid(Dialog) :-
    Prefix = result,
    forall(between(1, 9, Row),
           forall(between(1, 9, Col),
                  ( cell_item(Dialog, Prefix, Row, Col, CellItem),
                    send(CellItem, selection, '')
                  ))).

% Limpia la grilla input (establece todas las celdas a vacío).
clear_input_grid(Dialog) :-
    Prefix = input,
    forall(between(1, 9, Row),
           forall(between(1, 9, Col),
                  ( cell_item(Dialog, Prefix, Row, Col, CellItem),
                    send(CellItem, selection, '')
                  ))).

% Handler del botón Limpiar Todo: limpia ambas grillas (input y result).
on_clear_click(Dialog) :-
    clear_input_grid(Dialog),
    clear_result_grid(Dialog).

% Handler del botón Resolver: lee, resuelve y actualiza la grilla.
on_resolver_click(Dialog) :-
    clear_result_grid(Dialog),
    catch(
        (   gui_read_board(Dialog, Board, GivenMask),
            solve_status(Board, Status, Solution),
            handle_status(Dialog, Status, Solution, GivenMask)
        ),
        Error,
        (   format(atom(Msg), 'Error: ~w', [Error]),
            send(@display, inform, Msg)
        )
    ).

% Muestra el mensaje correspondiente y aplica la solución si corresponde.
handle_status(Dialog, solved, Solution, GivenMask) :-
    !,
    send(@display, inform, '¡Sudoku resuelto! Completando celdas vacías.'),
    gui_apply_solution(Dialog, GivenMask, Solution).
handle_status(_Dialog, already_solved, _Solution, _GivenMask) :-
    !,
    send(@display, inform, 'El puzzle ya está resuelto.').
handle_status(_Dialog, no_solution, _Solution, _GivenMask) :-
    !,
    send(@display, inform, 'Sin solución: el puzzle no tiene solución válida.').
handle_status(Dialog, multiple_solutions, Solution, GivenMask) :-
    !,
    send(@display, inform, 'No único: hay múltiples soluciones. Mostrando una.'),
    gui_apply_solution(Dialog, GivenMask, Solution).
handle_status(_Dialog, invalid_input(Reason), _Solution, _GivenMask) :-
    !,
    format(atom(Msg), 'Input inválido: ~w', [Reason]),
    send(@display, inform, Msg).
handle_status(_Dialog, inconsistent(Reason), _Solution, _GivenMask) :-
    !,
    format(atom(Msg), 'Puzzle inconsistente: ~w', [Reason]),
    send(@display, inform, Msg).

% Lee la grilla XPCE y produce el Board (0..9) y una máscara de pistas.
gui_read_board(Dialog, Board, GivenMask) :-
    Prefix = input,
    findall(RowCells,
            ( between(1, 9, Row),
              read_row(Dialog, Prefix, Row, RowCells, _RowMask)
            ),
            Board),
    findall(RowMask,
            ( between(1, 9, Row),
              read_row(Dialog, Prefix, Row, _RowCells, RowMask)
            ),
            GivenMask).

read_row(Dialog, Prefix, Row, RowCells, RowMask) :-
    findall(Cell,
            ( between(1, 9, Col),
              read_cell(Dialog, Prefix, Row, Col, Cell, _Clue)
            ),
            RowCells),
    findall(Clue,
            ( between(1, 9, Col),
              read_cell(Dialog, Prefix, Row, Col, _Cell, Clue)
            ),
            RowMask).

read_cell(Dialog, Prefix, Row, Col, Cell, Clue) :-
    cell_item(Dialog, Prefix, Row, Col, CellItem),
    get(CellItem, selection, Sel0),
    (   Sel0 == @nil
    ->  Sel = ''
    ;   atomic(Sel0)
    ->  Sel = Sel0
    ;   ( catch(get(Sel0, value, Sel), _, Sel = Sel0)
        -> true
        ;  Sel = Sel0
        )
    ),
    (   ( Sel == '' ; Sel == "" ; Sel == '0' )
    ->  Cell = 0,
        Clue = false
    ;   atom(Sel),
        atom_number(Sel, N),
        N >= 1, N =< 9
    ->  Cell = N,
        Clue = true
    ;   throw(invalid_cell(Row, Col, Sel0))
    ).

% Aplica la solución a la grilla result.
gui_apply_solution(Dialog, _GivenMask, Solution) :-
    Prefix = result,
    forall(between(1, 9, Row),
           forall(between(1, 9, Col),
                  ( nth1(Row, Solution, SolRow),
                    nth1(Col, SolRow, Val),
                    cell_item(Dialog, Prefix, Row, Col, CellItem),
                    number_string(Val, S),
                    send(CellItem, selection, S)
                  ))).

% === Handler para cargar ejercicios predefinidos ===
load_exercise(Dialog, N) :-
    clear_input_grid(Dialog),
    clear_result_grid(Dialog),
    exercise(N, Board),
    forall( ( nth1(Row, Board, RowList),
            nth1(Col, RowList, Val),
            Val > 0
          ),
          ( cell_item(Dialog, input, Row, Col, CellItem),
            number_string(Val, S),
            send(CellItem, selection, S)
          )).

% === Handler para Nuevo Puzzle ===
on_new_puzzle_click(Dialog, Difficulty) :-
    generate_puzzle(Difficulty, Puzzle),
    clear_input_grid(Dialog),
    clear_result_grid(Dialog),
    forall( ( nth1(Row, Puzzle, RowList),
            nth1(Col, RowList, Val),
            Val > 0
          ),
          ( cell_item(Dialog, input, Row, Col, CellItem),
            number_string(Val, S),
            send(CellItem, selection, S)
          )).

% === Handlers para Save y Open ===
on_save_click(Dialog) :-
    catch(
        (   gui_read_board(Dialog, Board, _GivenMask),
            new(FileDialog, file_dialog(save)),
            send(FileDialog, transient_for, Dialog),
            get(FileDialog, confirm, PathAtom),
            nonvar(PathAtom),
            atom_string(PathString, PathAtom),
            board_to_file(Board, PathString),
            update_status(Dialog, 'Board saved', darkgreen)
        ),
        Error,
        (   format(atom(Msg), 'Error: ~w', [Error]),
            update_status(Dialog, Msg, darkred)
        )
    ).

on_open_click(Dialog) :-
    catch(
        (   new(FileDialog, file_dialog(open)),
            send(FileDialog, transient_for, Dialog),
            get(FileDialog, confirm, PathAtom),
            nonvar(PathAtom),
            atom_string(PathString, PathAtom),
            file_to_board(PathString, Board),
            clear_input_grid(Dialog),
            clear_result_grid(Dialog),
            forall( ( nth1(Row, Board, RowList),
                    nth1(Col, RowList, Val)
                  ),
                  ( Val > 0
                  ->  cell_item(Dialog, input, Row, Col, CellItem),
                      number_string(Val, S),
                      send(CellItem, selection, S)
                  ;   true
                  )
            ),
            update_status(Dialog, 'Board loaded', darkgreen)
        ),
        Error,
        (   format(atom(Msg), 'Error: ~w', [Error]),
            update_status(Dialog, Msg, darkred)
        )
    ).

update_status(Dialog, Message, Colour) :-
    get(Dialog, member, status_label, StatusLabel),
    send(StatusLabel, selection, Message),
    send(StatusLabel, colour, Colour).
