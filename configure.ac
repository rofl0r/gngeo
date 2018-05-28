# Process this file with autoconf to produce a configure script.

AC_INIT([gngeo],[0.8])
AC_CONFIG_SRCDIR([src/emu.c])
AC_CANONICAL_TARGET
AC_CONFIG_HEADERS([config.h])


AM_INIT_AUTOMAKE(silent-rules)
AM_SILENT_RULES

# it's not optimal, but at least, it work
if test -z "$CC_FOR_BUILD"; then
  CC_FOR_BUILD=gcc
fi
AC_SUBST(CC_FOR_BUILD)


# Checks for programs.
AC_PROG_CC
AM_PROG_AR
AC_PROG_RANLIB
AM_PROG_AS

# Check whether CC is clang
AC_CACHE_CHECK([whether the C compiler is clang],[ng_cv_cc_clang],
               [if $CC -dM -E - </dev/null 2>/dev/null | grep -q __clang__; then
	         ng_cv_cc_clang=yes;
                else
	         ng_cv_cc_clang=no;
	       fi])

AC_DEFUN([GN_ARG_ENABLE],[
	AC_ARG_ENABLE($1,[  $2],
		[case "${enableval}" in
       	 yes) enable_$1=true ;;
       	 no)  enable_$1=false ;;
       	 *) AC_MSG_ERROR([bad value ${enableval} for --enable-$1]) ;;
     	 esac];$3,
     	 [enable_$1=false];$4)
]
)

GN_ARG_ENABLE(gp2x,    [--enable-gp2x           Enable GP2X build])
GN_ARG_ENABLE(wiz,     [--enable-wiz            Enable WIZ build])
GN_ARG_ENABLE(wii,     [--enable-wii            Enable WII build])
GN_ARG_ENABLE(rpi,     [--enable-rpi            Enable Raspberry Pi build])
GN_ARG_ENABLE(pandora, [--enable-pandora        Enable PANDORA build])
GN_ARG_ENABLE(win32,   [--enable-win32          Enable WIN32 build])
GN_ARG_ENABLE(mingw,   [--enable-mingw          Enable MinGW build])
GN_ARG_ENABLE(dingux,  [--enable-dingux         Enable DINGUX build])
GN_ARG_ENABLE(embedded,[--enable-embedded       Enable Embedded directory structure])


# Setup platform specific optimisation/source/cflags/libs/etc.
if test "x$enable_gp2x" = xtrue ; then
	AC_DEFINE([GP2X],[1],[Define if you build for gp2x])
	AC_DEFINE([ENABLE_940T],[1],[Define to process audio on the 940t])
	CFLAGS="$CFLAGS -mtune=arm920t"
	LIBS="$LIBS -lpthread -static";
	enable_embedded=true
    #PDEP_SOURCE=$PDEP_SOURCE 'gp2x.$(OBJEXT)'
fi
if test "x$enable_wiz" = xtrue ; then
	AC_DEFINE([WIZ],[1],[Define if you build for wiz])
	enable_embedded=true
#	CFLAGS="$CFLAGS -mtune=arm920t"
#	LIBS="$LIBS -lpthread -static";
fi
if test "x$enable_dingux" = xtrue ; then
	AC_DEFINE([DINGUX],[1],[Define if you build for dingux])
	enable_embedded=true
	CFLAGS="$CFLAGS -mips32 -mtune=r4600 -mno-mips16 -msoft-float -fexpensive-optimizations -fomit-frame-pointer -frename-registers"
#	LIBS="$LIBS -lpthread -static";
fi
if test "x$enable_pandora" = xtrue ; then
	AC_DEFINE([PANDORA],[1],[Define if you build for pandora])
	enable_embedded=true
#	CFLAGS="$CFLAGS -mtune=arm920t"
#	LIBS="$LIBS -lpthread -static";
fi
if test "x$enable_wii" = xtrue ; then
	AC_DEFINE([WII],[1],[Define if you build for wii])
	enable_embedded=true
	CFLAGS="$CFLAGS -DGEKKO -mrvl -mcpu=750 -meabi -mhard-float -MMD -MP"
	LIBS="$LIBS -lSDL -lfat -lwiiuse -lbte -logc -lm -lwiikeyboard";
fi
if test "x$enable_rpi" = xtrue ; then
	AC_DEFINE([RPI],[1],[Define if you build for Raspberry Pi])
	GL_CFLAGS="-I /opt/vc/include"
	GL_LDFLAGS="-L /opt/vc/lib"
	GL_LIBS="-lGLESv2"
