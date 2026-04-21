:- module(sudoku_gui,
          [ open_gui/0,
            gui_read_board/3,
            gui_read_board_raw/2,
            gui_apply_solution/3,
            load_exercise/2,
            practice_state/3,
            find_mistakes/4,
            mistake_to_string/2,
            format_elapsed_time/2,
            calculate_score/4
          ]).

:- use_module(library(pce)).
:- use_module(sudoku_solver).
:- use_module(sudoku_persistence).
:- use_module(sudoku_validate).

:- dynamic(practice_state/3).

% Windows XPCE Font Rendering Fix
:- initialization(fix_pce_fonts).
fix_pce_fonts :-
    (   current_prolog_flag(windows, true)
    ->  send(@pce, send_method, send_method(alias_font, vector(name, font), 
            message(@receiver, font, @arg1, @arg2))), % placeholder
        % We will just use the correct font object on Windows during creation or ignore missing alias
        true
    ;   true
    ).

cell_name(Prefix, Row, Col, NameAtom) :-
    atomic_list_concat([Prefix, '_cell_', Row, '_', Col], NameAtom).

cell_item(Dialog, Prefix, Row, Col, CellItem) :-
    cell_name(Prefix, Row, Col, NameAtom),
    get(Dialog, member, NameAtom, CellItem).

open_gui :-
    new(Dialog, dialog('Sudoku Solver')),
    send(Dialog, size, size(780, 500)),

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
    send(T1, font, font(helvetica, bold, 14)),
    send(Dialog, display, T1, point(10, 10)),

    new(T2, text('Resultados')),
    send(T2, font, font(helvetica, bold, 14)),
    send(Dialog, display, T2, point(410, 10)),

    % === PANEL DE BOTONES ===
    Row1Y = 410,

    % --- Izquierda: Ejercicios ---
    send(Dialog, display, new(LblEx, text('Ejercicios:')), point(10, Row1Y)),
    send(LblEx, font, font(helvetica, bold, 12)),
    forall(between(1, 5, N),
           (  XX is 100 + (N - 1) * 55,
              send(Dialog, display, button(N, message(@prolog, load_exercise, Dialog, N)), point(XX, Row1Y))
           )),

    % --- Derecha: Nuevo Puzzle ---
    send(Dialog, display, new(LblPu, text('Nuevo Puzzle:')), point(420, Row1Y)),
    send(LblPu, font, font(helvetica, bold, 12)),
    send(Dialog, display, button('Easy',   message(@prolog, on_new_puzzle_click, Dialog, easy)),   point(540, Row1Y)),
    send(Dialog, display, button('Medium', message(@prolog, on_new_puzzle_click, Dialog, medium)), point(620, Row1Y)),
    send(Dialog, display, button('Hard',   message(@prolog, on_new_puzzle_click, Dialog, hard)),   point(715, Row1Y)),

    % --- Fila inferior: Status a la izquierda, botones a la derecha ---
    Row2Y = 450,
    new(StatusLabel, text_item(status_label, 'Listo')),
    send(StatusLabel, font, font(helvetica, normal, 10)),
    send(StatusLabel, colour, colour(darkblue)),
    send(StatusLabel, editable, @off),
    send(StatusLabel, length, 25),
    send(Dialog, display, StatusLabel, point(10, Row2Y)),

    send(Dialog, display, button('Resolver', message(@prolog, on_resolver_click, Dialog)), point(300, Row2Y)),
    send(Dialog, display, button('Limpiar Todo', message(@prolog, on_clear_click, Dialog)), point(380, Row2Y)),
    send(Dialog, display, button('Practicar', message(@prolog, on_practice_click, Dialog)), point(480, Row2Y)),
    send(Dialog, display, button('Save', message(@prolog, on_save_click, Dialog)), point(560, Row2Y)),
    send(Dialog, display, button('Open', message(@prolog, on_open_click, Dialog)), point(620, Row2Y)),
    send(Dialog, display, button('Salir', message(@prolog, on_exit_click, Dialog)), point(680, Row2Y)),

    % === Practice Mode Controls (hidden initially) ===
    send(Dialog, display, new(PracticeTimer, text_item(practice_timer, '00:00')), point(480, Row2Y)),
    send(PracticeTimer, label, ''),
    send(PracticeTimer, font, font(helvetica, monospaced, 12)),
    send(PracticeTimer, editable, @off),
    send(PracticeTimer, length, 6),
    send(PracticeTimer, displayed, @off),

    send(Dialog, display, button('Comprobar', message(@prolog, on_comprobar_click, Dialog)), point(545, Row2Y)),
    send(Dialog, display, button('Volver', message(@prolog, on_return_click, Dialog)), point(615, Row2Y)),

    % Ocultar botones de practice inicialmente
    get(Dialog, member, practice_timer, PracticeTimer),
    send(PracticeTimer, displayed, @off),
    get(Dialog, member, practice_timer, PracticeTimer),  % noqa: F841
    (   get(Dialog, member, 'Comprobar', BtnComprobar)
    ->  send(BtnComprobar, displayed, @off)
    ;   true
    ),
    (   get(Dialog, member, 'Volver', BtnVolver)
    ->  send(BtnVolver, displayed, @off)
    ;   true
    ),

    send(Dialog, open, point(50, 50)).

