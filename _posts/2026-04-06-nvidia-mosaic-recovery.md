---
title: NVIDIA Mosaic 復旧手順と復旧バッチ
date: 2026-04-06 12:00:00 +0900
categories: [Windows, GPU]
tags: [NVIDIA, Mosaic, TDR, Windows, Troubleshooting]
pin: true
---

NVIDIA Mosaic 構成を使用している環境で、表示崩れやブラックアウトが発生したときに、**Mosaic を解除して通常の拡張表示へ戻す**ための手順と復旧バッチです。

今回のポイントは、処理を 3 層に分けることです。

1. **NVIDIA Mosaic 構成の解除**
2. **表示デバイスの再有効化**
3. **Windows の表示モードを拡張へ戻す**

Quadro Sync II のガイドでも、Mosaic は同期設定の前段にある構成要素として扱われ、Windows 側では Mosaic を先に設定してから同期を有効化する順序が示されています。さらに、同期中はディスプレイが点滅し得ることや、状態確認は System Topology Viewer や LED で行うことが説明されています。

## 想定している症状

- Mosaic 構成変更後に画面が正常復帰しない
- ブラックアウト後に一部モニターが戻らない
- NVIDIA Control Panel 上では変更したが、Windows 側の表示が崩れた
- 再起動なしで通常の拡張表示へ戻したい

## 使用するツールの役割

### configureMosaic.exe
NVIDIA Mosaic Utility に含まれるコマンドラインツールです。

```bat
configureMosaic.exe disable
```

を使って、**現在の Mosaic 構成を解除**します。

### MultiMonitorTool.exe
NirSoft の複数モニター管理ツールです。

```bat
MultiMonitorTool.exe /enable all
```

を使って、**Windows が認識している表示デバイスをまとめて有効化**します。

### DisplaySwitch.exe
Windows 標準の表示モード切替コマンドです。

```bat
DisplaySwitch.exe /extend
```

を使って、**Windows の表示方式を通常の拡張表示へ戻します**。

## 復旧の流れ

1. NVIDIA Control Panel の UI を閉じる
2. `configureMosaic.exe disable` を実行する
3. ドライバ・表示系の再構築を待つ
4. `MultiMonitorTool.exe /enable all` で全表示を有効化する
5. `DisplaySwitch.exe /extend` で拡張表示へ戻す
6. ログを保存して結果を確認する

## 復旧バッチ

以下を `MosaicRecovery.bat` として保存します。

```bat
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
```

## TDR 値について

TDR は、GPU が一定時間応答しないときに Windows がドライバをリセットする仕組みです。

長時間の GPU 計算や重い処理でドライバリセットが発生する場合は、次のレジストリ値を調整します。

- `TdrDelay`
- `TdrDdiDelay`

### レジストリの書き換え手順

1. `regedit` を起動する
2. 次のキーを開く

```text
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\GraphicsDrivers
```

3. 右クリック → 新規 → DWORD (32ビット) 値
4. 次の 2 つを作成する

- `TdrDelay`
- `TdrDdiDelay`

5. どちらも **10進数** で `60` を設定する
6. Windows を再起動する

### コマンドで設定する方法

```bat
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDelay /t REG_DWORD /d 60 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDdiDelay /t REG_DWORD /d 60 /f
```

設定後は再起動してください。

### 注意

- `TdrLevel=0` のような完全無効化は、このページでは推奨しません
- 値を上げても、Mosaic の表示崩れ自体が必ず直るわけではありません
- まずは `TdrDelay=60` と `TdrDdiDelay=60` の範囲で運用確認するのが無難です


