!ifndef VERSION
  !define VERSION 'DEV'
!endif
!addplugindir "nsisPlugins"

; The name of the installer
Name "Vanilla ${VERSION}"

; The file to write
OutFile "Vanilla_${VERSION}.exe"

; The default installation directory
InstallDir $PROGRAMFILES\Vanilla_${VERSION}

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\Vanilla_${VERSION}" "Install_Dir"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

; Set the LZMA compressor to reduce size.
SetCompressor /SOLID lzma
;--------------------------------

!include "MUI2.nsh"
!include "Library.nsh"

;--------------------------------

; StrContains
; This function does a case sensitive searches for an occurrence of a substring in a string. 
; It returns the substring if it is found. 
; Otherwise it returns null(""). 
; Written by kenglish_hi
; Adapted from StrReplace written by dandaman32
 
 
Var STR_HAYSTACK
Var STR_NEEDLE
Var STR_CONTAINS_VAR_1
Var STR_CONTAINS_VAR_2
Var STR_CONTAINS_VAR_3
Var STR_CONTAINS_VAR_4
Var STR_RETURN_VAR
 
Function StrContains
  Exch $STR_NEEDLE
  Exch 1
  Exch $STR_HAYSTACK
  ; Uncomment to debug
  ;MessageBox MB_OK 'STR_NEEDLE = $STR_NEEDLE STR_HAYSTACK = $STR_HAYSTACK '
    StrCpy $STR_RETURN_VAR ""
    StrCpy $STR_CONTAINS_VAR_1 -1
    StrLen $STR_CONTAINS_VAR_2 $STR_NEEDLE
    StrLen $STR_CONTAINS_VAR_4 $STR_HAYSTACK
    loop:
      IntOp $STR_CONTAINS_VAR_1 $STR_CONTAINS_VAR_1 + 1
      StrCpy $STR_CONTAINS_VAR_3 $STR_HAYSTACK $STR_CONTAINS_VAR_2 $STR_CONTAINS_VAR_1
      StrCmp $STR_CONTAINS_VAR_3 $STR_NEEDLE found
      StrCmp $STR_CONTAINS_VAR_1 $STR_CONTAINS_VAR_4 done
      Goto loop
    found:
      StrCpy $STR_RETURN_VAR $STR_NEEDLE
      Goto done
    done:
   Pop $STR_NEEDLE ;Prevent "invalid opcode" errors and keep the
   Exch $STR_RETURN_VAR  
FunctionEnd
 
!macro _StrContainsConstructor OUT NEEDLE HAYSTACK
  Push `${HAYSTACK}`
  Push `${NEEDLE}`
  Call StrContains
  Pop `${OUT}`
!macroend
 
!define StrContains '!insertmacro "_StrContainsConstructor"'
;--------------------------------

!define MUI_ICON "dist/resources/vanilla.ico"
!define MUI_BGCOLOR FFFFFF

; Directory page defines
!define MUI_DIRECTORYPAGE_VERIFYONLEAVE

; Header
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "header.bmp"
!define MUI_HEADERIMAGE_BITMAP_NOSTRETCH 
; Don't show the component description box
!define MUI_COMPONENTSPAGE_NODESC

;Do not leave (Un)Installer page automaticly
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

;Run Vanilla after installing
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Start Vanilla ${VERSION}"
!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchLink"

; Pages
;!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Languages
!insertmacro MUI_LANGUAGE "English"

; Reserve Files
!insertmacro MUI_RESERVEFILE_LANGDLL
ReserveFile '${NSISDIR}\Plugins\x86-unicode\InstallOptions.dll'
ReserveFile "header.bmp"

;--------------------------------