%% create_cell(+Dialog, +Prefix, +Row, +Col, +OffsetX)
create_cell(Dialog, Prefix, Row, Col, OffsetX) :-
    cell_name(Prefix, Row, Col, NameAtom),
    new(CellItem, text_item(NameAtom, '')),
    send(CellItem, label, ''),
    send(CellItem, length, 1),
    send(CellItem, alignment, center),
    send(CellItem, size, size(34, 20)),
    send(CellItem, font, font(helvetica, monospaced, 14)),
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
    send(L, pen, 3),
    send(L, colour, colour(black)),
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

% Actualiza el mensaje de estado en la barra interior.
update_status(Dialog, Message) :-
    get(Dialog, member, status_label, StatusLabel),
    send(StatusLabel, selection, Message).

% Handler del botón Limpiar Todo: limpia ambas grillas (input y result).
on_clear_click(Dialog) :-
    clear_input_grid(Dialog),
    clear_result_grid(Dialog),
    update_status(Dialog, '').

% Handler del botón Salir
on_exit_click(Dialog) :-
    send(Dialog, destroy).

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
            update_status(Dialog, Msg)
        )
    ).

% Muestra el mensaje correspondiente y aplica la solución si corresponde.
handle_status(Dialog, solved, Solution, GivenMask) :-
    !,
    update_status(Dialog, '¡Sudoku resuelto! Completando celdas vacías.'),
    gui_apply_solution(Dialog, GivenMask, Solution).
handle_status(Dialog, already_solved, _Solution, _GivenMask) :-
    !,
    update_status(Dialog, 'El puzzle ya está resuelto.').
handle_status(Dialog, no_solution, _Solution, _GivenMask) :-
    % No existe solución consistente.
    !,
    update_status(Dialog, 'Sin solución: el puzzle no tiene solución válida.').
handle_status(Dialog, multiple_solutions, Solution, GivenMask) :-
    !,
    update_status(Dialog, 'No único: hay múltiples soluciones. Mostrando una.'),
    gui_apply_solution(Dialog, GivenMask, Solution).
handle_status(Dialog, invalid_input(Reason), _Solution, _GivenMask) :-
    !,
    format(atom(Msg), 'Input inválido: ~w', [Reason]),
    update_status(Dialog, Msg).
handle_status(Dialog, inconsistent(Reason), _Solution, _GivenMask) :-
    % El tablero viola restricciones (duplicados iniciales).
    !,
    format(atom(Msg), 'Puzzle inconsistente: ~w', [Reason]),
    update_status(Dialog, Msg).

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

% Lee la grilla XPCE y produce el RawBoard con el texto exacto que el usuario ingresó.
% RawBoard contiene los átomos/strings sin conversión a números (excepto 0 para vacío).
gui_read_board_raw(Dialog, RawBoard) :-
    Prefix = input,
    findall(RowCells,
            ( between(1, 9, Row),
              read_row_raw(Dialog, Prefix, Row, RowCells)
            ),
            RawBoard).