fi
if test "x$enable_win32" = xtrue ; then
   enable_embedded=true
   AC_DEFINE([WIN32],[1],[Define if you build for win32])
   NASMENV="--prefix_"
fi
if test "x$enable_mingw" = xtrue ; then
   enable_embedded=true
   with_emudbg=no
   host=`uname -p`-w64-mingw32
   datarootdir="${prefix}"
   bindir="${prefix}"
   mandir="${prefix}"/doc
   CFLAGS="$CFLAGS -I/usr/${host}/include -I/usr/local/${host}/include"
   CPPFLAGS="$CPPFLAGS -I/usr/${host}/include -I/usr/local/${host}/include"
   LDFLAGS="$LDFLAGS -L/usr/${host}/lib -L/usr/local/${host}/lib"
   export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/local/${host}/lib/pkgconfig"
   AC_DEFINE([MINGW],[1],[Define if you build for MinGW])
fi
if test "x$enable_embedded" = xtrue ; then
   AC_DEFINE([EMBEDDED_FS],[1],[Define for embedded directory structure])
fi

# CFLAGS="$CFLAGS -DDATA_DIRECTORY=\"${pkgdatadir}\""

# Check for SDL
SDL_VERSION=2.0.0
AM_PATH_SDL2($SDL_VERSION,,AC_MSG_ERROR([*** SDL version $SDL_VERSION not found!]))
CFLAGS="$CFLAGS $SDL_CFLAGS"
LIBS="$LIBS $SDL_LIBS"

# Checks for libraries.
#AC_SUBST(LIBOBJS)
AC_CHECK_LIB([m], [acos])
AC_CHECK_LIB([z], [inflate])

AC_CHECK_FUNCS(getopt_long , , [ AC_LIBOBJ(getopt) AC_LIBOBJ(getopt1) ])
AC_CHECK_FUNCS(scandir)
AC_CHECK_FUNCS(basename)
AC_CHECK_FUNCS(mmap)
#have_nasm=false
use_starscream=false
use_raze=false
use_generator68k=false
use_cyclone=false
use_mamez80=false
#choice_68k=ko
#choice_z80=ko

# TODO: check mmx support
AC_ARG_ENABLE(i386asm,     [  --disable-i386asm       disable the use of i386 optimisation],
                           [case "${enableval}" in
       						yes) enablei386asm=true  ;;
       						no)  enablei386asm=false ;;
       						*) AC_MSG_ERROR([bad value ${enableval} for --disable-i386asm]) ;;
     						esac],
     						[enablei386asm=true])


AC_ARG_WITH(m68kcore,[  --with-m68kcore=[68kcore]     Specify which 68k core to use (cyclone|starscream|gen68k)],
            m68kcore="$withval", m68kcore="default")
AC_ARG_WITH(z80core, [  --with-z80core=[z80core]      Specify which z80 core to use (drz80|raze|mamez80)],
            z80core="$withval", z80core="default")
#echo $m68kcore
#echo $z80core
case $target_cpu in
    	i?86) 
if  test "$enablei386asm" = true ; then
	AC_CHECK_PROG(have_nasm, nasm, true,false)
	CFLAGS="$CFLAGS -m32 -DI386_ASM"
#    PDEP_SOURCE=$PDEP_SOURCE 'gp2x.$(OBJEXT)'
else
	have_nasm=false
fi
;;
esac

#setup default 68k core
if test $m68kcore = default ; then
	case $target_cpu in
    	i?86) 
			if test x$have_name=xtrue ; then
				m68kcore=starscream
			else
				m68kcore=gen68k
			fi   		
    		;;
    	arm) m68kcore=cyclone
    		;;
    	*)	 m68kcore=gen68k
    		;;
    esac
fi
#setup default z80 core
if test $z80core = default ; then
	case $target_cpu in
    	i?86) 
			if test x$have_name=xtrue ; then
				z80core=raze
			else
				z80core=mamez80
			fi   		
    		;;
    	arm) z80core=drz80
    		;;
    	*)	 z80core=mamez80
    		;;
    esac
fi

