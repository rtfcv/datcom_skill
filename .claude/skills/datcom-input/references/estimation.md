# Turning a vague description or drawing into numbers

Datcom needs concrete geometry and flight conditions. This file is the judgement layer:
how to extract them from an underspecified prompt or an image, and what to assume when a
value is missing. **Always list every assumed value back to the user** at the end.

## 0. First: establish a length scale

Every geometry number is in one unit system (`DIM FT`/`IN`/`M`/`CM`). Before measuring
anything:

1. If the description gives real dimensions (span, length, "Cessna-sized"), use them and
   set `DIM` to match (metric → `DIM M`, feet → `DIM FT`).
2. For a **drawing with no dimensions**, find ONE reference length to scale everything:
   - Ask the user for one real dimension (wingspan or fuselage length is best), **or**
   - if they want a quick model, build it in normalized units (e.g. fuselage length = 1.0)
     and **flag prominently** that all outputs are non-dimensional until a real length is
     supplied. Reference areas/lengths in OPTINS then scale consistently.
3. Measure everything else as a ratio to the reference, then multiply through.

## 1. Reading a drawing / 3-view

Identify the configuration first (body-only, wing-body, wing-body-tail, canard, flying
wing, lifting body, twin-tail, missile). Then read each view:

**Top view (planform)** → wing & tail horizontal geometry:
- span `b` → `SSPN = b/2` (theoretical semispan, centerline to tip).
- `SSPNE` = exposed semispan = `SSPN −` (half the fuselage width at the wing).
- root chord `CHRDR`, tip chord `CHRDTP`; taper λ = tip/root.
- leading-edge sweep → `SAVSI` with `CHSTAT=0.0`; if you read quarter-chord sweep use
  `CHSTAT=0.25`. Cranked/double-delta → add `SSPNOP, CHRDBP, SAVSO`, set `TYPE=2` (AR<3)
  or `3` (AR>3).
- longitudinal apex of each surface (LE of root chord) → `XW`, `XH`, `XV` measured from the
  same origin as the body `X` array (typically the nose).

**Side view** → fuselage and vertical surfaces:
- fuselage outline → the `X`/`R` (or `X`/`S`/`P`) station table (section 2).
- nose shape → `BNOSE` (1 cone, 2 ogive), `BLN` nose length, `BLA` constant-section length,
  `DS` bluntness (0 if pointed).
- vertical tail height → `VTPLNF` `SSPN`/`SSPNE`; its apex `XV`, `ZV`.
- vertical positions `ZW`, `ZH`, `ZCG` relative to the body reference line (high/mid/low
  wing → ZW positive/≈0/negative).

**Front view** → dihedral `DHDADI` (deg), and confirmation of vertical placement.

## 2. Tabulating the fuselage (BODY)

Datcom models the body as ≤20 cross-sections along X. From the side/top outline:
1. Pick 8–15 stations from nose (X small) to tail, closer together where the shape changes
   fast (nose, tail). First station usually at the nose tip, last at the base.
2. At each station read the local **half-width** `R` (top view) — simplest for a roughly
   circular/elliptical body. Set `NX` to the number of stations.
3. Better (used by the examples) — give cross-sectional area `S` and perimeter `P` too:
   - circular radius r: `R=r`, `S=π r²`, `P=2π r`.
   - elliptical half-width a, half-height c: `R=a`, `S=π a c`, `P≈π(3(a+c)−√((3a+c)(a+3c)))`.
4. Cambered / non-symmetric body (nose droop, upswept tail): add `ZU`, `ZL` upper/lower
   surface z at each station instead of relying on symmetry.
5. Ascending `X`; ends typically taper to `R=S=P=0` at a pointed nose/tail.

## 3. Flight conditions (FLTCON) — sensible defaults

Set from the described mission; otherwise default by vehicle class:

| Class | Mach set | Altitude | Alpha sweep (deg) |
|-------|----------|----------|-------------------|
| Light GA / UAV | 0.15, 0.25 | sea level–5 kft | −4,−2,0,2,4,6,8,10,12,14,16 |
| Transport / jet cruise | 0.3, 0.6, 0.8 | 30–35 kft | −2,0,2,4,6,8,10,12 |
| Fighter / supersonic | 0.6, 0.9, 1.2, 2.0 | 20–40 kft | −4,0,4,8,12,16,20 |
| Missile / hypersonic | as specified; set `HYPERS=.TRUE.` if M>4 | as specified | 0,5,10,15,20 |