read_row_raw(Dialog, Prefix, Row, RowCells) :-
    findall(Cell,
            ( between(1, 9, Col),
              read_cell_raw(Dialog, Prefix, Row, Col, Cell)
            ),
            RowCells).

% Lee la celda sin convertir a número - devuelve el texto exacto del usuario.
% cell puede ser: '' (vacío), '0', un átomo con número (ej '5'), o un átomo no-numérico (ej 'a')
read_cell_raw(Dialog, Prefix, Row, Col, Cell) :-
    cell_item(Dialog, Prefix, Row, Col, CellItem),
    get(CellItem, selection, Sel0),
    (   Sel0 == @nil
    ->  Cell = ''
    ;   atomic(Sel0)
    ->  Cell = Sel0
    ;   ( catch(get(Sel0, value, Sel), _, Sel = Sel0)
        -> true
        ;   Sel = Sel0
        ),
        Cell = Sel
    ).

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
    ;   Cell = 0,
        Clue = false
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
    update_status(Dialog, ''),
    % Obtiene el tablero del ejercicio N.
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

%% ask_file_path(+Dialog, +Mode, -PathString)
%  Abre un dialogo XPCE para ingresar un path de archivo.
%  Mode = save | open. Devuelve PathString o falla si el usuario cancela.
ask_file_path(Dialog, Mode, PathString) :-
    (Mode == save -> Title = 'Guardar tablero' ; Title = 'Abrir tablero'),
    new(D, dialog(Title)),
    send(D, append, new(TI, text_item(filename, ''))),
    send(TI, length, 40),
    send(D, append, button(ok, message(D, return, TI?selection))),
    send(D, append, button(cancelar, message(D, return, @nil))),
    send(D, default_button, ok),
    send(D, transient_for, Dialog),
    get(D, confirm_centered, Result),
    send(D, destroy),
    Result \== @nil,
    atom_string(Result, PathString),
    PathString \== ''.

on_save_click(Dialog) :-
    catch(
        (   gui_read_board(Dialog, Board, _GivenMask),
            ask_file_path(Dialog, save, PathString),
            board_to_file(Board, PathString),
            format(atom(Msg), 'Tablero guardado: ~w', [PathString]),
            update_status(Dialog, Msg, darkgreen)
        ),
        Error,
        (   format(atom(Msg), 'Error: ~w', [Error]),
            update_status(Dialog, Msg, darkred)
        )
    ).

