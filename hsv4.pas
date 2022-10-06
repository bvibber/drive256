program mmmmmmmmmmmmm;
{$X+}
uses Dos,Crt,Drive256,Mouse,StdStuff;

type
  tEvent = record
    f,x,y,b: Integer;
  end;

const
  HotX = 0;
  HotY = 0;
  CurMask: array[0..15,0..15] of Byte =
    (($00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00),
     ($00,$ff,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00),
     ($00,$ff,$ff,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00),
     ($00,$ff,$db,$ff, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00),

     ($00,$ff,$db,$db, $ff,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00),
     ($00,$ff,$db,$b6, $db,$ff,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00),
     ($00,$ff,$db,$b6, $b6,$db,$ff,$00, $00,$00,$00,$00, $00,$00,$00,$00),
     ($00,$ff,$db,$b6, $92,$92,$92,$ff, $00,$00,$00,$00, $00,$00,$00,$00),

     ($00,$ff,$db,$92, $6d,$6d,$6d,$6d, $6d,$00,$00,$00, $00,$00,$00,$00),
     ($00,$ff,$92,$6d, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00),
     ($00,$ff,$6d,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00),
     ($00,$6d,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00),

     ($00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00),
     ($00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00),
     ($00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00),
     ($00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00));

  ClearMask: array[0..15] of Word =
    ($3fff,
     $1fff,
     $0fff,
     $07ff,

     $03ff,
     $01ff,
     $00ff,
     $007f,

     $003f,
     $003f,
     $0fff,
     $1fff,

     $3fff,
     $ffff,
     $ffff,
     $ffff);

var
  ox,oy: Integer;
  ee,e: tEvent;
  ShowIt: Boolean;
  Save: array[0..15,0..15] of Byte;

procedure ShowM;
var
  x,y: Integer;
begin
  if ShowIt then Exit;
  asm cli end;
  ShowIt := True;
  ox := e.x; oy := e.y;
  for y := 0 to 15 do
    for x := 0 to 15 do
      Save[x,y] := GetPixel(ox+x-HotX,oy+y-HotY);
  for y := 0 to 15 do
    for x := 0 to 15 do begin
      if (ClearMask[y] shl x and $8000) = 0 then
        PutPixel(ox+x-HotX,oy+y-HotY,0);
      PutPixel(ox+x-HotX,oy+y-HotY,CurMask[y,x] xor
        GetPixel(ox+x-HotX,oy+y-HotY));
    end;
  asm sti end;
end;

procedure HideM;
var x,y: Integer;
begin
  if not ShowIt then Exit;
  asm cli end;
  ShowIt := False;
  for y := 0 to 15 do
    for x := 0 to 15 do
      PutPixel(ox+x-HotX,oy+y-HotY,Save[x,y]);
  ox := e.x; oy := e.y;
  asm sti end;
end;

{$F+}
procedure handler   { mouse event handler called by device driver }
          (flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP : Integer);
Interrupt;
var x,y: Integer;
begin
  e.f := AX;
  e.b := BX;
  e.x := CX;
  e.y := DX;
  if ShowIt and ((AX and 1) = 1) and ((CX <> ox) or (DX <> oy)) then begin
    for y := 0 to 15 do
      for x := 0 to 15 do
        PutPixel(ox+x-HotX,oy+y-HotY,Save[x,y]);
    ox := e.x; oy := e.y;
    for y := 0 to 15 do
      for x := 0 to 15 do
        Save[x,y] := GetPixel(ox+x-HotX,oy+y-HotY);
    for y := 0 to 15 do
      for x := 0 to 15 do begin
        if (ClearMask[y] shl x and $8000) = 0 then
          PutPixel(ox+x-HotX,oy+y-HotY,0);
        PutPixel(ox+x-HotX,oy+y-HotY,CurMask[y,x] xor
          GetPixel(ox+x-HotX,oy+y-HotY));
      end;
  end;
  inline (     { exit processing for far return to device driver }
          $8B/$E5/    { MOV SP,BP }
          $5D/        { POP BP    }
          $07/        { POP ES    }
          $1F/        { POP DS    }
          $5F/        { POP DI    }
          $5E/        { POP SI    }
          $5A/        { POP DX    }
          $59/        { POP CX    }
          $5B/        { POP BX    }
          $58/        { POP AX    }
          $CB);       { RETF      }
end;
{$F-}

