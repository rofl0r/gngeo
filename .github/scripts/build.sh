#!/bin/bash
set -e
autoreconf -iv
./configure $BUILD_PARAMS --prefix=$PREFIX --program-prefix=ngdevkit- CFLAGS='-DGNGEORC=\"ngdevkit-gngeorc\"' $EXTRA_PARAMS
make pkgdatadir=$PKGDATADIR
sudo make install pkgdatadir=$PKGDATADIR
