# Datcom file syntax, control cards & error catalog

The rules that make an input file *parse*. Getting these wrong is the #1 cause of failed
runs. Verified against the 11 example cases and by running the solver.

## 1. Column & line rules (critical)

- **Only columns 1–80 are read.** Anything past column 80 is silently discarded. If a
  namelist's terminating `$` falls past column 80 it is lost and you get
  `** MISSING NAMELIST TERMINATION ADDED **` + a syntax error. **Wrap long lines.**
- **Column 1 is reserved for control cards.** A namelist must therefore begin with at
  least one leading blank so its opening `$` is in column 2+. Control cards (DIM, CASEID,
  NEXT CASE, SAVE, NACA-…, DAMP, TRIM, BUILD, DUMP, DERIV, PART, PLOT, NAMELIST) start in
  column 1 with no leading space.
- Free-field within a namelist: spaces are ignored, items separated by commas.

## 2. Namelist syntax

```
 $NAME  VAR=value, VAR2=v, ARR(1)=a,b,c,d, FLAG=.TRUE. $
```
- Opens with `$NAME` (leading blank → not column 1), closes with a trailing `$`.
- A namelist may span many lines; continue by just starting the next line with a blank and
  more `VAR=…` items. Break lines at a comma, before column 80.
- Arrays are filled from an index: `X(1)=0.0,0.175,0.322,…`. The count assigned must not
  exceed the array's dimension (else CONERR code E).
- Reals should carry a decimal point (`10.0`, not `10`); exponent form `4.28E6` is fine.
- Booleans are `.TRUE.` / `.FALSE.`.
- The **same namelist may appear twice** in a case; later values update earlier ones (the
  examples use this to keep lines short, e.g. two `$WGSCHR` blocks).

## 3. Control cards (start in column 1)

### Units — pick one; `DIM FT` is the default
`DIM FT` · `DIM IN` · `DIM M` · `DIM CM` — sets the unit system for **all** input and
output lengths/areas. Choose the one matching your geometry numbers. (Persists across
SAVE.)

### Case control
- `CASEID <text>` — case title, text in **columns 7–80** (i.e. `CASEID ` then text). One
  per case; appears in the output header. Put it right before `NEXT CASE`.
- `NEXT CASE` — ends a case and starts execution. The only card that must **not** appear
  mid-namelist. Optional after the final case (if both SAVE and NEXT CASE end the last
  case, that case runs twice).
- `SAVE` — preserve this case's namelist data for the next case (which then only needs the
  *changes*). Only NACA/DERIV/DIM control cards persist across SAVE; total namelist
  appearances across consecutive SAVE cases ≤ 300.
- `NAMELIST` — echo each namelist's contents in the input unit system (debugging).

### Execution control
- `DAMP` — add dynamic (pitch/roll/yaw acceleration) derivative output.
- `TRIM` — compute trim (Cm=0) at each subsonic Mach; needs a control device (SYMFLP/
  ASYFLP or all-movable HT via HINAX), and usually `WT`/`GAMMA` in FLTCON.
- `BUILD` — output build-up: each component and combination separately.
- `PART` — auxiliary/partial output at each Mach (automatic at transonic Mach).
- `PLOT` — write a plot file (unit 13).

### Output control
- `DUMP CASE` / `DUMP INPUT` / `DUMP ALL` / `DUMP <ARR1>,<ARR2>` — dump internal arrays.
- `DERIV DEG` (default) / `DERIV RAD` — units of reported derivatives. (Persists like DIM.)

## 4. NACA airfoil card

Supplies an airfoil by designation and auto-computes the section characteristics, so you
can omit the matching `*SCHR` namelist. Fixed columns:

```
col: 1234 5 6 7 8 9 10...
     NACA - W - 4 - 2412
```
| Cols | Content | Values |
|------|---------|--------|
| 1–4 | `NACA` | literal |
| 5 | delimiter | any (`-`) |
| 6 | surface | `W` wing, `H` horiz tail, `V` vert tail, `F` ventral fin |
| 7 | delimiter | any (`-`) |
| 8 | series | `1`, `4`, `5`, `6`, or `S` (supersonic) |
| 9 | delimiter | any (`-`) |
| 10–80 | designation | free-field, ≤15 chars |

Vocabulary allowed in the designation: `0-9`, `A`, and `, . - =`. Anything else becomes 0.
Examples from the manual/examples:
- `NACA-W-4-2412` — 4-digit wing airfoil.
- `NACA-W-6-65A004` — 6-series.
- `NACA-W-S-3-30.0-2.5-20.0` — supersonic (double-wedge type) wing section.
- `NACA-H-6-65A004` — horizontal tail.

Applies to **both** panels of cranked/double-delta planforms. If airfoil coordinates are
also given for the same surface, the coordinates win. NACA cards persist across SAVE.

