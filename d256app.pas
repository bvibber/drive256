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
  ShowIt: Integer;
  Save: array[0..15,0..15] of Byte;

procedure ShowM;
var
  x,y: Integer;
begin
  Inc(ShowIt);
  if ShowIt > 1 then Exit;
  asm cli end;
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
  Dec(ShowIt);
  if ShowIt < 0 then Exit;
  asm cli end;
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
  if (ShowIt > 0) and ((AX and 1) = 1) and ((CX <> ox) or (DX <> oy)) then begin
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
  ShowIt := 0;
  mInstTask($ff,Seg(handler),Ofs(handler));
end;

procedure SetUpRgb;
var
  Clrs: array[0..255,0..2] of Byte;
  i: Integer;
begin
  for i := 0 to 255 do begin
    Clrs[i,0] := (i and $e0);
    Clrs[i,1] := (i and $1c) shl 3;
    Clrs[i,2] := (i and 3) shl 6;
    case Clrs[i,2] of
      60..127: Inc(Clrs[i,2],16);
      128..255: Inc(Clrs[i,2],32);
    end;
  end;
  SetPalette(0,256,Clrs);
end;

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

function DoAspect(y: Integer): Integer;
begin
  DoAspect := LongInt(y)*GetAspectMul div GetAspectDiv;
end;

function DeAspect(y: Integer): Integer;
begin
  DeAspect := LongInt(y)*GetAspectDiv div GetAspectMul;
end;


var
  r: ResetRec;
var
  i,j,k,l,m,n,o,p,q,t,u,v,w,x,y,z,ii: Integer;
begin
  InitDriver('d-v13');
  InitGraph;
  SetUpRgb;
  mReset(r);
  SetUpMouse;

  CloseGraph;
  KillDriver;
  mReset(r);
end.