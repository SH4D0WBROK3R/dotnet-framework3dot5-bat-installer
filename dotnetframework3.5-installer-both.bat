@echo off
setlocal EnableDelayedExpansion
title Instalacion de .NET Framework 3.5

REM ---- Requiere permisos de administrador: se auto-eleva si hace falta ----
net session >nul 2>&1
if errorlevel 1 (
    echo Solicitando permisos de administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
    if errorlevel 1 (
        echo.
        echo No se concedieron los permisos de administrador.
        echo Sin ellos no se puede instalar .NET Framework 3.5.
        pause
    )
    exit /b
)
cd /d "%~dp0"

REM ---- Si ya esta habilitado, no hay nada que hacer ----
call :estado
if /i "!ESTADO!"=="Enabled" (
    echo .NET Framework 3.5 ya esta habilitado. No hay nada que hacer.
    pause
    exit /b 0
)

:menu
cls
echo ============================================================
echo   Instalacion de .NET Framework 3.5
echo ============================================================
echo.
echo   1. Instalar desde Windows Update (requiere internet)
echo   2. Instalar desde un ISO o USB de Windows (sin internet)
echo   3. Salir
echo.
choice /c 123 /n /m "Elija una opcion: "
if errorlevel 3 goto :salir
if errorlevel 2 goto :iso
goto :online

:online
echo.
echo Instalando desde Windows Update. Puede tardar varios minutos...
echo.
dism /online /enable-feature /featurename:NetFx3 /all /norestart
set "RC=!errorlevel!"
goto :verificar

:iso
echo.
echo Monte el ISO de Windows con doble clic, o conecte el USB de instalacion.
set "LETRA="
set /p "LETRA=Letra de la unidad, por ejemplo D: "
set "LETRA=!LETRA:~0,1!"
set "SRC=!LETRA!:\sources\sxs"
if not exist "!SRC!\" (
    echo.
    echo No se encontro la carpeta !SRC!
    echo Revise la letra de la unidad.
    pause
    goto :menu
)
echo.
echo Instalando desde !SRC! ...
echo.
dism /online /enable-feature /featurename:NetFx3 /all /limitaccess /source:"!SRC!" /norestart
set "RC=!errorlevel!"
goto :verificar

:verificar
echo.
echo Verificando...
call :estado
echo   Codigo de DISM: !RC!
echo   Estado de NetFx3: !ESTADO!
echo.
if /i "!ESTADO!"=="Enabled" goto :exito
if /i "!ESTADO!"=="EnablePending" goto :exito
echo [FALLO] .NET Framework 3.5 no quedo habilitado.
echo Si aparecieron los errores 0x800f0950 o 0x800f081f, pruebe la opcion 2.
echo Registro detallado: C:\Windows\Logs\DISM\dism.log
echo.
pause
goto :menu

:exito
echo [OK] .NET Framework 3.5 esta habilitado.
echo.
if "!RC!"=="3010" goto :reiniciar
if /i "!ESTADO!"=="EnablePending" goto :reiniciar
pause
exit /b 0

:reiniciar
echo Se necesita reiniciar para terminar la instalacion.
choice /c SN /n /m "Reiniciar ahora? (S/N): "
if errorlevel 2 exit /b 0
shutdown /r /t 5
exit /b 0

:salir
exit /b 0

:estado
set "ESTADO="
for /f %%S in ('powershell -NoProfile -Command "(Get-WindowsOptionalFeature -Online -FeatureName NetFx3).State"') do set "ESTADO=%%S"
exit /b 0
