:- begin_tests(sudoku_persistence).

:- use_module('sudoku_persistence').

% Valid board for reuse
test_board([
    [5,3,0,0,7,0,0,0,0],
    [6,0,0,1,9,5,0,0,0],
    [0,9,8,0,0,0,0,6,0],
    [8,0,0,0,6,0,0,0,3],
    [4,0,0,8,0,3,0,0,1],
    [7,0,0,0,2,0,0,0,6],
    [0,6,0,0,0,0,2,8,0],
    [0,0,0,4,1,9,0,0,5],
    [0,0,0,0,8,0,0,7,9]]).

test_file('/tmp/sudoku_test_board.txt').

%% === board_to_file/2 ===

test(board_to_file_creates_file) :-
    test_board(Board),
    test_file(File),
    board_to_file(Board, File),
    exists_file(File).

test(board_to_file_content) :-
    test_board(Board),
    test_file(File),
    board_to_file(Board, File),
    read_file_to_string(File, Content, []),
    % File should have 9 lines
    split_string(Content, "\n", "\n", Lines),
    length(Lines, 9).

test(board_to_file_roundtrip) :-
    test_board(Board),
    test_file(File),
    board_to_file(Board, File),
    file_to_board(File, Loaded),
    Board == Loaded.

%% === file_to_board/2 ===

test(file_to_board_reads_valid) :-
    test_file(File),
    file_to_board(File, Board),
    length(Board, 9),
    forall(member(Row, Board), length(Row, 9)).

test(file_to_board_nonexistent_fails) :-
    \+ file_to_board('/tmp/nonexistent_sudoku_file.txt', _).

%% Cleanup
cleanup :-
    test_file(File),
    (exists_file(File) -> delete_file(File) ; true).

:- end_tests(sudoku_persistence).