case "${m68kcore}" in
     	cyclone)	use_cyclone=true
		   	AC_DEFINE([USE_CYCLONE],[1],[Define to enable cyclone])
		   	;;
	starscream)	use_starscream=true
    			AC_DEFINE([USE_STARSCREAM],[1],[Define to enable starscream])
    			;;
	gen68k)      	use_generator68k=true
    			AC_DEFINE([USE_GENERATOR68K],[1],[Define to enable generator68k])
    			;;
	*) AC_MSG_ERROR([The specified m68k core is invalid]) ;;
esac

case "${z80core}" in
	drz80)       use_drz80=true
				 AC_DEFINE([USE_DRZ80],[1],[Define to enable drz80])
				 ;;
	raze)        use_raze=true
    			 AC_DEFINE([USE_RAZE],[1],[Define to enable raze])
    			 ;;
	mamez80)     use_mamez80=true
    			 AC_DEFINE([USE_MAMEZ80],[1],[Define to enable mamez80])
    			 ;;
	*) AC_MSG_ERROR([The specified z80 core is invalid]) ;;
esac

dnl Make AX_CHECK_GL support both OpenGL and OpenGL ES
pushdef([_AX_CHECK_GL_PROGRAM],
          [AC_LANG_PROGRAM([[
# if defined(HAVE_WINDOWS_H) && defined(_WIN32)
#   include <windows.h>
# endif
# ifdef HAVE_GL_GL_H
#   include <GL/gl.h>
# elif defined(HAVE_OPENGL_GL_H)
#   include <OpenGL/gl.h>
# else
#   error no gl.h
# endif
]],[[glCreateProgram()]])])

AX_CHECK_GL
AM_CONDITIONAL(USE_OPENGL,[test "X$no_gl" != "Xyes"])

# dnl if GL was detected, configure blitter and compile flags
AS_IF([test "X$no_gl" != "Xyes"],[
# dnl distinguish between OpenGL and OpenGL ES
AC_MSG_CHECKING([whether the OpenGL library is OpenGL ES])
AC_LINK_IFELSE([_AX_CHECK_GL_PROGRAM],
[AC_MSG_RESULT([no])
 AC_DEFINE([USE_GL2],[1],[Define to use alternative opengl blitter])
 AC_CHECK_HEADERS(GL/glew.h)
 AC_CHECK_LIB(GLEW, glewInit,
   [LIBS="$LIBS -lGLEW"
    ng_cv_use_glsl=yes])
],
[AC_MSG_RESULT([yes])
 ng_cv_use_glsl=yes]
)
AS_IF([test "x$ng_cv_use_glsl" = "xyes"],[
   AC_DEFINE([USE_GLSL],[1],[Define to use alternative glsl blitter])
])
])

AM_CONDITIONAL(HAVE_NASM,[test x$have_nasm = xtrue])
AM_CONDITIONAL(USE_STARSCREAM,[test x$use_starscream = xtrue])
AM_CONDITIONAL(USE_RAZE,[test x$use_raze = xtrue])
AM_CONDITIONAL(USE_GENERATOR68K,[test x$use_generator68k = xtrue])
AM_CONDITIONAL(USE_CYCLONE,[test x$use_cyclone = xtrue])
AM_CONDITIONAL(USE_MAMEZ80,[test x$use_mamez80 = xtrue])
AM_CONDITIONAL(USE_DRZ80,[test x$use_drz80 = xtrue])
AM_CONDITIONAL(USE_GUI,[test x$enable_gui = xtrue])
AM_CONDITIONAL(USE_GP2X,[test x$enable_gp2x = xtrue])
AM_CONDITIONAL(USE_WIZ,[test x$enable_wiz = xtrue])
AM_CONDITIONAL(USE_MINGW,[test x$enable_mingw = xtrue])
AM_CONDITIONAL(USE_GLSL,[test x$ng_cv_use_glsl = xtrue])