procedure SetUpMouse;
begin
  mColRange(0,GetMaxX);
  mRowRange(0,GetMaxY);
  mMoveTo(GetWidth div 2,GetHeight div 2);
  e.f := 0;
  e.x := GetWidth div 2;
  e.y := GetHeight div 2;
  ox := e.x;
  oy := e.y;
  ShowIt := False;
  mInstTask($ff,Seg(handler),Ofs(handler));
end;

var
  BackCol: Integer;

procedure Text(x,y: Integer; txt: String; c: Integer);
var
  q,w,e,r,t,yy: byte;
begin
  for q := 1 to Length(txt) do
   begin
    r := Ord(txt[q]);
    for w := 0 to 7 do
     begin
      e := Mem[$FFA6:r*8+w+14];
      for t := 0 to 7 do
       begin
        yy := (e Shl(t)) and $80;
        if yy>0
          then PutPixel(x+((q-1)*8)+t,y+w,c)
          else PutPixel(x+((q-1)*8)+t,y+w,BackCol);
      end; { for t }
    end { for w }
  end; { for q }
end; { Text }

{ r,g,b:0-255 }
function Rgb(r,g,b: Integer): Integer;
begin
  if r > 255 then r := 255;
  if g > 255 then g := 255;
  if b > 255 then b := 255;
  Rgb := (b shr 6) or ((g shr 3) and $1c) or (r and $e0);
end;

procedure DoHsv(h,s,v: Integer; var r,g,b: Integer);
var
  rr,gg,bb,f,p1,p2,p3: Integer;
begin
  while h > 359 do Dec(h,360);
  while h < 0 do Inc(h,360);
  if s < 0 then s := 0;
  if s > 100 then s := 100;
  if v < 0 then v := 0;
  if v > 100 then v := 100;

  f := (h mod 60) * 5 div 3;
  h := h div 60;
  p1 := v*(100-s) div 625 * 16;
  p2 := v*(100-(s*f div 100)) div 625 * 16;
  p3 := v*(100-(s*(100-f) div 100)) div 625 * 16;
  v := v * 64 div 25;
  case h of
    0: begin r := v; g := p3; b := p1; end;
    1: begin r := p2; g := v; b := p1; end;
    2: begin r := p1; g := v; b := p3; end;
    3: begin r := p1; g := p2; b := v; end;
    4: begin r := p3; g := p1; b := v; end;
    5: begin r := v; g := p1; b := p2; end;
  end;
end;

{ h:0-359; s,v:0-100 }
function Hsv(h,s,v: Integer): Integer;
var
  r,g,b: Integer;
begin
  DoHsv(h,s,v,r,g,b);
  Hsv := Rgb(r,g,b);
end;

function CircleY(x: Integer): Integer;
begin
  CircleY := Round(Sqrt(2500*(1-((x*x)/2500))));
end;

procedure xy_2_ad(x,y: Integer; var a,d: Integer);
var s: Real;
begin
  d := Round(Sqrt(x*x + y*y)) shl 1;
  if y = 0 then
    if x > 0 then
      s := pi/2 else s := pi*1.5
    else s := ArcTan(x/y);
  a := Round(s*180/pi);
  if y < 0 then a := a+180;
  while a < 0 do Inc(a,360);
  while a > 360 do Dec(a,360);
end;

procedure ad_2_xy(a,d: Integer; var x,y: Integer);
begin
  while a < 0 do Inc(a,360);
  while a > 360 do Dec(a,360);
  x := Round((d div 2)*sin(a*pi/180));
  y := Round((d div 2)*cos(a*pi/180));
end;

var
  Clrs,Colors: array[0..255,0..2] of Byte;
  st: Boolean;
  s,c: Real;
  r: ResetRec;

  Hue, Satur, Value, oh, os, ov: Integer;

procedure DoStuff;
var
  i,j,k,r,g,b: Integer;
  si,cs: Real;