on_open_click(Dialog) :-
    catch(
        (   ask_file_path(Dialog, open, PathString),
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
            format(atom(Msg), 'Tablero cargado: ~w', [PathString]),
            update_status(Dialog, Msg, darkgreen)
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

% ============================================================
% Practice Mode Handlers
% ============================================================

%% on_practice_click(+Dialog)
% Maneja el click en botón "Practicar".
% Verifica que haya al menos 17 pistas antes de iniciar.
on_practice_click(Dialog) :-
    gui_read_board(Dialog, Board, _GivenMask),
    count_clues(Board, ClueCount),
    (   ClueCount < 17
    ->  show_error_dialog(Dialog, 'Se requieren 17 pistas como minimo para usar esta opcion')
    ;   start_practice_mode(Dialog, Board)
    ).

%% count_clues(+Board, -Count)
% Cuenta la cantidad de pistas (celdas no vacías) en el tablero.
count_clues(Board, Count) :-
    flatten(Board, Cells),
    exclude(==(0), Cells, Clues),
    length(Clues, Count).

%% start_practice_mode(+Dialog, +Board)
% Inicia el modo practice: bloquear celdas iniciales,
% guardar snapshot, mostrar controles de practice.
% Ahora con timer simplificado - solo guarda timestamp, sin UI polling.
start_practice_mode(Dialog, Board) :-
    % Guardar snapshot inicial y timestamp de inicio
    duplicate_term(Board, InitialSnapshot),
    get_time(StartTime),
    asserta(practice_state(practice, InitialSnapshot, StartTime)),

    % Bloquear celdas iniciales (given)
    lock_given_cells(Dialog, Board),

    % Mostrar controles de practice
    show_practice_controls(Dialog),

    update_status(Dialog, 'Modo Practice: Completa el Sudoku y presiona Comprobar').

%% lock_given_cells(+Dialog, +Board)
% Bloquea las celdas que tienen pistas (no son editables).
lock_given_cells(Dialog, Board) :-
    forall( ( between(1, 9, Row),
             between(1, 9, Col),
             nth1(Row, Board, RowList),
             nth1(Col, RowList, Val),
             Val > 0
           ),
           ( cell_item(Dialog, input, Row, Col, CellItem),
             send(CellItem, editable, @off)
           )).

%% show_practice_controls(+Dialog)
% Oculta controles normales y muestra los de practice.
show_practice_controls(Dialog) :-
    % Ocultar botones normales
    (   get(Dialog, member, 'Resolver', BtnResolver)
    ->  send(BtnResolver, displayed, @off)
    ;   true
    ),
    (   get(Dialog, member, 'Limpiar Todo', BtnLimpiar)
    ->  send(BtnLimpiar, displayed, @off)
    ;   true
    ),
    (   get(Dialog, member, 'Practicar', BtnPracticar)
    ->  send(BtnPracticar, displayed, @off)
    ;   true
    ),
    (   get(Dialog, member, 'Save', BtnSave)
    ->  send(BtnSave, displayed, @off)
    ;   true
    ),
    (   get(Dialog, member, 'Open', BtnOpen)
    ->  send(BtnOpen, displayed, @off)
    ;   true
    ),
    (   get(Dialog, member, 'Easy', BtnEasy)
    ->  send(BtnEasy, displayed, @off)
    ;   true
    ),
    (   get(Dialog, member, 'Medium', BtnMedium)
    ->  send(BtnMedium, displayed, @off)
    ;   true
    ),
    (   get(Dialog, member, 'Hard', BtnHard)
    ->  send(BtnHard, displayed, @off)
    ;   true
    ),

    % Ocultar labels de ejercicios
    (   get(Dialog, member, 'Ejercicios', LblEjercicios)
    ->  send(LblEjercicios, displayed, @off)
    ;   true
    ),
    (   get(Dialog, member, 'Nuevo Puzzle', LblNuevo)
    ->  send(LblNuevo, displayed, @off)
    ;   true
    ),
    (   get(Dialog, member, 'Ingresar datos', LblInput)
    ->  send(LblInput, displayed, @off)
    ;   true
    ),
    (   get(Dialog, member, 'Resultados', LblResult)
    ->  send(LblResult, displayed, @off)
    ;   true
    ),

    % Ocultar botones de ejercicios
    forall(between(1, 5, N), hide_exercise_button(Dialog, N)),

    % Mostrar controles de practice (sin timer UI - solo background timestamp)
    (   get(Dialog, member, 'Comprobar', BtnComprobar)
    ->  send(BtnComprobar, displayed, @on)
    ;   true
    ),
    (   get(Dialog, member, 'Volver', BtnVolver)
    ->  send(BtnVolver, displayed, @on)
    ;   true
    ).

hide_exercise_button(Dialog, N) :-
    (   get(Dialog, member, N, Btn)
    ->  send(Btn, displayed, @off)
    ;   true
    ).

%% on_comprobar_click(+Dialog)
% Maneja el botón "Comprobar":
% calcular tiempo, score, encontrar errores y mostrar resultado en popup.
on_comprobar_click(Dialog) :-
    practice_state(practice, InitialSnapshot, StartTime),

    % Obtener tiempo actual y calcular elapsed
    get_time(CurrentTime),
    Elapsed is round(CurrentTime - StartTime),
    format_elapsed_time(Elapsed, TimeStr),

    % Resolver el puzzle inicial para obtener solución
    solve_status(InitialSnapshot, SolverStatus, Solution),

    % Leer el tablero RAW del usuario (texto exacto)
    gui_read_board_raw(Dialog, RawBoard),

    % Calcular score (solo celdas originalmente vacías)
    % Primero necesitamos el board normalizado para el score
    gui_read_board(Dialog, UserBoard, _GivenMask),
    calculate_score(UserBoard, Solution, InitialSnapshot, ScorePercent),

    % Encontrar errores usando RawBoard vs Solution vs InitialSnapshot
    find_mistakes(RawBoard, Solution, InitialSnapshot, Mistakes),

    % Mostrar resultado en popup
    show_comprobar_result(Dialog, TimeStr, ScorePercent, Mistakes, SolverStatus, Solution).

%% format_elapsed_time(+Seconds, -TimeStr)
% Formatea segundos a string MM:SS
format_elapsed_time(Seconds, TimeStr) :-
    Minutes is Seconds // 60,
    Secs is Seconds mod 60,
    % Format with leading zeros
    (   Minutes < 10
    ->  format(atom(MinStr), '0~d', [Minutes])
    ;   format(atom(MinStr), '~d', [Minutes])
    ),
    (   Secs < 10
    ->  format(atom(SecStr), '0~d', [Secs])
    ;   format(atom(SecStr), '~d', [Secs])
    ),
    atomic_list_concat([MinStr, SecStr], ':', TimeStr).

%% find_mistakes(+RawBoard, +Solution, +InitialSnapshot, -Mistakes)
% Encuentra errores en la entrada del usuario comparando RawBoard contra Solution e InitialSnapshot.
% Tipos de errores:
%   mistake(invalid_char, Row, Col) - el caracter no es un número
%   mistake(invalid_number, Row, Col) - el número no está en rango 1-9
%   mistake(wrong_number, Row, Col, N) - el número es válido pero incorrecto
%   no_input - no se ingresó ningún valor nuevo
find_mistakes(RawBoard, Solution, InitialSnapshot, Mistakes) :-
    % Verificar si hay algún input nuevo EN CELDSAS QUE ESTABAN VACÍAS
    find_new_inputs(RawBoard, InitialSnapshot, HasNewInput),
    (   HasNewInput == no
    ->  Mistakes = [no_input]
    ;   find_mistakes_rec(RawBoard, Solution, InitialSnapshot, 1, 1, [], RawMistakes),
        (   RawMistakes = []
        ->  Mistakes = []  % Todo correcto
        ;   maplist(mistake_to_string, RawMistakes, Mistakes)
        )
    ).

%% find_new_inputs(+RawBoard, +InitialSnapshot, -HasNewInput)
% Verifica si el usuario agregó algún valor nuevo en celdas que estaban vacías.
% NOTA: Si el usuario MODIFICÓ una celda que ya tenía pistas (InitialVal > 0),
% eso cuenta como "new input" porque el valor cambió.
find_new_inputs(RawBoard, InitialSnapshot, HasNewInput) :-
    find_new_inputs_rec(RawBoard, InitialSnapshot, 1, 1, HasNewInput).

find_new_inputs_rec([], [], _Row, _Col, no) :- !.
find_new_inputs_rec([RowB|RestB], [RowS|RestS], Row, 1, HasNewInput) :- !,
    find_new_inputs_row(RowB, RowS, Row, 1, HasNewInputOrCont),
    (   HasNewInputOrCont = yes
    ->  HasNewInput = yes
    ;   NextRow is Row + 1,
        find_new_inputs_rec(RestB, RestS, NextRow, 1, HasNewInput)
    ).
find_new_inputs_rec([_|RestB], [_|RestS], Row, Col, HasNewInput) :-
    NextCol is Col + 1,
    find_new_inputs_rec(RestB, RestS, Row, NextCol, HasNewInput).

find_new_inputs_row([], [], _Row, _Col, no) :- !.
find_new_inputs_row([RawVal|RestU], [InitVal|RestS], Row, Col, HasNewInput) :-
    % Una celda cuenta como "new input" si:
    % 1. Estaba vacía inicialmente (InitVal = 0) Y ahora tiene algo, O
    % 2. Tenía un valor inicialmente (InitVal > 0) Y el usuario lo cambió
    (   InitVal = 0
    ->  % Celda estaba vacía - ver si ahora tiene algo
        (   RawVal = '' ; RawVal = '0' ; RawVal = 0
        ->  % Sigue vacía - no es new input
            find_new_inputs_row(RestU, RestS, Row, Col+1, HasNewInput)
        ;   % Ahora tiene algo - es new input!
            HasNewInput = yes
        )
    ;   % Celda tenía pistas - ver si cambió
        (   RawVal = InitVal
        ->  % No cambió
            find_new_inputs_row(RestU, RestS, Row, Col+1, HasNewInput)
        ;   % Cambió - es new input!
            HasNewInput = yes
        )
    ).

%% find_mistakes_rec(+RawBoard, +Solution, +InitialSnapshot, +Row, +Col, +Acc, -Mistakes)
find_mistakes_rec([], [], _Initial, _Row, _Col, Acc, Acc) :- !.
find_mistakes_rec([RowB|RestB], [RowS|RestS], Initial, Row, 1, Acc, Mistakes) :- !,
    find_mistakes_row(RowB, RowS, Initial, Row, 1, Acc, Acc2),
    NextRow is Row + 1,
    find_mistakes_rec(RestB, RestS, Initial, NextRow, 1, Acc2, Mistakes).
find_mistakes_rec([_|RestB], [_|RestS], Initial, Row, Col, Acc, Mistakes) :-
    NextCol is Col + 1,
    find_mistakes_rec(RestB, RestS, Initial, Row, NextCol, Acc, Mistakes).

find_mistakes_row([], [], _Initial, _Row, _Col, Acc, Acc) :- !.
find_mistakes_row([RawVal|RestU], [SolVal|RestS], Initial, Row, Col, Acc, Mistakes) :-
    % Obtener valor inicial de esta celda
    nth1(Row, Initial, InitialRow),
    nth1(Col, InitialRow, InitialVal),
    % Solo procesar si la celda estaba inicialmente vacía (era 0)
    (   InitialVal > 0
    ->  % Celda era pistas - ignorar lo que el usuario puso
        Acc2 = Acc
    ;   % Celda estaba vacía - analizar lo que puso el usuario
        (   RawVal = '' ; RawVal = '0' ; RawVal = 0
        ->  % Celda vacía - no hay error
            Acc2 = Acc
        ;   % Celda tiene contenido - analizar
            % Convertir a átomo si es necesario para atom_number
            (   integer(RawVal)
            ->  number_string(RawVal, RawStr)
            ;   RawStr = RawVal
            ),
            (   catch(atom_number(RawStr, N), _, fail)
            ->  % Es numérico
                (   N < 1 ; N > 9
                ->  % Número fuera de rango
                    Acc2 = [mistake(invalid_number, Row, Col)|Acc]
                ;   N \= SolVal
                    ->  % Número válido pero incorrecto
                        Acc2 = [mistake(wrong_number, Row, Col, N)|Acc]
                    ;   % Número correcto
                        Acc2 = Acc
                )
            ;   % No es numérico (letra, símbolo, etc.)
                Acc2 = [mistake(invalid_char, Row, Col)|Acc]
            )
        )
    ),
    NextCol is Col + 1,
    find_mistakes_row(RestU, RestS, Initial, Row, NextCol, Acc2, Mistakes).

%% mistake_to_string(+Mistake, -ErrorString)
% Convierte una estructura de error en el mensaje de error formateado.
mistake_to_string(no_input, "No se ha ingresaado ningun valor, que triste.") :- !.
mistake_to_string(mistake(invalid_char, Row, Col), ErrorStr) :-
    format(atom(ErrorStr), 'Fila ~d, Columna ~d: El caracter ingresaado no es un numero', [Row, Col]).
mistake_to_string(mistake(invalid_number, Row, Col), ErrorStr) :-
    format(atom(ErrorStr), 'Fila ~d, Columna ~d: El numero ingresaado no es valido', [Row, Col]).
mistake_to_string(mistake(wrong_number, Row, Col, N), ErrorStr) :-
    format(atom(ErrorStr), 'Fila ~d, Columna ~d: El numero ~d es incorrecto', [Row, Col, N]).

%% show_comprobar_result(+Dialog, +TimeStr, +ScorePercent, +Mistakes, +SolverStatus, +Solution)
% Muestra el resultado del check en un popup personalizado con tamaño variable.
show_comprobar_result(Dialog, TimeStr, ScorePercent, Mistakes, SolverStatus, Solution) :-
    ( SolverStatus = solved ; SolverStatus = multiple_solutions ),
    !,
    % Aplicar la solución al board result
    gui_apply_solution(Dialog, _GivenMask, Solution),
    % Formatear mensaje principal
    format(atom(MainMsg), 'Tiempo: ~w~nRendimiento: ~w%', [TimeStr, ScorePercent]),
    % Combinar mensajes
    (   Mistakes = []
    ->  FinalMsg = MainMsg
    ;   Mistakes = [no_input]
    ->  % Caso especial: no se ingreng ningun valor
        concat(MainMsg, '\n\nNo se ha ingresaado ningun valor, que triste.', FinalMsg)
    ;   length(Mistakes, NumErrors),
        format(atom(ErrMsg), '~n~nErrores (~d):~n', [NumErrors]),
        atomic_list_concat(Mistakes, '\n', AllErrors),
        concat(ErrMsg, AllErrors, FullErrMsg),
        concat(MainMsg, FullErrMsg, FinalMsg)
    ),
    % Calcular tamaño del editor según cantidad de errores
    (   Mistakes = []
    ->  Height = 6
    ;   Mistakes = [no_input]
    ->  Height = 8
    ;   length(Mistakes, NumErrors),
        Height is min(20, max(6, 6 + NumErrors))  % Min 6, max 20, grows with errors
    ),
    % Crear diálogo de resultados con tamaño variable
    new(ResultD, dialog('Resultados de Practica')),
    new(Txt, editor),
    send(ResultD, append, Txt),
    send(Txt, size, size(40, Height)),
    send(Txt, editable, @off),
    send(Txt, contents, FinalMsg),
    send(ResultD, append, button('Cerrar', message(ResultD, destroy))),
    send(ResultD, transient_for, Dialog),
    send(ResultD, default_button, 'Cerrar'),
    send(ResultD, open_centered, Dialog).
show_comprobar_result(Dialog, _TimeStr, _ScorePercent, _Mistakes, SolverStatus, Solution) :-
    % Si no es solved, mostrar la solución también
    handle_comprobar_result(Dialog, SolverStatus, Solution).

handle_comprobar_result(Dialog, solved, Solution) :-
    gui_apply_solution(Dialog, _GivenMask, Solution).
handle_comprobar_result(Dialog, already_solved, _Solution) :-
    new(MsgD, dialog('Resultado')),
    new(Txt, editor),
    send(MsgD, append, Txt),
    send(Txt, size, size(30, 6)),
    send(Txt, editable, @off),
    send(Txt, contents, '¡Ya estaba resuelto!'),
    send(MsgD, append, button('OK', message(MsgD, destroy))),
    send(MsgD, transient_for, Dialog),
    send(MsgD, default_button, 'OK'),
    send(MsgD, open_centered, Dialog).
handle_comprobar_result(Dialog, no_solution, _Solution) :-
    show_error_dialog(Dialog, 'El puzzle no tiene solucion').
handle_comprobar_result(Dialog, multiple_solutions, Solution) :-
    gui_apply_solution(Dialog, _GivenMask, Solution).
handle_comprobar_result(Dialog, invalid_input(Reason), _Solution) :-
    format(atom(Msg), 'Input invalido: ~w', [Reason]),
    show_error_dialog(Dialog, Msg).
handle_comprobar_result(Dialog, inconsistent(Reason), _Solution) :-
    format(atom(Msg), 'Puzzle inconsistente: ~w', [Reason]),
    show_error_dialog(Dialog, Msg).

%% calculate_score(+UserBoard, +Solution, +InitialSnapshot, -Percent)
% Calcula el porcentaje de celdas correctas SOLO para celdas que estaban
% originalmente vacías (no pistas).Formula: (Correct_User_Placements / Total_Empty_Cells) * 100.
calculate_score(UserBoard, Solution, InitialSnapshot, Percent) :-
    flatten(UserBoard, UserCells),
    flatten(Solution, SolutionCells),
    flatten(InitialSnapshot, OriginalCells),
    % Encontrar índices de celdas que estaban vacías originalmente
    findall(I, (nth1(I, OriginalCells, 0), I > 0), EmptyIndices),
    length(EmptyIndices, TotalEmpty),
    % Contar celdas correctas solo en esas posiciones
    findall(true, (
        member(I, EmptyIndices),
        nth1(I, UserCells, U),
        nth1(I, SolutionCells, S),
        U > 0,
        U =:= S
    ), Correct),
    length(Correct, CorrectCount),
    % Evitar división por cero
    (   TotalEmpty > 0
    ->  Percent is round(CorrectCount * 100 / TotalEmpty)
    ).

%% on_return_click(+Dialog)
% Maneja el botón "Volver":
% desbloquear todo, restaurar modo normal.
on_return_click(Dialog) :-
    % Desbloquear todas las celdas
    unlock_all_cells(Dialog),

    % Ocultar practice controls, mostrar normales
    hide_practice_controls(Dialog),

    % Limpiar estado de practice
    retractall(practice_state(_, _, _)),

    update_status(Dialog, 'Modo Normal').

%% unlock_all_cells(+Dialog)
% Desbloquea todas las celdas de input.
unlock_all_cells(Dialog) :-
    forall(between(1, 9, Row),
           forall(between(1, 9, Col),
                  ( cell_item(Dialog, input, Row, Col, CellItem),
                    send(CellItem, editable, @on)
                  ))).

%% hide_practice_controls(+Dialog)
% Oculta los controles de practice y muestra los normales.
hide_practice_controls(Dialog) :-
    % Ocultar practice controls
    (   get(Dialog, member, 'Comprobar', BtnComprobar)
    ->  send(BtnComprobar, displayed, @off)
    ;   true
    ),
    (   get(Dialog, member, 'Volver', BtnVolver)
    ->  send(BtnVolver, displayed, @off)
    ;   true
    ),

    % Mostrar botones normales
    (   get(Dialog, member, 'Resolver', BtnResolver)
    ->  send(BtnResolver, displayed, @on)
    ;   true
    ),
    (   get(Dialog, member, 'Limpiar Todo', BtnLimpiar)
    ->  send(BtnLimpiar, displayed, @on)
    ;   true
    ),
    (   get(Dialog, member, 'Practicar', BtnPracticar)
    ->  send(BtnPracticar, displayed, @on)
    ;   true
    ),
    (   get(Dialog, member, 'Save', BtnSave)
    ->  send(BtnSave, displayed, @on)
    ;   true
    ),
    (   get(Dialog, member, 'Open', BtnOpen)
    ->  send(BtnOpen, displayed, @on)
    ;   true
    ),
    (   get(Dialog, member, 'Easy', BtnEasy)
    ->  send(BtnEasy, displayed, @on)
    ;   true
    ),
    (   get(Dialog, member, 'Medium', BtnMedium)
    ->  send(BtnMedium, displayed, @on)
    ;   true
    ),
    (   get(Dialog, member, 'Hard', BtnHard)
    ->  send(BtnHard, displayed, @on)
    ;   true
    ),

    % Mostrar labels
    (   get(Dialog, member, 'Ejercicios', LblEjercicios)
    ->  send(LblEjercicios, displayed, @on)
    ;   true
    ),
    (   get(Dialog, member, 'Nuevo Puzzle', LblNuevo)
    ->  send(LblNuevo, displayed, @on)
    ;   true
    ),
    (   get(Dialog, member, 'Ingresar datos', LblInput)
    ->  send(LblInput, displayed, @on)
    ;   true
    ),
    (   get(Dialog, member, 'Resultados', LblResult)
    ->  send(LblResult, displayed, @on)
    ;   true
    ),

    % Mostrar botones de ejercicios
    forall(between(1, 5, N), show_exercise_button(Dialog, N)).

show_exercise_button(Dialog, N) :-
    (   get(Dialog, member, N, Btn)
    ->  send(Btn, displayed, @on)
    ;   true
    ).

% ============================================================
% Dialog de Error
% ============================================================

%% show_error_dialog(+Dialog, +Message)
% Muestra un diálogo de error con botón OK.
show_error_dialog(Dialog, Message) :-
    new(ErrDialog, dialog('Error')),
    send(ErrDialog, append, text(Message)),
    send(ErrDialog, append, button('OK', message(ErrDialog, destroy))),
    send(ErrDialog, transient_for, Dialog),
    send(ErrDialog, default_button, 'OK'),
    send(ErrDialog, open).
