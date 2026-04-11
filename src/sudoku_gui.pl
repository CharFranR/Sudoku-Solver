:- module(sudoku_gui,
          [ open_gui/0,
            gui_read_board/3,
            gui_apply_solution/3,
            load_exercise/2
          ]).

:- use_module(library(pce)).
:- use_module(sudoku_solver).
:- use_module(sudoku_persistence).

% Genera un nombre estable para cada celda (por prefijo, fila y columna).
% Prefix puede ser 'input' para celdas de entrada o 'result' para la grilla de resultados.
cell_name(Prefix, Row, Col, NameAtom) :-
    % Se usa para poder recuperar el widget luego con get(Dialog, member, Name).
    atomic_list_concat([Prefix, '_cell_', Row, '_', Col], NameAtom).

% Recupera el widget de una celda desde el Dialog.
% Las celdas están dentro de picture containers (inputPic o resultPic).
cell_item(Dialog, Prefix, Row, Col, CellItem) :-
    cell_name(Prefix, Row, Col, NameAtom),
    % Busca en el picture container correspondiente
    (   Prefix = input -> ContainerName = input_cell_container
    ;   Prefix = result -> ContainerName = result_cell_container
    ;   ContainerName = input_cell_container
    ),
    get(Dialog, member, ContainerName, Container),
    get(Container, member, NameAtom, CellItem).

% Abre la ventana principal con las dos grillas (input y result) y el botón Resolver.
open_gui :-
    new(Dialog, dialog('Sudoku Solver')),
    send(Dialog, gap, size(10, 5)),

    % === Grillas en picture containers (posición absoluta adentro) ===
    % Picture permite positioning absoluto pero es un widget que dialog puede layoutear.

    % --- Grilla INPUT ---
    new(InputPic, picture),
    send(InputPic, name, input_cell_container),
    send(InputPic, size, size(350, 370)),
    % Headers
    new(T1, text('Ingresar datos')),
    send(T1, font, font(pixels, bold, 16)),
    send(InputPic, display, T1, point(0, 0)),
    % Celdas
    forall(between(1, 9, Row),
           forall(between(1, 9, Col),
                  ( get_row_y(Row, Y), get_col_x(Col, X),
                    cell_name(input, Row, Col, Name),
                    new(C, text_item(Name, '')),
                    send(C, label, ''),
                    send(C, length, 1),
                    send(C, alignment, center),
                    send(C, size, size(34, 34)),
                    send(C, font, font(pixels, monospaced, 14)),
                    send(InputPic, display, C, point(X, Y))
                  ))),
    % Divisores
    draw_grid_dividers(InputPic, 10, 40, 38),
    send(Dialog, append, InputPic),

    % --- Grilla RESULT ---
    new(ResultPic, picture),
    send(ResultPic, name, result_cell_container),
    send(ResultPic, size, size(350, 370)),
    new(T2, text('Resultados')),
    send(T2, font, font(pixels, bold, 16)),
    send(ResultPic, display, T2, point(0, 0)),
    forall(between(1, 9, Row),
           forall(between(1, 9, Col),
                  ( get_row_y(Row, Y), get_col_x(Col, X),
                    cell_name(result, Row, Col, Name),
                    new(C, text_item(Name, '')),
                    send(C, label, ''),
                    send(C, length, 1),
                    send(C, alignment, center),
                    send(C, size, size(34, 34)),
                    send(C, font, font(pixels, monospaced, 14)),
                    send(ResultPic, display, C, point(X, Y))
                  ))),
    draw_grid_dividers(ResultPic, 10, 40, 38),
    send(Dialog, append, ResultPic, right),

    % === Botones con layout automático ===
    send(Dialog, append, new(@bv, button('Resolver', message(@prolog, on_resolver_click, Dialog)))),
    send(Dialog, append, new(button('Limpiar Todo', message(@prolog, on_clear_click, Dialog))), right),

    % Ejercicios
    new(ExHeader, text('Ejercicios:')),
    send(ExHeader, font, font(pixels, bold, 12)),
    send(Dialog, append, ExHeader),
    forall(between(1, 5, N),
           (  atomic_list_concat([' ', N, ' '], Lbl),
              B = button(Lbl, message(@prolog, load_exercise, Dialog, N)),
              (N = 1 -> send(Dialog, append, new(B))
              ;        send(Dialog, append, new(B), right))
           )),

    % Puzzle
    new(PuHeader, text('Puzzle:')),
    send(PuHeader, font, font(pixels, bold, 12)),
    send(Dialog, append, PuHeader),
    send(Dialog, append, new(button('Easy',   message(@prolog, on_new_puzzle_click, Dialog, easy)))),
    send(Dialog, append, new(button('Medium', message(@prolog, on_new_puzzle_click, Dialog, medium))), right),
    send(Dialog, append, new(button('Hard',   message(@prolog, on_new_puzzle_click, Dialog, hard))), right),
    send(Dialog, append, new(button('Save',   message(@prolog, on_save_click, Dialog))), right),
    send(Dialog, append, new(button('Open',   message(@prolog, on_open_click, Dialog))), right),

    % Status
    new(StatusLabel, text_item(status_label, 'Listo')),
    send(StatusLabel, font, font(pixels, normal, 10)),
    send(StatusLabel, colour, colour(darkblue)),
    send(StatusLabel, editable, @off),
    send(StatusLabel, length, 50),
    send(Dialog, append, StatusLabel),

    send(Dialog, open).

