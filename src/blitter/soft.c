
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "SDL.h"
#include "../emu.h"
#include "../screen.h"
#include "../video.h"
#include "../effect.h"
#include "../conf.h"
#include "../gnutil.h"
#ifdef GP2X
#include "../gp2x.h"

#define SC_STATUS     0x1802>>1
#define SC_DISP_FIELD (1<<8)

#endif
/*
static SDL_Rect buf_rect	 =	{16, 16, 304, 224};
*/
#ifdef DEVKIT8000
static SDL_Rect screen_rect =	{ 0,  0, 304, 240};
#else
static SDL_Rect screen_rect =	{ 0,  0, 304, 224};
#endif
static int vsync;

#if !defined(I386_ASM) && !defined(PROCESSOR_ARM)
#define RGB24_PIXELS 1
#define UPDATE_VISIBLE_AREA (visible_area.w>>0)
#else
#define UPDATE_VISIBLE_AREA (visible_area.w>>1)
#endif

int
blitter_soft_init()
{
	Uint32 width = visible_area.w;
	Uint32 height = visible_area.h;

	if (window != NULL) return GN_TRUE;

#ifdef GP2X
	Uint32 screen_w;
	int *tvoffset = CF_ARRAY(cf_get_item_by_name("tv_offset"));
#endif
	//int screen_size=CF_BOOL(cf_get_item_by_name("screen320"));
#ifdef DEVKIT8000
	Uint32 sdl_flags = fullscreen?SDL_WINDOW_FULLSCREEN:0;

	screen_rect.w=visible_area.w;
	screen_rect.h=240;
	height=240;
#else
	Uint32 sdl_flags = 0;

	vsync = CF_BOOL(cf_get_item_by_name("vsync"));

	if (vsync) {
		height=240;
		screen_rect.y = 8;

	} else {
		height=visible_area.h;
		screen_rect.y = 0;
		yscreenpadding=0;
	}

	screen_rect.w=visible_area.w;
	screen_rect.h=visible_area.h;


#endif
	if (neffect!=0)	scale =1;
	if (scale == 1) {
	    width *=effect[neffect].x_ratio;
	    height*=effect[neffect].y_ratio;
	} else {
	    if (scale > 3) scale=3;
	    width *=scale;
	    height *=scale;
	}
	
#ifdef PANDORA
		
	if (CF_BOOL(cf_get_item_by_name("wide"))) {
		setenv("SDL_OMAP_LAYER_SIZE","800x480",1);
	} else {
		setenv("SDL_OMAP_LAYER_SIZE","640x480",1);
	}
	
#endif
	
#ifdef GP2X
	//screen = SDL_SetVideoMode(width, height, 16, sdl_flags);

	//gp2x_video_RGB_setscaling(320, 240);
	//screen = SDL_SetVideoMode(320, 240, 16, 
	if ((screen_w=gp2x_is_tvout_on())==0) {
		screen = SDL_SetVideoMode(width, height, 16, 
					  sdl_flags|
					  (CF_BOOL(cf_get_item_by_name("vsync"))?SDL_DOUBLEBUF:0));

		if (CF_BOOL(cf_get_item_by_name("vsync"))) {
			set_LCD_custom_rate(LCDR_60);
		}
		
		if (width!=320) {
			//screen_rect.x=8;
			SDL_GP2X_MiniDisplay(8,8);
		} else {
			//screen_rect.y=8;
			SDL_GP2X_MiniDisplay(0,8);
		}
	} else {
		if (screen_w==240) /* ntsc */
			screen = SDL_SetVideoMode(360, 240, 16, 
						  sdl_flags|
						  (CF_BOOL(cf_get_item_by_name("vsync"))?SDL_DOUBLEBUF:0));
		else /* pal */
			screen = SDL_SetVideoMode(360, 288, 16, 
						  sdl_flags|
						  (CF_BOOL(cf_get_item_by_name("vsync"))?SDL_DOUBLEBUF:0));
		if (width!=320) {
			screen_rect.x=8;
		}
		screen_rect.y=8;
		/* tvout pseudo offset fix */
		screen_rect.y=(signed)screen_rect.y+tvoffset[1];
		screen_rect.x=(signed)screen_rect.x+tvoffset[0];
		if (screen_rect.x<0) {visible_area.x-=screen_rect.x;screen_rect.x=0;}
		if (screen_rect.y<0) {visible_area.y-=screen_rect.y;screen_rect.y=0;}
	}


#else
	window = SDL_CreateWindow("Gngeo",
				  SDL_WINDOWPOS_UNDEFINED,
				  SDL_WINDOWPOS_UNDEFINED,
				  width, height,
				  (fullscreen?SDL_WINDOW_FULLSCREEN_DESKTOP:0)|sdl_flags);
	renderer = SDL_CreateRenderer(window, -1, vsync?SDL_RENDERER_PRESENTVSYNC:0);
	// for preserving aspect when scaling
	SDL_RenderSetLogicalSize(renderer, width, height);
	//SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "linear");
#ifndef RGB24_PIXELS
	texture = SDL_CreateTexture(renderer,
				    SDL_PIXELFORMAT_RGB565,
				    SDL_TEXTUREACCESS_STREAMING,
				    width, height);
	screen = SDL_CreateRGBSurface(SDL_SWSURFACE, width, height, 16, 0xF800, 0x7E0, 0x1F, 0);
#else
	texture = SDL_CreateTexture(renderer,
				    SDL_PIXELFORMAT_ARGB8888,
				    SDL_TEXTUREACCESS_STREAMING,
				    width, height);
	screen = SDL_CreateRGBSurface(SDL_SWSURFACE, width, height, 32, 0, 0, 0, 0);
#endif
	//SDL_ShowCursor(SDL_DISABLE);
#endif
	if (!screen) return GN_FALSE;
	if (vsync) yscreenpadding = screen_rect.y * screen->pitch;

	return GN_TRUE;
}

