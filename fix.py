import sys

with open('src/sudoku_gui.pl', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix Singletons
text = text.replace('get(Dialog, member, Rendirse, BtnRendirse)', "get(Dialog, member, 'Rendirse', BtnRendirse)")
text = text.replace('get(Dialog, member, Volver, BtnVolver)', "get(Dialog, member, 'Volver', BtnVolver)")
text = text.replace('get(Dialog, member, Resolver, BtnResolver)', "get(Dialog, member, 'Resolver', BtnResolver)")
text = text.replace('get(Dialog, member, Easy, BtnEasy)', "get(Dialog, member, 'Easy', BtnEasy)")
text = text.replace('get(Dialog, member, Medium, BtnMedium)', "get(Dialog, member, 'Medium', BtnMedium)")
text = text.replace('get(Dialog, member, Hard, BtnHard)', "get(Dialog, member, 'Hard', BtnHard)")
text = text.replace('get(Dialog, member, Ejercicios, LblEjercicios)', "get(Dialog, member, 'Ejercicios', LblEjercicios)")

# Fix visibility
text = text.replace('visible, @off', 'displayed, @off')
text = text.replace('visible, @on', 'displayed, @on')

# Fix fonts
text = text.replace('font(pixels,', 'font(helvetica,')

with open('src/sudoku_gui.pl', 'w', encoding='utf-8') as f:
    f.write(text)
