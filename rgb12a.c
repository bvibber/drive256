/* RGB12A.C
  for use with RGB12.ASM to make RGB12.BGD
  by Brion Vibber, 11-23-92
*/

void far pascal PutPixel(void)
{
  int x,y;
  char r,g,b,c,rr,gg,bb,cc;
  unsigned offst,mask,oldds;

  x = _CX; y = _DX;
  r = _AL; g = _BH; b = _BL;
  oldds = _DS;
  _DS = _CS;

  //c =
  //  ((r & 0x80) >> 5) |
  //  ((g & 0x80) >> 6) |
  //  ((b & 0x80) >> 7);
  rr = (r & 0xc0) >> 6);
  gg = (g & 0xc0) >> 6);
  bb = (b & 0xc0) >> 6);
  //  NearestColor[
  //    ((r & 0xc0) >> 2) |
  //    ((g & 0xc0) >> 4) |
  //    ((b & 0xc0) >> 6)
  //  ];
  //  ((r & 0x40) >> 4) |
  //  ((g & 0x40) >> 5) |
  //  ((b & 0x40) >> 6) |
  //  (((r & 0x80) | (g & 0x80) | (b & 0x80)) >> 4);
  offst = y * 80 + (x / 8);
  mask = 0x80 >> (x % 8);

  asm {
    mov ax,0a000h
    mov es,ax
    mov bx,[offst]
    mov cl,[c]
    xor ch,ch
    mov ax,[mask]
    mov ah,al
    mov al,8
    mov dx,03ceh
    out dx,ax
    mov ax,0ff02h
    mov dl,0c4h
    out dx,ax
    or es:[bx],ch
    mov byte ptr es: [bx],0
    mov ah,cl
    out dx,ax
    mov byte ptr es: [bx],0ffh
    mov ah,0ffh
    out dx,ax
    mov dl,0ceh
    mov ax,3
    out dx,ax
    mov ax,0ff08h
    out dx,ax
  }
  _DS = oldds;
  _AH = 0;
}

void far pascal GetPixel(void)
{
  _AL = 0;
  _BH = 0;
  _BL = 0;
  _AH = 0;
}
