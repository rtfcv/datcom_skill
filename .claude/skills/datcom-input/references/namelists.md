# Digital Datcom namelist reference

Every namelist and its variables, distilled from the official *Digital Datcom Input
Quantities* tables. Group the file into cases; each case is built from these namelists
plus control cards (see `syntax-and-control.md`).

**Legend** — Dim = array length (max elements); blank/`-` = scalar. Units follow the
active `DIM` card (`FT` default, or `IN`/`M`/`CM`); `deg` and dimensionless are always
as noted. **REQ** marks namelists/variables required for a normal run.

Which namelists define which configuration is decided *by their presence*. Adding
`HTPLNF` tells Datcom the vehicle has a horizontal tail, etc. Only include the namelists
for parts the vehicle actually has.

---

## Group I — flight conditions & references

### FLTCON — Flight Conditions *(REQ for every conventional case)*
| Var | Dim | Units | Meaning |
|-----|-----|-------|---------|
| NMACH | - | - | number of Mach numbers / velocities (max 20) |
| MACH | 20 | - | freestream Mach numbers |
| VINF | 20 | l/t | freestream speeds (alternative to MACH) |
| NALPHA | - | - | number of angles of attack (max 20) |
| ALSCHD | 20 | deg | angles of attack, **ascending order** |
| RNNUB | 20 | 1/l | Reynolds number **per unit length** (one per Mach) |
| NALT | - | - | number of atmospheric conditions (max 20) |
| ALT | 20 | length | geometric altitudes |
| PINF | 20 | pressure | freestream static pressure (with VINF, no ALT) |
| TINF | 20 | deg | freestream temperature |
| HYPERS | - | - | `.TRUE.` = hypersonic analysis for all Mach > 1.4 |
| STMACH | - | - | upper Mach for subsonic analysis (0.6–0.99, dflt 0.6) |
| TSMACH | - | - | lower Mach for supersonic analysis (1.01–1.4, dflt 1.4) |
| TR | - | - | transition flag: 0 none (dflt), 1 transition strips/full-scale |
| WT | - | force | vehicle weight (trim) |
| GAMMA | - | deg | flight-path angle (trim) |
| LOOP | - | - | 1 vary alt+Mach together (dflt), 2 vary Mach at fixed alt, 3 vary alt at fixed Mach |

Supply Reynolds via **either** `RNNUB` **or** `ALT` (+ optional atmosphere). One RNNUB
per Mach. `NALPHA`+`ALSCHD` needed for aero tables.

### OPTINS — Reference dimensions *(optional; defaults to wing theoretical values)*
| Var | Units | Meaning |
|-----|-------|---------|
| SREF | area | reference area (dflt = theoretical wing area) |
| CBARR | length | longitudinal ref length / MAC (dflt = wing MAC) |
| BLREF | length | lateral ref length / span (dflt = wing span) |
| ROUGFC | length | surface roughness (dflt 0.16 milli-in / 0.4e-3 cm) |

### SYNTHS — Synthesis / component placement *(REQ for conventional configs)*
| Var | Units | Meaning |
|-----|-------|---------|
| XCG | length | longitudinal CG = moment reference center **(REQ)** |
| ZCG | length | vertical CG relative to reference plane |
| XW / ZW | length | theoretical **wing** apex location (long / vert) |
| ALIW | deg | wing root-chord incidence |
| XH / ZH | length | theoretical **horizontal tail** apex |
| ALIH | deg | horizontal-tail root incidence |
| XV / ZV | length | theoretical **vertical tail** apex |
| XVF / ZVF | length | theoretical **ventral fin** apex |
| VERTUP | - | `.TRUE.` = vertical panel above ref plane (dflt) |
| HINAX | length | horizontal-tail hinge axis (all-movable tail trim) |
| SCALE | - | multiplier applied to all input dimensions |

Apex = leading-edge point of the theoretical (root-chord) planform. Positions are in the
same length units as the geometry.

---

## Group II — basic geometry

### BODY — Fuselage geometry
| Var | Dim | Units | Meaning |
|-----|-----|-------|---------|
| NX | - | - | number of longitudinal stations (max 20) **(REQ)** |
| X | 20 | length | station x from an arbitrary origin, ascending **(REQ)** |
| S | 20 | area | cross-sectional area at each X |
| P | 20 | length | perimeter at each X |
| R | 20 | length | planform half-width at each X |
| ZU | 20 | length | upper-surface z (positive up) — cambered bodies |
| ZL | 20 | length | lower-surface z (positive down) — cambered bodies |
| BNOSE | - | - | 1 conical nose, 2 ogive nose |
| BTAIL | - | - | 1 conical tail, 2 ogive tail |
| BLN | - | length | nose length |
| BLA | - | length | cylindrical afterbody length |
| DS | - | length | nose bluntness diameter (0 = sharp) |
| ITYPE | - | - | 1 straight, 2 swept no area-rule (dflt), 3 swept area-ruled |
| METHOD | - | - | 1 existing methods (dflt), 2 Jorgensen |

