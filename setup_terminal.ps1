# =============================================================
#  PowerShell Terminal Setup — Pull & Play
#  Ejecuta esto UNA vez. El resto lo hace solo.
# =============================================================

$ErrorActionPreference = "Stop"

# ── Colores helper ───────────────────────────────────────────
function Write-Step  { param($msg) Write-Host "`n  ► $msg" -ForegroundColor Cyan }
function Write-OK    { param($msg) Write-Host "    ✓ $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "    ⚠ $msg" -ForegroundColor Yellow }
function Write-Fail  { param($msg) Write-Host "    ✗ $msg" -ForegroundColor Red }

Clear-Host
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║   PowerShell Terminal Setup — v1.0       ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── 1. Directorio de trabajo ──────────────────────────────────
Write-Step "Directorio de inicio del terminal"

$defaultPath = "$env:USERPROFILE\Documents"
Write-Host "    Deja vacío para usar: $defaultPath" -ForegroundColor DarkGray
$userInput = Read-Host "    Ruta"

if ([string]::IsNullOrWhiteSpace($userInput)) {
    $workDir = $defaultPath
} else {
    $workDir = $userInput.Trim()
}

if (!(Test-Path $workDir)) {
    Write-Warn "La ruta no existe. Intentando crear..."
    try {
        New-Item -ItemType Directory -Path $workDir -Force | Out-Null
        Write-OK "Carpeta creada: $workDir"
    } catch {
        Write-Fail "No se pudo crear la carpeta. Se usará Documents."
        $workDir = "$env:USERPROFILE\Documents"
    }
} else {
    Write-OK "Directorio: $workDir"
}

# ── 2. Execution Policy ───────────────────────────────────────
Write-Step "Verificando Execution Policy"

try {
    $policy = Get-ExecutionPolicy -Scope CurrentUser
    if ($policy -in @("Restricted", "AllSigned")) {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-OK "Execution Policy -> RemoteSigned"
    } else {
        Write-OK "Execution Policy OK ($policy)"
    }
} catch {
    Write-Warn "No se pudo cambiar la Execution Policy (puede requerir admin)"
}

# ── 3. Instalar módulos ───────────────────────────────────────
Write-Step "Instalando módulos (puede tardar un momento...)"

$modules = @("Terminal-Icons", "posh-git")

foreach ($mod in $modules) {
    try {
        if (Get-Module -ListAvailable -Name $mod) {
            Write-OK "$mod ya instalado"
        } else {
            Write-Host "    Instalando $mod..." -ForegroundColor DarkGray
            Install-Module $mod -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            Write-OK "$mod instalado"
        }
    } catch {
        Write-Warn "$mod no se pudo instalar: $_"
    }
}

# ── 4. Escribir el profile ─────────────────────────────────────
Write-Step "Escribiendo profile de PowerShell"

# Asegurarse de que existe el archivo
if (!(Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

# Escapar la ruta para PowerShell
$escapedPath = $workDir -replace "'", "''"

$profileContent = @"
# ── Extra PATH ───────────────────────────────────────────────
`$extraPaths = @(
    "C:\Program Files\Git\bin"
)
foreach (`$p in `$extraPaths) {
    if (Test-Path `$p) { `$env:Path += ";`$p" }
}

# ── Módulos ──────────────────────────────────────────────────
if ((Get-Module -ListAvailable -Name posh-git) -and (Get-Command git.exe -ErrorAction SilentlyContinue)) {
    Import-Module posh-git
}
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

Import-Module PSReadLine

# ── PSReadLine ───────────────────────────────────────────────
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
Set-PSReadLineOption -MaximumHistoryCount 20000
Set-PSReadLineOption -BellStyle None

Set-PSReadLineKeyHandler -Key Tab          -Function MenuComplete
Set-PSReadLineKeyHandler -Key Ctrl+r       -Function ReverseSearchHistory
Set-PSReadLineKeyHandler -Key UpArrow      -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow    -Function HistorySearchForward

# ── Alias ────────────────────────────────────────────────────
Set-Alias ll Get-ChildItem

# ── Prompt ───────────────────────────────────────────────────
function prompt {
    `$path = (Get-Location).Path
    `$git  = `$null

    if (Get-Command git.exe -ErrorAction SilentlyContinue) {
        `$branch = git rev-parse --abbrev-ref HEAD 2>`$null
        if (`$branch) { `$git = "  [`$branch]" }
    }

    Write-Host "[`$(Get-Date -Format HH:mm)] `$path`$git > " -ForegroundColor Cyan -NoNewline
    return " "
}

# ── Directorio inicial ───────────────────────────────────────
Set-Location '$escapedPath'

Clear-Host
"@

try {
    Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8
    Write-OK "Profile escrito en: $PROFILE"
} catch {
    Write-Fail "Error al escribir el profile: $_"
    exit 1
}

# ── 5. Resultado ──────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║           ✓  Setup completado            ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Directorio de inicio : $workDir" -ForegroundColor White
Write-Host "  Profile guardado en  : $PROFILE" -ForegroundColor White
Write-Host ""
Write-Host "  Cierra y vuelve a abrir PowerShell para ver los cambios." -ForegroundColor DarkGray
Write-Host ""

Read-Host "  Pulsa Enter para cerrar"
