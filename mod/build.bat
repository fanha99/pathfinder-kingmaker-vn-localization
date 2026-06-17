@echo off
REM ==== Bien dich KingmakerVN.dll bang csc cua .NET Framework 4 ====
REM Chay SAU khi da cai Unity Mod Manager vao game (de co 0Harmony.dll + UnityModManager.dll).
REM KHONG ghi vao thu muc Mods cua game nua. Build + gom vao  _viethoa\out\KingmakerVN\
REM (thu muc nay co the copy thang vao Mods\ de test, hoac dong goi release bang package_release.ps1).
setlocal
set CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe
set MANAGED=%~dp0..\..\..\..\Managed
set OUT=%~dp0..\out\KingmakerVN

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
REM goi ngon ngu da dich (full pack: da dich=Viet, chua=English) - sinh boi  python vh.py build/pack
if exist "%~dp0..\vnVN_pack.json" copy /y "%~dp0..\vnVN_pack.json" "%OUT%\vnVN_pack.json" >nul

echo [OK] Da build tai "%OUT%"
echo      - KingmakerVN.dll, Info.json, vnVN_pack.json
echo      De test: copy ca thu muc "%OUT%" vao  ...\Mods\  roi bat trong UMM (Ctrl+F10).
echo      De ra release: chay  package_release.ps1  (xem _viethoa\mod\README_MOD.md).
endlocal
