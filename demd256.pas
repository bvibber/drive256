program DemoD256;
{$X+}
uses Crt,Drive256;
var
  i,j,MaxX,MaxY: Integer;
  MaxColor,l,m: LongInt;
  s: String;
(*{$F+} procedure AssemblerStuff; external; {$F-}
{$L demd1.obj}*)

{$F+}
function MulLong386(a,b: LongInt): LongInt; external;
function DivLong386(a,b: LongInt): LongInt; external;
function AddLong386(a,b: LongInt): LongInt; external;
function SubLong386(a,b: LongInt): LongInt; external;
function ScaleLong386(a, m,d: LongInt): LongInt; external;
{$L math386.obj}
{$F-}

begin
  Write('Driver: ');
  Readln(s);
  InitDriver(s);
  if GraphError {or Is24bit} then Exit;
  InitGraph;
  if Is24Bit then MaxColor := $ffffff else MaxColor := $ff;
  MaxX := GetMaxX; MaxY := GetMaxY;
  {AssemblerStuff;}
  l := LongInt(GetMaxX)*LongInt(GetMaxY);
  for i := 0 to GetMaxX do
    for j := 0 to GetMaxY do begin
      asm
        mov ax,[i]
        mov bx,[j]
        imul bx
        mov word ptr [m],ax
        mov word ptr [m+2],dx
      end;
      {PutPixel(i,j,m * MaxColor div l);}
      PutPixel(i,j,ScaleLong386(m,MaxColor,l));
    end;
  ReadKey;
  CloseGraph;
  KillDriver;
end.