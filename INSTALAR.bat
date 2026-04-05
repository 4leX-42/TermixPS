@echo off
:: ═══════════════════════════════════════════════════
::  PowerShell Terminal Setup — Lanzador
::  Haz doble clic aquí. No toques nada más.
:: ═══════════════════════════════════════════════════

:: Buscar pwsh (PowerShell 7) o caer a powershell.exe (v5)
where pwsh >nul 2>&1
if %errorlevel%==0 (
    set PS=pwsh
) else (
    set PS=powershell
)

:: Ejecutar el script con bypass de política para este proceso
%PS% -NoLogo -ExecutionPolicy Bypass -File "%~dp0setup_terminal.ps1"
