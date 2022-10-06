program DumpD256;
{ Dump a Drive256 driver }
uses Crt,Dos,StdStuff;

type
  tbuf = array[0..65520] of Byte;
  D256Hdr = record
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

var
  f: File of Byte;
  ff: File absolute f;
  buf: ^tbuf;
  hdr: ^D256Hdr absolute buf;
  desc: ^String;
  bufsiz: Word;
  i,j: Integer;
  s: String;
begin
  Write('Driver: ');
  Readln(s);
  if Pos('.',s) = 0 then s := s + '.bgd';
  Assign(f,s);
  {$I-}
  Reset(f);
  {$I+}
  if IOResult <> 0 then begin
    Writeln('Could not open ',s);
    Exit;
  end;
  bufsiz := FileSize(f);
  GetMem(buf,bufsiz);
  BlockRead(ff,buf^,bufsiz);
  Close(f);
  ClrScr;
  Writeln('Driver: ',s);
  Writeln;
  desc := Ptr(Seg(buf^),Ofs(buf^)+hdr^.Description);
  with Hdr^ do begin
    Write('Ident: ''');
    for i := 1 to 4 do
      Write(Ident[i]);
    Writeln('''');
    Writeln(bits,' bits');
    Writeln('Width: ',ScrWidth);
    Writeln('Height: ',ScrHeight);
    Str((AspectMul/AspectDiv):0:4,s);
    Writeln('Apect ratio: ',s);
    Writeln('Offset of EnterGraphics: ',EnterGraphics);
    Writeln('Offset of LeaveGraphics: ',LeaveGraphics);
    Writeln('Offset of ClearScreen: ',ClearScreen);
    Writeln('Offset of PutPixel: ',PutPixel);
    Writeln('Offset of GetPixel: ',GetPixel);
    Writeln('Offset of SetPalette: ',SetPalette);
    Writeln('Offset of HorizLine: ',HorizLine);
    Writeln('Offset of CopyLineTo: ',CopyLineTo);
    Writeln('Offset of CopyLineFrom: ',CopyLineFrom);
    Writeln('Offset of Description: ',Description);
    if Description <> 0 then
      Writeln('Description: ',desc^);
  end;
  FreeMem(buf,bufsiz);
end.