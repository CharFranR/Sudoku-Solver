:- use_module(library(plunit)).

:- ['src/sudoku_validate.plt', 'src/sudoku_solver.plt'].

%% run_all_tests is semidet.
%  Loads all test suites and runs them. Fails if any test fails.
run_all_tests :-
    plunit:run_tests([sudoku_validate, sudoku_solver]).
