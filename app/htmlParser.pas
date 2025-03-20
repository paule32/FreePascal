unit htmlParser;
{$mode delphi}

interface
uses SysUtils, Classes, Dialogs, globals;

var
  yyinput: File;
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
    sElseIf, sElse, sWhile, sDo, sModule, sWrite, sNone
  );

const
  cSymbols : Array[TSymbol] of ShortString = (
    '', '', '', '+', '-', '*', '/', '=',
    '<', '>', '>=', '<=', '#',
    '(', ')', ',', '.', ';', ':=',
    'VAR', 'CONST', 'PROCEDURE', 'BEGIN', 'END', 'IF', 'THEN',
    'ELSEIF', 'ELSE', 'WHILE', 'DO', 'MODULE', 'WRITE', ''
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
  Ch : Char;
  Str : String;
  Symbol : TSymbol;
  symbolExpected: String;
  symbolName: String;

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
    if not EoF(yyinput) then
    BlockRead(yyinput, ch, 1) else
    raise Exception.Create('done.');

    ch := UpCase(ch);

    if ch = #10 then begin inc(line); ch := ' '; end else
    if ch = #13 then begin inc(line);            end;

    //if Ord(ch) < Ord(' ') then ch := ' ';
  end;
var
  I : TSymbol;
  start_comment: Boolean = false;
begin
  start_comment := false;

  while true do
  begin
    Str := '';
    Symbol := sNone;

//    while (Ch = ' ') and not EoF(yyinput) do
//    GetCh;
    if EoF(yyinput) then
    Exit;

    case ch of
    #9,' ': begin
      GetCh;
    end;
    '/':
    begin
      GetCh;
      if ch = '/' then // C++ comment
      begin
        while true do
        begin
          GetCh;
          if ch = #13 then break;
        end;
        ShowMessage('comment C++ end');
      end;
    end;
    '&':
    begin
      GetCh;
      if ch = '&' then // dbase comment 1
      begin
        while true do
        begin
          GetCh;
          if ch = #10 then break;
          if ch = #13 then
          begin
            GetCh;
            if not (ch = #10) then
            raise Exception.Create(
            Format('Error: %d: unexpected char found.', [Line]));
            break;
            ShowMessage('comment DBASE end');
          end;
        end;
        break;
      end;
    end;
    '*':
    begin
      GetCh;
      if ch = '*' then // dbase comment 2
      begin
        ShowMessage('comment DBASE end');
        while true do
        begin
          GetCh;
          if ch = #10 then break;
          if ch = #13 then
          begin
            ShowMessage('comment DBASE end');
            GetCh;
            if not (ch = #10) then
            raise Exception.Create(
            Format('Error: %d: unexpected char found.', [Line]));
            ShowMessage('comment DBASE end');
            break;
          end;
        end;
      end;
    end;
    'A'..'Z','_':
    begin (*Ident/Reserved Word*)
      while Ch in ['A'..'Z','_','0'..'9'] do
      begin
        Str := Str + Ch;
        GetCh
      end;
      Symbol := sIdent;

      for i := sUnknown to sNone do
        if Str = cSymbols[i] then
        begin
          Symbol := i;
          Break
        end;
      Exit
    end; (*Ident/Reserved Word*)

    ';','+','=','#',',','.':
    begin (*Symbole die nur aus 1 Zeichen bestehen können*)
      Str := Ch;
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

    '<':
    begin
      while True do
      begin
        GetCh;
        if Ch = '!' then
        begin
          GetCh;
          if ch = '-' then
          begin
            GetCh;
            if ch = '-' then
            begin
              start_comment := true;
              while True do
              begin
                GetCh;
                if ch = '-' then
                begin
                  GetCh;
                  if ch = '-' then
                  begin
                    GetCh;
                    continue;
                  end else
                  if ch = '>' then
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
              if ch = '>' then
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

    '(', ')':
    begin (*Klammern oder Kommentar*)
      Str := Ch;
      GetCh;
      if (Str='(') and (Ch = '*') then
      begin
        //Kommentar entdeckt
        GetCh;
        while True do
        begin
          GetCh;
          if Ch = '*' then
          begin
            GetCh;
            if Ch = ')' then
            begin
              GetCh;
              Break
            end
          end
          else if EoF(yyinput) then
            Break
        end
      end else
      if Str = '(' then
      begin
        Symbol := sOpenBracket;
        Exit
      end
      else
      begin
        Symbol := sCloseBracket;
        Exit
      end
    end;

    '0'..'9','$': (*Zahlen*)
    begin
      Symbol := sInteger;
      Str := Ch;
      GetCh;
      if (Str = '$') then
      begin
        //HexZahl
        while Ch in ['0'..'9','A'..'F'] do
        begin
          Str := Str + Ch;
          GetCh;
        end;
        Exit
      end
      else
      begin
        //NormaleZahl
        while Ch in ['0'..'9'] do
        begin
          Str := Str + Ch;
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
begin
  {$I-}
  AssignFile(yyinput, AFileName);
  Reset(yyinput, 1);
  {$I+}
  Seek(yyinput,0);
  Ch := ' ';
  Line := 1;
  GetSym;
  while Symbol <> sNone do
  begin
    GetSym;
  end;
  Form1.Memo2.Lines.Add('2Done...');
  CloseFile(yyinput);
end;

end.

