unit Drive256;
{ 256 color / 24-bit graphics, using drivers.
  by Brion Vibber, 11-21-92
    See Drive256.txt for info on how to make or read
  a driver.
  updated 11-23-92
}

interface

type
  D256Header = record
    Ident: array[1..4] of Char; { 'D256' for Drive256 drivers }
    bits: Byte;
    ScrWidth,
    ScrHeight,
    AspectMul,
    AspectDiv: Integer;
    EnterGraphics,
    LeaveGraphics,
    ClearScreen,
    PutPixel,
    GetPixel,
    SetPalette,
    HorizLine,
    CopyLineTo,
    CopyLineFrom,
    Description: Word;
  end;

const
  Drive256Ident = 'D256';
  Bits256Color = 8;
  Bits24Bit = 24;
  VectorEmpty = 0;
  VectorEmulate = 0;

  CurrColor: LongInt = 0;

procedure InitDriver(Drv: String);
procedure KillDriver;
procedure GetHeader(var h: D256Header);
function GraphSetUp: Boolean;
function InGraphMode: Boolean;
function GraphError: Boolean;
function Is256Color: Boolean;
function Is24Bit: Boolean;
function GetWidth: Integer;
function GetHeight: Integer;
function GetMaxX: Integer;
function GetMaxY: Integer;
function GetAspectMul: Integer;
function GetAspectDiv: Integer;
function GetAspect: Real;
function GetDescription: String;

procedure InitGraph;
procedure CloseGraph;
procedure ClearScreen;
procedure PutPixel(x,y: Integer; c: LongInt);
function GetPixel(x,y: Integer): LongInt;
procedure SetPalette(First,Num: Integer; var buf);
procedure HLine(x1,x2,y: Integer);
procedure CopyLineTo(x1,x2,y: Integer; var buf);
procedure CopyLineFrom(x1,x2,y: Integer; var buf);

procedure Line(x,y,x2,y2: Integer);
procedure Circle(xc,yc,r: Integer);
procedure Ellipse(xc,yc,rx,ry: Integer);
procedure Bar(x1,y1,x2,y2: Integer);
procedure CopyToScreen(x1,y1,x2,y2: Integer; var buf);
procedure CopyFromScreen(x1,y1,x2,y2: Integer; var buf);
procedure Text(x,y: Integer; txt: String);

function Rgb(r,g,b: Integer): LongInt;
procedure GetRgb(c: LongInt; var r,g,b: Integer);

implementation

type
  ByteArray = array[0..65520] of Byte;

const
  GraphicsSetUp: Boolean = False;
  InGraphicsMode: Boolean = False;
  GraphicsError: Boolean = False;

var
  Buffer: ^ByteArray;
  BufferSize: Word;
  Driver: ^ByteArray;
  DriverSeg: Word;
  Hdr: D256Header;

procedure InitDriver(Drv: String);
var
  f: File of Byte;
  ff: File absolute f;
  s,o: Word;
  l: LongInt;
begin
  GraphicsError := True;
  if Pos('.',Drv) = 0 then Drv := Drv + '.bgd';
  Assign(f,Drv);
  {$I-}
  Reset(f);
  {$I+}
  if IOResult <> 0 then Exit;
  l := FileSize(f);
  if l >= 65520 then begin
    Close(f);
    Exit;
  end;
  BufferSize := l+16;
  GetMem(Buffer,BufferSize);
  if Buffer = nil then begin
    Close(f);
    Exit;
  end;
  s := Seg(Buffer^); o := Ofs(Buffer^);
  { Modify so s is segment so that o is nearest to 0 }
  while (o >= 16) do begin
    Inc(s);
    Dec(o,16);
  end;
  { If necessary, move around so o is 0 }
  if o <> 0 then begin
    Inc(s);
    o := 0;
  end;
  DriverSeg := s;
  Driver := Ptr(s,o);
  BlockRead(ff,Driver^,l);
  Close(f);
  Move(Driver^,Hdr,SizeOf(D256Header));
  if Hdr.Ident <> 'D256' then begin
    FreeMem(Buffer,BufferSize);
    Exit;
  end;
  GraphicsError := False;
  GraphicsSetUp := True;
