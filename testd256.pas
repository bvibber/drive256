program testDrive256;
{$X+}
uses Crt,Drive256,StdStuff;

var
  dn: String;
  Color: LongInt;
  i: Integer;

procedure DrawBorder(s: String);
var i: Integer;
begin
  CurrColor := Color;
  Line(0,0,GetMaxX,0);
  Line(0,0,0,GetMaxY);
  Line(GetMaxX,0,GetMaxX,GetMaxY);
  Line(0,GetMaxY,GetMaxX,GetMaxY);
  Line(0,GetMaxY-11,GetMaxX,GetMaxY-11);
  Line(0,11,GetMaxX,11);
  CurrColor := 0;
  Bar(1,1,GetMaxX-1,10);
  CurrColor := Color;
  Text((GetMaxX div 2)-(Length(s)*4),2,s);
end;

procedure Status(s: String);
begin
  CurrColor := 0;
  Bar(1,GetMaxY-10,GetMaxX-1,GetMaxY-1);
  CurrColor := Color;
  Text((GetMaxX div 2)-(Length(s)*4),GetMaxY-9,s);
end;

function RandCol: LongInt;
begin
  if Is256Color then
    RandCol := Random(256)
  else
    RandCol := Rgb(Random(256),Random(256),Random(256));
end;

procedure DoDemo;
const
  Msg = 'Press any key or Esc to quit';
type
  ba = array[0..65520] of Byte;
  pba = ^ba;
var
  i,j,k,l,m,n,o,p,x,y,z,w: Integer;
  s: String;
  buf: pba;
label SkipTo;
begin
  goto SkipTo;
