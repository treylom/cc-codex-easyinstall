@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ============================================
echo  패스트캠퍼스 강의 - 설치 시작
echo ============================================
echo.
echo  잠시 후 "이 앱이 디바이스를 변경하도록 허용?" 창이 뜹니다.
echo  반드시 [예]를 눌러주세요. (관리자 권한이 있어야 설치됩니다)
echo.
pause
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','%~dp0windows\bootstrap.ps1'"
