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
uses TypInfo, MainForm;

resourcestring
  ERR_SCANNER_UNEXPECTED_CHAR = 'Error 0: Scanner: Unexpected char found in stream';

type
  TSymbol = (
    sUnknown, sIdent, sInteger, sPlus, sMinus, sStar, sSlash, sEqual,
    sSmaller, sBigger, sBiggerEqual, sSmallerEqual, sUnEqual,
    sOpenBracket, sCloseBracket, sComma, sDot, sSemiColon, sBecomes,
    sVar, sConst, sProcedure, sBegin, sEnd, sIf, sThen,
    sElseIf, sElse, sWhile, sDo, sModule, sWrite, sUnit, sNone
  );

const
  cSymbols : Array[TSymbol] of ShortString = (
    '', '', '', '+', '-', '*', '/', '=',
    '<', '>', '>=', '<=', '#',
    '(', ')', ',', '.', ';', ':=',
    'VAR', 'CONST', 'PROCEDURE', 'BEGIN', 'END', 'IF', 'THEN',
    'ELSEIF', 'ELSE', 'WHILE', 'DO', 'MODULE', 'WRITE',
    'UNIT', ''
  );

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

const
  TOK_EOF = 300;
  TOK_EOL = 301;

procedure Error(ErrorText : String);
begin
  raise Exception.Create(Format('%d: ' + ErrorText, [Line]));
end;

procedure Expect(Expected : TSymbol);
begin
  if Symbol <> Expected then
  begin
    symbolName     := GetEnumName(TypeInfo(TSymbol), Ord(Symbol));
    symbolExpected := GetEnumName(TypeInfo(TSymbol), Ord(Expected));
    raise Exception.Create('Expected: '
    + symbolExpected + #10
    + 'Found: '
    + symbolName);
  end;
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
        begin
          ch := TOK_EOF;
          exit;
        end else
        begin
          ch := TOK_EOL;
          exit;
        end;
      end else
      begin
        raise Exception.Create(
        Format('Error: %d: -Unexpected EOL - end of line found.', [Line]));
      end;
    end else
    if ch = 10 then
    begin
      inc(Line);
      ch := TOK_EOL;
      exit;
    end else
    if ch in [ord(#9), ord(' ')] then
    begin
      GetCh;
    end else
    if ch = 0 then
    begin
      ch := TOK_EOF;
    end;
  end;
  function getIdent: String;
  var
    id: String;
  begin
    id := '';
    while true do
    begin
      GetCh;
      if ch in [
      ord('A')..ord('Z'),
      ord('a')..ord('z'),
      ord('0')..ord('9'),
      ord('_')] then
      begin
        id := id + chr(ord(ch));
      end else
      begin
        dec(yypos);
        Symbol := sIdent;
        result := id;
        exit;
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
    case ch of
    TOK_EOF: begin
      break;
    end;
    TOK_EOL: begin
      break;
    end;
    ord('/'):
    begin
      GetCh;
      if ch = ord('/') then // C++ comment
      begin
        while true do
        begin
          GetCh;
          if (ch = TOK_EOL)
          or (ch = TOK_EOF) then break;
        end;
      end else
      if ch = ord('*') then // C comment
      begin
        while true do
        begin
          GetCh;
          if ch = ord('*') then
          begin
            GetCh;
            if ch = ord('/') then
            begin
              break
            end else
            if ch = TOK_EOF then
            begin
              raise Exception.Create(
              Format('Error: %d: C comment not terminated.', [Line]));
            end;
          end else
          if ch = TOK_EOF then
          begin
            raise Exception.Create(
            Format('Error: %d: C comment not terminated.', [Line]));
          end;
        end;
      end;
    end;
    ord('&'):
    begin
      GetCh;
      if ch = ord('&') then // dbase comment 1
      begin
        while true do
        begin
          GetCh;
          if (ch = TOK_EOL)
          or (ch = TOK_EOF) then break;
        end;
        break;
      end;
    end;
    ord('*'):
    begin
      GetCh;
      if ch = ord('*') then // dbase comment 2
      begin
        ShowMessage('comment DBASE end');
        while true do
        begin
          GetCh;
          if (ch = TOK_EOL)
          or (ch = TOK_EOF) then break;
        end;
      end;
    end;
    ord('A')..ord('Z'),
    ord('a')..ord('z'),ord('_'):
    begin (*Ident/Reserved Word*)
      str := str + Chr(ord(Ch));
      str := str + getIdent;

      for i := sUnknown to sNone do
      begin
        if UpperCase(Str) = cSymbols[i] then
        begin
          if i = sUNIT then
          showmessage('a unit');
          Symbol := i;
          Break
        end;
      end;
      Exit
    end; (*Ident/Reserved Word*)

    ord(';'),ord('+'),ord('='),ord('#'),ord(','),ord('.'):
    begin (*Symbole die nur aus 1 Zeichen bestehen können*)
      Str := chr(ord(Ch));
      Symbol := sUnknown;
      for i := sUnknown to sNone do
        if Str = cSymbols[i] then
        begin
          Symbol := i;
          Break
        end;
      GetCh;
      Exit
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
          if (ch = TOK_EOF) then
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

    ord('0')..ord('9'),ord('$'): (*Zahlen*)
    begin
      Symbol := sInteger;
      Str := chr(ord(Ch));
      GetCh;
      if (Str = chr(ord('$'))) then
      begin
        //HexZahl
        while Ch in [ord('0')..ord('9'),ord('A')..ord('F')] do
        begin
          Str := Str + chr(ord(Ch));
          GetCh;
        end;
        Exit
      end
      else
      begin
        //NormaleZahl
        while Ch in [ord('0')..ord('9')] do
        begin
          Str := Str + chr(ord(Ch));
          GetCh;
        end;
        Exit
      end
    end; (*Zahlen*)

    else
      Error(Format('%s%s%c',[ERR_SCANNER_UNEXPECTED_CHAR, #10,ch]));
    end;
    //Assert(Symbol <> SUnknown);
  end
end (*GetSym*);

procedure yymain(AFileName: String);
var
  strList: TStringList;
begin
  Ch      := ord(' ');
  Line    := 1;
  yypos   := 0;
  yyinput := '';

  strList := TStringList.Create;
  try
    strList.LoadFromFile(AFileName);
    yyinput := strList.Text;
    showmessage('--->' + yyinput);
  finally
    strList.Free;
    strList := nil;
  end;

  while true do
  begin
    GetSym;
    if ch = TOK_EOF then
    break;
  end;
  Form1.Memo2.Lines.Add('2Done...');
end;

end.

