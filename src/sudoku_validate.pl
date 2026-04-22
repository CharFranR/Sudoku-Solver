:- module(sudoku_validate,
          [ validate_board/2,
            check_shape/2,
            check_range/2,
            check_consistency/2,
            is_cell_valid/3,
            conflicts_in_board/3
          ]).

% Valida un tablero 9x9 y devuelve un estado.
validate_board(Board, Status) :-
    % Primero valida la forma, luego el rango de valores y por último la consistencia.
    check_shape(Board, ShapeReason),
    (   ShapeReason \== ok
    ->  Status = invalid_input(ShapeReason)
    ;   check_range(Board, RangeReason),
        (   RangeReason \== ok
        ->  Status = invalid_input(RangeReason)
        ;   check_consistency(Board, ConsReason),
            (   ConsReason \== ok
            ->  Status = inconsistent(ConsReason)
            ;   Status = ok
            )
        )
    ).

% Verifica que el tablero sea una matriz 9x9.
check_shape(Board, ok) :-
    % Acepta solo una lista de 9 filas, y cada fila debe tener 9 elementos.
    is_list(Board),
    length(Board, 9),
    forall(nth0(_, Board, Row),
           ( is_list(Row),
             length(Row, 9)
           )),
    !.
check_shape(_, 'Debe ser una lista de 9 filas, cada una con 9 columnas').

% Verifica que todas las celdas sean enteros entre 0 y 9.
check_range(Board, ok) :-
    % 0 representa celda vacía; 1..9 son pistas o valores.
    forall(member(Row, Board),
           forall(member(Cell, Row),
                  ( integer(Cell),
                    Cell >= 0,
                    Cell =< 9
                  ))),
    !.
check_range(_, 'Las celdas deben ser enteros entre 0 y 9').

% Verifica que el tablero no tenga duplicados (1..9) en filas, columnas o bloques.
check_consistency(Board, ok) :-
    % Recorre filas.
    forall(nth0(_RowIdx, Board, Row),
           no_duplicates_except_zero(Row)),
    % Recorre columnas (se obtiene transponiendo).
    transpose_matrix(Board, Cols),
    forall(member(Col, Cols),
           no_duplicates_except_zero(Col)),
    % Recorre bloques 3x3.
    get_3x3_blocks(Board, Blocks),
    forall(member(Block, Blocks),
           no_duplicates_except_zero(Block)),
    !.
check_consistency(_, 'Hay duplicados en filas/columnas/bloques 1..9').

% True si la lista no repite valores distintos de 0.
no_duplicates_except_zero(RowOrCol) :-
    % Filtra ceros, ordena y compara longitudes.
    findall(V, (member(V, RowOrCol), V \== 0), Values),
    sort(Values, Sorted),
    length(Values, Len),
    length(Sorted, Len).

% Transpone una matriz N×N para obtener sus columnas como listas.
transpose_matrix(Matrix, Transposed) :-
    % N se toma como la cantidad de filas.
    length(Matrix, N),
    transpose_cols(1, N, Matrix, Transposed).

% Caso base: cuando el índice de columna supera N, termina.
transpose_cols(I, N, _Matrix, []) :-
    I > N,
    !.

% Construye la columna I y continúa con la siguiente.
transpose_cols(I, N, Matrix, [Col|Cols]) :-
    I =< N,
    findall(V,
            ( nth1(_, Matrix, Row),
              nth1(I, Row, V)
            ),
            Col),
    I2 is I + 1,
    transpose_cols(I2, N, Matrix, Cols).

% Extrae los 9 bloques 3x3 en orden (de arriba a abajo y de izquierda a derecha).
get_3x3_blocks(Board, Blocks) :-
    % Se asume que ya es 9x9 (esto se valida en check_shape/2).
    Board = [R1,R2,R3,R4,R5,R6,R7,R8,R9],
    blocks_from_row_triple([R1,R2,R3], TopBlocks),
    blocks_from_row_triple([R4,R5,R6], MiddleBlocks),
    blocks_from_row_triple([R7,R8,R9], BottomBlocks),
    append([TopBlocks, MiddleBlocks, BottomBlocks], Blocks).

