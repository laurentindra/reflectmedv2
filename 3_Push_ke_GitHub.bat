@echo off
title REFLECTMED AI - Push ke GitHub
color 0E
echo ================================================================
echo               PUSH KODE REFLECTMED AI KE GITHUB
echo ================================================================
echo.
echo Repositori Target: https://github.com/laurentindra/reflectmedv2
echo.
set "PATH=C:\Program Files\Git\cmd;%PATH%"
cd /d "%~dp0"

echo Mengirim commit ke GitHub main branch...
git push -u origin main

echo.
if %ERRORLEVEL% EQU 0 (
    echo ============================================================
    echo [BERHASIL] Seluruh kode berhasil ter-push ke GitHub!
    echo Kunjungi: https://github.com/laurentindra/reflectmedv2
    echo ============================================================
) else (
    echo [INFO] Jika muncul jendela login, silakan login melalui browser
    echo atau gunakan GitHub Personal Access Token (PAT).
)
echo.
pause