end;

procedure KillDriver;
begin
  if GraphicsSetUp then begin
    FreeMem(Buffer,BufferSize);
    GraphicsSetUp := False;
    GraphicsError := False;
  end;
end;

procedure GetHeader(var h: D256Header);
begin
  Move(Driver^,h,SizeOf(D256Header));
end;

function GraphSetUp: Boolean;
begin
  GraphSetUp := GraphicsSetUp;
end;

function InGraphMode: Boolean;
begin
  InGraphMode := InGraphicsMode;
end;

function GraphError: Boolean;
begin
  GraphError := GraphicsError;
end;

function Is256Color: Boolean;
begin
  if GraphicsSetUp then
    Is256Color := Hdr.Bits = 8
  else
    Is256Color := False;
end;

function Is24Bit: Boolean;
begin
  if GraphicsSetUp then
    Is24Bit := Hdr.Bits = 24
  else
    Is24Bit := False;
end;

function GetWidth: Integer;
begin
  if GraphicsSetUp then
    GetWidth := Hdr.ScrWidth
  else
    GetWidth := 0;
end;

function GetHeight: Integer;
begin
  if GraphicsSetUp then
    GetHeight := Hdr.ScrHeight
  else
    GetHeight := 0;
end;

function GetMaxX: Integer;
begin
  if GraphicsSetUp then
    GetMaxX := Hdr.ScrWidth-1
  else
    GetMaxX := 0;
end;

function GetMaxY: Integer;
begin
  if GraphicsSetUp then
    GetMaxY := Hdr.ScrHeight-1
  else
    GetMaxY := 0;
end;

function GetAspectMul: Integer;
begin
  if GraphicsSetUp then
    GetAspectMul := Hdr.AspectMul
  else
    GetAspectMul := 0;
end;

function GetAspectDiv: Integer;
begin
  if GraphicsSetUp then
    GetAspectDiv := Hdr.AspectDiv
  else
    GetAspectDiv := 1;
end;

function GetAspect: Real;
begin
  if GraphicsSetUp then
    GetAspect := Hdr.AspectMul / Hdr.AspectDiv
  else
    GetAspect := 0.0;
end;

function GetDescription: String;
type
  PString = ^String;
begin
  if (not GraphicsSetUp) or (Hdr.Description = 0) then
    GetDescription := ''
  else
    GetDescription := PString(Ptr(DriverSeg,Hdr.Description))^;
end;


var
  cdf_l: LongInt;

procedure InitGraph; assembler;
asm
  mov ax,[DriverSeg]
  mov word ptr [cdf_l+2],ax
  mov ax,[Hdr.EnterGraphics]
  mov word ptr [cdf_l],ax
  call [cdf_l]
  mov [GraphicsError],ah
end;

procedure CloseGraph; assembler;
asm
  mov ax,[DriverSeg]
  mov word ptr [cdf_l+2],ax
  mov ax,[Hdr.LeaveGraphics]
  mov word ptr [cdf_l],ax
  call [cdf_l]
  mov [GraphicsError],ah
end;

procedure ClearScreen; assembler;
asm
  mov ax,[DriverSeg]
  mov word ptr [cdf_l+2],ax
  mov ax,[Hdr.ClearScreen]
  mov word ptr [cdf_l],ax
  call [cdf_l]
  mov [GraphicsError],ah
end;

procedure PutPixel(x,y: Integer; c: LongInt);
label label1,label2;
begin
  if (Word(x) >= Hdr.ScrWidth) or (Word(y) >= Hdr.ScrHeight) then
    Exit;
  asm
    mov ax,[DriverSeg]
    mov word ptr [cdf_l+2],ax
    mov ax,[Hdr.PutPixel]
    mov word ptr [cdf_l],ax

    cmp byte ptr [Hdr.Bits],8
    jne label1
    mov al,byte ptr [c]
    jmp label2
    label1:
    mov al,byte ptr [c+2]
    mov bx,word ptr [c]
    label2:

    mov cx,[x]
    mov dx,[y]

    call [cdf_l]
    mov [GraphicsError],ah
  end;
