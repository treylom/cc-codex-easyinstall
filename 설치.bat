@echo off
cd /d "%~dp0"
echo ============================================
echo   FastCampus Lecture - Installer
echo ============================================
echo.
echo  A Windows "User Account Control" window will
echo  pop up next. Please click [Yes] to continue.
echo  (Administrator rights are required to install.)
echo.
pause
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','%~dp0windows\bootstrap.ps1'"
