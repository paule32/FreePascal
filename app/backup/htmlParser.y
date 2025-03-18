%{
unit htmlParser;
{$mode delphi}

interface
uses SysUtils, Dialogs, globals;

var
  SourceFile: Text;

procedure yymain(filename: String);

implementation
uses globals, YaccLib, LexLib;
%}

%start start
%token <Integer> NUMBER
%type <Integer> expr term factor

%%

start
    : expr '\n' { WriteLn('Ergebnis: ', $1); }
    ;
expr
    : expr '+' term { $$ := $1 + $3; }
    | expr '-' term { $$ := $1 - $3; }
    | term          { $$ := $1; }
    ;
term
    : term '*' factor { $$ := $1 * $3; }
    | term '/' factor { $$ := $1 div $3; }
    | factor          { $$ := $1; }
    ;
factor
    : NUMBER          { $$ := $1; }
    | '(' expr ')'    { $$ := $2; }
    ;
%%

{$include htmlLexer.pas}

procedure yymain(filename: String);
var
  Err: integer;
  ErrorMsg, fn: String;

  procedure openFile(AFileName: String; flag: Integer);
  begin
    if not FileExists(filename) then
    begin
      ShowMessage(
        tr('Error: file: "') + AFileName +
        tr('" could not be found.'));
      yyclear;
      exit;
    end;

    if flag = 0 then
    Assign(yyinput , AFileName) else // Immer wieder neu zuweisen!
    Assign(yyoutput, AFileName);

    {$push}{$I-}
    filemode := 0;
    if flag = 0 then
    Reset(yyinput) else  // Datei öffnen
    ReWrite(yyoutput);
    Err := IOResult; // Fehler merken
    {$pop}

    Case Err of
      0  : ErrorMsg := 'Success';
      2  : ErrorMsg := 'File not found';
      3  : ErrorMsg := 'Path not found';
      4  : ErrorMsg := 'Too many open files';
      5  : ErrorMsg := 'File access denied';
      6  : ErrorMsg := 'Invalid file handle';
      12 : ErrorMsg := 'Invalid file access code';
      102: ErrorMsg := 'File not assigned';
      103: ErrorMsg := 'File not open';
      104: ErrorMsg := 'File not open for input';
      105: ErrorMsg := 'File not open for output';
    else
      ErrorMsg := Format('Error %d occurred', [Err]);
    end;
    ShowMessage(ErrorMsg);
  end;

begin

  fn := StringReplace(ExtractFilePath(Paramstr(0)) + filename,
  '/', '\', [rfReplaceAll]);
  openFile(fn,0);

  fn := StringReplace(ExtractFilePath(Paramstr(0)) + filename + '.out',
  '/', '\', [rfReplaceAll]);
  openFile(fn,1);

  exit;
  yyWrap := @newYYwrap;
  yyclear;
  yyParse;

  close(yyinput);
  ShowMessage('Parsing abgeschlossen.');
end;

end.