% A partir de 3 filas, arma los 3 bloques horizontales correspondientes.
blocks_from_row_triple([R1,R2,R3], [B1,B2,B3]) :-
    % Cada bloque toma 3 columnas consecutivas.
    get_block_cols(R1, R2, R3, 1, B1),
    get_block_cols(R1, R2, R3, 4, B2),
    get_block_cols(R1, R2, R3, 7, B3).

% Extrae un bloque 3x3 a partir de una columna inicial (1-indexada).
get_block_cols(R1, R2, R3, Start, Block) :-
    End is Start + 2,
    get_cols_range(R1, Start, End, Row1Cols),
    get_cols_range(R2, Start, End, Row2Cols),
    get_cols_range(R3, Start, End, Row3Cols),
    append([Row1Cols, Row2Cols, Row3Cols], Block).

% Devuelve los valores de una fila entre Start y End (inclusive), usando nth1.
get_cols_range(Row, Start, End, Cols) :-
    findall(V,
            ( between(Start, End, I),
              nth1(I, Row, V)
            ),
            Cols).

%% is_cell_valid(+Board, +Position, -Status)
%  Valida el estado de una celda en el tablero.
%  Position = Row-Col (1-indexed)
%  Status = valid | invalid_row | invalid_col | invalid_block | empty
%  Empty cells (value 0) siempre retornan 'empty'.
%  Celdas no vacías retornan el primer conflicto encontrado (row, col, o block).
is_cell_valid(Board, Row-Col, Status) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Value),
    (   Value = 0
    ->  Status = empty
    ;   conflicts_in_board(Board, Row-Col, Conflicts),
        (   memberchk(Row-_, Conflicts)
        ->  Status = invalid_row
        ;   memberchk(_-Col, Conflicts)
        ->  Status = invalid_col
        ;   in_same_block(Row, Col, Conflicts)
        ->  Status = invalid_block
        ;   Status = valid
        )
    ).

%% in_same_block(+Row, +Col, +Conflicts)
%  True si hay alguna posición en Conflicts que esté en el mismo bloque 3x3.
in_same_block(Row, Col, Conflicts) :-
    BlockRowStart is ((Row - 1) // 3) * 3 + 1,
    BlockColStart is ((Col - 1) // 3) * 3 + 1,
    BlockRowEnd is BlockRowStart + 2,
    BlockColEnd is BlockColStart + 2,
    member(R-C, Conflicts),
    R >= BlockRowStart, R =< BlockRowEnd,
    C >= BlockColStart, C =< BlockColEnd.

%% conflicts_in_board(+Board, +Position, -Conflicts)
%  Retorna la lista de posiciones (Row-Col) que conflictúan con la celda
%  en Position. Un conflicto existe cuando otra celda (no vacía) tiene
%  el mismo valor en la misma fila, columna, o bloque 3x3.
conflicts_in_board(Board, Row-Col, Conflicts) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Value),
    (   Value = 0
    ->  Conflicts = []
    ;   findall(R-C,
                ( conflicting_cell(Board, Row, Col, Value, R, C),
                  (R-C) \== (Row-Col)
                ),
                Conflicts0),
        sort(Conflicts0, Conflicts)
    ).

%% conflicting_cell(+Board, +Row, +Col, +Value, -R, -C)
%  True si la celda (R,C) tiene el mismo Value y está en la misma
%  fila, columna, o bloque 3x3 que (Row,Col).
conflicting_cell(Board, Row, Col, Value, R, C) :-
    % Misma fila, diferente columna
    member(Row, Board),
    nth1(C, Row, Value),
    C \== Col,
    R = Row.
conflicting_cell(Board, Row, Col, Value, R, C) :-
    % Misma columna, diferente fila
    nth1(R, Board, RowList),
    nth1(Col, RowList, Value),
    R \== Row,
    C = Col.
conflicting_cell(Board, Row, Col, Value, R, C) :-
    % Mismo bloque 3x3, diferente posición
    BlockRowStart is ((Row - 1) // 3) * 3 + 1,
    BlockColStart is ((Col - 1) // 3) * 3 + 1,
    BlockRowEnd is BlockRowStart + 2,
    BlockColEnd is BlockColStart + 2,
    between(BlockRowStart, BlockRowEnd, R),
    between(BlockColStart, BlockColEnd, C),
    (R-C) \== (Row-Col),
    nth1(R, Board, BR),
    nth1(C, BR, Value).
