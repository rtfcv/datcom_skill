# datcom-input — Datcom input file generator (Claude Code skill)

Turn a **vague aircraft description or a drawing/3-view** into a valid, runnable
**USAF Digital Datcom** input file (`.INP` namelist format), then validate it by running
`datcom.exe` and auto-fixing until it executes clean.

This is a [Claude Code skill](https://docs.claude.com/en/docs/claude-code). You don't run it
directly — you describe an aircraft to Claude Code and it follows `SKILL.md` to produce the
deck. This README is for the human operator: how to install, use, and troubleshoot it.

---

## What it produces

A Datcom `.INP` deck for the described vehicle, validated against the solver, plus a
**Given vs. Assumed** summary of every value Claude chose so you can correct anything before
trusting it. Full aerodynamic output is written next to the input as `datcom.out`.

Covers conventional aircraft (body + wing + horizontal/vertical tail), canards, high-lift
devices, twin verticals, prop/jet power, and Datcom's special configurations (low-aspect
lifting bodies, transverse-jet, hypersonic flap).

## Requirements

- **Windows + PowerShell** (the validator is `scripts/run_datcom.ps1`).
- **`datcom.exe`** — the Digital Datcom solver. In this repo it lives at
  `references/datcom.exe`, and the validator finds it automatically. See *Deploy* below for
  use outside this repo.

## Deploy / install

Claude Code discovers skills at session start. Pick the scope you want:

### A. In this repo (zero config — recommended)
The skill is at `.claude/skills/datcom-input/`. Just start a Claude Code session with this
repo as the working directory. The validator auto-locates `references/datcom.exe` at the
repo root, so nothing else is needed.

### B. Available in every project (personal skill)
Copy the folder to your user skills directory **and** make the solver findable:

```powershell
Copy-Item -Recurse .claude\skills\datcom-input $HOME\.claude\skills\datcom-input
# self-contained: bundle the solver so the validator finds it by walking up
Copy-Item ..\..\..\references\datcom.exe $HOME\.claude\skills\datcom-input\references\datcom.exe
```

Alternatively, instead of bundling the exe, point the validator at it with an env var
(add to your PowerShell profile to persist):

```powershell
$env:DATCOM_EXE = "C:\path\to\datcom_skill\references\datcom.exe"
```

### C. Share with a team
Wrap it in a Claude Code plugin (`plugin.json` + this folder) and distribute via git or a
plugin marketplace.

> After installing, **start a fresh session** — an already-running session won't see a
> newly added skill.

## How to use

Just describe the aircraft to Claude Code. Examples:

- *"Make me a Datcom input for a small low-wing GA aircraft, ~9 m span, conventional tail,
  cruise around Mach 0.2."*
- *"Here's a 3-view sketch of a UAV [image]. The wingspan is 3 m. Generate a Datcom deck."*
- *"Body-only supersonic missile, 6 m long, ogive nose — Datcom input at Mach 0.9, 1.4, 2.5."*

Claude will extract geometry, fill the namelists (preferring a `NACA` airfoil card when the
airfoil is named), write the `.INP`, run the validator, fix any errors, and hand back the
file path plus its assumptions. If a value matters and can't be defaulted (e.g. no scale on
a drawing), it will ask.

## Validate a deck yourself

You can run the validator on any `.INP` directly:

```powershell
pwsh .claude\skills\datcom-input\scripts\run_datcom.ps1 path\to\model.INP
# optional explicit solver path:
pwsh .claude\skills\datcom-input\scripts\run_datcom.ps1 path\to\model.INP C:\path\to\datcom.exe
```

It prints `RESULT: PASS` / `FAIL`, the offending `datcom.out` lines on failure, and a count
of informational extrapolation/warning notes. Exit code: `0` clean, `1` errors, `2` couldn't
run.

## Package contents

| File | Purpose |
|------|---------|
| `SKILL.md` | Entry point Claude follows: the 6-step workflow. |
| `references/namelists.md` | Every namelist — variables, units, required/pairing rules. |
| `references/syntax-and-control.md` | Column/file syntax, control cards, NACA card, error catalog. |
| `references/estimation.md` | Vague text/drawing → numbers: scaling, 3-views, defaults, Reynolds, airfoils. |
| `references/templates.md` | Copy-paste skeletons per configuration + add-on blocks. |
| `scripts/run_datcom.ps1` | Runs the solver and reports PASS/FAIL with error lines. |

## Gotchas worth knowing

- **Columns 1–80 only.** Datcom silently truncates anything past column 80; a lost `$`
  terminator becomes a syntax error. The skill always wraps namelist lines.
- **The process exit code is unreliable** (a clean run may exit non-zero; a fatal case error
  can exit 0). Validation is based on markers in `datcom.out`, not the exit code.
- **`DAMP`/`TRIM` can cause intermittent silent aborts** — this old FORTRAN build reads
  uninitialized memory in the dynamic-derivative/trim paths, so the same file may abort one
  run and pass the next. The plain static run is deterministic; drop `DAMP`/`TRIM` if a case
  aborts with no error. (See `references/syntax-and-control.md §7`.)

## Notes

- Datcom's accuracy is bounded by its 1970s handbook methods; the deliverable is a valid,
  runnable model of the described geometry, not flight-test-grade data.
- Non-Windows: `datcom.exe` is a Windows build. Port `run_datcom.ps1` to launch it via your
  platform's Fortran build/emulator, keeping the same stdin-filename → `datcom.out` contract.
