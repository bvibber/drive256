.model tpascal

.data
  extrn MaxColor: DWord
  extrn MaxX: Word, MaxY: Word

.code
  extrn PutPixel: far
  public AssemblerStuff

AssemblerStuff proc far
  .386
  xor eax,eax
  xor ebx,ebx
  xor ecx,ecx
  .8086
  mov ax,[MaxX]
  mov bx,[MaxY]
  .386
  imul ebx
  xor edx,edx
  .8086
  xLoop:
    xor dx,dx
    YLoop:
      push cx ; for PutPixel
      push dx ; for PutPixel
      .386
      push edx
      push ecx
      push eax
      ; Calculate color
      push eax                  ;save eax
      mov eax,ecx               ;eax = x
      imul edx                  ;eax = x*y
      imul dword ptr [MaxColor] ;eax = x*y*MaxColor
      mov ebx,eax               ;ebx = x*y*MaxColor
      pop eax                   ;restore eax = MaxX*MaxY
      xchg ebx,eax              ;ebx = MaxX*MaxY, eax = x*y*MaxColor
      idiv ebx                  ;eax = (x*y*MaxColor) / (MaxX*MaxY)
      push eax ; for PutPixel
      .8086
      call far [PutPixel]
      .386
      pop eax
      pop ecx
      pop edx
      .8086

      inc dx
      cmp dx,MaxY
    jle YLoop
    inc cx
    cmp cx,MaxX
  jle XLoop
  retf
AssemblerStuff endp

end
