#!/bin/bash
set -eu

# Download MINGW-specific, non-packaged dependencies
mkdir -p $WINDEPS
pushd .
cd $WINDEPS
curl -L "$SDL" | tar zx; sudo cp -af SDL2-*/*-mingw32 /usr/local
curl -LO "$GLEW"; unzip $(basename "$GLEW")
popd

# Build as usual
export EXTRA_PARAMS="PKG_CONFIG_PATH=/usr/x86_64-w64-mingw32/lib/pkgconfig --with-glew=$(find ${WINDEPS} -name 'glew*' -type d)"
./.github/scripts/build.sh

# Additionally, build a native gngeo installer
make -C nsis all SDL2_URL="$NSIS_SDL2" GLEW_URL="$NSIS_GLEW" INSTALLER_NAME=setup-ngdevkit-gngeo-nightly.exe
sudo cp nsis/setup-ngdevkit-gngeo-nightly.exe nsis/setup-ngdevkit-gngeo-nightly.exe.sha256 $PREFIX
