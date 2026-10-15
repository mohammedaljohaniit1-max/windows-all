@echo off
chcp 65001 >nul
title NEXORA-WINDOWS v20.0 APEX - Local Web Dashboard Server
color 0A
echo ===============================================================================
echo   NEXORA-WINDOWS v20.0 APEX OMNI-MASTER
echo   تشغيل الداشبورد الاحترافية في المتصفح (http://localhost:7788)
echo ===============================================================================
echo.
where node >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [INFO] تم اكتشاف Node.js - جاري تشغيل الخادم المحلي المتقدم على المنفذ 7788...
    node "%~dp0..\server.js"
) else (
    echo [INFO] جاري تشغيل الخادم المحلي عبر PowerShell Native HttpListener على المنفذ 7788...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Local-WebServer.ps1" -Port 7788
)
pause
