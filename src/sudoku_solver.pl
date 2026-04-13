:- module(sudoku_solver,
          [ solve_status/3,
            solve_one/2,
            has_multiple_solutions/2,
            generate_puzzle/2,
            exercise/2
          ]).

:- use_module(library(clpfd)).
:- use_module(sudoku_validate).
:- reexport(sudoku_validate).


% Resuelve un Sudoku con validación previa y devuelve un estado.
solve_status(Board, Status, Solution) :-
    % Primero valida el input para diferenciar inválido vs inconsistente.
    sudoku_validate:validate_board(Board, ValidationStatus),
    (   ValidationStatus \== ok
    ->  % Si el tablero no es válido o es inconsistente, no se intenta resolver.
        Status = ValidationStatus,
        Solution = []
    ;   is_fully_filled(Board)
    ->  % Si ya no hay ceros, el tablero ya está completo.
        Status = already_solved,
        Solution = Board
    ;   % Busca hasta 2 soluciones para poder detectar no unicidad.
        find_solutions(Board, Solutions),
        (   Solutions = []
        ->  Status = no_solution,
            Solution = []
        ;   Solutions = [S1]
        ->  Status = solved,
            Solution = S1
        ;   Solutions = [S1|_]
        ->  Status = multiple_solutions,
            Solution = S1
        )
    ).

% Encuentra 0, 1 o 2 soluciones (máximo 2) para detectar múltiples soluciones.
find_solutions(Board, Solutions) :-
    % Convierte el tablero a variables CLPFD manteniendo la estructura.
    board_to_vars(Board, Sudoku, AllVars),
    constrain_board(Sudoku),
    findnsols(2,
              Sol,
              ( labeling([], AllVars),
                board_from_vars(Sudoku, Sol)
              ),
              Solutions),
    !.
find_solutions(_Board, []).

% Aplica las restricciones estándar de Sudoku (filas, columnas y bloques).
constrain_board(Sudoku) :-
    % Todos los valores están en 1..9.
    maplist(maplist(in_), Sudoku),
    % Filas distintas.
    maplist(all_distinct, Sudoku),
    % Columnas distintas.
    transpose(Sudoku, Cols),
    maplist(all_distinct, Cols),
    % Bloques 3x3 distintos.
    blocks(Sudoku, Blocks),
    maplist(all_distinct, Blocks).

% Impone dominio 1..9 a una celda.
in_(V) :-
    V in 1..9.

% Extrae los 9 bloques 3x3 de una matriz 9x9.
blocks(Sudoku, Blocks) :-
    % Se trabaja en tres bandas de filas: (1-3), (4-6) y (7-9).
    Sudoku = [R1,R2,R3,R4,R5,R6,R7,R8,R9],
    block_row(R1, R2, R3, 1, B1, B2, B3),
    block_row(R4, R5, R6, 1, B4, B5, B6),
    block_row(R7, R8, R9, 1, B7, B8, B9),
    Blocks = [B1,B2,B3,B4,B5,B6,B7,B8,B9].

% Para tres filas, arma los tres bloques horizontales (cols 1-3, 4-6, 7-9).
block_row(R1, R2, R3, BaseCol, B1, B2, B3) :-
    % BaseCol se usa como referencia para calcular el inicio de cada bloque.
    C1 is BaseCol,
    C2 is BaseCol + 3,
    C3 is BaseCol + 6,
    block(R1, R2, R3, C1, B1),
    block(R1, R2, R3, C2, B2),
    block(R1, R2, R3, C3, B3).

% Extrae un bloque (9 celdas) a partir de StartCol en tres filas.
block(R1, R2, R3, StartCol, Block) :-
    C2 is StartCol + 1,
    C3 is StartCol + 2,
    nth1(StartCol, R1, V1), nth1(StartCol, R2, V4), nth1(StartCol, R3, V7),
    nth1(C2,        R1, V2), nth1(C2,        R2, V5), nth1(C2,        R3, V8),
    nth1(C3,        R1, V3), nth1(C3,        R2, V6), nth1(C3,        R3, V9),
    Block = [V1,V2,V3,V4,V5,V6,V7,V8,V9].

% Convierte el board (0..9) a una matriz de variables/constantes para CLPFD.
board_to_vars(Board, Sudoku, AllVars) :-
    % 0 se transforma en variable; 1..9 se mantiene como constante.
    maplist(row_to_vars, Board, RowVars),
    append(RowVars, AllVars),
    Sudoku = RowVars.

% Convierte una fila a variables/constantes.
row_to_vars(Row, RowVars) :-
    maplist(cell_to_var, Row, RowVars).

% Convierte una celda: 0 -> variable CLPFD; N -> constante N.
cell_to_var(0, Var) :-
    % Truco CLPFD: deja Var como variable.
    Var #= Var.
cell_to_var(N, N) :-
    % Restringe explícitamente el rango para constantes.
    N in 1..9.