Provide **S** *or* **R** (and optionally P). Axisymmetric body: give X+R (or X+S+P).
Cambered body: add ZU/ZL. `NX` must equal the number of X values.

### WGPLNF / HTPLNF / VTPLNF / VFPLNF — Planforms
Same variable set for Wing / Horizontal tail / Vertical tail / Ventral fin.
| Var | Units | Meaning |
|-----|-------|---------|
| CHRDR | length | theoretical root chord |
| CHRDTP | length | tip chord (0 for a delta) |
| CHRDBP | length | chord at the panel breakpoint (cranked/double-delta) |
| SSPN | length | theoretical semispan (centerline to tip) |
| SSPNE | length | **exposed** semispan (body side to tip) |
| SSPNOP | length | outboard-panel semispan (cranked/double-delta) |
| SAVSI | deg | inboard-panel sweep |
| SAVSO | deg | outboard-panel sweep |
| CHSTAT | - | chord fraction the sweep is referenced to (0 = LE, .25 = c/4) |
| TWISTA | deg | tip twist (negative = washout) |
| DHDADI | deg | inboard dihedral (if DHDADO equal, give only DHDADI) |
| DHDADO | deg | outboard dihedral |
| SSPNDD | length | semispan where dihedral starts |
| TYPE | - | 1 straight-tapered, 2 double-delta (AR<3), 3 cranked (AR>3) |

For a simple tapered surface: `CHRDR, CHRDTP, SSPN, SSPNE, SAVSI, CHSTAT, TYPE=1`.
Vertical tail: `SSPN`/`SSPNE` are the full/exposed height; typically no dihedral.
Supersonic interference extras (SHB, SEXT, RLPH, SVWB, SVB, SVHB) only for those regimes.

### WGSCHR / HTSCHR / VTSCHR / VFSCHR — Section (airfoil) characteristics
Required with the matching planform **unless** a `NACA` control card supplies the airfoil.
| Var | Dim | Meaning |
|-----|-----|---------|
| TOVC | - | max thickness / chord |
| XOVC | - | chordwise location of max thickness |
| DELTAY | - | LE sharpness param = (ordinate@6% − @15%)·... (percent chord) |
| LERI / LERO | - | LE radius (inboard / outboard), fraction of chord |
| CLI | - | section design lift coefficient |
| ALPHAI | deg | angle of attack at design CL |
| CLALPA | 20 | section lift-curve slope, **per degree** (~0.1) |
| CLAMO | - | section lift-curve slope at M=0, per deg |
| CLMAX | 20 | section max lift coefficient |
| CLMAXL | - | section CLmax at M=0 |
| CMO / CM0 | - | section zero-lift pitching moment |
| CAMBER | - | `.TRUE.` cambered section flag |
| TCEFF | - | planform effective t/c |
| XAC | - | section aerodynamic center, fraction of chord |
| DWASH | - | subsonic downwash method: 1, 2, or 3 |
| TYPEIN | - | airfoil-coordinate mode: 1 upper+lower, 2 mean+thickness |

Outboard-panel variants for cranked wings: `TOVCO, XOVCO, CMOT/CM0T`.
**Coordinate input** (when `TYPEIN` set): `NPTS`, `XCORD(50)`, `YUPPER(50)`, `YLOWER(50)`
(TYPEIN=1) or `MEAN(50)`, `THICK(50)` (TYPEIN=2); require first x=0, last x=1, ends=0.

> Minimal usable section set for an unknown airfoil:
> `TOVC, XOVC=0.3, DELTAY, CLALPA=0.1, CLMAX, CMO, LERI, CLAMO=0.105`.
> Prefer a `NACA` card when the airfoil is named — it computes all of this.

---

## Group II — controls (attached to wing/tail)

