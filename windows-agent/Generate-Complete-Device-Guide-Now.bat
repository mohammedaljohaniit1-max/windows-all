@echo off
chcp 65001 >nul
title NEXORA-WINDOWS v20.0 APEX - استخراج دليل الجهاز الكامل (Complete Device Guide)
color 0B
echo ===============================================================================
echo   NEXORA-WINDOWS v20.0 APEX OMNI-MASTER
echo   أيقونة استخراج «دليل الجهاز الكامل» (16-Layer Complete Device Guide .MD)
echo ===============================================================================
echo.
echo [1] استخراج الدليل مباشرة على سطح المكتب (Desktop) - (الوضع الافتراضي السريع)
echo [2] تحديد مسار مخصص لحفظ ملف الدليل (.md)
echo.
set /p CHOICE="اختر رقم العملية (اضغط Enter لاختيار 1 تلقائياً): "

if "%CHOICE%"=="2" (
    set /p CUSTOM_DIR="أدخل المسار الكامل للمجلد (مثال D:\Reports): "
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Generate-Complete-Device-Guide.ps1" -OutputDirectory "%CUSTOM_DIR%" -IncludeJsonExport -OpenWhenDone
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Generate-Complete-Device-Guide.ps1" -IncludeJsonExport -OpenWhenDone
)

echo.
echo ===============================================================================
echo   اكتمل استخراج الدليل! يمكنك الآن إرفاق ملف .md مع برومبت NEXORA v20.0 APEX
echo ===============================================================================
pause
