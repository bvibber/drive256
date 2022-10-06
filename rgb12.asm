; RGB12.ASM -> RGB12.BGD
; Drive256 driver for VGA standard mode 12h, RGB test version
; by Brion Vibber, 11-23-92

_Text segment
Assume cs: _Text, ds: _Text

bits equ 24
ScrWidth equ 640
ScrHeight equ 480
AspectMul equ 1
AspectDiv equ 1

; Header
db 'D256'             ; Identification for Drive256
db bits               ; 8 for 256 color, 24 for 24-bit
dw ScrWidth           ; Width of screen in pixels
dw ScrHeight          ; Height of screen in pixels
dw AspectMul          ; Aspect ratio of pixel = AspectMul / AspectDiv
dw AspectDiv          ;

; Vectors

extrn PutPixel: far
extrn GetPixel: far

; Required
dw EnterGraphics      ; Pointer to mode-set routine (see procedure
                      ;  format below).
dw LeaveGraphics      ; Pointer to proc to leave graphics mode
dw ClearScreen        ; Pointer to screen clearing routine
dw PutPixel           ; Pointer to pixel drawing routine
dw GetPixel           ; Pointer to pixel getting routine
dw 0;SetPalette         ; Pointer to palette-setting routine. Leave blank
                      ;  for 24-bit modes.
; Optional (leave blank for emulation on procs, or no description)
dw 0;HorizLine          ; Pointer to horizontal line routine.
dw 0;CopyLineTo         ; Pointers to routines to copy a line to or from the
dw 0;CopyLineFrom       ;  screen.
dw Description        ; Pointer to Pascal-style string, that describes the
                      ;  driver mode.

; Procedures and stuff

EnterGraphics proc far
  mov ax,12h
  int 10h

  ; Set palette
  push cs
  pop es
  mov dx,offset PaletteArr
  mov ax,1002h
  int 10h

  xor ah,ah
  retf
EnterGraphics endp

LeaveGraphics proc far
  mov ax,3
  int 10h
  xor ah,ah
  retf
LeaveGraphics endp

ClearScreen proc far
  mov ax,0a000h
  mov es,ax
  sub di,di
  sub ax,ax
  mov cx,8000h
  rep stosw
  retf
ClearScreen endp

Description label byte
  db 30,'Vga Mode 12h, RGB test version'

; For EnterGraphics
PaletteArr label byte
  db 0,1,2,3,4,5,6,7
  db 38h,9,12h,1bh,24h,2dh,36h,3fh
  db 0

_Text ends

end
