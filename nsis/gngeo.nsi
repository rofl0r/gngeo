; GnGeo NSIS Installer
; this file expects the following variables to be defined
; SDL2_URL - URL to download SDL2 from. Has to use a HTTP scheme
; GLEW_URL - URL to download GLEW from. Has to use a HTTP scheme

; extract version number of dependencies
; SDL2: http://libsdl.org/release/SDL2-<SDL2_VERSION>-win32-x64.zip
!searchparse "${SDL2_URL}" `release/SDL2-` SDL2_VERSION `-win32`
; GLEW: http://downloads.sourceforge.net/project/glew/glew/<GLEW_VERSION>/glew-<GLEW_VERSION>-win32.zip
!searchparse "${GLEW_URL}" `project/glew/glew/` GLEW_VERSION `/glew-`

!addplugindir "."

!include "MUI2.nsh"

!define NAME "GnGeo ngdevkit"
!define GNGEO "ngdevkit-gngeo"
!define TMPDIR "$TEMP\ngdevkit-gngeo"

Name "${NAME}"
OutFile "ngdk-gngeo-inst.exe"

; dest dir selection
InstallDir "$LOCALAPPDATA\${NAME}"

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "../COPYING"
!define MUI_COMPONENTSPAGE_TEXT_TOP "${NAME} depends on a couple of run-time dependencies. This wizard lets you download and install them automatically."
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"


Section "${NAME}"
  SectionIn RO
  ; contents
  SetOutPath $INSTDIR
  File "/oname=${GNGEO}.exe" "../src/gngeo.exe"
  File "/oname=gngeo_data.zip" "../gngeo.dat/gngeo_data.zip"
  File "/oname=LICENSE" "../COPYING"
  CreateDirectory $INSTDIR\conf
  CreateDirectory $INSTDIR\rom
  CreateDirectory $INSTDIR\doc
  CreateDirectory $INSTDIR\save
  SetOutPath $INSTDIR\shaders
  File "../src/blitter/noop.glsl"
  File "../src/blitter/noop.glslp"

  ; start menu shortcuts
  CreateDirectory "$SMPROGRAMS\${NAME}"
  CreateShortCut "$SMPROGRAMS\${NAME}\Uninstall.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\Uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\${NAME}\${NAME}.lnk" "$INSTDIR\${GNGEO}.exe" "" "$INSTDIR\${GNGEO}.exe" 0

  ; desktop shortcut
  SetOutPath $INSTDIR
  CreateShortCut "$DESKTOP\${NAME}.lnk" "$INSTDIR\${GNGEO}.exe" ""

  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

SectionGroup /e "Run-time dependencies"
Section "ZLib" zlib
  SetOutPath $INSTDIR
  ; bundle zlib dll, it's easier and safer than picking
  ; a random one off the internet
  File "zlib1.dll"
SectionEnd

Section "SDL2 ${SDL2_VERSION}" sdl
  CreateDirectory "${TMPDIR}"
  SetOutPath $INSTDIR
  NSISdl::download "${SDL2_URL}" "${TMPDIR}\SDL2.zip"
  nsisunz::UnzipToLog /noextractpath /file "SDL2.dll" "${TMPDIR}\SDL2.zip" "$INSTDIR"
  Delete "${TMPDIR}\SDL2.zip"
  RMDir "${TMPDIR}"
SectionEnd

Section "GLEW ${GLEW_VERSION}" glew
  CreateDirectory "${TMPDIR}"
  SetOutPath $INSTDIR
  NSISdl::download "${GLEW_URL}" "${TMPDIR}\glew.zip"
  nsisunz::UnzipToLog /noextractpath /file "glew-${GLEW_VERSION}/bin/Release/x64/glew32.dll" "${TMPDIR}\glew.zip" "$INSTDIR"
  Delete "${TMPDIR}\glew.zip"
  RMDir "${TMPDIR}"
SectionEnd
SectionGroupEnd

Section "Uninstall"
  ; contents
  RMDir /r "$INSTDIR\conf"
  RMDir /r "$INSTDIR\rom"
  RMDir /r "$INSTDIR\doc"
  RMDir /r "$INSTDIR\save"
  RMDir /r "$INSTDIR\shaders"
  Delete "$INSTDIR\${GNGEO}.exe"
  Delete "$INSTDIR\gngeo_data.zip"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\Uninstall.exe"
  Delete "$INSTDIR\gngeo_log.txt"
  Delete "$INSTDIR\zlib1.dll"
  Delete "$INSTDIR\SDL2.dll"
  Delete "$INSTDIR\glew32.dll"
  RMDir "$INSTDIR"

  ; shortcuts
  Delete "$DESKTOP\${NAME}.lnk"
  Delete "$SMPROGRAMS\${NAME}\*.*"
  RMDir  "$SMPROGRAMS\${NAME}"
SectionEnd