end;

function GetPixel(x,y: Integer): LongInt;
label label1,label2;
begin
  if (Word(x) >= Hdr.ScrWidth) or (Word(y) >= Hdr.ScrHeight) then
    GetPixel := 0
  else
    asm
      mov ax,[DriverSeg]
      mov word ptr [cdf_l+2],ax
      mov ax,[Hdr.GetPixel]
      mov word ptr [cdf_l],ax
      mov cx,[x]
      mov dx,[y]
      call [cdf_l]

      mov [GraphicsError],ah
      cmp byte ptr [Hdr.Bits],8
      jne label1
      xor ah,ah
      mov word ptr [@Result],ax
      mov word ptr [@Result+2],0
      jmp label2
      label1:
      xor ah,ah
      mov word ptr [@Result+2],ax
      mov word ptr [@Result],bx
      label2:
    end;
end;

procedure SetPalette(First,Num: Integer; var buf);
begin
  if Hdr.SetPalette <> 0 then
    asm
      mov ax,[DriverSeg]
      mov word ptr [cdf_l+2],ax
      mov ax,[Hdr.SetPalette]
      mov word ptr [cdf_l],ax
      mov cx,[First]
      mov dx,[Num]
      mov bx,word ptr [buf]
      mov ax,word ptr [buf+2]
      mov es,ax
      call [cdf_l]
      mov [GraphicsError],ah
    end;
end;

procedure HLine(x1,x2,y: Integer);
label label1,label2;
var
  i: Integer;
begin
  if ((x1 < 0) and (x2 < 0)) or
    ((x1 >= Hdr.ScrWidth) and (x2 >= Hdr.ScrWidth)) or
    (y < 0) or (y >= Hdr.ScrHeight) then Exit;
  if x1 > x2 then begin
    i := x1; x1 := x2; x2 := i;
  end;
  if x1 < 0 then x1 := 0; if x2 >= Hdr.ScrWidth then x2 := Hdr.ScrWidth-1;
  if Hdr.HorizLine = 0 then begin
    for i := x1 to x2 do
      PutPixel(i,y,CurrColor);
  end else
    asm
      mov ax,[DriverSeg]
      mov word ptr [cdf_l+2],ax
      mov ax,[Hdr.HorizLine]
      mov word ptr [cdf_l],ax

      cmp byte ptr [Hdr.Bits],8
      jne label1
      mov al,byte ptr [CurrColor]
      jmp label2
      label1:
      mov al,byte ptr [CurrColor+2]
      mov bx,word ptr [CurrColor]
      label2:

      mov cx,[x1]
      mov dx,[x2]
      mov si,[y]

      call [cdf_l]
      mov [GraphicsError],ah
    end;
end;

procedure CopyLineTo(x1,x2,y: Integer; var buf);
var
  i: Integer;
  c: LongInt;
  b: ByteArray absolute buf;
begin
  if Hdr.CopyLineTo = 0 then begin
    for i := 0 to x2-x1 do begin
      if Hdr.Bits = 8 then
        c := b[i]
      else
        c := (LongInt(b[i*3]) shl 16) or (LongInt(b[i*3+1]) shl 8) or
          LongInt(b[i*3+2]);
      PutPixel(x1+i,y,c);
    end;
  end else
    asm
      mov cx,[x1]
      mov dx,[x2]
      mov si,[y]
      mov bx,word ptr [buf]
      mov ax,word ptr [buf+2]
      mov es,ax

      mov ax,[DriverSeg]
      mov word ptr [cdf_l+2],ax
      mov ax,[Hdr.CopyLineTo]
      mov word ptr [cdf_l],ax
      call [cdf_l]
      mov [GraphicsError],ah
    end;