void 
update_double()
{
	buffer_pixel_t *src, *dst;
	Uint32 s, d;
	buffer_pixel_t w, h;
	
	src = (buffer_pixel_t *)buffer->pixels + visible_area.x + (buffer->w << 4);// LeftBorder + RowLength * UpperBorder

	dst = (buffer_pixel_t *)screen->pixels + yscreenpadding;
	
	for(h = visible_area.h; h > 0; h--)
	{
		for(w = UPDATE_VISIBLE_AREA; w > 0; w--)
		{		
			s = *(Uint32 *)src;
#ifndef RGB24_PIXELS
#ifdef WORDS_BIGENDIAN
			d = (s & 0xFFFF0000) + ((s & 0xFFFF0000)>>16);
			*(Uint32 *)(dst) = d;
			*(Uint32 *)(dst+(visible_area.w<<1)) = d;
				
			d = (s & 0x0000FFFF) + ((s & 0x0000FFFF)<<16);
			*(Uint32 *)(dst+2) = d;
			*(Uint32 *)(dst+(visible_area.w<<1)+2) = d;
#else
			d = (s & 0x0000FFFF) + ((s & 0x0000FFFF) << 16);
			*(Uint32 *)(dst) = d;
			*(Uint32 *) (dst + (visible_area.w << 1)) = d;

			d = (s & 0xFFFF0000) + ((s & 0xFFFF0000)>>16);
			*(Uint32 *)(dst+2) = d;
			*(Uint32 *)(dst+(visible_area.w<<1)+2) = d;
				
			dst += 4;
			src += 2;

#endif
#else
			*(buffer_pixel_t *)(dst) = s;
			*(buffer_pixel_t *)(dst+1) = s;
			*(buffer_pixel_t *) (dst + (visible_area.w << 1)) = s;
			*(buffer_pixel_t *) (dst + (visible_area.w << 1)+1) = s;
			dst += 2;
			src += 1;
#endif
		}
		//memcpy(dst,dst-(visible_area.w<<1),(visible_area.w<<2));
		src += (visible_area.x<<1);		
		dst += (visible_area.w<<1);
//		dst += (buffer->pitch);
	}
}

