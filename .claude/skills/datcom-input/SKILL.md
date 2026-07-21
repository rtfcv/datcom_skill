---
name: datcom-input
description: >-
  Create a USAF Digital Datcom input file (.INP namelist format) from a vague
  aircraft description, spec, or drawing/3-view image, then validate it by
  running datcom.exe and fixing errors until it executes clean. Use whenever the
  user wants a Datcom / DATCOM input deck, stability & control geometry model,
  aerodynamic coefficient run, or to convert an aircraft/missile/lifting-body
  concept into Datcom namelists (FLTCON, SYNTHS, BODY, WGPLNF, HTPLNF, VTPLNF,
  etc.).
---

# Datcom input-file generator

Turn an underspecified aircraft (text description or drawing) into a **valid, runnable**
USAF Digital Datcom input file, and prove it by running the solver and repairing any errors.

Datcom is a 1970s FORTRAN program with strict, unforgiving input rules (column-1 control
cards, `$NAMELIST … $` blocks, a hard 80-column limit, required namelist pairings). This
skill supplies the distilled knowledge and a validation loop so the output actually runs.

## Reference files (read as needed)
- `references/namelists.md` — every namelist and variable, with units and required/pairing rules.
- `references/syntax-and-control.md` — file/column syntax, control cards, the NACA airfoil card, and the **error catalog** (marker → fix) used in step 5.
- `references/estimation.md` — how to turn vague text or a drawing into numbers: length-scaling, reading 3-views, fuselage tabulation, default flight envelope, Reynolds, airfoils, CG.
- `references/templates.md` — copy-paste skeletons per configuration + add-on blocks.
- `scripts/run_datcom.ps1` — runs `datcom.exe` on a file and reports PASS/FAIL with error lines.

## Workflow

### 1. Gather geometry & conditions
Determine the configuration (body-only, wing-body, wing-body-tail, canard, flying wing,
lifting body, twin-tail, missile) and collect dimensions.
- Follow `references/estimation.md`. **Establish one real length scale first**; for a
  drawing with no dimensions, ask the user for one reference length (span or fuselage
  length) or build a normalized model and flag it.
- Read top/side/front views for planform, fuselage stations, tail sizes/positions, dihedral.
- Note explicitly what was **given** vs. what you will **assume**.

If a critical, non-defaultable fact is missing (e.g. no scale at all, or the config is
ambiguous), ask the user a brief question before proceeding.

### 2. Pick the configuration recipe
Choose the matching skeleton in `references/templates.md` (A wing-body-tail is the default
"aircraft"). Add-on blocks (flaps, ailerons, twin verticals, power, ground effect) layer
onto a basic configuration.

### 3. Fill the namelists
Use `references/namelists.md` for names/units and `references/estimation.md` for defaults
(Mach/alpha/altitude, Reynolds-per-unit-length, section characteristics, CG). **Prefer a
`NACA` control card** when the airfoil is named; otherwise fill the `*SCHR` namelist with
class-based estimates. Run the sanity checks in `estimation.md §6`.

### 4. Emit the file
Write a `.INP` obeying `references/syntax-and-control.md`:
- Control cards (`DIM`, `NACA-…`, `DAMP`, `TRIM`, `CASEID`, `NEXT CASE`) start in **column 1**.
- Namelist lines start with a **leading blank** and **wrap before column 80**.
- Follow the recommended ordering; include required pairings (planform ↔ section/NACA).
- Give the file a short basename (e.g. `model.INP`) — the runner passes the basename to the exe.

### 5. Validate & auto-fix (do not skip)
Run the solver and iterate until clean:
```
pwsh <skill>/scripts/run_datcom.ps1 <path>/model.INP
```
- `RESULT: PASS` → the case ran and produced output tables. Note any `EXTRAPOLATION` /
  `*** WARNING` lines as **informational** (Datcom charts stretched, or `NDM` = no method
  for that quantity) — not failures.
- `RESULT: FAIL` **with** error lines → look each marker up in the **error catalog**
  (`syntax-and-control.md §7`), fix the `.INP`, and re-run. Most common real fixes: wrap a
  line that passed column 80, add a missing `*SCHR` namelist or `NACA` card, correct a count
  variable (`NX`/`NMACH`/`NALPHA`), fix a variable name.
- `RESULT: FAIL` **with no error lines** (silent abort — parsed fine but the solver crashed
  mid-computation) → first remove `DAMP`/`TRIM` if present, then simplify suspicious geometry
  or bisect the configuration. See `syntax-and-control.md §7 "Silent abort"`.
- The runner auto-detects `references/datcom.exe`; override with `-Exe <path>` or
  `$env:DATCOM_EXE` if needed. Full aero output is written next to the input as `datcom.out`.

### 6. Summarize
Give the user: the path to the `.INP` (and `datcom.out`), a **Given vs. Assumed** table for
every value you chose, and a note that Datcom's accuracy is bounded by its handbook methods —
the deliverable is a valid, runnable model of the described geometry, not flight-test data.

## Notes
- Cover all Datcom configurations, including special cases (LARWB lifting body, transverse
  jet, hypersonic flap) and power/control add-ons — see `templates.md` and `namelists.md`.
- Don't modify anything under the repo's `references/` folder; the skill only *runs* the
  `datcom.exe` there.
- Non-Windows: `datcom.exe` is a Windows build; port `run_datcom.ps1` to invoke it via the
  platform's Fortran build/emulator, keeping the same stdin-filename + `datcom.out` contract.