% Crea una celda editable (text_item) en una posición de la grilla.
% Prefix puede ser 'input' para celdas de entrada o 'result' para la grilla de resultados.
% OffsetX es el desplazamiento horizontal para dibujar la grilla completa en otra posición X.
create_cell(Dialog, Prefix, Row, Col, OffsetX) :-
    % El nombre del item sirve para identificarlo dentro del Dialog.
    cell_name(Prefix, Row, Col, NameAtom),
    new(CellItem, text_item(NameAtom, '')),
    % Oculta el label para que no aparezca texto al lado de cada celda.
    send(CellItem, label, ''),
    % Limita a 1 caracter para permitir solo un dígito.
    send(CellItem, length, 1),
    % Centra el texto en el campo.
    send(CellItem, alignment, center),
    % Ajusta tamaño del widget.
    send(CellItem, size, size(34, 34)),
    % Fuente monoespaciada para que los dígitos se vean uniformes.
    send(CellItem, font, font(pixels, monospaced, 14)),
    % Calcula posición absoluta (con OffsetX) y muestra el widget.
    get_row_y(Row, Y),
    get_col_x(Col, XBase),
    X is XBase + OffsetX,
    send(Dialog, display, CellItem, point(X, Y)).

% Calcula la coordenada Y de una fila.
get_row_y(Row, Y) :-
    % 38 es el paso (tamaño + separación), 40 es el margen superior (ajustado por headers).
    Y is (Row - 1) * 38 + 40.

% Calcula la coordenada X de una columna.
get_col_x(Col, X) :-
    % 38 es el paso (tamaño + separación), 10 es el margen izquierdo.
    X is (Col - 1) * 38 + 10.

% Dibuja una línea separadora para marcar bloques 3x3.
% OffsetX es el desplazamiento horizontal para dibujar la grilla completa en otra posición X.
draw_block_divider(Dialog, vertical, XBase, OffsetX) :-
    % Línea vertical de arriba a abajo de la grilla (ajustada por headers).
    !,
    X is XBase + OffsetX,
    new(L, line(X, 40, X, 378)),
    send(L, pen, 2),
    send(L, colour, colour('#666666')),
    send(Dialog, display, L).
draw_block_divider(Dialog, horizontal, Y, OffsetX) :-
    XStart is 10 + OffsetX,
    XEnd is 348 + OffsetX,
    new(L, line(XStart, Y, XEnd, Y)),
    send(L, pen, 2),
    send(L, colour, colour('#666666')),
    send(Dialog, display, L).

%% draw_grid_dividers(+Container, +OriginX, +OriginY, +Step)
%  Dibuja las 4 líneas divisorias de bloques 3x3 en un picture container.
draw_grid_dividers(Container, OX, OY, Step) :-
    % Líneas verticales: entre columnas 3-4 y 6-7
    VX1 is OX + 3 * Step - 2,
    VX2 is OX + 6 * Step - 2,
    VBottom is OY + 9 * Step,
    draw_line(Container, VX1, OY, VX1, VBottom),
    draw_line(Container, VX2, OY, VX2, VBottom),
    % Líneas horizontales: entre filas 3-4 y 6-7
    HY1 is OY + 3 * Step - 2,
    HY2 is OY + 6 * Step - 2,
    HRight is OX + 9 * Step,
    draw_line(Container, OX, HY1, HRight, HY1),
    draw_line(Container, OX, HY2, HRight, HY2).

%% draw_line(+Container, +X1, +Y1, +X2, +Y2)
draw_line(Container, X1, Y1, X2, Y2) :-
    new(L, line(X1, Y1, X2, Y2)),
    send(L, pen, 2),
    send(L, colour, colour('#666666')),
    send(Container, display, L).

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
    % Primero limpia la grilla de resultados.
    clear_result_grid(Dialog),
    % Captura excepciones (por ejemplo, input inválido en una celda).
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
    % Caso de solución única encontrada.
    !,
    send(@display, inform, '¡Sudoku resuelto! Completando celdas vacías.'),
    gui_apply_solution(Dialog, GivenMask, Solution).