`NMACH`/`NALPHA` must equal the count of values. Keep alpha in **ascending** order.

### Reynolds number
Datcom wants **Reynolds per unit length** (`RNNUB`), one value per Mach — not per chord.
Either give altitude (`ALT`, `NALT`) and let Datcom use the standard atmosphere, or compute
`RNNUB = ρ·V/μ = Re_per_length`. Approximate sea-level-to-altitude Re **per foot** per unit
Mach (i.e. multiply by Mach to get RNNUB at that Mach):

| Altitude | a (ft/s) | Re per ft per unit Mach (≈) |
|----------|----------|------------------------------|
| SL | 1116 | 7.1e6 |
| 10 kft | 1077 | 5.0e6 |
| 20 kft | 1037 | 3.4e6 |
| 30 kft | 995 | 2.2e6 |
| 40 kft | 968 | 1.35e6 |

So `RNNUB(Mach) ≈ Mach × (value above)`. Example: M=0.25 at SL → ≈0.25×7.1e6 ≈ 1.8e6 /ft.
For `DIM M`, multiply per-ft values by 3.28 to get per-metre. When altitude is unknown,
default to sea level and note it. (Datcom will `EXTRAPOLATION`-warn at very low Re; that's
informational.)

## 4. Airfoil / section characteristics

Order of preference:
1. **Named airfoil** (e.g. "NACA 2412", "NACA 65-006") → use a `NACA` control card
   (`NACA-W-4-2412`) and omit `WGSCHR`. Cleanest and most accurate. See
   `syntax-and-control.md §4` for series digit (1/4/5/6/S).
2. **Only thickness known** → give a minimal `WGSCHR`:
   `TOVC=<t/c>, XOVC=0.3, CLALPA=0.1, CLAMO=0.105, CLMAX=<below>, CMO=<camber>, LERI=<t/c-based>`.
3. **Nothing known** → assume by class:

| Class | t/c (TOVC) | CLMAX | CMO | LERI | notes |
|-------|-----------|-------|-----|------|-------|
| GA / trainer | 0.12 | 1.4 | −0.05 | 0.015 | cambered, `CAMBER=.TRUE.` |
| Transport | 0.10–0.12 | 1.3 | −0.06 | 0.012 | mild camber |
| Fighter | 0.04–0.06 | 0.9 | 0.0 | 0.004 | thin, near-symmetric |
| Tail surfaces | 0.06–0.09 | 0.9 | 0.0 | 0.006 | symmetric (CMO=0) |

`CLALPA`/`CLAMO` (per-degree lift slope) ≈ 0.10–0.11 for conventional sections. `DELTAY`
(LE sharpness) ≈ 26×(t/c) for typical 4-digit shapes if a value is needed. Tails are
symmetric → `CMO=0`, no camber flag.

## 5. CG, reference dimensions, incidence
- **XCG** (moment reference): if unstated, ~25% of the wing MAC aft of the wing apex →
  `XCG ≈ XW + 0.25·CHRDR·(cos of sweep small)`; simpler: `XCG ≈ XW + 0.25·MAC`. Flag it.
- **OPTINS** is optional — omit to let Datcom use the theoretical wing area/MAC/span, or set
  `SREF, CBARR, BLREF` explicitly if you computed them.
- Wing incidence `ALIW`, tail incidence `ALIH`: default 0 unless the description says
  otherwise (typical wing setting +1 to +2 deg).

## 6. Sanity checks before running
- `SSPNE ≤ SSPN`; `CHRDTP ≤ CHRDR`; every count var (`NX, NMACH, NALPHA, NDELTA`) equals
  its list length.
- `X` array strictly ascending; `NX` matches its length; body reference origin is the same
  one used for `XW/XH/XV/XCG`.
- Alpha ascending; one `RNNUB` per Mach.
- Flap span stations `SPANFI/SPANFO` lie **outboard** of the body side (> SSPN−SSPNE).
- Vertical tail typically has no dihedral; `VERTUP=.TRUE.` for a normal upright fin.
- All namelist lines wrap before column 80 (see `syntax-and-control.md §1`).

## 7. What to report back to the user
A short table of **Given vs. Assumed** for: units, configuration, span/chords/sweep, body
stations, tail sizes/positions, XCG, Mach/alpha/altitude/Reynolds, and airfoil choice —
so they can correct anything before trusting the numbers.
