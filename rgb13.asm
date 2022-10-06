; RGB13.ASM -> RGB13.BGD
; Drive256 driver for VGA standard mode 13h, RGB test version
; by Brion Vibber, 11-22-92

_Text segment
Assume cs: _Text, ds: _Text

bits equ 24
ScrWidth equ 320
ScrHeight equ 200
AspectMul equ 5
AspectDiv equ 6

; Header
db 'D256'             ; Identification for Drive256
db bits               ; 8 for 256 color, 24 for 24-bit
dw ScrWidth           ; Width of screen in pixels
dw ScrHeight          ; Height of screen in pixels
dw AspectMul          ; Aspect ratio of pixel = AspectMul / AspectDiv
dw AspectDiv          ;

; Vectors

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
dw HorizLine          ; Pointer to horizontal line routine.
dw 0;CopyLineTo         ; Pointers to routines to copy a line to or from the
dw 0;CopyLineFrom       ;  screen.
dw Description        ; Pointer to Pascal-style string, that describes the
                      ;  driver mode.

; Procedures and stuff

; input: al=red,bh=green,bl=blue
; output: al=color
; destroys: cl
rgb_2_bit8 proc near
  mov cl,6
  shr bl,cl
  mov cl,3
  shr bh,cl
  and bh,1ch
  and al,0e0h
  or al,bh
  or al,bl
  retn
rgb_2_bit8 endp

; input: al=color
; output: al=red,bh=green,bl=blue
; destroys: cl
bit8_2_rgb proc near
  mov bh,al
  mov bl,al
  and al,0e0h
  and bh,1ch
  and bl,3
  mov cl,3
  shl bh,cl
  mov cl,6
  shl bl,cl
  retn
bit8_2_rgb endp

EnterGraphics proc far
  mov ax,13h
  int 10h

  ; Set palette
  push cs
  pop es
  mov di,offset PaletteArr
  cld
  xor dl,dl
  mov cx,256
  EnterGraphicsSetPaletteLoop:
  push cx
  mov al,dl
  inc dl
  call bit8_2_rgb
  shr al,1
  shr al,1
  shr bh,1
  shr bh,1
  shr bl,1
  shr bl,1
  stosb
  mov al,bh
  stosb
  mov al,bl
  stosb
  pop cx
  loop EnterGraphicsSetPaletteLoop
  mov ax,1012h
  xor bx,bx
  mov cx,256
  mov dx,offset PaletteArr
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

PutPixel proc far
  push cx
  call rgb_2_bit8
  pop cx
  push ax
  mov ax,0a000h
  mov es,ax
  mov ax,dx
  mov bx,320
  mul bx
  add ax,cx
  mov di,ax
  pop ax
  stosb
  xor ah,ah
  retf
PutPixel endp

GetPixel proc far
  push ds
  mov ax,0a000h
  mov ds,ax
  mov ax,dx
  mov bx,320
  mul bx
  add ax,cx
  mov si,ax
  lodsb
  pop ds
  call bit8_2_rgb
  xor ah,ah
  retf
GetPixel endp

HorizLine proc far
  push cx
  call rgb_2_bit8
  pop cx
  push ax
  push dx
  mov ax,0a000h
  mov es,ax
  mov ax,si
  mov bx,320
  mul bx
  add ax,cx
  mov di,ax
  pop dx
  pop ax
  xchg cx,dx
  sub cx,dx
  inc cx
  cld
  rep stosb
  xor ah,ah
  retf
HorizLine endp

Description label byte
  db 30,'Vga Mode 13h, RGB test version'

; Used by EnterGraph for setting the palette to RGB
PaletteArr label byte
  db 768 dup (0)

_Text ends

end