## 5. Required pairings & essential namelists
- **FLTCON** and **SYNTHS** are required for a conventional case.
- Every planform namelist needs its section data or a NACA card:
  `WGPLNF`→`WGSCHR`/`NACA-W`; `HTPLNF`→`HTSCHR`/`NACA-H`; `VTPLNF`→`VTSCHR`/`NACA-V`;
  `VFPLNF`→`VFSCHR`/`NACA-F`. Conversely a section namelist needs its planform.
- Special configs (`LARWB`, `TRNJET`, `HYPEFF`) run with just `FLTCON` (+ maybe OPTINS),
  not the Group II planforms.

## 6. Recommended ordering (avoids "forgot a namelist")

```
DIM <unit>            (optional; column 1)
 $FLTCON ... $
 $OPTINS ... $        (optional)
 $SYNTHS ... $
 $BODY   ... $        (if there is a fuselage)
 $WGPLNF ... $        \ wing
 $WGSCHR ... $        / (or NACA-W card)
 $VTPLNF ... $        \ vertical tail
 $VTSCHR ... $        /
 $HTPLNF ... $        \ horizontal tail
 $HTSCHR ... $        /
 ...control/power namelists (SYMFLP, PROPWR, ...)
DAMP / TRIM / BUILD   (optional execution cards, column 1)
CASEID <title>
NEXT CASE
```
Namelists and most control cards may technically appear in any order; following this
layout prevents the most common omissions. Repeat the block after `NEXT CASE` (optionally
with `SAVE`) for additional cases.

## 7. Error catalog (what the runner surfaces → the fix)

`scripts/run_datcom.ps1` greps `datcom.out` for these. The `CONERR - INPUT ERROR CHECKING`
header and its `0 A/0 B/…` code list appear even on a clean run — ignore those; act on the
markers below.

| Marker in datcom.out | Cause | Fix |
|----------------------|-------|-----|
| `** ERROR ** … n*A` | unknown variable name (n>0 for code A) | misspelled variable; check `namelists.md` |
| `… n*B` | missing `=` after a variable | add the equals sign |
| `… n*C` | array index `(N)` on a scalar variable | remove the `(1)` from a scalar |
| `… n*D` | scalar assigned multiple values | give one value, or it should be an array |
| `… n*E` | more values than the array holds | trim the list / raise the count var (NX, NMACH…) |
| `… n*F` | syntax error | usually a line ran past col 80 losing `$`, or a stray char — **wrap the line** |
| `** MISSING NAMELIST TERMINATION ADDED **` | no closing `$` found | add `$`, and check col-80 wrap |
| `** ILLEGAL CONTROL CARD` / `UNKNOWN NAMELIST NAME` | control card / namelist misspelled or `$` in column 1 | fix spelling; ensure namelist has a leading blank |
| `INCORRECT LIFTING SURFACE DESIGNATION ON NACA CARD` | col 6 not W/H/V/F | fix the NACA card column layout |
| `ERROR-FLIGHT CONDITIONS NOT PRESENT … *FLTCON*` | FLTCON missing | add FLTCON |
| `ERROR-SYNTHESIS DATA MISSING … *SYNTHS*` | SYNTHS missing | add SYNTHS (at least XCG) |
| `…SECTION CHARACTERISTICS ABSENT-MISSING NAME*WGSCHR*` (or HT/VT/VF) | planform without section data | add the `*SCHR` namelist or a `NACA-` card |
| `…PLANFORM ABSENT-MISSING NAME*WGPLNF*` (or HT/VT/VF) | section data without planform | add the planform namelist |
| `ERROR … FLAP INBOARD EDGE SPANI … INSIDE THE BODY` | SPANFI < (SSPN−SSPNE) | move SPANFI outboard of the body side |

### Silent abort (no error marker, but no output)
If the runner reports `RESULT: FAIL - no result table produced` yet prints **no** error
lines, the parse succeeded but the solver crashed mid-computation (the `datcom.out` echo of
input cards is clean and the section-definition block may be present, then output just
stops). This is a numerical failure in a Datcom method, not an input-syntax error. It can be
**intermittent** — this old FORTRAN build reads uninitialized memory in some paths, so the
*same* file may abort on one run and complete on the next. **Do not rely on a lucky re-run**;
fix the input so it succeeds deterministically. Fixes, in order:
1. **Remove `DAMP` and/or `TRIM`** — the dynamic-derivative and trim methods are the most
   common cause; the plain static run is far more robust and deterministic. (Confirmed: a
   config that aborts intermittently with `DAMP` runs clean every time without it.)
2. Simplify/round suspicious geometry (extreme aspect ratio, near-zero sweep with an add-on,
   a control-surface span error) and re-run.
3. Reduce to the basic configuration, confirm it runs, then add components back one at a
   time to find the offender.

`EXTRAPOLATION` and `*** WARNING` lines are **informational** — the run still succeeds;
report them but don't treat as failures. `NDM` in a table cell = "no Datcom method for
this quantity" (expected for some components), not an error.
