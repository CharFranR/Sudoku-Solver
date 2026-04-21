import re

with open('src/sudoku_gui.pl', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix dynamic declaration
content = content.replace('dynamic(practice_state/4).', 'dynamic(practice_state/5).')

# Fix all practice_state calls - need to handle 5 args now
# Pattern: practice_state(practice, Snapshot, Running, PollTimer, DisplayTimer)

# Line 414
content = content.replace(
    "asserta(practice_state(practice, InitialSnapshot, false, @nil)),",
    "asserta(practice_state(practice, InitialSnapshot, false, @nil, @nil)),"
)

# Line 524-526 in check_cell_changes
content = content.replace(
    "practice_state(practice, Snapshot, false, _),\n    retractall(practice_state(practice, _, _, _)),\n    asserta(practice_state(practice, Snapshot, false, PollTimer)).",
    "practice_state(practice, Snapshot, false, PollTimer, _),\n    retractall(practice_state(practice, _, _, _, _)),\n    asserta(practice_state(practice, Snapshot, false, PollTimer, @nil))."
)

# Line 531 in check_cell_changes 
content = content.replace(
    "practice_state(practice, _Snapshot, TimerStarted, _PollTimer),",
    "practice_state(practice, _Snapshot, TimerStarted, _PollTimer, _DisplayTimer),"
)

# Line 552 in on_cell_edit_practice
content = content.replace(
    "practice_state(practice, _InitialSnapshot, TimerStarted, _TimerObj),",
    "practice_state(practice, _InitialSnapshot, TimerStarted, _PollTimer, _DisplayTimer),"
)

# Line 579 in on_surrender_click
content = content.replace(
    "practice_state(practice, InitialSnapshot, _, _),",
    "practice_state(practice, InitialSnapshot, _, _PollTimer, _DisplayTimer),"
)

# Line 635 in on_return_click
content = content.replace(
    "retractall(practice_state(_, _, _, _)),",
    "retractall(practice_state(_, _, _, _, _)),"
)

# Line 733 in setup_practice_edit_handler  
content = content.replace(
    "practice_state(practice, Snapshot, false, _),",
    "practice_state(practice, Snapshot, false, _PollTimer, _),"
)

# Line 746-768 in stop_practice_timer
content = content.replace(
    "(   practice_state(practice, Snapshot, Running, PollTimer)\n    ->  % Destruir timer de polling si existe\n        ( PollTimer \\== @nil -> catch(send(PollTimer, destroy), _, true) ; true ),\n        % Destruir timer de display si estaba corriendo (esta en otro lugar del estado)\n        (   Running == true\n        ->  % Buscar y destruir el timer de display\n            (   catch((\n                    practice_state(practice, _, _, PT),\n                    PT \\== @nil,\n                    send(PT, destroy)\n                ), _, true)\n            ;   true\n            )\n        ;   true\n        ),\n        retractall(practice_state(practice, _, _, _)),\n        asserta(practice_state(practice, Snapshot, false, @nil))\n    ;   true\n    ).",
    "(   practice_state(practice, Snapshot, Running, PollTimer, DisplayTimer)\n    ->  % Destruir timer de polling si existe\n        ( PollTimer \\== @nil -> catch(send(PollTimer, destroy), _, true) ; true ),\n        % Destruir timer de display si estaba corriendo\n        (   Running == true, DisplayTimer \\== @nil\n        ->  catch(send(DisplayTimer, destroy), _, true)\n        ;   true\n        ),\n        retractall(practice_state(practice, _, _, _, _)),\n        asserta(practice_state(practice, Snapshot, false, @nil, @nil))\n    ;   true\n    )."
)

with open('src/sudoku_gui.pl', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
