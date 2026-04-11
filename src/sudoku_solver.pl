:- module(sudoku_solver,
          [ solve_status/3,
            solve_one/2,
            has_multiple_solutions/2,
            exercise/2
          ]).

:- use_module(library(clpfd)).
:- use_module(sudoku_validate).

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
has_multiple_solutions(Board, true) :-
    % Enumera hasta 2 soluciones y chequea que haya al menos dos.
    board_to_vars(Board, Sudoku, AllVars),
    constrain_board(Sudoku),
    findnsols(2,
              Sol,
              ( labeling([], AllVars),
                board_from_vars(Sudoku, Sol)
              ),
              Solutions),
    !,
    length(Solutions, Len),
    Len >= 2.
has_multiple_solutions(_, false).

% True si no hay ceros (tablero completo).
is_fully_filled(Board) :-
    % Recorre todas las celdas y exige que ninguna sea 0.
    forall(member(Row, Board),
           forall(member(Cell, Row),
                  Cell \== 0)).

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
          [[0,0,5,9,1,0,0,0,0],
           [0,0,0,0,0,2,0,0,0],
           [0,3,0,0,0,0,6,0,0],
           [0,0,0,0,0,0,0,7,2],
           [1,0,0,0,6,0,0,0,8],
           [6,4,0,0,0,0,0,0,0],
           [0,0,9,0,0,0,0,1,0],
           [0,0,0,8,0,0,0,0,0],
           [0,0,0,0,3,5,2,0,0]]).
