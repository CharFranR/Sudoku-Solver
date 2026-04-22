# PRD — Sudoku Solver (SWI-Prolog + XPCE)

## Document Status

| Field | Value |
|-------|-------|
| **Version** | 1.1 |
| **Status** | Draft |
| **Date** | 2026-04-10 |
| **Stakeholders** | Project maintainers, contributors, end‑users |
| **Previous Versions** | 1.0 (2026-04-10) |
| **Changes** | Splitted Phase 1 into 1A/1B, adjusted metrics, added "Why Prolog", separated user modes, added effort context |

## Executive Summary

Sudoku Solver es una aplicación educativa y práctica que resuelve puzzles Sudoku 9×9 usando **Prolog puro** (declarativo) con una interfaz gráfica **XPCE**. El proyecto actual ya implementa:

- **Core solver** con validación completa (forma, rango, consistencia inicial)
- **GUI XPCE** con dos grillas separadas (input / resultados), botón "Resolver", "Limpiar Todo" y 5 ejercicios predefinidos
- **Módulos separados**: validación, solver, GUI, entry point
- **Verificación manual** detallada en `README.md`

Esta PRD define el roadmap para transformar el prototipo funcional en una **herramienta profesional** con testing automatizado, CI/CD, experiencia de usuario mejorada y capacidades avanzadas.

## Vision

> Un entorno de aprendizaje y práctica de Sudoku que combine la elegancia de la programación lógica (Prolog) con una interfaz gráfica intuitiva, útil tanto para resolver puzzles como para enseñar algoritmos de resolución.

### ¿Por qué Prolog?

Prolog es el **lenguaje ideal** para resolver Sudoku, y este proyecto demuestra por qué:

- **Declarativo**: El solver se expresa como **restricciones lógicas** ("cada fila debe tener 1-9"), no como algoritmos imperativos con loops y punteros.
- **Backtracking automático**: Prolog retrocede cuando una rama falla — el motor de inferencia hace el trabajo por nosotros.
- **Detección natural de múltiples soluciones**: enumerar hasta 2 soluciones es trivial con `findall`.
- **Legibilidad**: `solve_status/3` en 30 líneas vs 200+ en Python/Java.

Esto hace que el código sea **más corto, más legible, y menos propenso a bugs** que implementaciones imperativas equivalentes.

## Problem Statement

### Current Gaps

1. **Testing manual** → no escala, no da confianza para cambios futuros.
2. **Sin CI/CD** → cada PR se revisa manualmente, no hay validación automática.
3. **UX limitada**:
   - Errores solo en consola (no en ventana).
   - No hay validación en tiempo real.
   - Falta generación de puzzles nuevos.
   - No se pueden guardar/cargar boards.
4. **Infraestructura débil**:
   - No hay templates de issue/PR.
   - No hay script de instalación o Makefile.
   - Documentación interna limitada.

### Target Users

| User | Mode | Needs |
|------|------|-------|
| **Aprendiz de Prolog** | Desarrollador | Ver cómo se aplica CLPFD a un problema real, ejecutar tests, entender backtracking, experimentar con el solver. |
| **Entusiasta de Sudoku** | Usuario | Resolver puzzles rápidamente con la GUI, probar ejercicios con distintos niveles, obtener hints, guardar puzzles interesantes. |
| **Mantenidor** | Desarrollador | Código testeado, documentado, con CI que garantice calidad en cada PR. |

> **Nota**: Los modos no son excluyentes. Un aprendiz puede querer usar la GUI para probar su solver modificado.

## Success Metrics

> *Estimaciones asumen 1 desarrollador, 10-15 horas/semana.*

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Tests críticos** | Todos los predicados públicos de `sudoku_solver.pl` y `sudoku_validate.pl` tienen al menos un test happy-path + edge-cases | No hay herramientas de coverage para Prolog; lo importante es que los predicados críticos estén cubiertos |
| **CI pass rate** | 100% en `main`/`develop` | Los tests corren en cada push/PR |
| **Time to first solve** | < 2 minutos para usuario nuevo | Abrir GUI, ingresar puzzle, resolver |
| **Contributor onboarding** | < 10 minutos para correr tests | `make test` o equivalente |

