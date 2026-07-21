# Datcom input templates

Copy-paste skeletons for each configuration, distilled from the 11 verified example cases.
Fill the `<PLACEHOLDER>` values, keep every line wrapped before **column 80**, and keep the
leading blank on namelist lines (control cards stay in column 1). See `namelists.md` for
variable meanings and `syntax-and-control.md` for the rules. Prefer a `NACA` card over the
`*SCHR` namelist when the airfoil is named.

---

## A. Wing-body-tail (the default "aircraft")  ← start here

Conventional fuselage + wing + horizontal + vertical tail. Structure follows EX7/EX8.

```
DIM FT
 $FLTCON NMACH=1.0, MACH(1)=<M>, NALPHA=9.0,
    ALSCHD(1)=-2.0,0.0,2.0,4.0,8.0,12.0,16.0,20.0,24.0,
    RNNUB(1)=<RE_PER_LEN>$
 $OPTINS SREF=<Sref>, CBARR=<MAC>, BLREF=<span>$
 $SYNTHS XCG=<xcg>, ZCG=0.0, XW=<xw>, ZW=<zw>, ALIW=<iw>,
    XH=<xh>, ZH=<zh>, ALIH=0.0, XV=<xv>, VERTUP=.TRUE.$
 $BODY NX=<n>,
    X(1)=<x1>,<x2>,...,<xn>,
    R(1)=<r1>,<r2>,...,<rn>$
 $WGPLNF CHRDTP=<ct>, SSPNE=<be2>, SSPN=<b2>, CHRDR=<cr>,
    SAVSI=<sweep>, CHSTAT=0.25, TWISTA=0.0, SSPNDD=0.0,
    DHDADI=<dih>, DHDADO=<dih>, TYPE=1.0$
 $WGSCHR TOVC=<t/c>, DELTAY=<dy>, XOVC=0.4, CLI=0.0, ALPHAI=0.0,
    CLALPA(1)=0.105, CLMAX(1)=<clmax>, CMO=<cmo>, LERI=<le>,
    CLAMO=0.105$
 $VTPLNF CHRDTP=<vct>, SSPNE=<vbe>, SSPN=<vb>, CHRDR=<vcr>,
    SAVSI=<vsweep>, CHSTAT=0.25, TWISTA=0.0, TYPE=1.0$
 $VTSCHR TOVC=0.09, XOVC=0.4, CLALPA(1)=0.105, LERI=0.006$
 $HTPLNF CHRDTP=<hct>, SSPNE=<hbe>, SSPN=<hb>, CHRDR=<hcr>,
    SAVSI=<hsweep>, CHSTAT=0.25, TWISTA=0.0, SSPNDD=0.0,
    DHDADI=0.0, DHDADO=0.0, TYPE=1.0$
 $HTSCHR TOVC=0.06, XOVC=0.4, CLALPA(1)=0.105, CLMAX(1)=0.9,
    CMO=0.0, LERI=0.005, CLAMO=0.105$
CASEID <TITLE>
NEXT CASE
```

**Airfoil-by-name variant** — replace each `*SCHR` namelist with a NACA card (column 1):
```
NACA-W-4-2412
NACA-V-4-0009
NACA-H-4-0006
```

Add `DAMP` (dynamic derivatives) and/or `TRIM` as column-1 cards before `CASEID`
**only if requested**. These exercise Datcom's most fragile methods and can make the solver
**silently abort** (output truncates, no error marker, no coefficient table) for some
geometries — sometimes **intermittently** (same file aborts one run, passes the next). The
static run without them is far more robust and deterministic. If a run aborts with no error
but no table, remove `DAMP`/`TRIM` first (see `syntax-and-control.md §7`).

---

## B. Body only (axisymmetric or cambered) — EX1

```
DIM FT
 $FLTCON NMACH=1.0, MACH(1)=<M>, NALPHA=11.0,
    ALSCHD(1)=-6.0,-4.0,-2.0,0.0,2.0,4.0,8.0,12.0,16.0,20.0,24.0,
    RNNUB=<RE_PER_LEN>$
 $OPTINS SREF=<Sref>, CBARR=<ref_len>, BLREF=<ref_len>$
 $SYNTHS XCG=<xcg>, ZCG=0.0$
 $BODY NX=<n>, BNOSE=<1cone|2ogive>, BLN=<nose_len>, BLA=<mid_len>,
    X(1)=<x1>,...,<xn>,
    R(1)=<r1>,...,<rn>,
    S(1)=<s1>,...,<sn>,
    P(1)=<p1>,...,<pn>$
CASEID <TITLE>
NEXT CASE
```
Cambered body: add `ZU(1)=...` and `ZL(1)=...` arrays. No SYNTHS wing/tail needed.

---

## C. Wing alone (exposed / cranked / double-delta) — EX2

```
DIM FT
 $FLTCON NMACH=1.0, MACH(1)=<M>, NALPHA=11.0,
    ALSCHD(1)=-6.0,-4.0,-2.0,0.0,2.0,4.0,8.0,12.0,16.0,20.0,24.0$
 $OPTINS SREF=<Sref>, CBARR=<MAC>, BLREF=<span>$
 $SYNTHS XW=<xw>, ZW=<zw>, ALIW=<iw>, XCG=<xcg>$
 $WGPLNF CHRDTP=<ct>, SSPNE=<be2>, SSPN=<b2>, CHRDR=<cr>,
    SAVSI=<sweep>, CHSTAT=0.0, TWISTA=0.0, SSPNDD=0.0,
    DHDADI=0.0, DHDADO=0.0, TYPE=1.0$
 $WGSCHR DELTAY=<dy>, XOVC=0.4, CLALPA=0.105, TOVC=<t/c>,
    CLMAX(1)=<clmax>, CMO=<cmo>, LERI=<le>, CLAMO=0.105, TCEFF=<t/c>$
CASEID <TITLE>
NEXT CASE
```
Cranked wing: add `SSPNOP, CHRDBP, SAVSO`, set `TYPE=3.0`. Double-delta: `TYPE=2.0`.

