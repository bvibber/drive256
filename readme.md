# Drive256 - a very primitive loadable graphics driver for the VGA 256-color modes

I wrote this little experiment in 1992 while playing with Turbo Pascal, Turbo C, and Turbo Assembler -- we were a Borland household I guess! ;)

The "drivers" were written in assembler or a mix of assembly and C, and loaded at runtime. The header specified some parameters like the resolution and color depth, and had some vectors to functions which could be far-called by the client program. A high-level Pascal implementation wrapped the loader, the call thunks, and some high-level drawing code (points, lines, circles, ellipses, text) as a unit for program to use.

It's very incomplete and often makes .... weird decisions in optimization. ;) But it was just an exploration of tooling and hardware fiddling, mostly. :D

Enjoy!

-- brion of 30 years later

Notable files:

* [`drive256.txt`](https://github.com/brion/drive256/blob/main/drive256.txt) describes the header format for the drivers
* [`drive256.pas`](https://github.com/brion/drive256/blob/main/drive256.pas) is the Pascal unit source which calls into the driver implementations or do high-level operations using `PutPixel`/`GetPixel`
* Drivers
  * [`d-v13.asm`](https://github.com/brion/drive256/blob/main/d-v13.asm) - standard VGA 320x200 256-color driver
  * [`d-vx.asm`](https://github.com/brion/drive256/blob/main/d-vx.asm), [`d-vx1.c`](https://github.com/brion/drive256/blob/main/d-vx1.c) - "mode X" 320x240 256-color driver, with square pixels and accelerated horizontal line drawing (ooooh)
  * [`d-vy.asm`](https://github.com/brion/drive256/blob/main/d-vy.asm), [`d-vy1.c`](https://github.com/brion/drive256/blob/main/d-vy1.c) - 360x480 variant of same, highest resolution you could drive the VGA at in 256 colors!
  * [`rgb13.asm`](https://github.com/brion/drive256/blob/main/rgb13.asm) - (looks workable) 320x240 256-color emulating 24-bit color (3 bits red, 3 bits green, 2 bits blue)
* Test programs (not tested since the 1990s, gonna have to track down the compilers)
  * [`testd256.pas`](https://github.com/brion/drive256/blob/main/testd256.pas) - test the various functions.
  * [`hsv4.pas`](https://github.com/brion/drive256/blob/main/hsv4.pas) - some sort of hue/saturation/value visualization, half of it's a mouse driver ;)
  * [`tgapic10.pas`](https://github.com/brion/drive256/blob/main/tgapic10.pas) - reads a Targa (`.tga`) image file and draws it, slowly, to output. For 256-color output it uses a 3/3/2-bit RGB palette for 24-bit files, with some dithering. I'm somewhat dubious of the dithering and scaling algorithms.
  * [`dumpd256.pas`](https://github.com/brion/drive256/blob/main/dumpd256.pas) - reads the driver header and dumps it to output
  * [`demd256.pas`](https://github.com/brion/drive256/blob/main/demd256.pas), [`demd1.asm`](https://github.com/brion/drive256/blob/main/demd1.asm) - draws every possible color in a loop?
  * [`d256app.pas`](https://github.com/brion/drive256/blob/main/d256app.pas) - looks like a template skeleton for an app that uses it and does a crappy copy-pasta mouse cursor driver?