SkipTo:
  DrawBorder('Drive256 Demo');
  Text(10,20,'Driver: '+dn);
  s := GetDescription;
  if s = '' then
    Text(10,30,'No description.')
  else
    Text(10,30,s);
  if Is256Color then
    Text(10,40,'256 colors')
  else
    Text(10,40,'24 bit');
  Text(10,50,'Width: '+StrI(GetWidth));
  Text(10,60,'Height: '+StrI(GetHeight));
  Text(10,70,'GetMaxX: '+StrI(GetMaxX));
  Text(10,80,'GetMaxY: '+StrI(GetMaxY));
  Text(10,90,'AspectMul: '+StrI(GetAspectMul));
  Text(10,100,'AspectDiv: '+StrI(GetAspectDiv));
  Str(GetAspect:0:4,s);
  Text(10,110,'Aspect ratio: '+s);
  Status(Msg);
  if ReadKey = #27 then Exit;

  ClearScreen;
  DrawBorder('PutPixel Demo');
  Status(Msg);
  repeat
    PutPixel(Random(GetWidth-2)+1,Random(GetHeight-24)+12,RandCol);
  until KeyPressed;
  if ReadKey = #27 then Exit;

  DrawBorder('GetPixel Demo');
  y := 12;
  while (y <= (GetMaxY-12)) and (not KeyPressed) do begin
    for x := 1 to ((GetMaxX-2) div 2) do
      PutPixel(x,y, GetPixel(GetMaxX-1-x,y));
    Inc(y);
  end;
  if ReadKey = #27 then Exit;

  ClearScreen;
  DrawBorder('Horizontal Line Demo');
  Status(Msg);
  repeat
    CurrColor := RandCol;
    HLine(Random(GetWidth-2)+1,Random(GetWidth-2)+1,Random(GetHeight-24)+12);
  until KeyPressed;
  if ReadKey = #27 then Exit;

  ClearScreen;
  DrawBorder('Bar Demo');
  Status(Msg);
  repeat
    CurrColor := RandCol;
    Bar(Random(GetWidth-2)+1,Random(GetHeight-24)+12,
      Random(GetWidth-2)+1,Random(GetHeight-24)+12);
  until KeyPressed;
  if ReadKey = #27 then Exit;

  ClearScreen;
  DrawBorder('Line Demo');
  Status(Msg);
  repeat
    CurrColor := RandCol;
    Line(Random(GetWidth-2)+1,Random(GetHeight-24)+12,
      Random(GetWidth-2)+1,Random(GetHeight-24)+12);
  until KeyPressed;
  if ReadKey = #27 then Exit;

  ClearScreen;
  DrawBorder('Circle Demo');
  Status(Msg);
  k := GetAspectMul; l := GetAspectDiv;
  repeat
    CurrColor := RandCol;
    i := Random(100);
    asm
      mov ax,[i]
      mov bx,[k]
      imul bx
      mov bx,[l]
      idiv bx
      mov [j],ax
    end;
    Circle(Random(GetWidth-2-i-i)+i+1,
      Random(GetHeight-24-j-j)+12+j,i);
  until KeyPressed;
  if ReadKey = #27 then Exit;

  ClearScreen;
  DrawBorder('Ellipse Demo');
  Status(Msg);
  repeat
    CurrColor := RandCol;
    i := Random(100);
    j := Random(100);
    Ellipse(Random(GetWidth-2-i-i)+i+1,
      Random(GetHeight-24-j-j)+12+j,i,j);
  until KeyPressed;
  if ReadKey = #27 then Exit;

  ClearScreen;
  DrawBorder('Text Demo');
  x := 10; y := 20; s[0] := #1;
  for i := 0 to 127 do begin
    s[1] := Chr(i);
    Text(x,y,s);
    Inc(x,10);
    if (x+10) >= GetMaxX then begin
      x := 10;
      Inc(y,10);
    end;
  end;
  Status(Msg);
  if ReadKey = #27 then Exit;

  ClearScreen;
  DrawBorder('CopyFromScreen/CopyToScreen Demo');
  if Is256Color then begin
    for i := 0 to 15 do
      for j := 0 to 15 do
        PutPixel(i+1,j+12,j*16+i);
    GetMem(buf,256);
  end else begin
    for i := 0 to 15 do
      for j := 0 to 15 do
        PutPixel(i+1,j+12,Rgb(i*16,j*16,0));
    GetMem(buf,768);
  end;
  CopyFromScreen(1,12,16,27,buf^);
  Status(Msg);
  repeat
    x := Random(GetWidth-18)+1;
    y := Random(GetHeight-40)+12;
    CopyToScreen(x,y,x+15,y+15,buf^);
  until KeyPressed;
  if Is256Color then
    FreeMem(buf,256)
  else
    FreeMem(buf,768);
  if ReadKey = #27 then Exit;

  if Is256Color then begin
    ClearScreen;
    DrawBorder('SetPalette Demo');
    x := (GetWidth-2) div 16;
    y := (GetHeight-24) div 16;
    for i := 0 to 15 do
      for j := 0 to 15 do begin
        CurrColor := j*16+i;
        Bar(i*x+1,j*y+12,i*x+x,j*y+y+11);
      end;
    GetMem(buf,768);
    for i := 0 to 767 do
      buf^[i] := i div 3;
    Status(Msg);
    repeat
      SetPalette(0,256,buf^);
      j := buf^[0]; k := buf^[1]; l := buf^[2];
      for i := 3 to 767 do
        buf^[i-3] := buf^[i];
      buf^[765] := j; buf^[766] := k; buf^[767] := l;
    until KeyPressed;
    FreeMem(buf,768);
    if ReadKey = #27 then Exit;
  end else begin
    ClearScreen;
    DrawBorder('RGB Color Demo');
    x := (GetWidth-2) div 2;
    y := (GetHeight-24) div 2;
    Status(Msg);
    i := 0;
    while (i < x) and (not KeyPressed) do begin
      for j := 0 to y-1 do begin
        l := LongInt(i)*256 div x;
        m := LongInt(j)*256 div x;
        if i > j then k := l else k := m;
        PutPixel(1+i,12+j,Rgb(k,0,0));
        PutPixel(1+x+i,12+j,Rgb(0,k,0));
        PutPixel(1+i,12+y+j,Rgb(0,0,k));
        PutPixel(1+x+i,12+y+j,Rgb(k,k,k));
      end;
      Inc(i);
    end;
    if ReadKey = #27 then Exit;
  end;
end;

begin
  Write('Driver: ');
  Readln(dn);
  InitDriver(dn);
  if GraphError then begin
    Writeln('Error');
    Exit;
  end;

  if Is256Color then
    Color := 15
  else
    Color := $ffffff;

  InitGraph;

  Randomize;
  DoDemo;

  CloseGraph;
  KillDriver;
end.