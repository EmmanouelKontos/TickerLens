; TickerLens Windows installer (NSIS)
; Build: makensis TickerLens.nsi  (with STAGE_DIR pointing at portable folder)

!ifndef VERSION
  !define VERSION "2.0.1"
!endif
!ifndef STAGE_DIR
  !define STAGE_DIR "..\..\dist\TickerLens-windows-x64-${VERSION}"
!endif
!ifndef APP_ICON
  !define APP_ICON "..\assets\app.ico"
!endif

Name "TickerLens ${VERSION}"
!ifndef OUTFILE
  !define OUTFILE "TickerLens-windows-x64-${VERSION}-setup.exe"
!endif
OutFile "${OUTFILE}"
Unicode True
RequestExecutionLevel user
InstallDir "$LOCALAPPDATA\TickerLens"
InstallDirRegKey HKCU "Software\TickerLens" "InstallDir"
SetCompressor /SOLID lzma

!include "MUI2.nsh"

!define MUI_ABORTWARNING
!define MUI_ICON "${APP_ICON}"
!define MUI_UNICON "${APP_ICON}"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "TickerLens"
VIAddVersionKey "FileDescription" "TickerLens markets and news for Windows"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "LegalCopyright" "TickerLens contributors (GPL-3.0)"

Section "Install"
  SetOutPath "$INSTDIR"

  ; Full portable tree
  File /r "${STAGE_DIR}\*.*"

  ; Start Menu
  CreateDirectory "$SMPROGRAMS\TickerLens"
  CreateShortCut "$SMPROGRAMS\TickerLens\TickerLens.lnk" "$INSTDIR\TickerLens.exe" "" "$INSTDIR\TickerLens.exe" 0
  CreateShortCut "$SMPROGRAMS\TickerLens\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

  ; Desktop
  CreateShortCut "$DESKTOP\TickerLens.lnk" "$INSTDIR\TickerLens.exe" "" "$INSTDIR\TickerLens.exe" 0

  ; Uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\TickerLens" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TickerLens" "DisplayName" "TickerLens ${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TickerLens" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TickerLens" "Publisher" "TickerLens"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TickerLens" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TickerLens" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TickerLens" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TickerLens" "NoRepair" 1

  ; Launch after install
  Exec '"$INSTDIR\TickerLens.exe"'
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\TickerLens.lnk"
  Delete "$SMPROGRAMS\TickerLens\TickerLens.lnk"
  Delete "$SMPROGRAMS\TickerLens\Uninstall.lnk"
  RMDir "$SMPROGRAMS\TickerLens"

  RMDir /r "$INSTDIR"

  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TickerLens"
  DeleteRegKey HKCU "Software\TickerLens"
SectionEnd