handle_status(_Dialog, already_solved, _Solution, _GivenMask) :-
    % Si ya estaba completo, no se modifica nada.
    !,
    send(@display, inform, 'El puzzle ya está resuelto.').
handle_status(_Dialog, no_solution, _Solution, _GivenMask) :-
    % No existe solución consistente.
    !,
    send(@display, inform, 'Sin solución: el puzzle no tiene solución válida.').
handle_status(Dialog, multiple_solutions, Solution, GivenMask) :-
    % Hay más de una solución; se muestra una para completar.
    !,
    send(@display, inform, 'No único: hay múltiples soluciones. Mostrando una.'),
    gui_apply_solution(Dialog, GivenMask, Solution).
handle_status(_Dialog, invalid_input(Reason), _Solution, _GivenMask) :-
    % El input del board es inválido (forma o rango).
    !,
    format(atom(Msg), 'Input inválido: ~w', [Reason]),
    send(@display, inform, Msg).
handle_status(_Dialog, inconsistent(Reason), _Solution, _GivenMask) :-
    % El tablero viola restricciones (duplicados iniciales).
    !,
    format(atom(Msg), 'Puzzle inconsistente: ~w', [Reason]),
    send(@display, inform, Msg).

% Lee la grilla XPCE y produce el Board (0..9) y una máscara de pistas.
gui_read_board(Dialog, Board, GivenMask) :-
    Prefix = input,
    % Construye el tablero fila por fila.
    findall(RowCells,
            ( between(1, 9, Row),
              read_row(Dialog, Prefix, Row, RowCells, _RowMask)
            ),
            Board),
    % Construye la máscara de pistas (true si el usuario ingresó un dígito).
    findall(RowMask,
            ( between(1, 9, Row),
              read_row(Dialog, Prefix, Row, _RowCells, RowMask)
            ),
            GivenMask).

% Lee una fila completa (valores y máscara).
read_row(Dialog, Prefix, Row, RowCells, RowMask) :-
    % Lee los 9 valores.
    findall(Cell,
            ( between(1, 9, Col),
              read_cell(Dialog, Prefix, Row, Col, Cell, _Clue)
            ),
            RowCells),
    % Lee la máscara de pistas.
    findall(Clue,
            ( between(1, 9, Col),
              read_cell(Dialog, Prefix, Row, Col, _Cell, Clue)
            ),
            RowMask).

% Lee una celda y la interpreta como 0 (vacío) o 1..9 (pista/valor).
read_cell(Dialog, Prefix, Row, Col, Cell, Clue) :-
    % Obtiene el widget y su texto.
    cell_item(Dialog, Prefix, Row, Col, CellItem),
    get(CellItem, selection, Sel0),
    % Normaliza selection a un átomo para parsear.
    (   Sel0 == @nil
    ->  Sel = ''
    ;   atomic(Sel0)
    ->  Sel = Sel0
    ;   ( catch(get(Sel0, value, Sel), _, Sel = Sel0)
        -> true
        ;  Sel = Sel0
        )
    ),
    % Interpreta el contenido.
    (   ( Sel == '' ; Sel == "" ; Sel == '0' )
    ->  Cell = 0,
        Clue = false
    ;   atom(Sel),
        atom_number(Sel, N),
        N >= 1, N =< 9
    ->  Cell = N,
        Clue = true
    ;   % Si no es vacío ni dígito 1..9, dispara error.
        throw(invalid_cell(Row, Col, Sel0))
    ).

% Aplica la solución a la grilla result (ignora GivenMask - escribe todas las celdas).
gui_apply_solution(Dialog, _GivenMask, Solution) :-
    Prefix = result,
    % Recorre todas las celdas y escribe el valor de la solución.
    forall(between(1, 9, Row),
           forall(between(1, 9, Col),
                  ( nth1(Row, Solution, SolRow),
                    nth1(Col, SolRow, Val),
                    cell_item(Dialog, Prefix, Row, Col, CellItem),
                    number_string(Val, S),
                    send(CellItem, selection, S)
                  ))).

% === Handler para cargar ejercicios predefinidos ===
% load_exercise(Dialog, N): limpia grids y carga el exercise N en la grilla input.
load_exercise(Dialog, N) :-
    % Limpia ambas grillas.
    clear_input_grid(Dialog),
    clear_result_grid(Dialog),
    % Obtiene el tablero del ejercicio N.
    exercise(N, Board),
    % Itera sobre el tablero y filled las celdas non-vacías.
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

%% update_status(+Dialog, +Message, +Colour)
update_status(Dialog, Message, Colour) :-
    get(Dialog, member, status_label, StatusLabel),
    send(StatusLabel, selection, Message),
    send(StatusLabel, colour, Colour).
