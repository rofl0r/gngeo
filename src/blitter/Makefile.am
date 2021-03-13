noinst_LIBRARIES = libblitter.a
libblitter_a_SOURCES = glproc.h soft.c opengl.c glsl.c # overlay.c

if USE_GLSL
if USE_MINGW
shaderdir = $(datadir)/shaders
else
shaderdir = $(pkgdatadir)
endif

dist_shader_DATA = noop.glsl noop.glslp
endif

if USE_MINGW
  AM_CFLAGS = -I$(top_builddir)/mingw
endif