begin
  PutPixel(oh div 2,os,Hsv(oh,os,100));
  PutPixel(Hue div 2, Satur,0);

  si := Sin(oh*pi/180); cs := Cos(oh*pi/180);
  PutPixel(240+Round(si*os) div 2,50+Round(cs*os) div 2,Hsv(oh,os,100));
  si := Sin(Hue*pi/180); cs := Cos(Hue*pi/180);
  PutPixel(240+Round(si*Satur) div 2,50+Round(cs*Satur) div 2,0);

  PutPixel(299,ov,BackCol);
  PutPixel(310,ov,BackCol);
  PutPixel(299,Value,0);
  PutPixel(310,Value,0);

  for i := 0 to 100 do begin
    j := Hsv(Hue,Satur,i);
    for k := 0 to 9 do
      PutPixel(300+k,i,j);
  end;

  DoHsv(Hue,Satur,Value,r,g,b);
  Text(250,120,'Hue: '+StrI(Hue)+'  ',Hsv(Hue,100,100));
  i := Hsv(Hue,Satur,100); if i = BackCol then BackCol := Rgb(128,128,128);
  Text(194,130,'Saturation: '+StrI(Satur)+'   ',i);
  i := Hsv(Hue,Satur,Value); BackCol := Rgb(192,192,192);
  if i = BackCol then BackCol := Rgb(128,128,128);
  Text(234,140,'Value: '+StrI(Value)+'   ',i);
  BackCol := Rgb(192,192,192);
  Text(250,150,'Red: '+StrI(r)+'  ',Rgb(128+(r div 2),0,0));
  Text(234,160,'Green: '+StrI(g)+'  ',Rgb(0,128+(g div 2),0));
  Text(242,170,'Blue: '+StrI(b)+'  ',Rgb(0,0,128+(b div 2)));

  CurrColor := Hsv(Hue,Satur,Value);
  Bar(10,110,110,210);
  if CurrColor = BackCol then begin
    CurrColor := Rgb(128,128,128);
    Line(10,110, 10,210);
    Line(10,110, 110,110);
    Line(10,210,110,210);
    Line(110,110, 110,210);
  end;
end;

const
  halfpi = pi / 2;
  oneonehalfpi = pi*1.5;
  degrad = 180/pi;
  a1 = Round(halfpi*degrad);
  a2 = Round(oneonehalfpi*degrad);

var
  i,j,k,l,m,n,o,p,q,t,u,v,w,x,y,z,ii: Integer;
begin
  InitDriver('d-v13');
  InitGraph;
  for i := 0 to 255 do begin
    Clrs[i,0] := (i and $e0);
    Clrs[i,1] := (i and $1c) shl 3;
    Clrs[i,2] := (i and 3) shl 6;
  end;
  SetPalette(0,256,Clrs);
  BackCol := Rgb(192,192,192);
  CurrColor := BackCol;
  Bar(0,0,GetMaxX,GetMaxY);

  for i := 0 to 179 do
    for j := 0 to 100 do
      PutPixel(i,j,Hsv(i shl 1,j,100));
  l := Trunc(50*GetAspect);
  for i := -50 to 50 do begin
    ii := i*i;
    j := Trunc(GetAspect*Sqrt(2500 - ii));
    for k := -j to j do begin
      m := k*GetAspectDiv div GetAspectMul;
      x := Round(Sqrt(m*m + ii)) shl 1;
      if m = 0
        then if i > 0 then y := a1 else y := a2
        else y := Round(ArcTan(i/m)*degrad);
      if m < 0 then y := y+180;
      PutPixel(240+i,l+k,Hsv(y,x,100));
    end;
  end;
  mReset(r);
  SetUpMouse;
  Hue := 0;
  Satur := 0;
  Value := 100;
  oh := 0;
  os := 0;
  ov := 100;
  DoStuff;
  ShowM;
  repeat
    if (e.f and $2 <> 0) then begin
      ee := e;
      if (ee.x < 180) and (ee.y < 101) then begin
        Hue := ee.x shl 1;
        Satur := ee.y;
        HideM;
        DoStuff;
        ShowM;
        oh := Hue;
        os := Satur;
      end;
      if (ee.x > 189) and (ee.x < 291) and
        (Abs(ee.y-50) <= CircleY(ee.x-240)) then begin
        xy_2_ad(ee.x-240,ee.y-50, Hue,Satur);
        HideM;
        DoStuff;
        ShowM;
        oh := Hue;
        os := Satur;
      end;
      if (ee.x > 299) and (ee.x < 310) and (ee.y < 101) then begin
        Value := ee.y;
        HideM;
        DoStuff;
        ShowM;
        ov := Value;
      end;
      e.f := 0;
    end;
  until KeyPressed or (e.f and $10 <> 0);
  HideM;
  while KeyPressed do ReadKey;
  CloseGraph;
  KillDriver;
  mReset(r);
end.