## Features & Requirements

### ✅ **Already Implemented** (v1.0)

| Feature | Module | Status |
|---------|--------|--------|
| Solver CLPFD (solved, no_solution, already_solved, multiple) | `sudoku_solver.pl` | ✅ |
| Validación completa (forma, rango, consistencia) | `sudoku_validate.pl` | ✅ |
| GUI XPCE con grilla editable 9×9 | `sudoku_gui.pl` | ✅ |
| Dos grillas separadas (input / result) | `sudoku_gui.pl` | ✅ (PR #1) |
| Botón "Limpiar Todo" | `sudoku_gui.pl` | ✅ (PR #1) |
| 5 ejercicios predefinidos (easy → master) | `sudoku_solver.pl` | ✅ (PR #1) |
| Entry point `main/0` | `main.pl` | ✅ |
| Verificación manual (README) | `README.md` | ✅ |

### 🚨 **Phase 1A — Infraestructura base** (v1.1)
**Timeline:** 1–2 semanas | **Esfuerzo:** 15-20h

| Feature | Priority | Description | Impact |
|---------|----------|-------------|--------|
| **Testing con plunit** | Critical | Tests unitarios para `sudoku_validate.pl` y `sudoku_solver.pl`. Todos los predicados públicos con al menos un test. | Confianza para cambios |
| **CI/CD (GitHub Actions)** | Critical | Workflow `.github/workflows/test.yml` que instala SWI-Prolog y ejecuta tests. Badge en README. | Automatización, calidad |

### 🔧 **Phase 1B — UX inmediata** (v1.1.5)
**Timeline:** 1–2 semanas | **Esfuerzo:** 10-15h

| Feature | Priority | Description | Impact |
|---------|----------|-------------|--------|
| **Manejo de errores en ventana** | High | Mostrar mensajes de error/éxito en un `text_item` de estado dentro de la GUI, no solo en consola. | UX inmediata, usuario no necesita terminal |
| **Fix bugs PR #1** | Medium | Corregir cualquier bug menor descubierto durante testing (validación de input, ejercicios inconsistentes, etc.) | Estabilidad |

### 📈 **Phase 2 — UX mejorada** (v1.2)
**Timeline:** 2–3 semanas | **Esfuerzo:** 25-30h

| Feature | Priority | Description | Impact |
|---------|----------|-------------|--------|
| **Validación en tiempo real** | High | Colorear celdas inválidas (rojo) mientras el usuario escribe; prevenir duplicados en fila/columna/bloque. | Prevención de errores, UX moderna |
| **Generador de puzzles aleatorios** | High | `generate_puzzle/1` que devuelve board con solución única; botón "Nuevo puzzle" en GUI. | Valor agregado infinito |
| **Guardar / cargar boards** | Medium | Serializar board a archivo (formato simple texto o JSON); botones "Guardar"/"Abrir". | Persistencia |

### 🎨 **Phase 3 — Avanzado** (v1.3)
**Timeline:** 2–3 semanas | **Esfuerzo:** 20-25h

| Feature | Priority | Description |
|---------|----------|-------------|
| **Hints / resolver paso a paso** | Medium | Botón "Pista" que completa una celda vacía; modo "paso a paso" para enseñanza. |
| **Estadísticas** | Low | Mostrar tiempo de resolución, dificultad estimada, número de backtrackings. |
| **Temas (claro/oscuro)** | Low | Selector de tema en GUI. |

### 🌟 **Phase 4 — Experimental** (futuro)
**Timeline:** sin estimar | **Esfuerzo:** investigar

| Feature | Priority | Description |
|---------|----------|-------------|
| **Candidatos (pencil marks)** | Low | Mostrar números pequeños en celdas vacías con posibles valores. |
| **Animación de resolución** | Low | Mostrar progreso del solver paso a paso (delay entre celdas). |
| **Soporte para variantes** (6×6, 12×12) | Low | Extender solver y GUI a otros tamaños. |
| **Exportar/importar formato estándar** | Low | Soportar formatos como `.sdk` de Sudoku Exchange. |

## Non‑Functional Requirements

| Category | Requirement | Priority |
|----------|-------------|----------|
| **Performance** | Resolver cualquier puzzle 9×9 en < 1 segundo (en hardware moderno). | High |
| **Usability** | GUI intuitiva: botones claros, mensajes en español, sin necesidad de terminal. | High |
| **Maintainability** | Código Prolog bien comentado, módulos cohesivos, tests automatizados. | High |
| **Portability** | Funcionar en Linux (Debian/Ubuntu), macOS (Homebrew), WSL. | High |

## User Stories

### Modo Usuario (Entusiasta de Sudoku)
1. Como usuario, quiero **abrir la GUI** y ver dos grillas claras (input/result) sin configurar nada.
2. Como usuario, quiero **ingresar un puzzle** y que la GUI me avise si hay duplicados mientras escribo.
3. Como usuario, quiero **presionar "Resolver"** y ver la solución en la grilla de resultados.
4. Como usuario, quiero **generar un puzzle aleatorio** con un clic.
5. Como usuario, quiero **guardar un puzzle** que me interesa y retomarlo después.

### Modo Desarrollador (Aprendiz de Prolog)
1. Como desarrollador, quiero **ejecutar `make test`** y ver que todos los tests pasan.
2. Como desarrollador, quiero **leer el solver** y entender cómo usa CLPFD para resolver Sudoku.
3. Como desarrollador, quiero **modificar el solver** y que la CI me avise si rompí algo.
4. Como desarrollador, quiero **agregar un ejercicio** y que se ejecute en la GUI automáticamente.

### Modo Mantenedor
1. Como mantenedor, quiero que **cada PR ejecute tests automáticamente** antes de poder mergear.
2. Como mantenedor, quiero **templates de issues** para que los reportes sean consistentes.
3. Como mantenedor, quiero **un Makefile** que verifique dependencias y prepare el entorno.

## Roadmap

### Phase 1A — Infraestructura base (v1.1)
**Timeline:** 1–2 semanas | **Esfuerzo:** 15-20h

```
Objetivo: Base sólida para desarrollo seguro.

1. Testing con plunit
   ├── Tests para sudoku_validate.pl (happy-path + edge-cases)
   ├── Tests para sudoku_solver.pl (todos los outcomes)
   └── Tests para exercises (cada ejercicio resuelve correctamente)

2. CI/CD (GitHub Actions)
   ├── Workflow .github/workflows/test.yml
   ├── Instalar SWI-Prolog en Ubuntu
   ├── Ejecutar plunit tests
   └── Badge en README

Entregable: `make test` corre localmente, CI corre en cada push.
```

### Phase 1B — UX inmediata (v1.1.5)
**Timeline:** 1–2 semanas | **Esfuerzo:** 10-15h

```
Objetivo: Mejorar experiencia sin terminal.

1. Manejo de errores en ventana
   ├── Agregar text_item de estado en GUI
   ├── Mostrar: "Puzzle resuelto", "Sin solución", "Input inválido", etc.
   └── Limpiar mensaje al cambiar input

2. Fix bugs de PR #1
   ├── Verificar que todos los ejercicios resuelven
   ├── Verificar que input inválido no crashea
   └── Tests para los bugs encontrados

Entregable: GUI muestra errores/éxito sin necesidad de ver consola.
```

### Phase 2 — UX mejorada (v1.2)
**Timeline:** 2–3 semanas | **Esfuerzo:** 25-30h

```
Objetivo: Features de valor agregado.

1. Validación en tiempo real
   ├── Colorear celdas inválidas (fondo rojo)
   ├── Verificar duplicados al escribir
   └── Deshabilitar "Resolver" si input inválido

2. Generador de puzzles aleatorios
   ├── Algoritmo: generar solución completa, luego eliminar celdas
   ├── Verificar que la solución es única
   └── Botón "Nuevo puzzle" con selector de dificultad

3. Guardar / cargar boards
   ├── Formato simple: texto plano (9 líneas, 9 números por línea)
   ├── Botón "Guardar" (dialog de archivo)
   └── Botón "Abrir" (dialog de archivo)

Entregable: GUI más interactiva, puzzles infinitos, persistencia básica.
```

### Phase 3 — Avanzado (v1.3)
**Timeline:** 2–3 semanas | **Esfuerzo:** 20-25h

```
Objetivo: Features de enseñanza y personalización.

1. Hints / paso a paso
   ├── Botón "Pista" que completa UNA celda vacía
   ├── Lógica: resolver board completo, elegir celda vacía al azar
   └── Modo "paso a paso": resolver celda por celda con delay

2. Estadísticas
   ├── Tiempo de resolución (system_time antes/después)
   ├── Dificultad estimada (celdas vacías / total)
   └── Mostrar en barra de estado

3. Temas (claro/oscuro)
   ├── Selector en menú
   └── Colores definidos para cada tema

Entregable: Herramienta de enseñanza completa.
```

## Out of Scope

- **Multi‑usuario** o servidor web.
- **Competencias** o ranking en línea.
- **Reconocimiento de imágenes** (OCR para puzzles escaneados).
- **Múltiples idiomas** (español/inglés es suficiente).

## Technical Constraints

| Constraint | Details |
|------------|---------|
| **Lenguaje** | Prolog (SWI‑Prolog ≥ 8.x) |
| **GUI** | XPCE (incluido en SWI‑Prolog, paquete `swi-prolog-x`) |
| **Testing** | `plunit` (nativo de SWI‑Prolog) |
| **CI** | GitHub Actions (Linux, con `apt install swi-prolog`) |
| **Formato de código** | Convenciones SWI‑Prolog: predicados en minúsculas, módulos claros, documentar modos de uso con `%%`. |

## Open Questions

| Question | Phase | Decision Needed |
|----------|-------|----------------|
| ¿Soportar múltiples tamaños de Sudoku (6×6, 12×12)? | 4+ | Evaluar complejidad vs. beneficio educativo. |
| ¿Usar JSON o texto plano para guardar/cargar? | 2 | JSON es más estructurado, texto es más simple de leer. |
| ¿Cómo mostrar "candidatos" (pencil marks) en XPCE? | 3 | Investigar opciones de texto en celdas. |

## Appendix

### A. Current Architecture

```
src/
├── sudoku_validate.pl   % Validación de board (forma, rango, consistencia)
├── sudoku_solver.pl     % Solver CLPFD + API de outcomes + exercises
├── sudoku_gui.pl        % GUI XPCE (dos grillas, botones, ejercicios)
└── main.pl              % Entry point (abre GUI)
```

### B. Existing Specs & Design

El proyecto ya cuenta con especificaciones detalladas y diseño en `openspec/changes/sudoku-gui-solver/`. Esta PRD extiende esos documentos con nuevas capacidades.

### C. References

- [SWI‑Prolog Documentation](https://www.swi-prolog.org/)
- [XPCE GUI Library](https://www.swi-prolog.org/pldoc/doc_for?object=section(%27packages/xpce.html%27))
- [CLPFD Constraints](https://www.swi-prolog.org/pldoc/man?section=clpfd)
- [plunit Unit Testing](https://www.swi-prolog.org/pldoc/doc_for?object=section(%27packages/plunit.html%27))

---

**Next Steps:** Aprobar esta PRD, luego crear issues para Phase 1A (testing + CI) y ejecutar.