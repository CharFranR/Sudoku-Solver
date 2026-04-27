%% Sudoku Persistence Module
%% Handles board serialization/deserialization and XPCE file dialogs
%% File format: 9 lines, each with 9 space-separated integers (0-9)

:- module(sudoku_persistence,
          [ board_to_file/2,   % +Board, +Path
            file_to_board/2,   % +Path, -Board
            save_board_dialog/2,  % +Dialog, +Board
            load_board_dialog/2   % +Dialog, -Board
          ]).

:- use_module(sudoku_validate).

%% board_to_file(+Board, +Path)
%  Writes a 9x9 board to a file in the standard format.
%  Each row becomes a line with space-separated integers.
%  Fails if Board is invalid.
board_to_file(Board, Path) :-
    %% First validate the board to ensure it's valid
    sudoku_validate:validate_board(Board, ok),
    !,
    %% Open and write with guaranteed cleanup
    setup_call_cleanup(
        open(Path, write, Stream, []),
        (   forall(nth0(_, Board, Row),
                   (   forall(nth0(_, Row, Cell),
                               format(Stream, '~w ', [Cell])),
                       nl(Stream)
                   ))),
        close(Stream)
    ).
board_to_file(_Board, _Path) :-
    %% If validation fails, this fails
    fail.

%% file_to_board(+Path, -Board)
%  Reads a board from a file in the standard format.
%  Returns a 9x9 matrix of integers (0-9).
%  Fails if the file format is invalid or board is inconsistent.
file_to_board(Path, Board) :-
    %% Open and read with guaranteed cleanup
    catch(
        (   setup_call_cleanup(
                open(Path, read, Stream, []),
                (   read_lines(Stream, 9, Board),
                    sudoku_validate:validate_board(Board, ok)),
                close(Stream))
        ),
        Error,
        (   print_message(error, Error),
            fail
        )
    ),
    !.
file_to_board(_Path, _Board) :-
    %% If any step fails, fail
    fail.

%% read_lines(+Stream, +Count, -Rows)
%  Reads Count lines from Stream and returns a list of rows.
read_lines(_Stream, 0, []) :- !.
read_lines(Stream, Count, [Row|Rest]) :-
    Count > 0,
    read_line(Stream, Row),
    Count1 is Count - 1,
    read_lines(Stream, Count1, Rest).

%% read_line(+Stream, -Row)
%  Reads a single line and parses it as 9 integers.
read_line(Stream, Row) :-
    %% Read the line as a string
    read_line_to_string(Stream, LineString),
    %% Split by whitespace and convert to integers
    split_string(LineString, " ", "\s\t\n", Tokens),
    %% Filter out empty tokens and convert to integers
    exclude(=(''), Tokens, NonEmpty),
    maplist(atom_number, NonEmpty, Row).

%% save_board_dialog(+Dialog, +Board)
%  Opens a file dialog to save the board.
%  This predicate will be integrated with XPCE in the GUI phase.
%  For now, it expects Dialog to have a file_dialog method.
save_board_dialog(Dialog, Board) :-
    %% Get the file path from XPCE file dialog
    get(Dialog, file_dialog(save), PathAtom),
    nonvar(PathAtom),
    !,
    atom_string(PathString, PathAtom),
    board_to_file(Board, PathString).

%% load_board_dialog(+Dialog, -Board)
%  Opens a file dialog to load a board.
%  This predicate will be integrated with XPCE in the GUI phase.
load_board_dialog(Dialog, Board) :-
    %% Get the file path from XPCE file dialog
    get(Dialog, file_dialog(open), PathAtom),
    nonvar(PathAtom),
    !,
    atom_string(PathString, PathAtom),
    file_to_board(PathString, Board).