% Devuelve el tablero resuelto (misma estructura que Sudoku).
board_from_vars(Sudoku, Board) :-
    % Después de labeling/2, Sudoku queda totalmente instanciado.
    is_list(Sudoku),
    length(Sudoku, 9),
    Board = Sudoku.

% Resuelve una sola solución (o falla si no hay).
solve_one(Board, Solution) :-
    % Construye el problema y etiqueta variables para obtener una solución.
    board_to_vars(Board, Sudoku, AllVars),
    constrain_board(Sudoku),
    labeling([], AllVars),
    board_from_vars(Sudoku, Solution).

% True si el tablero tiene dos o más soluciones.
has_multiple_solutions(Board, Result) :-
    board_to_vars(Board, Sudoku, AllVars),
    constrain_board(Sudoku),
    (   findnsols(2,
                  Sol,
                  ( labeling([], AllVars),
                    board_from_vars(Sudoku, Sol)
                  ),
                  Solutions),
        length(Solutions, Len),
        Len >= 2
    ->  Result = true
    ;   Result = false
    ).

% True si no hay ceros (tablero completo).
is_fully_filled(Board) :-
    % Recorre todas las celdas y exige que ninguna sea 0.
    forall(member(Row, Board),
           forall(member(Cell, Row),
                  Cell \== 0)).

% === Puzzle Generator ===
% Genera un puzzle Sudoku con solucion unica segun la dificultad.
% Usa CLPFD para generar un tablero completo, luego remueve celdas
% iterativamente verificando que siga teniendo solucion unica.

%% generate_puzzle(+Difficulty, -Puzzle)
%  Difficulty = easy | medium | hard
%  Puzzle es un tablero 9x9 con 0 (vacío) y 1-9 (pistas) que tiene exactamente
%  una solucion. El numero de pistas depende de la dificultad:
%    - easy: 35-40 pistas
%    - medium: 27-32 pistas
%    - hard: 22-27 pistas
generate_puzzle(Difficulty, Puzzle) :-
    difficulty_clue_range(Difficulty, MinClues, MaxClues),
    % 1. Genera un tablero completamente resuelto.
    generate_complete_board(Complete),
    % 2. Remueve celdas iterativamente hasta alcanzar el rango de pistas.
    remove_cells_to_clues(Complete, MinClues, MaxClues, Puzzle).

%% difficulty_clue_range(+Difficulty, -Min, -Max)
%  Define el rango de pistas para cada dificultad.
difficulty_clue_range(easy,  35, 40).
difficulty_clue_range(medium, 27, 32).
difficulty_clue_range(hard,  22, 27).

%% generate_complete_board(-Board)
%  Genera un tablero Sudoku completamente resuelto usando CLPFD.
%  La variabilidad viene de random_permutation/2 en el proceso de remocion.
generate_complete_board(Board) :-
    % Crea la estructura del tablero con 81 variables.
    Board = [R1,R2,R3,R4,R5,R6,R7,R8,R9],
    maplist(row_vars(9), [R1,R2,R3,R4,R5,R6,R7,R8,R9]),
    % Aplica restricciones Sudoku.
    constrain_board(Board),
    % Labeling para obtener una solucion.
    append(Board, AllVars),
    labeling([], AllVars).

%% row_vars(+Length, -Row)
%  Crea una fila de variables CLPFD.
row_vars(Length, Row) :-
    length(Row, Length),
    maplist(in_, Row).

%% remove_cells_to_clues(+Complete, +MinClues, +MaxClues, -Puzzle)
%  Remueve celdas del tablero completo manteniendo solucion unica.
remove_cells_to_clues(Complete, MinClues, MaxClues, Puzzle) :-
    % Obtiene las posiciones de todas las celdas.
    findall((R,C), (between(1,9,R), between(1,9,C)), Positions),
    % Baraja las posiciones para removal aleatorio.
    random_permutation(Positions, Shuffled),
    % Remueve celdas iterativamente.
    remove_iteratively(Shuffled, Complete, MinClues, MaxClues, Complete, Puzzle).

%% remove_iteratively(+Positions, +Board, +MinClues, +MaxClues, +Current, -Puzzle)
%  Itera sobre posiciones barajadas, removiendo celdas si la unicidad se mantiene.
%  Board = tablero original completo (para leer valores originales)
%  Current = tablero actual con remociones parciales
remove_iteratively([], _Board, _MinClues, _MaxClues, Puzzle, Puzzle) :- !.
remove_iteratively(_, _Board, MinClues, MaxClues, Current, Puzzle) :-
    % Si ya estamos en el rango objetivo, terminamos.
    count_clues(Current, Count),
    Count >= MinClues,
    Count =< MaxClues,
    !,
    Puzzle = Current.
