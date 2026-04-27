:- module(sudoku_gui,
          [ open_gui/0,
            gui_read_board/3,
            gui_apply_solution/3,
            load_exercise/2,
            % Practice mode exports (for testing)
            gui_read_board_practice/2,
            calculate_score/4,
            format_elapsed_time/2,
            practice_session/4,
            count_clues/2
          ]).

:- use_module(library(pce)).
:- use_module(library(thread)).
:- use_module(sudoku_solver).
:- use_module(sudoku_persistence).
:- use_module(sudoku_game_flow).

:- dynamic(practice_session/4).
    % practice_session(InitialBoard, TargetSolution, StartTime, _ThreadId)

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
    send(T1, font, font(pixels, bold, 14)),
    send(Dialog, display, T1, point(10, 10)),

    new(T2, text('Resultados')),
    send(T2, font, font(pixels, bold, 14)),
    send(Dialog, display, T2, point(410, 10)),

    % === PANEL DE BOTONES ===
    Row1Y = 410,

    % --- Izquierda: Ejercicios ---
    send(Dialog, display, new(LblEx, text('Ejercicios:')), point(10, Row1Y)),
    send(LblEx, font, font(pixels, bold, 12)),
    forall(between(1, 5, N),
           (  XX is 100 + (N - 1) * 55,
              send(Dialog, display, button(N, message(@prolog, load_exercise, Dialog, N)), point(XX, Row1Y))
           )),

    % --- Derecha: Nuevo Puzzle ---
    send(Dialog, display, new(LblPu, text('Nuevo Puzzle:')), point(420, Row1Y)),
    send(LblPu, font, font(pixels, bold, 12)),
    send(Dialog, display, button('Easy',   message(@prolog, on_new_puzzle_click, Dialog, easy)),   point(540, Row1Y)),
    send(Dialog, display, button('Medium', message(@prolog, on_new_puzzle_click, Dialog, medium)), point(620, Row1Y)),
    send(Dialog, display, button('Hard',   message(@prolog, on_new_puzzle_click, Dialog, hard)),   point(715, Row1Y)),

    % --- Fila inferior: Status a la izquierda, botones a la derecha ---
    Row2Y = 450,
    new(StatusLabel, text_item(status_label, 'Listo')),
    send(StatusLabel, font, font(pixels, normal, 10)),
    send(StatusLabel, colour, colour(darkblue)),
    send(StatusLabel, editable, @off),
    send(StatusLabel, length, 25),
    send(Dialog, display, StatusLabel, point(10, Row2Y)),

    send(Dialog, display, button('Resolver', message(@prolog, on_resolver_click, Dialog)), point(300, Row2Y)),
    send(Dialog, display, button('Limpiar Todo', message(@prolog, on_clear_click, Dialog)), point(380, Row2Y)),
    send(Dialog, display, button('Practicar', message(@prolog, on_practice_click, Dialog)), point(480, Row2Y)),
    send(Dialog, display, button('Save', message(@prolog, on_save_click, Dialog)), point(560, Row2Y)),
    send(Dialog, display, button('Open', message(@prolog, on_open_click, Dialog)), point(620, Row2Y)),

    % Practice controls (hidden initially)
    new(TimerText, text_item(practice_timer_display, '00:00')),
    send(TimerText, label, ''),
    send(TimerText, font, font(pixels, monospaced, 12)),
    send(TimerText, editable, @off),
    send(TimerText, length, 6),
    send(Dialog, display, TimerText, point(480, Row2Y)),
    send(TimerText, displayed, @off),

    send(Dialog, display, button('Comprobar', message(@prolog, on_comprobar_click, Dialog)), point(530, Row2Y)),
    send(Dialog, display, button('Volver', message(@prolog, on_return_click, Dialog)), point(620, Row2Y)),

    % Ensure practice controls are hidden initially
    (   get(Dialog, member, 'Comprobar', BtnComp)
    ->  send(BtnComp, displayed, @off)
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

% Actualiza el mensaje de estado en la barra interior.
update_status(Dialog, Message) :-
    get(Dialog, member, status_label, StatusLabel),
    send(StatusLabel, selection, Message).

%% leave_practice_mode_if_active(+Dialog)
%  Sale del modo práctica si está activo (por si se acciona un handler normal).
leave_practice_mode_if_active(Dialog) :-
    (   practice_session(_, _, _, _)
    ->  cleanup_practice,
        unlock_all_cells(Dialog),
        hide_practice_controls(Dialog),
        clear_result_grid(Dialog)
    ;   true
    ).

% Handler del botón Limpiar Todo: limpia ambas grillas (input y result).
on_clear_click(Dialog) :-
    leave_practice_mode_if_active(Dialog),
    clear_input_grid(Dialog),
    clear_result_grid(Dialog),
    update_status(Dialog, '').

% Handler del botón Resolver: lee, resuelve y actualiza la grilla.
on_resolver_click(Dialog) :-
    leave_practice_mode_if_active(Dialog),
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
    leave_practice_mode_if_active(Dialog),
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
    leave_practice_mode_if_active(Dialog),
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
    send(D, focus, TI),
    get(D, confirm_centered, Result),
    send(D, destroy),
    Result \== @nil,
    atom_string(Result, PathString),
    PathString \== ''.

on_save_click(Dialog) :-
    leave_practice_mode_if_active(Dialog),
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
    leave_practice_mode_if_active(Dialog),
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

% =====================================================================
% MODO PRÁCTICA
% =====================================================================

%% count_clues(+Board, -Count)
%  Cuenta celdas no-cero (pistas) en Board.
count_clues(Board, Count) :-
    flatten(Board, Cells),
    exclude(==(0), Cells, Clues),
    length(Clues, Count).

%% on_practice_click(+Dialog)
%  Handler del botón Practicar: valida 17 pistas mínimas e inicia modo.
on_practice_click(Dialog) :-
    cleanup_practice,
    gui_read_board(Dialog, Board, _GivenMask),
    count_clues(Board, ClueCount),
    (   ClueCount < 17
    ->  update_status(Dialog, 'Se requieren al menos 17 pistas para practicar')
    ;   practice_start_status(Board, Status, TargetSolution),
        handle_practice_start(Dialog, Board, Status, TargetSolution)
    ).

handle_practice_start(Dialog, Board, practice_ready, TargetSolution) :-
    !,
    start_practice_mode(Dialog, Board, TargetSolution).
handle_practice_start(Dialog, _Board, already_solved, _TargetSolution) :-
    !,
    update_status(Dialog, 'El puzzle ya está resuelto. No hay nada que practicar.').
handle_practice_start(Dialog, _Board, no_solution, _TargetSolution) :-
    !,
    update_status(Dialog, 'Sin solución: el puzzle no tiene solución válida.').
handle_practice_start(Dialog, _Board, non_unique, _TargetSolution) :-
    !,
    update_status(Dialog, 'El puzzle no tiene solución única. No es apto para práctica.').
handle_practice_start(Dialog, _Board, invalid_input(Reason), _TargetSolution) :-
    !,
    format(atom(Msg), 'Input inválido: ~w', [Reason]),
    update_status(Dialog, Msg).
handle_practice_start(Dialog, _Board, inconsistent(Reason), _TargetSolution) :-
    !,
    format(atom(Msg), 'Puzzle inconsistente: ~w', [Reason]),
    update_status(Dialog, Msg).

%% start_practice_mode(+Dialog, +Board, +TargetSolution)
%  Activa el modo práctica: bloquea pistas, muestra controles, arranca timer.
start_practice_mode(Dialog, Board, TargetSolution) :-
    duplicate_term(Board, InitialSnapshot),
    get_time(StartTime),
    % Crear thread Prolog para el timer (XPCE timer no funciona en este entorno)
    thread_create(timer_loop(Dialog), Tid, []),
    asserta(practice_session(InitialSnapshot, TargetSolution, StartTime, Tid)),
    lock_clue_cells(Dialog, Board),
    show_practice_controls(Dialog),
    update_status(Dialog, 'Modo práctica: completa las celdas vacías y presiona Comprobar').

%% timer_loop(+Dialog)
%  Loop de timer en thread separado: tickea cada 1 segundo.
timer_loop(Dialog) :-
    catch(
        (   repeat,
            sleep(1),
            (   practice_session(_, _, StartTime, _)
            ->  get_time(Now),
                Elapsed is round(Now - StartTime),
                format_elapsed_time(Elapsed, TimeStr),
                (   get(Dialog, member, practice_timer_display, TW)
                ->  send(TW, selection, TimeStr)
                ;   true
                ),
                fail
            ;   !   % No hay sesión de práctica → salir del loop
            )
        ),
        exit,
        true
    ).

%% lock_clue_cells(+Dialog, +Board)
%  Deshabilita edición en celdas que tienen pistas (Val > 0).
lock_clue_cells(Dialog, Board) :-
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
%  Oculta botones normales y muestra controles de práctica.
show_practice_controls(Dialog) :-
    % Ocultar botones normales
    forall(member(Label, ['Resolver', 'Limpiar Todo', 'Practicar', 'Save', 'Open',
                           'Easy', 'Medium', 'Hard']),
           hide_dialog_child(Dialog, Label)),
    forall(between(1, 5, N),
           hide_dialog_child(Dialog, N)),
    % Mostrar timer y botones de práctica
    show_dialog_child(Dialog, practice_timer_display),
    show_dialog_child(Dialog, 'Comprobar'),
    show_dialog_child(Dialog, 'Volver').

%% hide_practice_controls(+Dialog)
%  Oculta controles de práctica y muestra botones normales.
hide_practice_controls(Dialog) :-
    hide_dialog_child(Dialog, practice_timer_display),
    hide_dialog_child(Dialog, 'Comprobar'),
    hide_dialog_child(Dialog, 'Volver'),
    % Mostrar botones normales
    forall(member(Label, ['Resolver', 'Limpiar Todo', 'Practicar', 'Save', 'Open',
                           'Easy', 'Medium', 'Hard']),
           show_dialog_child(Dialog, Label)),
    forall(between(1, 5, N),
           show_dialog_child(Dialog, N)).

hide_dialog_child(Dialog, Name) :-
    (   get(Dialog, member, Name, Obj)
    ->  send(Obj, displayed, @off)
    ;   true
    ).

show_dialog_child(Dialog, Name) :-
    (   get(Dialog, member, Name, Obj)
    ->  send(Obj, displayed, @on)
    ;   true
    ).

%% format_elapsed_time(+Seconds, -TimeStr)
%  Formatea segundos a string MM:SS.
format_elapsed_time(Seconds, TimeStr) :-
    Minutes is Seconds // 60,
    Secs is Seconds mod 60,
    (   Minutes < 10
    ->  format(atom(MinStr), '0~d', [Minutes])
    ;   format(atom(MinStr), '~d', [Minutes])
    ),
    (   Secs < 10
    ->  format(atom(SecStr), '0~d', [Secs])
    ;   format(atom(SecStr), '~d', [Secs])
    ),
    atomic_list_concat([MinStr, SecStr], ':', TimeStr).

%% stop_practice_timer
%  Detiene el thread del timer si está corriendo.
stop_practice_timer :-
    practice_session(_, _, _, Tid),
    catch(thread_signal(Tid, throw(exit)), _, true),
    catch(thread_join(Tid, _), _, true),
    !.
stop_practice_timer.

%% cleanup_practice
%  Limpia todo estado de práctica: timer, sesión, celdas.
cleanup_practice :-
    stop_practice_timer,
    retractall(practice_session(_, _, _, _)).

%% on_comprobar_click(+Dialog)
%  Handler del botón Comprobar: compara el board del usuario contra la solución.
on_comprobar_click(Dialog) :-
    practice_session(InitialSnapshot, TargetSolution, StartTime, _Timer),
    !,
    % Leer board del usuario (tratando inválidos como vacíos)
    gui_read_board_practice(Dialog, UserBoard),
    % Obtener tiempo transcurrido
    get_time(CurrentTime),
    Elapsed is round(CurrentTime - StartTime),
    format_elapsed_time(Elapsed, TimeStr),
    % Evaluar usando el contrato puro
    practice_check_status(UserBoard, InitialSnapshot, TargetSolution, CheckResult),
    handle_practice_check(Dialog, UserBoard, InitialSnapshot, TargetSolution,
                          CheckResult, TimeStr, Elapsed).
on_comprobar_click(_Dialog) :-
    update_status(_, 'No hay sesión de práctica activa').

handle_practice_check(Dialog, UserBoard, InitialSnapshot, TargetSolution,
                       solved, TimeStr, _Elapsed) :-
    !,
    calculate_score(UserBoard, TargetSolution, InitialSnapshot, ScorePercent),
    gui_apply_solution(Dialog, _GivenMask, TargetSolution),
    format(atom(Msg), '¡Resuelto! Tiempo: ~w  Rendimiento: ~w%', [TimeStr, ScorePercent]),
    update_status(Dialog, Msg),
    show_practice_dialog(Dialog, TimeStr, ScorePercent, []).
handle_practice_check(Dialog, UserBoard, InitialSnapshot, TargetSolution,
                       incomplete, TimeStr, _Elapsed) :-
    !,
    calculate_score(UserBoard, TargetSolution, InitialSnapshot, ScorePercent),
    format(atom(Msg), 'Incompleto — Rendimiento: ~w%', [ScorePercent]),
    update_status(Dialog, Msg),
    format(atom(MainMsg), 'Tiempo: ~w~nRendimiento: ~w%~n~nSigue completando celdas vacías...', [TimeStr, ScorePercent]),
    show_practice_dialog_raw(Dialog, MainMsg).
handle_practice_check(Dialog, UserBoard, InitialSnapshot, TargetSolution,
                       incorrect(Mistakes), TimeStr, _Elapsed) :-
    !,
    calculate_score(UserBoard, TargetSolution, InitialSnapshot, ScorePercent),
    update_status(Dialog, 'Hay errores. Revisa las celdas marcadas.'),
    show_practice_dialog(Dialog, TimeStr, ScorePercent, Mistakes).

%% calculate_score(+UserBoard, +TargetSolution, +InitialSnapshot, -Percent)
%  Calcula el % de celdas editables correctas sobre el total de celdas vacías.
calculate_score(UserBoard, TargetSolution, InitialSnapshot, Percent) :-
    flatten(UserBoard, UserCells),
    flatten(TargetSolution, SolutionCells),
    flatten(InitialSnapshot, OriginalCells),
    % Índices de celdas que estaban vacías originalmente
    findall(I, (nth1(I, OriginalCells, 0), I > 0), EmptyIndices),
    length(EmptyIndices, TotalEmpty),
    % Celdas correctas en esas posiciones
    findall(true, (
        member(I, EmptyIndices),
        nth1(I, UserCells, U),
        nth1(I, SolutionCells, S),
        U > 0,
        U =:= S
    ), Correct),
    length(Correct, CorrectCount),
    (   TotalEmpty > 0
    ->  Percent is round(CorrectCount * 100 / TotalEmpty)
    ;   Percent = 0
    ).

%% show_practice_dialog(+Dialog, +TimeStr, +ScorePercent, +Mistakes)
%  Muestra diálogo de resultados con errores (si hay).
show_practice_dialog(Dialog, TimeStr, ScorePercent, Mistakes) :-
    format(atom(MainMsg), 'Tiempo: ~w~nRendimiento: ~w%', [TimeStr, ScorePercent]),
    (   Mistakes = []
    ->  show_practice_dialog_raw(Dialog, MainMsg)
    ;   maplist(mistake_to_string, Mistakes, StringMistakes),
        length(StringMistakes, NumErrors),
        format(atom(ErrMsg), '~n~nErrores (~d):~n', [NumErrors]),
        atomic_list_concat(StringMistakes, '\n', AllErrors),
        concat(ErrMsg, AllErrors, FullErrMsg),
        concat(MainMsg, FullErrMsg, FinalMsg),
        show_practice_dialog_raw(Dialog, FinalMsg)
    ).

%% mistake_to_string(+Mistake, -String)
%  Convierte (Row,Col) a string legible.
mistake_to_string((Row, Col), ErrorStr) :-
    format(atom(ErrorStr), 'Fila ~d, Columna ~d', [Row, Col]).

%% show_practice_dialog_raw(+Dialog, +Message)
%  Muestra un diálogo emergente con un mensaje.
show_practice_dialog_raw(Dialog, Message) :-
    new(ResultD, dialog('Resultados de Práctica')),
    new(Txt, editor),
    send(ResultD, append, Txt),
    send(Txt, size, size(40, 8)),
    send(Txt, editable, @off),
    send(Txt, contents, Message),
    send(ResultD, append, button('Cerrar', message(ResultD, destroy))),
    send(ResultD, transient_for, Dialog),
    send(ResultD, default_button, 'Cerrar'),
    send(ResultD, open_centered).

%% gui_read_board_practice(+Dialog, -Board)
%  Lee el board de la GUI sin lanzar errores en input inválido.
%  Trata celdas inválidas o vacías como 0.
gui_read_board_practice(Dialog, Board) :-
    Prefix = input,
    findall(RowCells,
            ( between(1, 9, Row),
              findall(Cell,
                      ( between(1, 9, Col),
                        read_cell_silent(Dialog, Prefix, Row, Col, Cell)
                      ),
                      RowCells)
            ),
            Board).

%% read_cell_silent(+Dialog, +Prefix, +Row, +Col, -Cell)
%  Lee una celda sin lanzar excepciones. Inválido/vacío → 0.
read_cell_silent(Dialog, Prefix, Row, Col, Cell) :-
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
    ->  Cell = 0
    ;   atom(Sel),
        atom_number(Sel, N),
        N >= 1, N =< 9
    ->  Cell = N
    ;   Cell = 0   % Inválido → tratar como vacío
    ).

%% on_return_click(+Dialog)
%  Handler del botón Volver: sale del modo práctica.
on_return_click(Dialog) :-
    cleanup_practice,
    unlock_all_cells(Dialog),
    hide_practice_controls(Dialog),
    clear_result_grid(Dialog),
    update_status(Dialog, 'Modo normal').

%% unlock_all_cells(+Dialog)
%  Restaura edición en todas las celdas de input.
unlock_all_cells(Dialog) :-
    forall(between(1, 9, Row),
           forall(between(1, 9, Col),
                  ( cell_item(Dialog, input, Row, Col, CellItem),
                    send(CellItem, editable, @on)
                  ))).
