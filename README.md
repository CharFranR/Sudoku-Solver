# Sudoku Solver — SWI-Prolog + XPCE

Un resolvedor de Sudoku 9×9 en Prolog puro con interfaz gráfica XPCE.

## Prerrequisitos

- **SWI-Prolog** ≥ 8.x con soporte a `library(clpfd)` y `library(pce)` (XPCE)
- En Linux (Debian/Ubuntu): `sudo apt install swi-prolog swi-prolog-x`
- En macOS: `brew install swi-prolog`
- Verificar XPCE: `swipl -g "use_module(library(pce)), writeln(pce_ok)" -t halt`

## Ejecución

```bash
cd /path/to/Sudoku-Solver
swipl src/main.pl
```

Esto abre la ventana del Sudoku Solver con una grilla 9×9 vacía.

## Uso de la GUI

1. **Ingresar pistas**: hacer clic en una celda y escribir un dígito 1–9 (o dejarla vacía = 0).
2. **Resolver**: presionar el botón `Resolver` para resolver el puzzle.
3. **Resultado**: la GUI completa SOLO las celdas vacías, preservando las pistas ingresadas.

## Verificación Manual

Ejecutar las siguientes pruebas en el REPL de SWI-Prolog:

### sudoku-solver-core — Escenarios

#### Requisito: Board input contract

**Scenario: Input válido (forma y rango)**
```prolog
?- use_module(src/sudoku_validate).
?- validate_board([[5,3,0,0,7,0,0,0,0],
                   [6,0,0,1,9,5,0,0,0],
                   [0,9,8,0,0,0,0,6,0],
                   [8,0,0,0,6,0,0,0,3],
                   [4,0,0,8,0,3,0,0,1],
                   [7,0,0,0,2,0,0,0,6],
                   [0,6,0,0,0,0,2,8,0],
                   [0,0,0,4,1,9,0,0,5],
                   [0,0,0,0,8,0,0,7,9]], Status).
% Esperado: Status = ok
```

**Scenario: Input inválido (forma)**
```prolog
?- validate_board([[5,3,0,0,7,0,0,0]], Status).
% Esperado: Status = invalid_input('Debe ser una lista de 9 filas, cada una con 9 columnas')
```

**Scenario: Input inválido (valores fuera de rango)**
```prolog
?- validate_board([[-1,0,0,0,0,0,0,0,0],
                   [0,0,0,0,0,0,0,0,0],
                   [0,0,0,0,0,0,0,0,0],
                   [0,0,0,0,0,0,0,0,0],
                   [0,0,0,0,0,0,0,0,0],
                   [0,0,0,0,0,0,0,0,0],
                   [0,0,0,0,0,0,0,0,0],
                   [0,0,0,0,0,0,0,0,0],
                   [0,0,0,0,0,0,0,0,0]], Status).
% Esperado: Status = invalid_input('Las celdas deben ser enteros entre 0 y 9')
```

#### Requisito: Initial consistency validation

**Scenario: Tablero consistente**
```prolog
?- validate_board([[5,3,0,0,7,0,0,0,0],
                   [6,0,0,1,9,5,0,0,0],
                   [0,9,8,0,0,0,0,6,0],
                   [8,0,0,0,6,0,0,0,3],
                   [4,0,0,8,0,3,0,0,1],
                   [7,0,0,0,2,0,0,0,6],
                   [0,6,0,0,0,0,2,8,0],
                   [0,0,0,4,1,9,0,0,5],
                   [0,0,0,0,8,0,0,7,0]], Status).
% Esperado: Status = ok
```

**Scenario: Duplicado en una fila**
```prolog
?- validate_board([[5,3,5,0,7,0,0,0,0],
                   [6,0,0,1,9,5,0,0,0],
                   [0,9,8,0,0,0,0,6,0],
                   [8,0,0,0,6,0,0,0,3],
                   [4,0,0,8,0,3,0,0,1],
                   [7,0,0,0,2,0,0,0,6],
                   [0,6,0,0,0,0,2,8,0],
                   [0,0,0,4,1,9,0,0,5],
                   [0,0,0,0,8,0,0,7,0]], Status).
% Esperado: Status = inconsistent('Hay duplicados en filas/columnas/bloques 1..9')
```

#### Requisito: Solve outcomes

