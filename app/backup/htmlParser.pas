unit htmlParser;
{$mode delphi}

interface
uses SysUtils, Classes, Dialogs, globals;

var
  yyinput: String;
  yypos: Integer;
  Line : Integer;

procedure yymain(AFileName: String);

implementation
uses TypInfo, Generics.Collections, MainForm;

resourcestring
  ERR_SCANNER_UNEXPECTED_CHAR = 'Error 0: Scanner: Unexpected char found in stream';

type
  TSymbol = (
    sUnknown, sIdent, sInteger, sEOL, sEOF,
    sPlus, sMinus, sStar, sSlash, sEqual,
    sSmaller, sBigger, sBiggerEqual, sSmallerEqual, sUnEqual,
    sOpenBracket, sCloseBracket, sComma, sDot, sSemiColon, sBecomes,
    sVar, sConst, sProcedure, sBegin, sEnd, sIf, sThen,
    sElseIf, sElse, sWhile, sDo, sModule, sWrite,
    sUnit, sInterface, sImplementation,
    sNone
  );

const
  cSymbols : Array[TSymbol] of ShortString = (
    '', '', '', '', '', '+', '-', '*', '/', '=',
    '<', '>', '>=', '<=', '#',
    '(', ')', ',', '.', ';', ':=',
    'VAR', 'CONST', 'PROCEDURE', 'BEGIN', 'END', 'IF', 'THEN',
    'ELSEIF', 'ELSE', 'WHILE', 'DO', 'MODULE', 'WRITE',
    'UNIT',
    'INTERFACE',
    'IMPLEMENTATION',
    ''
  );
var
  SymbolMap: TDictionary<TSymbol, string>;

type
  TIdentType = (itConstant, itVariable, itProcedure);
  TIdent = record
             Name : String;
             Kind : TIdentType;
           end;
  TIdentList = Array of TIdent;

var
  Table: TIdentList;
var
  Ch : Integer;
  Str : String;
  Symbol : TSymbol;
  symbolExpected: String;
  symbolName: String;
  yyIdent: String;
  commentOpen: Boolean;

procedure Error(ErrorText : String);
begin
  raise Exception.Create(Format('%d: ' + ErrorText, [Line]));
end;

function MakeOneLiner(const MultiLine: string): string;
var
  i: Integer;
  c: Char;
  InWhitespace: Boolean;