# Checks for header files.
AC_HEADER_DIRENT
AC_HEADER_STDC
AC_CHECK_HEADERS([errno.h limits.h malloc.h stddef.h stdlib.h string.h sys/time.h unistd.h libgen.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_C_INLINE
AC_HEADER_TIME
AC_STRUCT_TM
AC_C_BIGENDIAN

# Checks for library functions.
AC_FUNC_VPRINTF
AC_CHECK_FUNCS([atexit floor gettimeofday memset mkdir pow strchr strstr strtoul])

# Checks for emudbg source-level debugging extension
AC_ARG_WITH([emudbg],
    AS_HELP_STRING([--without-emudbg], [Ignore emudbg source-level debugging extension]))
AS_IF([test "x$with_emudbg" != "xno"],[
   AC_CHECK_HEADERS([emudbg.h])
   AC_CHECK_LIB([emudbg], [emudbg_server_loop], [use_emudbg=true])
])
AM_CONDITIONAL(USE_EMUDBG,[test x$use_emudbg = xtrue])


# Check for processor.
  case $target_cpu in
    i?86)  AC_MSG_RESULT(Turning on x86 processor optimisations)
           AC_DEFINE(PROCESSOR_INTEL, 1, [Define if you have an x86 processor])
           ALIGNLONGS=0
	   proc_i386=true
		CFLAGS="$CFLAGS -O3 -fstrength-reduce -frerun-loop-opt -Wall -Wno-unused -funroll-loops \
                    -ffast-math -falign-functions=2 -falign-jumps=2 -fexpensive-optimizations \
                    -falign-loops=2 -fschedule-insns2 -malign-double -fomit-frame-pointer -g \
		    -fno-strict-aliasing -pipe -mtune=$target_cpu -DCPU=$target_cpu"
           ;;
     x86_64)
	   AC_MSG_RESULT(Turning on x86_64 processor optimisations)
           AC_DEFINE(PROCESSOR_ADM64, 1, [Define if you have an x86_64 processor])
           ALIGNLONGS=0
	   proc_x64=true
		CFLAGS="$CFLAGS -O3 -fstrength-reduce -frerun-loop-opt -Wall -Wno-unused -funroll-loops \
                    -ffast-math  -fexpensive-optimizations \
                     -malign-double -fomit-frame-pointer -g \
		    -fno-strict-aliasing -pipe -DCPU=$target_cpu"
           ;;
    sparc*) AC_MSG_RESULT(Turning on sparc processor optimisations)
           AC_DEFINE(PROCESSOR_SPARC, 1, [Define if you have a sparc processor])
	   ALIGNLONGS=1
	   proc_sparc=true
	   if test $target_cpu = sparc64 && test $CC_MAJOR -ge 3 ; then
		CFLAGS="$CFLAGS -mcpu=v9"
	   fi
	   CFLAGS="$CFLAGS -O3 -Wall -Wno-unused -funroll-loops \
                    -ffast-math -fomit-frame-pointer -g"
           ;;
    arm)   AC_MSG_RESULT(Turning on arm processor optimisations)
           AC_DEFINE(PROCESSOR_ARM, 1, [Define if you have an ARM processor])
           ALIGNLONGS=1
	   proc_arm=true
	   CFLAGS="$CFLAGS -O3 -Wall -ftracer -fstrength-reduce -Wno-unused -funroll-loops \
                    -fomit-frame-pointer -fstrict-aliasing -ffast-math \
	   	    "

	   	    ;;
    *)     AC_MSG_RESULT(Processor type unknown - Use generic optimisations)
           ALIGNLONGS=1
           optimum=no
	   CFLAGS="$CFLAGS -O3 -Wall -Wno-unused -funroll-loops \
                    -ffast-math -g"
           ;;
  esac

# Unset optimizations not support by clang
if test "x$ng_cv_cc_clang" = "xyes"; then
   CFLAGS=`echo $CFLAGS | sed -e 's/-fexpensive-optimizations//g' -e 's/-frerun-loop-opt//g' -e 's/-fstrength-reduce//' -e 's/-malign-double//g'`
fi

# Force define of system types on Darwin
case $target_os in
    *darwin*)
    libmamez80_a_CFLAGS='-Duint="unsigned int"'
    AC_SUBST(libmamez80_a_CFLAGS)
    ;;
esac

AM_CONDITIONAL(PROCESSOR_ARM,[test x$proc_arm = xtrue])
  
AC_DEFINE(ALIGNLONGS, ALIGNLONGS,
            [Undefine if your processor can read unaligned 32-bit values])

# needed, so def68k can find it in out-of-source builds
AC_CONFIG_LINKS([src/generator68k/def68k.def:src/generator68k/def68k.def])

AC_CONFIG_FILES([Makefile
                 gngeo.dat/Makefile
                 pnd/Makefile
                 src/Makefile
                 src/raze/Makefile
                 src/star/Makefile
                 src/mamez80/Makefile
                 src/generator68k/Makefile
                 src/cyclone/Makefile
                 src/drz80/Makefile
                 src/effect/Makefile
                 src/blitter/Makefile
                 src/ym2610/Makefile])
AC_OUTPUT