---

## D. Body + wing + canard — EX4

A canard is entered as the **horizontal tail forward of the wing** (`XH < XW`). Same
namelists as template A; just place `XH` ahead of the wing and size `HTPLNF` as the canard.
`NACA-W-…` / `NACA-H-…` cards work here too. Include `SHB, SEXT, RLPH` in `HTPLNF` for
supersonic interference if running supersonic (see EX4).

---

## E. Lifting body (low aspect ratio) — EX9  *(uses LARWB instead of Group II)*

```
DIM FT
 $FLTCON NMACH=1.0, MACH(1)=<M>, NALPHA=6.0,
    ALSCHD(1)=-5.0,0.0,5.0,10.0,15.0,20.0, RNNUB(1)=<RE_PER_LEN>$
 $LARWB ZB=0.0, SREF=<Sref>, DELTEP=<LE_angle>, SFRONT=<frontal_area>,
    AR=<aspect_ratio>, L=<ref_len>, SWET=<wetted_area>,
    PERBAS=<base_perimeter>, SBASE=<base_area>, HB=<base_height>,
    BB=<base_span>, BLF=.FALSE., XCG=<xcg>, THETAD=<semi_apex_deg>,
    ROUNDN=.FALSE., SBS=<side_area>, SBSLB=<fwd_side_area>,
    XCENSB=<x_side_centroid>, XCENW=<x_plan_centroid>$
CASEID <TITLE>
NEXT CASE
```

---

## F. Transverse-jet reaction control (sizing) — EX10

```
DIM FT
 $FLTCON NMACH=1.0, MACH(1)=<M>, RNNUB(1)=<RE>, PINF(1)=<p>,
    HYPERS=.TRUE.$
 $TRNJET NT=5.0,
    TIME(1)=1.,2.,3.,4.,5.,
    FC(1)=<f1>,<f2>,<f3>,<f4>,<f5>,
    ALPHA(1)=0.,3.,6.,9.,13.,
    LAMNRJ=.FALSE.,.FALSE.,.FALSE.,.FALSE.,.TRUE.,
    ME=<exitMach>, ISP=<Isp>, SPAN=<nozzle_span>, PHE=<incl_deg>,
    GP=<gamma>, CC=<discharge_coef>, LFP=<x_from_LE>$
CASEID <TITLE>
NEXT CASE
```

---

## G. Flat plate / surface with hypersonic flap — EX11

```
DIM FT
 $FLTCON NMACH=1.0, MACH(1)=<M>, RNNUB(1)=<RE>,
    NALPHA=5.0, ALSCHD(1)=0.0,5.0,10.0,15.0,20.0, HYPERS=.TRUE.$
 $OPTINS SREF=1.0, CBARR=1.0$
 $HYPEFF ALITD=<altitude>, XHL=<hinge_from_LE>, TWOTI=<Tw/Tinf>,
    CF=<control_chord>, HNDLTA=<n>,
    HDELTA(1)=0.,2.,4.,6.,10.,12.,16.,20.,25.,30.,
    LAMNR=.TRUE.$
CASEID <TITLE>
NEXT CASE
```

---

## Add-on blocks (drop into a basic configuration)

**Symmetric flaps (SYMFLP)** — needs a wing; add `TRIM` for trimmed high-lift:
```
 $SYMFLP FTYPE=1.0, NDELTA=6.0,
    DELTA(1)=0.,10.,20.,30.,40.,60.,
    PHETE=0.0522, PHETEP=0.0391, SPANFI=<in>, SPANFO=<out>,
    CHRDFI=<ci>, CHRDFO=<co>, CB=<balance_c>, TC=<hinge_t>, NTYPE=1.0$
```
FTYPE: 1 plain, 2 slotted, 3 fowler, 4 double-slotted, 5 split, 6 LE flap.

**Aileron / differential control (ASYFLP)**:
```
 $ASYFLP STYPE=4.0, NDELTA=5.0,
    DELTAL(1)=5.,10.,20.,30.,40.,
    DELTAR(1)=-2.,-5.,-10.,-15.,-20.,
    CHRDFI=<ci>, CHRDFO=<co>, SPANFI=<in>, SPANFO=<out>, PHETE=0.0522$
```
STYPE: 1/2/3 spoiler variants, 4 plain aileron, 5 differential all-movable HT.

**Twin vertical tails (TVTPAN)** — replaces the single VT for H-tail/twin-boom layouts:
```
 $TVTPAN BVP=<span_above>, BV=<panel_span>, BDV=<fus_depth_c4>,
    BH=<gap_between>, SV=<one_panel_area>, VPHITE=<TE_angle>,
    VLP=<arm_from_CG>, ZP=<vert_arm>$
```

**Propeller power (PROPWR)** / **Jet power (JETPWR)** — add to a wing-body(-tail); needs a
single-Mach FLTCON. See `namelists.md` for the full variable list (EX3 cases 4 & 5).

**Ground effect (GRNDEF)**:
```
 $GRNDEF NGH=<n>, GRDHT(1)=<h1>,<h2>,...$
```

---

## Multi-case with SAVE (parametric studies)

Only the *changes* need re-stating after `SAVE`; NACA/DERIV/DIM persist automatically.
```
   ...full case A namelists...
CASEID BASELINE
SAVE
NEXT CASE
 $FLTCON MACH(1)=<newM>$        (only what changed)
CASEID HIGHER MACH
NEXT CASE
```
