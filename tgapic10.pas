program mmmmmmmmmmmmm;
{$X+}
uses Dos,Crt,Drive256;

function Scale(a, m,d: Integer): Integer;
begin asm
  mov ax,a
  imul m
  idiv d
  mov @Result,ax
end end;

type
  TgaHeader = record { 18 bytes total }
    who_knows: array[1..12] of Byte;
    Width: Word;
    Height: Word;
    BitsPerPixel: Byte;
    who_knows2: Byte;
  end;

{ r,g,b:0-255 }
function Rgb(r,g,b: Integer): Integer;
begin
  if r > 255 then r := 255;
  if g > 255 then g := 255;
  if b > 255 then b := 255;
  Rgb := (b shr 6) or ((g shr 3) and $1c) or (r and $e0);
end;

procedure RgbDot(x,y,r,g,b: Integer);
var
  r1,g1,b1,r2,g2,b2,c1,c2: Integer;
begin
  if Is256Color then begin
    r1 := r and $e0; g1 := g and $e0; b1 := b and $c0;
    r2 := r1 + (r mod 32)+16;
    g2 := g1 + (g mod 32)+16;
    b2 := b1 + (b mod 64)+32;
    c1 := Rgb(r1,g1,b1); c2 := Rgb(r2,g2,b2);
    if (x mod 2) = (y mod 2) then PutPixel(x,y,c1) else PutPixel(x,y,c2);
  end else
    PutPixel(x,y,Drive256.Rgb(r,g,b));
end;

procedure DrawIt(st: String);
type
  TBuffer = array[0..65520] of Byte;
  PBuffer = ^TBuffer;
const
  HeaderLen = 18;
  BufSize = 3840;
var
  Clrs: array[0..255,0..2] of Byte;
  Buf: array[0..BufSize-1] of Byte;
  BufPos: Integer;
  f: File of Byte;
  ff: File absolute f;
  x,y,i,j,k,l,m,n,o,nn,ll: Integer;
  r,g,b,c,r1,g1,b1: Byte;
  w: Word;
  hdr: TgaHeader;
  Buf1,Buf2,Buf3: PBuffer;
begin
  Assign(f,st);
  {$I-}
  Reset(f);
  {$I+}
  if IOResult <> 0 then begin
    if Is24Bit then CurrColor := $ffffff else CurrColor := 15;
    Text(0,0,'Could not load file '+st);
    Exit;
  end;
  BlockRead(ff,Hdr,18);
  case Hdr.BitsPerPixel of
    8: begin
      BlockRead(ff,Buf,768); { Palette }
      for i := 0 to 255 do
        for j := 0 to 2 do
          Clrs[i,2-j] := Buf[i*3+j];
      GetMem(Buf1,Hdr.Width*Hdr.Height);
    end;
    24: begin
      for i := 0 to 255 do begin
        Clrs[i,0] := (i and $e0);
        Clrs[i,1] := (i and $1c) shl 3;
        Clrs[i,2] := (i and 3) shl 6;
        case Clrs[i,2] of
          60..127: Inc(Clrs[i,2],16);
          128..255: Inc(Clrs[i,2],32);
        end;
      end;
      GetMem(Buf1,Hdr.Width*Hdr.Height);
      GetMem(Buf2,Hdr.Width*Hdr.Height);
      GetMem(Buf3,Hdr.Width*Hdr.Height);
    end;
    else Exit;
  end;
  if Is256Color then SetPalette(0,256,Clrs);

  x := 0; y := Hdr.Height-1;
  BlockRead(ff,Buf,BufSize); BufPos := 0;
  while (y >= 0) and (not KeyPressed) do begin
    case Hdr.BitsPerPixel of
      8: begin
        c := Buf[BufPos]; Inc(BufPos);
        Buf1^[y*Hdr.Width+x] := c;
      end;
      24: begin
        b := Buf[BufPos]; g := Buf[BufPos+1]; r := Buf[BufPos+2];
        Inc(BufPos,3);
        Buf1^[y*Hdr.Width+x] := r;
        Buf2^[y*Hdr.Width+x] := g;
        Buf3^[y*Hdr.Width+x] := b;
      end;
    end;
    if BufPos >= BufSize then begin
      {$I-}
      BlockRead(ff,Buf,BufSize,w); BufPos := 0;
      {$I+}
    end;
    Inc(x);
    if x = Hdr.Width then begin
      x := 0;
      Dec(y);
    end;
  end;
  Close(f);
  y := 0;
  j := 0;
  repeat
    k := Scale(y+1,GetHeight,Hdr.Height);
    for x := 0 to Hdr.Width-1 do begin
      i := Scale(x,GetWidth,Hdr.Width);
      m := Scale(x+1,GetWidth,Hdr.Width);
      for n := i to m-1 do
        for l := j to k-1 do
          case Hdr.BitsPerPixel of
            8: begin
              c := Buf1^[y*Hdr.Width+x];
              if Is256Color then
                PutPixel(n,l,c)
              else
                PutPixel(n,l,Drive256.Rgb(Clrs[c,0],Clrs[c,1],Clrs[c,2]));
            end;
            24: begin
              if x = (Hdr.Width-1) then nn := i else nn := n;
              if y = (Hdr.Height-1) then ll := j else ll := l;
              r := Buf1^[y*Hdr.Width+x];
              g := Buf2^[y*Hdr.Width+x];
              b := Buf3^[y*Hdr.Width+x];
              if (nn = i) and (ll <> j) then begin
                r1 := Buf1^[(y+1)*Hdr.Width+x];
                g1 := Buf2^[(y+1)*Hdr.Width+x];
                b1 := Buf3^[(y+1)*Hdr.Width+x];
              end;
              if (nn <> i) and (ll = j) then begin
                r1 := Buf1^[y*Hdr.Width+x+1];
                g1 := Buf2^[y*Hdr.Width+x+1];
                b1 := Buf3^[y*Hdr.Width+x+1];
              end;
              if (nn <> i) and (ll <> j) then begin
                r1 := Buf1^[(y+1)*Hdr.Width+x+1];
                g1 := Buf2^[(y+1)*Hdr.Width+x+1];
                b1 := Buf3^[(y+1)*Hdr.Width+x+1];
              end;
              if (ll = j) and (nn = i) then
                RgbDot(n,l,r,g,b)
              else
                RgbDot(n,l,(r+r1) div 2,(g+g1) div 2,(b+b1) div 2);
            end;
          end;
    end;
    Inc(y);
    j := k;
  until KeyPressed or (y = Hdr.Height);
  case Hdr.BitsPerPixel of
    8: begin
      FreeMem(Buf1,Hdr.Width*Hdr.Height);
    end;
    24: begin
      FreeMem(Buf1,Hdr.Width*Hdr.Height);
      FreeMem(Buf2,Hdr.Width*Hdr.Height);
      FreeMem(Buf3,Hdr.Width*Hdr.Height);
    end;
  end;
end;


var
  i,j,k,l: Integer;
  s,s1: String;
begin
  Write('Driver: ');
  Readln(s1);
  Write('File: ');
  Readln(s);
  if Pos('.',s) = 0 then s := s + '.tga';
  InitDriver(s1);
  if GraphError then begin
    Writeln('Could not load driver ',s1);
    Exit;
  end;
  InitGraph;
  Drawit(s);
  ReadKey;
  CloseGraph;
  KillDriver;
end.