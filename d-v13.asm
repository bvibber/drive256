; D-V13.ASM -> D-V13.BGD
; Drive256 driver for VGA standard mode 13h
; by Brion Vibber, 11-21-92
; updated 11-22-92

Code segment
Assume cs: Code, ds: Code

bits equ 8
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
dw SetPalette         ; Pointer to palette-setting routine. Leave blank
                      ;  for 24-bit modes.
; Optional (leave blank for emulation on procs, or no description)
dw HorizLine          ; Pointer to horizontal line routine.
dw CopyLineTo         ; Pointers to routines to copy a line to or from the
dw CopyLineFrom       ;  screen.
dw Description        ; Pointer to Pascal-style string, that describes the
                      ;  driver mode.

; Procedures and stuff

EnterGraphics proc far
  mov ax,13h
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
  xor ah,ah
  retf
GetPixel endp

SetPalette proc far
  push ds
  xchg bx,cx
  xchg dx,cx
  push es
  pop ds
  push cs
  pop es
  mov si,dx
  mov di,offset PaletteArr
  push cx
  mov dx,cx
  add cx,dx
  add cx,dx
  cld
  SetPaletteArrayCopyLoop:
  lodsb
  shr al,1
  shr al,1
  stosb
  loop SetPaletteArrayCopyLoop
  pop cx
  ;
  mov dx,offset PaletteArr
  mov ax,1012h
  int 10h
  pop ds
  xor ah,ah
  retf
SetPalette endp

HorizLine proc far
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

CopyLineTo proc far
  push ds
  push dx
  push bx
  mov ax,si
  mov bx,320
  mul bx
  add ax,cx
  mov di,ax
  pop bx
  mov si,bx
  push es
  pop ds
  mov ax,0a000h
  mov es,ax
  pop dx
  xchg cx,dx
  sub cx,dx
  inc cx
  cld
  rep movsb
  pop ds
  xor ah,ah
  retf
CopyLineTo endp

CopyLineFrom proc far
  push ds
  push dx
  push bx
  mov ax,si
  mov bx,320
  mul bx
  add ax,cx
  mov si,ax
  pop bx
  mov di,bx
  mov ax,0a000h
  mov ds,ax
  pop dx
  xchg cx,dx
  sub cx,dx
  inc cx
  cld
  rep movsb
  pop ds
  xor ah,ah
  retf
CopyLineFrom endp

Description label byte
  db 31,'Vga Mode 13h- 320x200 256 color'

; Used by SetPalette
PaletteArr label byte
  db 768 dup (0)

Code ends

end
