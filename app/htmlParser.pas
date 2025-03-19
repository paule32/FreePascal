unit htmlParser;
{$mode delphi}

interface
uses SysUtils, Classes, Dialogs, globals;

var
  yyinput: File;
  Line : Integer;

procedure yymain(AFileName: String);

implementation
uses MainForm;

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

var
  Ch : Char;
  Str : String;
  Symbol : TSymbol;

procedure Error(ErrorText : String);
begin
  raise Exception.Create(Format('%d: ' + ErrorText, [Line]));
end;

procedure GetSym;
  procedure GetCh;
  begin
    if not EoF(yyinput) then
      BlockRead(yyinput, Ch, 1)
    else
      raise Exception.Create('done.');
    //Case in-sensitive
    Ch := UpCase(Ch);

    //Zeile erhöhen?
    if Ch = #13 then Inc(Line);
    //Spezialzeichen filtern
    if Ord(Ch) < Ord(' ') then Ch := ' '
  end (*GetCh*);
var
  I : TSymbol;
  start_comment: Boolean = false;
begin
  start_comment := false;

  //Überspringen von Kommentaren
  while true do
  begin
    Str := '';
    Symbol := sNone;

    while (Ch = ' ') and not EoF(yyinput) do
    GetCh;

    //Wir brauchen nichts machen, wenn das Dateiende erreicht ist
    if EoF(yyinput) then
    Exit;

    case Ch of
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

    ';','+','=','#',',','.', '*', '/':
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
    Assert(Symbol <> SUnknown);
  end
end (*GetSym*);

procedure yymain(AFileName: String);
begin
  AssignFile(yyinput, AFileName);
  Reset(yyinput, 1);
  //Ch mit leerzeichen initialisieren
  Ch := ' ';
  Line := 1;
  GetSym;
  while Symbol <> sNone do
  begin
    Form1.Memo2.Lines.Add(str);
    GetSym;
  end;
  Form1.Memo2.Lines.Add('Done...');
  CloseFile(yyinput)
end;

end.

