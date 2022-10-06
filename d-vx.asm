; D-VX.ASM -> D-VX.BGD
; Drive256 driver for VGA mode X
; by Brion Vibber, 11-22-92

_Text segment
Assume cs: _Text, ds: _Text

bits equ 8
ScrWidth equ 320
ScrHeight equ 240
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

; Required
dw EnterGraphics      ; Pointer to mode-set routine (see procedure
                      ;  format below).
dw LeaveGraphics      ; Pointer to proc to leave graphics mode
dw ClearScreen        ; Pointer to screen clearing routine
dw PutPixel           ; Pointer to pixel drawing routine
dw GetPixel           ; Pointer to pixel getting routine
dw SetPalette         ; Pointer to palette-setting routine. Leave blank
                      ;  for 24-bit modes.
extrn HorizLine:far
; Optional (leave blank for emulation on procs, or no description)
dw HorizLine          ; Pointer to horizontal line routine.
dw 0;CopyLineTo         ; Pointers to routines to copy a line to or from the
dw 0;CopyLineFrom       ;  screen.
dw Description        ; Pointer to Pascal-style string, that describes the
                      ;  driver mode.

; Procedures and stuff

EnterGraphics proc far
  sc_index equ 3c4h
  crtc_index equ 3d4h
  misc_output equ 3c2h
  screen_seg equ 0a000h
  crt_parm_length equ 10

  mov ax,13h
  int 10h

  mov dx,sc_index
  mov ax,604h
  out dx,ax
  mov ax,100h
  out dx,ax

  mov dx,misc_output
  mov al,0e3h
  out dx,al

  mov dx,sc_index
  mov ax,300h
  out dx,ax

  mov dx,crtc_index
  mov al,11h
  out dx,al
  inc dx
  in al,dx
  and al,7fh
  out dx,al
  dec dx
  cld

  push ds
  push cs
  pop ds
  mov si,offset CRTParms
  mov cx,crt_parm_length
SetCRTParmsLoop:
  lodsw
  out dx,ax
  loop SetCRTParmsLoop
  pop ds

  mov dx,sc_index
  mov ax,0f02h
  out dx,ax
  mov ax,screen_seg
  mov es,ax
  sub di,di
  sub ax,ax
  mov cx,8000h
  rep stosw

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
  mov dx,3c4h
  mov ax,0f02h
  out dx,ax
  mov ax,0a000h
  mov es,ax
  sub di,di
  sub ax,ax
  mov cx,8000h
  rep stosw
  retf
ClearScreen endp

PutPixel proc far
  ; Set write plane
  push ax
  push cx
  push dx
  mov dx,3c4h
  mov ax,102h
  and cl,3
  shl ah,cl
  out dx,ax
  pop dx
  pop cx

  ; Write a byte
  mov ax,0a000h
  mov es,ax
  mov ax,dx
  mov dx,80
  mul dx
  mov di,cx
  shr di,1
  shr di,1
  add di,ax
  pop ax
  stosb

  ; Restore write plane
  mov dx,3c4h
  mov ax,0f02h
  out dx,ax

  xor ah,ah
  retf
PutPixel endp

GetPixel proc far
  ; Set read plane
  push dx
  mov dx,3ceh
  mov al,4
  mov ah,cl
  and ah,3
  out dx,ax
  pop dx

  ; Read a byte
  push ds
  mov ax,0a000h
  mov ds,ax
  mov ax,dx
  mov dx,80
  mul dx
  mov si,cx
  shr si,1
  shr si,1
  add si,ax
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

CopyLineTo proc far
  mov ah,1
  retf
CopyLineTo endp

CopyLineFrom proc far
  mov ah,1
  retf
CopyLineFrom endp

Description label byte
  db 29,'Vga Mode X- 320x240 256 color'

; Used by EnterGraph
CRTParms label word
 dw 00d06h
 dw 03e07h
 dw 04109h
 dw 0ea10h
 dw 0ac11h
 dw 0df12h
 dw 00014h
 dw 0e715h
 dw 00616h
 dw 0e317h

; Used by SetPalette
PaletteArr label byte
  db 768 dup (0)

_Text ends

end
