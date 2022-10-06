/* HorzLine proc for my Drive256 mode X driver */
void far pascal HorizLine(void)
{
  int x1,x2,y,x,off,off1,edge1_xpos,edge2_xpos;
  char c,edge1_planes,edge2_planes;

  asm {
    mov word ptr x1,cx
    mov word ptr x2,dx
    mov word ptr y,si
    mov byte ptr c,al

    mov ax,si
    mov bx,90
    mul bx
    mov word ptr off1,ax
  }

  edge1_planes = (15 << (x1 & 3)) & 15;
  edge2_planes = (~(15 << ((x2 & 3)+1))) & 15;
  asm {
    mov cl,2
    mov ax,x1
    shr ax,cl
    mov word ptr [edge1_xpos],ax
    mov ax,x2
    shr ax,cl
    mov word ptr edge2_xpos,ax
  }
  if (edge1_xpos==edge2_xpos) {
    edge1_planes = edge1_planes & edge2_planes;
    edge2_planes = 0;
  }
  asm {
    cld
    mov ax,0xa000
    mov es,ax

    mov dx,0x3c4
    mov ah,edge1_planes
    mov al,2
    out dx,ax

    mov di,off1
    add di,edge1_xpos
    mov al,c
    stosb
  }
  if (edge2_planes)
    asm {
      mov dx,0x3c4
      mov ah,edge2_planes
      mov al,2
      out dx,ax
      mov di,off1
      add di,edge2_xpos
      mov al,c
      stosb

      mov dx,0x3c4
      mov ax,0xf02
      out dx,ax
      mov al,c
      mov di,off1
      add di,edge1_xpos
      inc di
      mov cx,edge2_xpos
      sub cx,edge1_xpos
      dec cx
      rep stosb
    }
}
