:- module(sudoku_game_flow,
          [ manual_check_status/2,
            practice_start_status/3,
            practice_check_status/4
          ]).

:- use_module(sudoku_solver, [solve_status/3]).
:- use_module(sudoku_validate, [validate_board/2]).

%% manual_check_status(+Board, -Status)
%  Determina el estado de un board para el modo de verificación manual.
%  Status puede ser: solved_correctly, incomplete_consistent,
%                    incorrect(invalid_input(Reason)),
%                    incorrect(inconsistent(Reason))
manual_check_status(Board, solved_correctly) :-
    validate_board(Board, ok),
    board_complete(Board),
    !.
manual_check_status(Board, incomplete_consistent) :-
    validate_board(Board, ok),
    !.
manual_check_status(Board, incorrect(invalid_input(Reason))) :-
    validate_board(Board, invalid_input(Reason)),
    !.
manual_check_status(Board, incorrect(inconsistent(Reason))) :-
    validate_board(Board, inconsistent(Reason)).

%% practice_start_status(+Board, -Status, -TargetSolution)
%  Determina si se puede iniciar modo práctica en Board.
%  Status puede ser: practice_ready, already_solved,
%                    invalid_input(Reason), inconsistent(Reason),
%                    no_solution, non_unique
%  Si Status = practice_ready, TargetSolution se une a la solución.
practice_start_status(Board, practice_ready, TargetSolution) :-
    validate_board(Board, ok),
    \+ board_complete(Board),
    solve_status(Board, solved, TargetSolution),
    !.
practice_start_status(Board, already_solved, []) :-
    validate_board(Board, ok),
    board_complete(Board),
    !.
practice_start_status(Board, invalid_input(Reason), []) :-
    validate_board(Board, invalid_input(Reason)),
    !.
practice_start_status(Board, inconsistent(Reason), []) :-
    validate_board(Board, inconsistent(Reason)),
    !.
practice_start_status(Board, no_solution, []) :-
    solve_status(Board, no_solution, _),
    !.
practice_start_status(Board, non_unique, []) :-
    solve_status(Board, multiple_solutions, _).

%% practice_check_status(+UserBoard, +InitialBoard, +TargetSolution, -Result)
%  Compara el board del usuario contra la solución target.
%  Result puede ser: solved (todo correcto y completo),
%                    incomplete (sin errores pero incompleto),
%                    incorrect(Mistakes) (con lista de (Row,Col) errores)
practice_check_status(UserBoard, InitialBoard, TargetSolution, Result) :-
    editable_mistakes(UserBoard, InitialBoard, TargetSolution, Mistakes),
    (   Mistakes \= []
    ->  Result = incorrect(Mistakes)
    ;   board_complete(UserBoard)
    ->  Result = solved
    ;   Result = incomplete
    ).

%% board_complete(+Board)
%  Verdadero si todas las celdas de Board tienen valores 1-9.
board_complete(Board) :-
    forall(member(Row, Board),
           forall(member(Cell, Row),
                  ( integer(Cell),
                    Cell >= 1,
                    Cell =< 9
                  ))).

%% editable_mistakes(+UserBoard, +InitialBoard, +TargetSolution, -Mistakes)
%  Encuentra celdas editables (que estaban vacías inicialmente) donde
%  el usuario ingresó un valor incorrecto. Mistakes es lista de (Row,Col).
editable_mistakes(UserBoard, InitialBoard, TargetSolution, Mistakes) :-
    findall((Row, Col),
            ( between(1, 9, Row),
              between(1, 9, Col),
              nth1(Row, InitialBoard, InitialRow),
              nth1(Col, InitialRow, InitialValue),
              InitialValue =:= 0,
              nth1(Row, UserBoard, UserRow),
              nth1(Col, UserRow, UserValue),
              UserValue =\= 0,
              nth1(Row, TargetSolution, TargetRow),
              nth1(Col, TargetRow, TargetValue),
              UserValue =\= TargetValue
            ),
            Mistakes).