remove_iteratively([(R,C)|Rest], Board, MinClues, MaxClues, Current, Puzzle) :-
    % Obtiene el valor actual de la celda.
    nth1(R, Current, Row),
    nth1(C, Row, Value),
    Value \== 0,
    % Crea tablero de prueba sin esta celda.
    replace_cell(Current, R, C, 0, TrialBoard),
    % Solo verifica unicidad si al remover caeriamos por debajo del min.
    count_clues(TrialBoard, TrialCount),
    (   TrialCount >= MinClues
    ->  % Verifica que tenga solucion unica.
        \+ has_multiple_solutions(TrialBoard, true)
    ;   % Si al remover caeriamos por debajo del min, no vale la pena verificar.
        fail
    ),
    !,
    % Remocion exitosa, continuamos con el nuevo tablero.
    remove_iteratively(Rest, Board, MinClues, MaxClues, TrialBoard, Puzzle).
remove_iteratively([_|Rest], Board, MinClues, MaxClues, Current, Puzzle) :-
    % No se pudo remover esta celda (ya era 0 o perdia unicidad),
    % intentamos la siguiente.
    remove_iteratively(Rest, Board, MinClues, MaxClues, Current, Puzzle).

%% replace_cell(+Board, +Row, +Col, +Value, -NewBoard)
%  Reemplaza una celda en el tablero.
replace_cell(Board, Row, Col, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    replace_nth(OldRow, Col, Value, NewRow),
    replace_nth(Board, Row, NewRow, NewBoard).

%% replace_nth(+List, +Index, +Value, -NewList)
%  Reemplaza el elemento en Index con Value.
replace_nth([_|Rest], 1, Value, [Value|Rest]) :- !.
replace_nth([H|T], Index, Value, [H|NewT]) :-
    Index > 1,
    Index1 is Index - 1,
    replace_nth(T, Index1, Value, NewT).

%% count_clues(+Board, -Count)
%  Cuenta las celdas no vacias (pistas) en el tablero.
count_clues(Board, Count) :-
    flatten(Board, Cells),
    exclude(=(0), Cells, Clues),
    length(Clues, Count).

% === Ejercicios predefinidos ===
% exercise(N, Board): Board es un tablero 9x9 con valores 0 (vacío) o 1-9.
% Cada ejercicio es un puzzle Sudoku válido y solucionable con solución única.
% Los 5 ejercicios tienen soluciones completamente distintas entre sí.

% Ejercicio 1 (easy)
exercise(1,
          [[5,3,0,0,7,0,0,0,0],
           [6,0,0,1,9,5,0,0,0],
           [0,9,8,0,0,0,0,6,0],
           [8,0,0,0,6,0,0,0,3],
           [4,0,0,8,0,3,0,0,1],
           [7,0,0,0,2,0,0,0,6],
           [0,6,0,0,0,0,2,8,0],
           [0,0,0,4,1,9,0,0,5],
           [0,0,0,0,8,0,0,7,9]]).

% Ejercicio 2 (medium)
exercise(2,
          [[0,0,0,2,6,0,7,0,1],
           [6,8,0,0,7,0,0,9,0],
           [1,9,0,0,0,4,5,0,0],
           [8,2,0,1,0,0,0,4,0],
           [0,0,4,6,0,2,9,0,0],
           [0,5,0,0,0,3,0,2,8],
           [0,0,9,3,0,0,0,7,4],
           [0,4,0,0,5,0,0,3,6],
           [7,0,3,0,1,8,0,0,0]]).

% Ejercicio 3 (hard)
exercise(3,
          [[0,2,0,6,0,8,0,0,0],
           [5,8,0,0,0,9,7,0,0],
           [0,0,0,0,4,0,0,0,0],
           [3,7,0,0,0,0,5,0,0],
           [6,0,0,0,0,0,0,0,4],
           [0,0,8,0,0,0,0,1,3],
           [0,0,0,0,2,0,0,0,0],
           [0,0,9,8,0,0,0,3,6],
           [0,0,0,3,0,6,0,9,0]]).

% Ejercicio 4 (expert)
exercise(4,
          [[0,0,0,6,0,0,4,0,0],
           [7,0,0,0,0,3,6,0,0],
           [0,0,0,0,9,1,0,8,0],
           [0,0,0,0,0,0,0,0,0],
           [0,5,0,1,8,0,0,0,3],
           [0,0,0,3,0,6,0,4,5],
           [0,4,0,2,0,0,0,6,0],
           [9,0,3,0,0,0,0,0,0],
           [0,2,0,0,0,0,1,0,0]]).

% Ejercicio 5 (master)
exercise(5,
          [[0,0,0,0,0,0,0,0,0],
           [0,0,0,0,0,3,0,8,5],
           [0,0,1,0,2,0,0,0,0],
           [0,0,0,5,0,7,0,0,0],
           [0,0,4,0,0,0,1,0,0],
           [0,9,0,0,0,0,0,0,0],
           [5,0,0,0,0,0,0,7,3],
           [0,0,2,0,1,0,0,0,0],
           [0,0,0,0,4,0,0,0,9]]).