; The stuff to install
Section "Vanilla ${VERSION}"

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put file there
  File /r "dist\"
  
  ; Write the installation path into the registry
  WriteRegStr HKLM "SOFTWARE\Vanilla_${VERSION}" "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Vanilla_${VERSION}" "DisplayName" "Vanilla ${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Vanilla_${VERSION}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Vanilla_${VERSION}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Vanilla_${VERSION}" "NoRepair" 1
  WriteUninstaller "uninstall.exe"

  ; Write start menu entries for all users
  SetShellVarContext all
  
  CreateDirectory "$SMPROGRAMS\Vanilla ${VERSION}"
  CreateShortCut "$SMPROGRAMS\Vanilla ${VERSION}\Uninstall Vanilla ${VERSION}.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\Vanilla ${VERSION}\Vanilla ${VERSION}.lnk" "$INSTDIR\python\pythonw.exe" '-m "Cura.cura"' "$INSTDIR\resources\vanilla.ico" 0
  
SectionEnd

Function LaunchLink
  ; Write start menu entries for all users
  SetShellVarContext all
  Exec '"$WINDIR\explorer.exe" "$SMPROGRAMS\Vanilla ${VERSION}\Vanilla ${VERSION}.lnk"'
FunctionEnd

Section "Install Arduino Drivers"
  ; Set output path to the driver directory.
  SetOutPath "$INSTDIR\drivers\"
  File /r "drivers\"
  
  ${If} ${RunningX64}
    IfSilent +2
      ExecWait '"$INSTDIR\drivers\dpinst64.exe" /lm'
  ${Else}
    IfSilent +2
      ExecWait '"$INSTDIR\drivers\dpinst32.exe" /lm'
  ${EndIf}
SectionEnd

Section "Open STL files with Vanilla"
	WriteRegStr HKCR .stl "" "Vanilla STL model file"
	DeleteRegValue HKCR .stl "Content Type"
	WriteRegStr HKCR "Vanilla STL model file\DefaultIcon" "" "$INSTDIR\resources\stl.ico,0"
	WriteRegStr HKCR "Vanilla STL model file\shell" "" "open"
	WriteRegStr HKCR "Vanilla STL model file\shell\open\command" "" '"$INSTDIR\python\pythonw.exe" -c "import os; os.chdir(\"$INSTDIR\"); import Cura.cura; Cura.cura.main()" "%1"'
SectionEnd

Section /o "Open OBJ files with Vanilla"
	WriteRegStr HKCR .obj "" "Vanilla OBJ model file"
	DeleteRegValue HKCR .obj "Content Type"
	WriteRegStr HKCR "Vanilla OBJ model file\DefaultIcon" "" "$INSTDIR\resources\stl.ico,0"
	WriteRegStr HKCR "Vanilla OBJ model file\shell" "" "open"
	WriteRegStr HKCR "Vanilla OBJ model file\shell\open\command" "" '"$INSTDIR\python\pythonw.exe" -c "import os; os.chdir(\"$INSTDIR\"); import Cura.cura; Cura.cura.main()" "%1"'
SectionEnd

Section /o "Open AMF files with Vanilla"
	WriteRegStr HKCR .amf "" "Vanilla AMF model file"
	DeleteRegValue HKCR .amf "Content Type"
	WriteRegStr HKCR "Vanilla AMF model file\DefaultIcon" "" "$INSTDIR\resources\stl.ico,0"
	WriteRegStr HKCR "Vanilla AMF model file\shell" "" "open"
	WriteRegStr HKCR "Vanilla AMF model file\shell\open\command" "" '"$INSTDIR\python\pythonw.exe" -c "import os; os.chdir(\"$INSTDIR\"); import Cura.cura; Cura.cura.main()" "%1"'
SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Vanilla_${VERSION}"
  DeleteRegKey HKLM "SOFTWARE\Vanilla_${VERSION}"

  ; Write start menu entries for all users
  SetShellVarContext all
  ; Remove directories used
  RMDir /r "$SMPROGRAMS\Vanilla ${VERSION}"
  RMDir /r "$INSTDIR"

SectionEnd