end;

procedure CopyLineFrom(x1,x2,y: Integer; var buf);
var
  i: Integer;
  c: LongInt;
  b: ByteArray absolute buf;
begin
  if Hdr.CopyLineFrom = 0 then begin
    for i := 0 to x2-x1 do begin
      c := GetPixel(x1+i,y);
      if Hdr.Bits = 8 then
        b[i] := c
      else begin
        b[i*3] := (c and $ff0000) shr 16;
        b[i*3+1] := (c and $ff00) shr 8;
        b[i*3+2] := c and $ff;
      end;
    end;
  end else
    asm
      mov cx,[x1]
      mov dx,[x2]
      mov si,[y]
      mov bx,word ptr [buf]
      mov ax,word ptr [buf+2]
      mov es,ax

      mov ax,[DriverSeg]
      mov word ptr [cdf_l+2],ax
      mov ax,[Hdr.CopyLineFrom]
      mov word ptr [cdf_l],ax
      call [cdf_l]
      mov [GraphicsError],ah
    end;
end;


function Sign(a: Integer): Integer;
begin
  if a = 0 then Sign := 0;
  if a > 0 then Sign := 1;
  if a < 0 then Sign := -1;
end;

procedure Line(x,y,x2,y2: Integer);
var
 i, steps, sx, sy, dx, dy, e: integer;
 steep: boolean;
begin
  dx := abs(x2-x);
  sx := Sign(x2-x);
  dy := abs(y2-y);
  sy := Sign(y2-y);
  steep := (dy > dx);
  if steep then begin
    i := x; x := y; y := i;
    i := dx; dx := dy; dy := i;
    i := sx; sx := sy; sy := i;
  end;
  e := 2*dy - dx;
  for i := 1 to dx do begin
    if steep then PutPixel(y,x,CurrColor)
         else PutPixel(x,y,CurrColor);
    while e >= 0 do begin
      y := y + sy;
      e := e - 2*dx;
    end;
    x := x + sx;
    e := e + 2*dy;
  end;
  PutPixel(x2,y2,CurrColor);
end;

procedure Circle(xc,yc,r: Integer);
var
  x,y,d: integer;
begin
  if Hdr.AspectMul <> Hdr.AspectDiv then begin
    asm
      push [xc]
      push [yc]
      push [r]
      mov ax,[r]
      mov bx,[Hdr.AspectMul]
      imul bx
      mov bx,[Hdr.AspectDiv]
      idiv bx
      push ax
      call [Ellipse]
    end;
    {Ellipse(xc,yc,r,r*Hdr.AspectMul div Hdr.AspectDiv);}
    Exit;
  end;
  x := 0;
  y := r;
  d := 2 *(1-r);
  while y > x do begin
    PutPixel(xc+x,yc+y,CurrColor);
    PutPixel(xc-x,yc-y,CurrColor);
    PutPixel(xc+x,yc-y,CurrColor);
    PutPixel(xc-x,yc+y,CurrColor);
    PutPixel(xc+y,yc+x,CurrColor);
    PutPixel(xc-y,yc-x,CurrColor);
    PutPixel(xc-y,yc+x,CurrColor);
    PutPixel(xc+y,yc-x,CurrColor);
    if d + y > 0 then begin
      y := y - 1;
      d := d - 2*y + 1;
    end;
    if x > d then begin
      x := x + 1;
      d := d + 2*x + 1;
    end;
  end;
  PutPixel(xc+x,yc+y,CurrColor);
  PutPixel(xc-x,yc-y,CurrColor);
  PutPixel(xc+x,yc-y,CurrColor);
  PutPixel(xc-x,yc+y,CurrColor);
  PutPixel(xc+y,yc+x,CurrColor);
  PutPixel(xc-y,yc-x,CurrColor);
  PutPixel(xc-y,yc+x,CurrColor);
  PutPixel(xc+y,yc-x,CurrColor);
