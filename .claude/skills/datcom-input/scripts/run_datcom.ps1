<#
.SYNOPSIS
    Run USAF Digital Datcom on an input file and report pass/fail with the
    relevant error lines, so the calling skill can validate and auto-fix.

.DESCRIPTION
    Datcom (datcom.exe) prompts for the input file name on stdin and writes
    "datcom.out" to the current working directory. This wrapper:
      * locates datcom.exe (param -> $env:DATCOM_EXE -> search upward for
        references/datcom.exe),
      * runs it from the input file's own directory (so datcom.out lands there),
      * scans datcom.out for the reliable failure markers (the process exit code
        is NOT trustworthy: a fatal case error still exits 0),
      * prints a concise PASS/FAIL report plus any error lines and a count of
        informational extrapolation warnings,
      * removes the for0*.dat scratch files.

    Exit code of THIS script: 0 = clean, 1 = errors found, 2 = could not run.

.PARAMETER InputFile
    Path to the Datcom .INP file to run.

.PARAMETER Exe
    Optional explicit path to datcom.exe. Overrides auto-detection.

.EXAMPLE
    pwsh scripts/run_datcom.ps1 model.INP
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $InputFile,

    [Parameter(Position = 1)]
    [string] $Exe
)

$ErrorActionPreference = 'Stop'

function Resolve-DatcomExe {
    param([string] $Explicit)

    if ($Explicit) {
        if (Test-Path -LiteralPath $Explicit) { return (Resolve-Path -LiteralPath $Explicit).Path }
        throw "datcom.exe not found at -Exe path: $Explicit"
    }
    if ($env:DATCOM_EXE -and (Test-Path -LiteralPath $env:DATCOM_EXE)) {
        return (Resolve-Path -LiteralPath $env:DATCOM_EXE).Path
    }
    # Walk upward from this script looking for references/datcom.exe.
    $dir = $PSScriptRoot
    for ($i = 0; $i -lt 8 -and $dir; $i++) {
        $candidate = Join-Path $dir 'references/datcom.exe'
        if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
        $parent = Split-Path -Parent $dir
        if ($parent -eq $dir) { break }
        $dir = $parent
    }
    throw "Could not locate datcom.exe. Pass -Exe <path> or set `$env:DATCOM_EXE."
}

# --- Resolve inputs -------------------------------------------------------
if (-not (Test-Path -LiteralPath $InputFile)) {
    Write-Host "FAIL: input file not found: $InputFile"
    exit 2
}
$inp     = Resolve-Path -LiteralPath $InputFile
$workDir = Split-Path -Parent $inp
$base    = Split-Path -Leaf   $inp

try {
    $exePath = Resolve-DatcomExe -Explicit $Exe
} catch {
    Write-Host "FAIL: $($_.Exception.Message)"
    exit 2
}

# --- Run ------------------------------------------------------------------
Push-Location $workDir
try {
    # Feed the basename on stdin; suppress the banner + IEEE FP notices.
    $base | & $exePath *> $null
    $exit = $LASTEXITCODE
} finally {
    Pop-Location
}

$outPath = Join-Path $workDir 'datcom.out'
if (-not (Test-Path -LiteralPath $outPath)) {
    Write-Host "FAIL: datcom.out was not produced (exe exit $exit)."
    exit 2
}

# --- Analyze output -------------------------------------------------------
# Failure markers (case-insensitive). These do NOT appear in a clean run.
$failPattern =
    '\*\* ERROR \*\*'               + '|' +
    'MISSING NAMELIST TERMINATION'  + '|' +
    'ERROR-'                        + '|' +   # case-level, e.g. ERROR-WING PLANFORM ... MISSING NAME*WGSCHR*
    'ILLEGAL CONTROL CARD'          + '|' +
    'INCORRECT LIFTING SURFACE'     + '|' +
    'UNKNOWN NAMELIST NAME'

# A completed result section. Covers standard aero plus the special configurations
# (transverse jet, hypersonic flap, control/trim). A silent abort dies BEFORE any of
# these (typically inside a "... SECTION DEFINITION" pre-computation block), so their
# absence is the signal that the case aborted.
$resultPattern =
    'CHARACTERISTICS AT ANGLE OF ATTACK' + '|' +
    'DYNAMIC DERIVATIVE'                 + '|' +
    'CONTROL EFFECTIVENESS'              + '|' +   # hypersonic flap (HYPEFF)
    'INCREMENT IN NORMAL FORCE'          + '|' +   # hypersonic flap tables
    'HINGE MOMENT'                       + '|' +
    'TRIMMED'                            + '|' +
    'JET\('                                        # transverse jet (TRNJET) output

$errLines = Select-String -LiteralPath $outPath -Pattern $failPattern -CaseSensitive:$false
$extrap   = (Select-String -LiteralPath $outPath -Pattern 'EXTRAPOLATION' -CaseSensitive:$false | Measure-Object).Count
$tables   = (Select-String -LiteralPath $outPath -Pattern $resultPattern -CaseSensitive:$false | Measure-Object).Count
$warnings = (Select-String -LiteralPath $outPath -Pattern '\*\*\* WARNING' -CaseSensitive:$false | Measure-Object).Count

# --- Report ---------------------------------------------------------------
Write-Host "datcom.out : $outPath"
Write-Host "exe exit    : $exit   (not authoritative)"
Write-Host "result tables produced : $tables"
Write-Host "extrapolation notes    : $extrap (informational)"
Write-Host "*** WARNING notes      : $warnings (review, usually non-fatal)"

if ($errLines) {
    Write-Host ""
    Write-Host "==== ERRORS (fix these) ===="
    foreach ($m in $errLines) {
        Write-Host ("  line {0}: {1}" -f $m.LineNumber, $m.Line.Trim())
    }
    Write-Host "============================"
}

# Clean up scratch files Datcom leaves behind.
Get-ChildItem -LiteralPath $workDir -Filter 'for0*.dat' -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

if ($errLines) {
    Write-Host ""
    Write-Host "RESULT: FAIL - $($errLines.Count) error line(s)."
    exit 1
}
if ($tables -eq 0) {
    Write-Host ""
    Write-Host "RESULT: FAIL - no result section found (silent abort; no input error). Try removing DAMP/TRIM or simplifying geometry. Check datcom.out."
    exit 1
}
Write-Host ""
Write-Host "RESULT: PASS - ran clean with output."
exit 0