void 
update_triple()
{
	buffer_pixel_t *src, *dst;
	Uint32 s, d;
	buffer_pixel_t w, h;
	
	src = (buffer_pixel_t *)buffer->pixels + visible_area.x + (buffer->w << 4);// LeftBorder + RowLength * UpperBorder
	dst = (buffer_pixel_t *)screen->pixels + yscreenpadding;
	
	for(h = visible_area.h; h > 0; h--)
	{
		for(w = UPDATE_VISIBLE_AREA; w > 0; w--)
		{		
			s = *(Uint32 *)src;
#ifndef RGB24_PIXELS
#ifdef WORDS_BIGENDIAN
			d = (s & 0xFFFF0000) + ((s & 0xFFFF0000)>>16);
			*(Uint32 *)(dst) = d;
			*(Uint32 *)(dst+(visible_area.w*3)) = d;
			*(Uint32 *)(dst+(visible_area.w*6)) = d;
				
			*(Uint32 *)(dst+2) = s;
			*(Uint32 *)(dst+(visible_area.w*3)+2) = s;
			*(Uint32 *)(dst+(visible_area.w*6)+2) = s;

			d = (s & 0x0000FFFF) + ((s & 0x0000FFFF)<<16);
			*(Uint32 *)(dst+4) = d;
			*(Uint32 *)(dst+(visible_area.w*3)+4) = d;
			*(Uint32 *)(dst+(visible_area.w*6)+4) = d;

#else				
			d = (s & 0xFFFF0000) + ((s & 0xFFFF0000)>>16);
			*(Uint32 *)(dst+4) = d;
			*(Uint32 *)(dst+(visible_area.w*3)+4) = d;
			*(Uint32 *)(dst+(visible_area.w*6)+4) = d;

			*(Uint32 *)(dst+2) = s;
			*(Uint32 *)(dst+(visible_area.w*3)+2) = s;
			*(Uint32 *)(dst+(visible_area.w*6)+2) = s;

			d = (s & 0x0000FFFF) + ((s & 0x0000FFFF)<<16);
			*(Uint32 *)(dst) = d;
			*(Uint32 *)(dst+(visible_area.w*3)) = d;
			*(Uint32 *)(dst+(visible_area.w*6)) = d;
#endif			
			dst += 6;
			src += 2;
#else
			*(buffer_pixel_t *)(dst) = s;
			*(buffer_pixel_t *)(dst+1) = s;
			*(buffer_pixel_t *)(dst+2) = s;
			*(buffer_pixel_t *) (dst + (visible_area.w * 3)) = s;
			*(buffer_pixel_t *) (dst + (visible_area.w * 3)+1) = s;
			*(buffer_pixel_t *) (dst + (visible_area.w * 3)+2) = s;
			*(buffer_pixel_t *) (dst + (visible_area.w *6)) = s;
			*(buffer_pixel_t *) (dst + (visible_area.w *6)+1) = s;
			*(buffer_pixel_t *) (dst + (visible_area.w *6)+2) = s;
			dst += 3;
			src += 1;
#endif
		}
		src += (visible_area.x<<1);		
		dst += (visible_area.w*6);
	}
}
#ifdef GP2X
int threaded_blit(void *buf)
{
	SDL_Surface *b=(SDL_Surface*)buf;
	SDL_BlitSurface(b, &visible_area, screen, &screen_rect);
	SDL_Flip(screen);
	return 0;
}
#endif
void
blitter_soft_update()
{
#ifdef GP2X
    SDL_BlitSurface(buffer, &visible_area, screen, &screen_rect);
    SDL_Flip(screen);
#else
#ifdef PANDORA
	if (neffect == 0 || neffect == 1) {
#else
		if (neffect == 0) {
#endif
			switch (scale) {
				case 2: update_double(); break;
				case 3: update_triple(); break;
				default:
					SDL_BlitSurface(buffer, &visible_area, screen, &screen_rect);
					break;
			}
			
		}

#ifndef RGB24_PIXELS
  SDL_UpdateTexture(texture, NULL, screen->pixels, screen->w*2);
#else
  SDL_UpdateTexture(texture, NULL, screen->pixels, screen->w*4);
#endif
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);

#endif
 
}

void
blitter_soft_close()
{
    
}
	
void
blitter_soft_fullscreen() {
  SDL_SetWindowFullscreen(window,
			  fullscreen?SDL_WINDOW_FULLSCREEN:0);
}
	
