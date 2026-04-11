:- module(run_tests, [run_all_tests/0]).

%% run_all_tests is semidet.
%  Loads all test suites and runs them. Fails if any test fails.
run_all_tests :-
    consult('src/sudoku_validate.plt'),
    consult('src/sudoku_solver.plt'),
    run_tests([]).