### SYMFLP — Symmetric trailing/leading-edge flaps
`NDELTA` (# deflections, max 9), `DELTA(9)` deflection angles (streamwise, deg),
`FTYPE` (1 plain, 2 single-slotted, 3 fowler, 4 double-slotted, 5 split, 6 LE, 7 TE,
8 Krueger), `NTYPE` (1 round/2 elliptic/3 sharp nose), `SPANFI`/`SPANFO` (in/outboard span
stations), `CHRDFI`/`CHRDFO` (flap chords), `CB`, `TC`, `PHETE`, `PHETEP`. Jet-flap extras:
`CMU, DELJET, JETFLP, EFFJET`.

### ASYFLP — Asymmetric controls (ailerons, spoilers, differential tail)
`STYPE` (1 flap-spoiler, 2 plug-spoiler, 3 spoiler-slot-deflector, 4 plain aileron,
5 differential all-movable HT), `NDELTA`, `DELTAL(9)`/`DELTAR(9)` (L/R deflections, deg),
spoiler set `DELTAS/DELTAD/XSOC/HSOC/XSPRME`, `SPANFI/SPANFO`, `CHRDFI/CHRDFO`, `PHETE`.

### CONTAB — Control tabs
`TTYPE` (1 tab / 2 trim tab / 3 both), inboard/outboard chords & spans for control tab
(`CFITC/CFOTC/BITC/BOTC`) and trim tab (`CFITT/CFOTT/BITT/BOTT`), plus hinge-moment params
`B1..B4, D1..D3, GCMAX, KS, RL, BGR, DELR`.

---

## Group III — special configurations & power

### PROPWR — Propeller power
`AIETLP` (thrust-axis incidence, deg), `NENGSP` (1 or 2), `THSTCP` (thrust coeff),
`PHALOC/PHVLOC` (hub axial/vertical), `PRPRAD` (radius), `ENGFCT`, `BWAPR3/6/9` (blade
widths), `NOPBPE` (blades/engine), `BAPR75` (blade angle @0.75R), `CROT` (counter-rotating),
`YP` (lateral engine location).

### JETPWR — Jet power
`AIETLJ` (incidence), `NENGSJ` (1 or 2), `THSTCJ` (thrust coeff), inlet `JIALOC/JINLTA`,
exit `JEALOC/JEVLOC/JELLOC/JEANGL/JEVELO/JESTMP/JETOTP/JERAD`, ambient `AMBTMP/AMBSTP`.

### LARWB — Low-aspect-ratio wing / wing-body (lifting body) *(used INSTEAD of Group II)*
`SREF, AR, L` (ref length), `SWET, SBASE, PERBAS, HB, BB` (base geometry), `SFRONT`,
`DELTEP`/`R3LEOB`/`DELTAL` (LE params), `THETAD` (semi-apex), `ROUNDN` (rounded nose T/F),
`ZB, XCG, BLF, SBS, SBSLB, XCENSB, XCENW`. A LARWB case needs only `FLTCON` + `LARWB`.

### TVTPAN — Twin vertical panels
`BVP` (span above lifting surface), `BV` (panel span), `BDV` (fuselage depth @ c/4),
`BH` (distance between panels), `SV` (one-panel area), `VPHITE` (TE angle), `VLP`
(long. arm from CG, +aft), `ZP` (vertical arm, +above CG).

### TRNJET — Transverse-jet control
`NT` (# time points, max 10), `TIME(10)`, `FC(10)` (trim force), `ALPHA(10)`, `LAMNRJ(10)`
(laminar T/F), `ME` (exit Mach), `ISP`, `SPAN`, `PHE`, `GP`, `CC`, `LFP`.

### HYPEFF — Hypersonic flap control
`ALITD` (altitude), `XHL` (hinge distance from LE), `TWOTI` (wall/freestream temp ratio),
`CF` (control chord), `LAMNR` (laminar T/F), `HNDLTA` (# deflections, max 10), `HDELTA(10)`.

### GRNDEF — Ground effect
`NGH` (# ground heights), `GRDHT(10)` (reference-plane heights above ground).

### EXPR / EXPRnn — Experimental-data substitution
Per-component measured tables to override Datcom methods: body `CDB/CLB/CMB/CLAB/CMAB`,
wing `CDW/CLW/...`, tail `CDH/...`, wing-body `CDWB/...`, plus `QOQINF, EPSLON, DEODA` and
scalars `ALPOW, ALPLW, ACLMW, CLMW, ALPOH, ALPLH, ACLMH, CLMH`. Numbered `EXPR01`, `EXPR02`
apply to successive build-up steps.

---

## Required-namelist quick rules
- Conventional case must have **FLTCON** and **SYNTHS**.
- Each planform requires its section characteristics **or** a NACA card:
  WGPLNF↔WGSCHR/`NACA-W`, HTPLNF↔HTSCHR/`NACA-H`, VTPLNF↔VTSCHR/`NACA-V`, VFPLNF↔VFSCHR/`NACA-F`.
- `LARWB`, `TRNJET`, `HYPEFF` are stand-alone special cases (with FLTCON); don't mix with
  Group II planforms.
- Control/power namelists (SYMFLP, ASYFLP, PROPWR, JETPWR, TVTPAN, GRNDEF) attach to an
  existing basic configuration.
