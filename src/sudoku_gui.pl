:- module(sudoku_gui,
          [ open_gui/0,
            gui_read_board/3,
            gui_apply_solution/3
          ]).

:- use_module(library(pce)).
:- use_module(sudoku_solver).

% Genera un nombre estable para cada celda (por prefijo, fila y columna).
% Prefix puede ser 'input' para celdas de entrada o 'result' para la grilla de resultados.
cell_name(Prefix, Row, Col, NameAtom) :-
    % Se usa para poder recuperar el widget luego con get(Dialog, member, Name).
    atomic_list_concat([Prefix, '_cell_', Row, '_', Col], NameAtom).

% Recupera el widget de una celda desde el Dialog.
% Prefix puede ser 'input' para celdas de entrada o 'result' para la grilla de resultados.
cell_item(Dialog, Prefix, Row, Col, CellItem) :-
    % Cada celda fue creada con un name atom del estilo input_cell_R_C.
    cell_name(Prefix, Row, Col, NameAtom),
    get(Dialog, member, NameAtom, CellItem).

% Abre la ventana principal con la grilla y el botón Resolver.
open_gui :-
    % Crea el diálogo principal.
    new(Dialog, dialog('Sudoku Solver')),

    % Crea la grilla 9x9 de campos de texto.
    forall(between(1, 9, Row),
           forall(between(1, 9, Col),
                  create_cell(Dialog, input, Row, Col))),

    % Dibuja separadores gruesos entre bloques 3x3.
    draw_block_divider(Dialog, vertical, 124),
    draw_block_divider(Dialog, vertical, 238),
    draw_block_divider(Dialog, horizontal, 124),
    draw_block_divider(Dialog, horizontal, 238),

    % Crea el botón Resolver y lo posiciona debajo de la grilla.
    new(ResolverBtn, button('Resolver', message(@prolog, on_resolver_click, Dialog))),
    send(Dialog, display, ResolverBtn, point(10, 396)),

    % Abre la ventana en una posición razonable.
    send(Dialog, open, point(50, 50)).

% Crea una celda editable (text_item) en una posición de la grilla.
% Prefix puede ser 'input' para celdas de entrada o 'result' para la grilla de resultados.
create_cell(Dialog, Prefix, Row, Col) :-
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
    % Calcula posición absoluta y muestra el widget.
    get_row_y(Row, Y),
    get_col_x(Col, X),
    send(Dialog, display, CellItem, point(X, Y)).

% Calcula la coordenada Y de una fila.
get_row_y(Row, Y) :-
    % 38 es el paso (tamaño + separación), 10 es el margen superior.
    Y is (Row - 1) * 38 + 10.

% Calcula la coordenada X de una columna.
get_col_x(Col, X) :-
    % 38 es el paso (tamaño + separación), 10 es el margen izquierdo.
    X is (Col - 1) * 38 + 10.

% Dibuja una línea separadora para marcar bloques 3x3.
draw_block_divider(Dialog, vertical, X) :-
    % Línea vertical de arriba a abajo de la grilla.
    !,
    new(L, line(X, 10, X, 348)),
    send(L, pen, 2),
    send(L, colour, colour('#666666')),
    send(Dialog, display, L).
draw_block_divider(Dialog, horizontal, Y) :-
    % Línea horizontal de izquierda a derecha de la grilla.
    new(L, line(10, Y, 348, Y)),
    send(L, pen, 2),
    send(L, colour, colour('#666666')),
    send(Dialog, display, L).

% Handler del botón Resolver: lee, resuelve y actualiza la grilla.
on_resolver_click(Dialog) :-
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
    % Construye el tablero fila por fila.
    findall(RowCells,
            ( between(1, 9, Row),
              read_row(Dialog, Row, RowCells, _RowMask)
            ),
            Board),
    % Construye la máscara de pistas (true si el usuario ingresó un dígito).
    findall(RowMask,
            ( between(1, 9, Row),
              read_row(Dialog, Row, _RowCells, RowMask)
            ),
            GivenMask).

% Lee una fila completa (valores y máscara).
read_row(Dialog, Row, RowCells, RowMask) :-
    % Lee los 9 valores.
    findall(Cell,
            ( between(1, 9, Col),
              read_cell(Dialog, Row, Col, Cell, _Clue)
            ),
            RowCells),
    % Lee la máscara de pistas.
    findall(Clue,
            ( between(1, 9, Col),
              read_cell(Dialog, Row, Col, _Cell, Clue)
            ),
            RowMask).

% Lee una celda y la interpreta como 0 (vacío) o 1..9 (pista/valor).
read_cell(Dialog, Row, Col, Cell, Clue) :-
    % Obtiene el widget y su texto.
    cell_item(Dialog, input, Row, Col, CellItem),
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

% Aplica la solución a la grilla sin sobreescribir pistas del usuario.
gui_apply_solution(Dialog, GivenMask, Solution) :-
    % Recorre todas las celdas y escribe solo donde GivenMask sea false.
    forall(between(1, 9, Row),
           forall(between(1, 9, Col),
                  ( nth1(Row, GivenMask, MaskRow),
                    nth1(Col, MaskRow, IsClue),
                    (   IsClue == true
                    ->  true
                    ;   nth1(Row, Solution, SolRow),
                        nth1(Col, SolRow, Val),
                        cell_item(Dialog, input, Row, Col, CellItem),
                        number_string(Val, S),
                        send(CellItem, selection, S)
                    )
                  ))).
