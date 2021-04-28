#!/bin/bash
set -eu
autoreconf -iv
./configure \
    --prefix=/mingw64 \
    --build=x86_64-w64-mingw32 \
    --host=x86_64-w64-mingw32 \
    --target=x86_64-w64-mingw32 \
    --program-prefix=ngdevkit- \
    CFLAGS="-Wno-implicit-function-declaration -DGNGEORC=\\\"ngdevkit-gngeorc\\\"" \
    GL_LIBS="-L/mingw64/bin -lglew32 -lopengl32"
make -j1 pkgdatadir=/mingw64/share/ngdevkit-gngeo
make install pkgdatadir=/mingw64/share/ngdevkit-gngeo