begin
  Result := '';
  InWhitespace := False;

  for i := 1 to Length(MultiLine) do
  begin
    c := MultiLine[i];
    // Prüfen auf Zeilenumbruch oder Leerraum
    if c in [#10, #13, #9, ' '] then
    begin
      if not InWhitespace then
      begin
        Result := Result + ' ';
        InWhitespace := True;
      end;
    end
    else
    begin
      Result := Result + c;
      InWhitespace := False;
    end;
  end;

  // Überflüssiges führendes/trailing Leerzeichen entfernen
  Result := Trim(Result);
end;

procedure GetSym;
  procedure GetCh;
  begin
    if yypos >= Length(yyinput) then
    raise Exception.Create('done.');
    inc(yypos);
    ch := ord(yyinput[yypos]);

    // Windows EOL: #13#10
    if ch = 13 then
    begin
      inc(yypos);
      inc(Line);
      ch := ord(yyinput[yypos]);
      if ch = 10 then
      begin
        if yypos >= Length(yyinput) then
        Symbol := sEOF else
        Symbol := sEOL;
        exit;
      end else
      begin
        raise Exception.Create(
        Format('Error: %d: -Unexpected EOL - end of line found.', [Line]));
      end;
    end else
    if ch = 10 then
    begin
      inc(Line);
      Symbol := sEOL;
      exit;
    end else
    if ch = 0 then
    begin
      Symbol := sEOF;
    end;
  end;
  function getIdent: String;
  var
    id: String;
  begin
    result := '';
    while true do
    begin
      GetCh;
      if ch in [
      ord('A')..ord('Z'),
      ord('a')..ord('z'),
      ord('0')..ord('9'),
      ord('_')] then
      begin
        Symbol := sIdent;
        result := result + chr(ord(ch));
      end else
      begin
        dec(yypos);
        ch := ord(yyinput[yypos]);
        if ch = 10 then inc(yypos);
        if ch = 13 then inc(yypos);
        ShowMessage('>' + yyinput[yypos] + '<');
        break;
      end;
    end;
  end;
var
  I : TSymbol;
  start_comment: Boolean = false;
begin
  start_comment := false;
  while true do
  begin
    Str := '';
    GetCh;
    if (Symbol = sEOF) then
    begin
      Error('EOF reached.');
    end else
    if (Symbol = sEOL) then
    begin
      continue;
    end;
    case ch of
    ord(#9), ord(' '): begin
      continue;
    end;

    ord('/'):
    begin
      GetCh;
      if ch = ord('/') then // C++ comment
      begin
        Symbol := sNone;
        while true do
        begin
          GetCh;
          if (Symbol = sEOL)
          or (Symbol = sEOF) then exit;
        end;
      end else
      if ch = ord('*') then // C comment
      begin
        commentOpen := true;
        while true do
        begin
          inc(yypos);
          if yypos >= Length(yyinput) then
          Error('comment not closed.');
          ch := ord(yyinput[yypos]);
          if ch = ord('/') then
          begin
            commentOpen := false;
            exit;
          end;
        end;
      end;
    end;

    ord('&'):
    begin
      GetCh;
      if Symbol = sEOF then exit;
      if ch = ord('&') then // dbase comment 1
      begin
        while true do
        begin
          GetCh;
          if (Symbol = sEOL)
          or (Symbol = sEOF) then exit;
        end;
        break;
      end;
    end;

    ord('*'):
    begin
      GetCh;
      if Symbol = sEOF then exit;
      if ch = ord('*') then // dbase comment 2
      begin
        ShowMessage('comment DBASE end');
        while true do
        begin
          GetCh;
          if (Symbol = sEOL)
          or (Symbol = sEOF) then exit;
        end;
      end;
    end;

    // Ident/Reserved Word
    ord('A')..ord('Z'),
    ord('a')..ord('z'),ord('_'):
    begin
      str := '';
      str := str + Chr(ord(Ch));
      str := str + getIdent;
      for i := sUnknown to sNone do
      begin
        if UpperCase(Str) = cSymbols[i] then
        begin
          showmessage('yy: ' + str);
          yyident := str;
          Symbol := i;
          exit;
        end;
      end;
      yyIdent := str;
      Symbol := sIdent;
      exit;
    end;

    // Symbole die nur aus 1 Zeichen bestehen können
    ord(';'):
    begin
      Symbol := sSemiColon;
      exit;
    end;
    ord('+'),
    ord('='),ord('#'),
    ord(','),ord('.'):
    begin
      Str := chr(ord(Ch));
      Symbol := sUnknown;
      for i := sUnknown to sNone do
      begin
        if Str = cSymbols[i] then
        begin
          Symbol := i;
          exit;
        end;
      end;
    end; (*Symbole die nur aus 1 Zeichen bestehen können*)

    ord('<'):
    begin
      while True do
      begin
        GetCh;
        if Ch = ord('!') then
        begin
          GetCh;
          if ch = ord('-') then
          begin
            GetCh;
            if ch = ord('-') then
            begin
              start_comment := true;
              while True do
              begin
                GetCh;
                if ch = ord('-') then
                begin
                  GetCh;
                  if ch = ord('-') then
                  begin
                    GetCh;
                    continue;
                  end else
                  if ch = ord('>') then
                  begin
                    break;
                  end else
                  begin
                    continue
                  end;
                end else
                begin
                  continue
                end;
              end;
              if ch = ord('>') then
              begin
                break;
              end else
              begin
                Error(ERR_SCANNER_UNEXPECTED_CHAR);
              end;
            end else
            begin
              Error(ERR_SCANNER_UNEXPECTED_CHAR);
            end;
          end else
          begin
            Error(ERR_SCANNER_UNEXPECTED_CHAR);
          end;
        end else
        begin
          Error(ERR_SCANNER_UNEXPECTED_CHAR);
        end;
      end;
    end;

    ord('('), ord(')'):
    begin (*Klammern oder Kommentar*)
      Str := chr(ord(Ch));
      GetCh;
      if (Str=chr(ord('('))) and (Ch = ord('*')) then
      begin
        //Kommentar entdeckt
        while True do
        begin
          GetCh;
          if (Symbol = sEOF) then
          begin
            raise Exception.Create(
            Format('Error: %d: Pascal comment not terminated.', [Line]));
          end;
          if Ch = ord('*') then
          begin
            GetCh;
            if Ch = ord(')') then
            Break
          end
        end
      end else
      if Str = '(' then
      begin
        Symbol := sOpenBracket;
        Exit
      end else
      begin
        Symbol := sCloseBracket;
        Exit
      end
    end;

    // Zahlen
    ord('0')..ord('9'),ord('$'):
    begin
      Symbol := sInteger;
      Str := chr(ord(Ch));
      GetCh;
      if (Str = chr(ord('$'))) then
      begin
        // HexZahl
        while Ch in [ord('0')..ord('9'),ord('A')..ord('F')] do
        begin
          Str := Str + chr(ord(Ch));
          GetCh;
        end;
        Exit
      end
      else
      begin
        // NormaleZahl
        while Ch in [ord('0')..ord('9')] do
        begin
          Str := Str + chr(ord(Ch));
          GetCh;
        end;
        Exit
      end
    end; // Zahlen

    else
      Error(Format('%s%s%c',[ERR_SCANNER_UNEXPECTED_CHAR, #10,ch]));
    end;
    //Assert(Symbol <> SUnknown);
  end
end (*GetSym*);

procedure Expect(Expected : TSymbol);
begin
  GetSym;
  if Symbol = sEOL then
  begin
    GetSym;
    exit;
  end;
  if Symbol <> Expected then
  begin
    symbolName     := GetEnumName(TypeInfo(TSymbol), Ord(Symbol));
    symbolExpected := GetEnumName(TypeInfo(TSymbol), Ord(Expected));
    Error('Expected: '
    + SymbolMap[Expected] + #10
    + 'Found: '
    + SymbolMap[Symbol]);
  end;
end;

procedure yymain(AFileName: String);
var
  strList: TStringList;
  str: String;
begin
  Ch      := ord(' ');
  Line    := 0;
  Symbol  := sNone;
  yypos   := 0;
  yyinput := '';

  commentOpen := false;

  strList   := TStringList.Create;
  SymbolMap := TDictionary<TSymbol, string>.Create;

  try
    try
      strList.LoadFromFile(AFileName);
      yyinput := (strList.Text);
      showmessage(yyinput);
    except
      ShowMessage('Error: can not opern source file.');
      exit;
    end;

    with SymbolMap do
    begin
      Add(sUnknown, 'Unknown');
      Add(sIdent,   'identifier');
      Add(sInteger, 'keyword INTEGER');
      Add(sEOL, 'EOL - End of Line');
      Add(sEOF, 'EOF - End of File');
      Add(sPlus, 'plus sign (+)');
      Add(sMinus, 'minus sign (-)');
      Add(sStar, 'times sign (*)');
      Add(sSlash, 'division sign (/)');
      Add(sEqual, 'equal sign (=)');
      Add(sSmaller, 'smaller sign (<)');
      Add(sBigger, 'bigger sign (>)');
      Add(sBiggerEqual, '>=');
      Add(sSmallerEqual, '<=');
      Add(sUnEqual, '<>');
      Add(sOpenBracket, 'backet sign: (');
      Add(sCloseBracket, 'bracket sign: )');
      Add(sComma, 'comma sign (,)');
      Add(sDot, 'dot sign (.)');
      Add(sSemiColon, 'semicolon sign (;)');
      Add(sBecomes, 'keyword assign sign (:=)');
      Add(sVar, 'keyword VAR');
      Add(sConst, 'keyword CONST');
      Add(sProcedure, 'keyword PROCEDURE');
      Add(sBegin, 'keyword BEGIN');
      Add(sEnd, 'keyword END');
      Add(sIf, 'keyword IF');
      Add(sThen, 'keyword THEN');
      Add(sElseIf, 'keyword ELSE IF');
      Add(sElse, 'keyword ELSE');
      Add(sWhile, 'keyword WHILE');
      Add(sDo, 'keyword DO');
      Add(sModule, 'keyword MODULE');
      Add(sWrite, 'keyword WRITE');
      Add(sUnit, 'keyword UNIT');
      Add(sInterface, 'keyword INTERFACE');
      Add(sImplementation, 'keyword IMPLEMENTATION');
      Add(sNone, '');
    end;

    try
      while true do
      begin
        Symbol := sNone;
        GetSym;
        if Symbol = sUnit then
        begin
          ShowMessage('eine unut');
          GetSym;
          if Symbol = sIdent then
          begin
            GetSym;
            if Symbol = sSemiColon then
            begin
              showmessage('iddd: ' + yyident);
            end else
            begin
              Error('semicolon expected.');
            end;
          end else
          begin
            Error('ident expected.');
          end;


          if Symbol = sEOL then
          begin
            GetSym;
          end else
          if Symbol = sEOF then Error('EOF Reached');
          if Symbol = sIdent then
          begin
            showmessage(yyident);
            GetSym;
            if Symbol = sEOL then
            begin
              GetSym;
            end else
            if Symbol = sEOF then Error('EOF REached');
          end;

          ShowMessage('unit: ' + str);
        end else
        if Symbol = sIdent then
        begin
          ShowMessage('ident: ' + yyident);
        end else
        begin
          if commentOpen then
          Error('comment not closed.');
        end;
      end;
    except
      on E: Exception do
      begin
        ShowMessage(E.Message);
      end;
    end;
  finally
    strList.Free;
    SymbolMap.Free;
  end;

  Form1.Memo2.Lines.Add('2Done...');
end;

end.

