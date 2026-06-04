@echo off
REM ==== Bien dich KingmakerVN.dll bang csc cua .NET Framework 4 ====
REM Chay SAU khi da cai Unity Mod Manager vao game (de co 0Harmony.dll + UnityModManager.dll).
setlocal
set CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe
set MANAGED=%~dp0..\..\..\..\Managed
set OUT=%~dp0..\..\..\..\..\Mods\KingmakerVN

REM --- tim UMM dll (2 vi tri thuong gap) ---
set UMM=%MANAGED%\UnityModManager\UnityModManager.dll
set HARMONY=%MANAGED%\UnityModManager\0Harmony.dll
if not exist "%UMM%" set UMM=%MANAGED%\UnityModManager.dll
if not exist "%HARMONY%" set HARMONY=%MANAGED%\0Harmony.dll

if not exist "%UMM%" ( echo [LOI] Khong thay UnityModManager.dll - hay cai Unity Mod Manager truoc. & exit /b 1 )
if not exist "%HARMONY%" ( echo [LOI] Khong thay 0Harmony.dll - hay cai Unity Mod Manager truoc. & exit /b 1 )

if not exist "%OUT%" mkdir "%OUT%"

"%CSC%" /target:library /nologo /optimize+ /out:"%OUT%\KingmakerVN.dll" ^
 /r:"%MANAGED%\Assembly-CSharp.dll" ^
 /r:"%MANAGED%\Assembly-CSharp-firstpass.dll" ^
 /r:"%MANAGED%\UnityEngine.dll" ^
 /r:"%MANAGED%\UnityEngine.CoreModule.dll" ^
 /r:"%MANAGED%\Newtonsoft.Json.dll" ^
 /r:"%HARMONY%" ^
 /r:"%UMM%" ^
 /r:System.dll /r:System.Core.dll ^
 "%~dp0KingmakerVN.cs"

if errorlevel 1 ( echo [LOI] Bien dich that bai. & exit /b 1 )

copy /y "%~dp0Info.json" "%OUT%\Info.json" >nul
REM copy goi du phong (mod uu tien doc tu StreamingAssets neu co)
if exist "%~dp0..\vnVN_pack.json" copy /y "%~dp0..\vnVN_pack.json" "%OUT%\vnVN_pack.json" >nul

echo [OK] Da bien dich tai %OUT%\KingmakerVN.dll
echo      Khoi dong game, vao Unity Mod Manager de bat mod "Vietnamese Translation".
endlocal
