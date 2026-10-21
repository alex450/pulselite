@echo off
chcp 65001 >nul
setlocal

REM 输出目录：默认桌面（工作区外，避免沙箱 Low 完整性标签导致读不到运行中的应用列表）
REM 可用第一个参数覆盖，例如: buildtodesktop.bat D:\out
set "OUTDIR=%~1"
if "%OUTDIR%"=="" set "OUTDIR=%USERPROFILE%\Desktop"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

cd /d "%~dp0"

set CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe
if not exist "%CSC%" (
    set CSC=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe
)

echo =======================================================
echo Compiling PulseLite (Open-Source Clean Raw Binary)...
echo Compiler: %CSC%
echo =======================================================

"%CSC%" /target:winexe /optimize+ /codepage:65001 /win32icon:app.ico /r:System.Drawing.dll /r:System.Windows.Forms.dll /out:"%OUTDIR%\PulseLite.exe" /recurse:src\*.cs

if %ERRORLEVEL% neq 0 (
    echo [FAILED] Compilation failed with error code: %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo [SUCCESS] Build successful (Pure Open-Source Raw Binary): %OUTDIR%\PulseLite.exe

endlocal