end;

procedure Ellipse(xc,yc,rx,ry: Integer);

var
  reverse: Boolean;
  t,x,y,d: Integer;

procedure epoint;
var
  round: longint;
  yy,xx, xpos,ypos: Integer;
  xp,yp: ^Integer;
begin
   round := rx shr 1;
   yy := (longint(ry) * y + round) div longint(rx);
   xx := (longint(ry) * x + round) div longint(rx);
   if reverse then begin xp := @ypos; yp := @xpos; end
   else begin xp := @xpos; yp := @ypos; end;

   ypos := yc + yy; xpos := xc + x; PutPixel(xp^,yp^,CurrColor);
   ypos := yc + xx; xpos := xc + y; PutPixel(xp^,yp^,CurrColor);
   ypos := yc - xx; xpos := xc + y; PutPixel(xp^,yp^,CurrColor);
   ypos := yc - yy; xpos := xc + x; PutPixel(xp^,yp^,CurrColor);
   ypos := yc - yy; xpos := xc - x; PutPixel(xp^,yp^,CurrColor);
   ypos := yc - xx; xpos := xc - y; PutPixel(xp^,yp^,CurrColor);
   ypos := yc + xx; xpos := xc - y; PutPixel(xp^,yp^,CurrColor);
   ypos := yc + yy; xpos := xc - x; PutPixel(xp^,yp^,CurrColor);
end;

begin
   if rx = 0 then begin
     Line(xc,yc-ry,xc,yc+ry);
     Exit;
   end;
   reverse := False;
   if rx < ry then begin
      t := xc; xc := yc; yc := t;
      t := rx; rx := ry; ry := t;
      reverse := True;
   end;
   x := 0;
   y := rx;
   d := 3 - rx+rx;
   while (x < y) do begin
      epoint;
      if (d < 0) then d := d + 4*x + 6
      else begin
         d := d + 4*(x - y) + 10;
         Dec(y);
      end;
      Inc(x);
   end;
   if (x = y) then epoint;
end;

procedure Bar(x1,y1,x2,y2: Integer);
var
  y: Integer;
begin
  if y1 > y2 then begin
    y := y1; y1 := y2; y2 := y;
  end;
  for y := y1 to y2 do
    HLine(x1,x2,y);
end;

procedure CopyToScreen(x1,y1,x2,y2: Integer; var buf);
var
  y: Integer;
  b: ByteArray absolute buf;
  w: Word;
begin
  w := (x2-x1+1)*Hdr.Bits;
  for y := 0 to y2-y1 do
    CopyLineTo(x1,x2,y1+y,b[y*w]);
end;

procedure CopyFromScreen(x1,y1,x2,y2: Integer; var buf);
var
  y: Integer;
  b: ByteArray absolute buf;
  w: Word;
begin
  w := (x2-x1+1)*Hdr.Bits;
  for y := 0 to y2-y1 do
    CopyLineFrom(x1,x2,y1+y,b[y*w]);
end;

procedure Text(x,y: Integer; txt: String);
var
  q,w,e,r,t,yy: byte;
begin
  for q := 1 to Length(txt) do begin
    r := Ord(txt[q]);
    for w := 0 to 7 do begin
      e := Mem[$FFA6:r*8+w+14];
      for t := 0 to 7 do begin
        yy := (e Shl t) and $80;
        if yy > 0 then PutPixel(x+((q-1)*8)+t,y+w,CurrColor);
      end;
    end;
  end;
end;

function Rgb(r,g,b: Integer): LongInt;
begin
  Rgb := ((LongInt(r and $ff)) shl 16) or
    ((LongInt(g) and $ff) shl 8) or (LongInt(b) and $ff);
end;

procedure GetRgb(c: LongInt; var r,g,b: Integer);
begin
  r := (c and $ff0000) shr 16;
  g := (c and $ff00) shr 8;
  b := c and $ff;
end;

end.