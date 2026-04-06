@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "TOOL_DIR=C:\NVIDIA\Tools"
set "MOSAIC_EXE=%TOOL_DIR%\configureMosaic.exe"
set "MMT_EXE=%TOOL_DIR%\MultiMonitorTool.exe"

set "LOG_DIR=%~dp0logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%I"
set "LOG_FILE=%LOG_DIR%\MosaicRecovery_%TS%.log"

call :log INFO "=================================================="
call :log INFO "Mosaic 復旧バッチ 開始"
call :log INFO "Log File : %LOG_FILE%"
call :log INFO "TOOL_DIR : %TOOL_DIR%"
call :log INFO "=================================================="

net session >nul 2>&1
if %errorlevel% neq 0 (
    call :log ERROR "管理者権限がありません。右クリックして「管理者として実行」してください。"
    echo.
    echo [ERROR] 右クリックして「管理者として実行」してください。
    pause
    exit /b 1
)
call :log INFO "管理者権限チェック OK"

if not exist "%MOSAIC_EXE%" (
    call :log ERROR "configureMosaic.exe が見つかりません: %MOSAIC_EXE%"
    echo [ERROR] configureMosaic.exe が見つかりません。
    echo         %MOSAIC_EXE%
    pause
    exit /b 1
)
call :log INFO "configureMosaic.exe 存在確認 OK"

if not exist "%MMT_EXE%" (
    call :log ERROR "MultiMonitorTool.exe が見つかりません: %MMT_EXE%"
    echo [ERROR] MultiMonitorTool.exe が見つかりません。
    echo         %MMT_EXE%
    pause
    exit /b 1
)
call :log INFO "MultiMonitorTool.exe 存在確認 OK"

call :log INFO "[1/4] NVIDIA UI を終了します..."
echo [1/4] NVIDIA UI を終了します...
taskkill /f /im nvcplui.exe >> "%LOG_FILE%" 2>&1
set "RC=%errorlevel%"
if "%RC%"=="0" (
    call :log INFO "taskkill nvcplui.exe 成功"
) else if "%RC%"=="128" (
    call :log WARN "nvcplui.exe は起動していませんでした"
) else (
    call :log WARN "taskkill nvcplui.exe 戻り値=%RC%"
)

call :log INFO "[2/4] Mosaic 構成を解除します..."
echo [2/4] Mosaic 構成を解除します...
"%MOSAIC_EXE%" disable >> "%LOG_FILE%" 2>&1
set "RC=%errorlevel%"
call :log INFO "configureMosaic.exe disable 戻り値=%RC%"

if not "%RC%"=="0" (
    call :log ERROR "Mosaic の解除に失敗しました。"
    echo [ERROR] Mosaic の解除に失敗しました。
    pause
    exit /b 1
)

call :log INFO "[3/4] システムの再構築を待ちます（30秒）..."
echo [3/4] システムの再構築を待ちます（30秒）...
timeout /t 30 /nobreak >> "%LOG_FILE%" 2>&1
set "RC=%errorlevel%"
call :log INFO "timeout 30秒 戻り値=%RC%"

call :log INFO "[4/4] 全ディスプレイを強制アクティブ化 ＆ 拡張..."
echo [4/4] 全ディスプレイを強制アクティブ化 ＆ 拡張...

"%MMT_EXE%" /enable all >> "%LOG_FILE%" 2>&1
set "RC=%errorlevel%"
call :log INFO "MultiMonitorTool /enable all 戻り値=%RC%"
if not "%RC%"=="0" (
    call :log WARN "MultiMonitorTool /enable all で問題が発生した可能性があります。"
)

timeout /t 5 /nobreak >> "%LOG_FILE%" 2>&1
set "RC=%errorlevel%"
call :log INFO "timeout 5秒 戻り値=%RC%"

DisplaySwitch.exe /extend >> "%LOG_FILE%" 2>&1
set "RC=%errorlevel%"
call :log INFO "DisplaySwitch.exe /extend 戻り値=%RC%"
if not "%RC%"=="0" (
    call :log WARN "DisplaySwitch.exe /extend で問題が発生した可能性があります。"
)

call :log INFO "処理完了"
call :log INFO "=================================================="

echo --------------------------------------------------
echo 処理完了。画面が戻るまで何もせずにお待ちください。
echo ログ: %LOG_FILE%
echo --------------------------------------------------
pause
exit /b 0

:log
set "LV=%~1"
set "MSG=%~2"
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd HH:mm:ss.fff"') do set "NOW=%%I"
echo [+] [%LV%] %MSG%
>> "%LOG_FILE%" echo [+] [%LV%] %MSG%
exit /b 0