**Scenario: Resuelve un Sudoku típico**
```prolog
?- use_module(src/sudoku_solver).
?- solve_status([[0,3,0,0,7,0,0,0,0],
                 [6,0,0,1,9,5,0,0,0],
                 [0,9,8,0,0,0,0,6,0],
                 [8,0,0,0,6,0,0,0,3],
                 [4,0,0,8,0,3,0,0,1],
                 [7,0,0,0,2,0,0,0,6],
                 [0,6,0,0,0,0,2,8,0],
                 [0,0,0,4,1,9,0,0,5],
                 [0,0,0,0,8,0,0,7,0]], Status, Solution).
% Esperado: Status = solved, Solution = board completo sin ceros
```

**Scenario: No tiene solución**
```prolog
?- solve_status([[5,3,0,0,7,0,0,0,0],
                 [6,0,0,1,9,5,0,0,0],
                 [0,9,8,0,0,0,0,6,0],
                 [8,0,0,0,6,0,0,0,3],
                 [4,0,0,8,0,3,0,0,1],
                 [7,0,0,0,2,0,0,0,6],
                 [0,6,0,0,0,0,2,8,0],
                 [0,0,0,4,1,9,0,0,5],
                 [0,0,0,0,8,0,0,0,0]], Status, Solution).
% Esperado: Status = no_solution, Solution = []
```

**Scenario: Ya resuelto**
```prolog
?- solve_status([[5,3,4,6,7,8,9,1,2],
                 [6,7,2,1,9,5,3,4,8],
                 [1,9,8,3,4,2,5,6,7],
                 [8,5,9,7,6,1,4,2,3],
                 [4,2,6,8,5,3,7,9,1],
                 [7,1,3,9,2,4,8,5,6],
                 [9,6,1,5,3,7,2,8,4],
                 [2,8,7,4,1,9,6,3,5],
                 [3,4,5,2,8,6,1,7,9]], Status, Solution).
% Esperado: Status = already_solved, Solution = board de entrada
```

#### Requisito: Multiple solutions detection

**Scenario: Detecta no unicidad**
```prolog
?- use_module(src/sudoku_solver).
?- has_multiple_solutions([[0,3,0,0,7,0,0,0,0],
                            [6,0,0,1,9,5,0,0,0],
                            [0,9,8,0,0,0,0,6,0],
                            [8,0,0,0,6,0,0,0,3],
                            [4,0,0,8,0,3,0,0,1],
                            [7,0,0,0,2,0,0,0,6],
                            [0,6,0,0,0,0,2,8,0],
                            [0,0,0,4,1,9,0,0,5],
                            [0,0,0,0,8,0,0,7,0]], Multiple).
% Esperado (para puzzle estándar): Multiple = false
% Si el puzzle tiene múltiples soluciones → Multiple = true
```

---

### sudoku-gui-xpce — Escenarios

#### Requisito: 9x9 editable grid

**Scenario: Ingreso de celda válida**
1. Abrir GUI: `swipl src/main.pl`
2. Hacer clic en cualquier celda
3. Ingresar "7" → la celda muestra "7"

**Scenario: Ingreso de celda inválida**
1. Hacer clic en una celda
2. Ingresar "a" o "12" → La GUI muestra mensaje de error

#### Requisito: Solve button fills solution

**Scenario: Resolver completa los vacíos**
1. Ingresar puzzle estándar (pistas del ejemplo de spec)
2. Presionar "Resolver"
3. Verificar: celdas vacías completadas, pistas sin modificar

**Scenario: Puzzle inconsistente**
1. Ingresar un puzzle con duplicados (ejemplo inconsistent)
2. Presionar "Resolver"
3. Verificar: mensaje "Puzzle inconsistente" + grilla sin modificar

**Scenario: Múltiples soluciones**
1. Ingresar puzzle que tiene más de una solución
2. Presionar "Resolver"
3. Verificar: mensaje "No único: múltiples soluciones" + grilla se completa

**Scenario: Ya resuelto**
1. Ingresar un Sudoku completamente resuelto y válido
2. Presionar "Resolver"
3. Verificar: mensaje "Ya resuelto" + grilla sin modificar

---

## Estructura de Archivos

```
src/
  sudoku_validate.pl  — Validación de board (forma, rango, consistencia)
  sudoku_solver.pl    — Solver CLPFD + API de outcomes
  sudoku_gui.pl       — GUI XPCE (grilla + botón Resolver)
  main.pl             — Entry point (carga GUI y abre ventana)
```

## Notas de Implementación

- Board = lista de 9 listas de 9 enteros, donde `0` = vacío
- El solver usa `library(clpfd)` para constraints declarativos
- Múltiples soluciones: se enumeran hasta 2 soluciones (corte en 2) para detectar no unicidad
- La GUI NO sobreescribe celdas que el usuario marcó como pistas (GivenMask)
