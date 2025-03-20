unit CommentPreprocessor;
{$mode delphi}

interface
uses
  SysUtils, Classes, Dialogs;

type
  TCommentLexer = class
  private
    FSource: TStringList;
    FProcessedSource: TStringList;
    function RemoveComments(const Line: string): string;
    function RemoveMultilineComments(const Source: string): TStringList;
  public
    constructor Create; overload;
    constructor Create(s: string); overload;
    destructor Destroy; override;
    function LoadFromFile(const Filename: string): string;
    function LoadFromString(const SourceCode: String): TStringList;
    function GetProcessedSource: TStringList;
  end;

type
  ECommentException = class(exception);

function CommentLexer(src: string): TStringList; stdcall; export;

implementation
uses StrUtils;

type
  TTokenInfo = class
  public
    Line: Integer;
    Column: Integer;
    constructor Create(ALine, AColumn: Integer);
  end;

constructor TTokenInfo.Create(ALine, AColumn: Integer);
begin
  inherited Create;

  Line := ALine;
  Column := AColumn;
end;

constructor TCommentLexer.Create;
begin
  inherited Create;

  FSource := TStringList.Create;
  FProcessedSource := TStringList.Create;
end;
constructor TCommentLexer.Create(s: string);
begin
  inherited Create;

  FSource := TStringList.Create;
  FProcessedSource := TStringList.Create;

  LoadFromString(s);
end;

destructor TCommentLexer.Destroy;
begin
  FreeAndNil(FSource);
  FreeAndNil(FProcessedSource);

  inherited Destroy;
end;

function TCommentLexer.LoadFromFile(const Filename: string): string;
begin
  result := '';
  FSource.LoadFromFile(Filename);
  FProcessedSource.Clear;
  result := FSource.Text;
end;

function TCommentLexer.LoadFromString(const SourceCode: string): TStringList;
begin
  result := nil;
  FSource.Text := SourceCode;
  FProcessedSource.Clear;
  result := FSource;
end;

// Funktion entfernt einzeilige Kommentare und ersetzt sie mit Leerzeichen
function TCommentLexer.RemoveComments(const Line: string): string;
var
  CommentStart: Integer;
begin
  Result := Line;

  // Finde das erste Auftreten eines Kommentarzeichens
  CommentStart := Pos('//', Result);

  if (CommentStart = 0) or ((Pos('**', Result) > 0) and (Pos('**', Result) < CommentStart)) then
  CommentStart := Pos('**', Result);

  if (CommentStart = 0) or ((Pos('&&', Result) > 0) and (Pos('&&', Result) < CommentStart)) then
  CommentStart := Pos('&&', Result);

  // Falls ein Kommentar gefunden wurde, ersetze alles dahinter mit Leerzeichen
  if CommentStart > 0 then
  begin
    // Ersetze alles ab `CommentStart` bis zum Ende der Zeile mit Leerzeichen
    FillChar(Result[CommentStart], Length(Result) - CommentStart + 1, ' ');
  end;
end;

// Funktion entfernt mehrzeilige Kommentare und ersetzt sie mit Leerzeichen
function TCommentLexer.RemoveMultilineComments(const Source: string): TStringList;
var
  Lines: TStringList;
  TokenList: TStringList;
  i, StartPos, EndPos, ColumnIndex, TokenStart: Integer;
  InComment: Boolean;
  Line, CleanLine, RemainingText, OriginalLine, Token: string;
  TokenInfo: TTokenInfo;
  c: Char;
begin
  Lines := TStringList.Create;
  TokenList := TStringList.Create;
  try
    Lines.Text := Source;
    InComment := False;

    for i := 0 to Lines.Count - 1 do
    begin
      Line := Lines[i];
      OriginalLine := Line;  // Speichert die Originalzeile für spätere Berechnung der Spalte
      ColumnIndex := 1;
      RemainingText := '';

      if InComment then
      begin
        EndPos := Pos('*/', Line);
        if EndPos > 0 then
        begin
          RemainingText := Copy(Line, EndPos + 2, Length(Line));
          ColumnIndex := EndPos + 2;
          Line := Copy(Line, 1, EndPos - 1) + StringOfChar(' ', EndPos - 1);
          InComment := False;
        end
        else
        begin
          Line := StringOfChar(' ', Length(Line));
        end;
      end
      else
      begin
        StartPos := Pos('/*', Line);
        while StartPos > 0 do
        begin
          EndPos := Pos('*/', Line);
          if EndPos > StartPos then
          begin
            RemainingText := Copy(Line, EndPos + 2, Length(Line));
            ColumnIndex := EndPos + 2;
            Line := Copy(Line, 1, StartPos - 1) + StringOfChar(' ', EndPos - StartPos + 2);
            InComment := False;
          end
          else
          begin
            ColumnIndex := StartPos;
            Line := Copy(Line, 1, StartPos - 1) + StringOfChar(' ', Length(Line) - StartPos + 1);
            InComment := True;
          end;
          Break;
        end;
      end;

      // Falls nach `*/` noch Text existiert, bleibt dieser in der gleichen Zeile
      Lines[i] := Trim(Line) + ' ' + Trim(RemainingText);
    end;

    if InComment then
      raise ECommentException.Create('Comment not terminated.');

    // **Zweite Schleife: Tokenisierung mit Trennung von Sonderzeichen**
    for i := 0 to Lines.Count - 1 do
    begin
      CleanLine := TrimLeft(Lines[i]);
      ColumnIndex := Pos(CleanLine, Lines[i]); // Startposition des ersten Tokens
      TokenStart := ColumnIndex;
      Token := '';

      for StartPos := 1 to Length(CleanLine) do
      begin
        c := CleanLine[StartPos];

        // Falls ein Sonderzeichen auftritt oder ein Leerzeichen den Token beendet
        if (c in ['<', '>', '=', '+', '-', '*', '/', '(', ')', '{', '}', '[', ']', ',', ';', ' ']) then
        begin
          // Falls es ein vorhergehendes Token gibt, speichere es
          if Token <> '' then
          begin
            TokenList.AddObject(Token, TTokenInfo.Create(i + 1, TokenStart));
            Token := '';
          end;

          // Falls das Zeichen selbst ein separates Token ist, speichere es
          if not (c in [' ']) then
          begin
            TokenList.AddObject(c, TTokenInfo.Create(i + 1, StartPos));
          end;

          TokenStart := StartPos + 1;
        end
        else
        begin
          // Zeichen zum aktuellen Token hinzufügen
          if Token = '' then
            TokenStart := StartPos;
          Token := Token + c;
        end;
      end;

      // Falls noch ein Rest-Token übrig ist
      if Token <> '' then
      TokenList.AddObject(Token, TTokenInfo.Create(i + 1, TokenStart));
    end;

    Result := TokenList;
  finally
    Lines.Free;
  end;
end;

function TCommentLexer.GetProcessedSource: TStringList;
var
  i: Integer;
  Line: string;
begin
  FProcessedSource.Clear;

  // Prüfen, ob FSource existiert, bevor darauf zugegriffen wird
  if not Assigned(FSource) then
  raise Exception.Create('FSource wurde nicht initialisiert.');

  for i := 0 to FSource.Count - 1 do
  begin
    Line := RemoveComments(FSource[i]); // Einzeilige Kommentare entfernen
    FProcessedSource.Add(Line);
  end;

  // Mehrzeilige Kommentare entfernen
  Result := RemoveMultilineComments(FProcessedSource.Text);
end;

function CommentLexer(src: String): TStringList; stdcall; export;
var
  Lexer: TCommentLexer;
  i: Integer;
  ProcessedSource: TStringList;
  s: string;
begin
  result := nil;
  Lexer := TCommentLexer.Create;
  try
    try
      // Test mit Datei
      //Lexer.LoadFromFile('test.pas');
      //ProcessedSource := Lexer.GetProcessedSource;

      //txt := '--- Code aus Datei ohne Kommentare ---';
      //txt := txt + ProcessedSource;
      //ShowMessage(txt);

      // Test mit String
      //TestSource :=
      //  'var x: Integer; // Kommentar' + sLineBreak +
      //  'x := 10; ** Noch ein Kommentar' + sLineBreak +
      //  '/* Mehrzeiliger' + sLineBreak +
      //  'Kommentar */' + sLineBreak +
      //  'x := x + 1; && Kommentar';

      Lexer := TCommentLexer.Create;
      ProcessedSource := Lexer.LoadFromString(src);
      ProcessedSource := Lexer.GetProcessedSource;

      s := '--- Code aus String ohne Kommentare ---' + #10;
      for i := 0 to ProcessedSource.Count - 1 do
      begin
        if (Trim(ProcessedSource[i]) <> #13)
        or (Trim(ProcessedSource[i]) <> #10) then
        begin
          s := s + ProcessedSource[i];
          //s := s + ' row: ' + IntToStr(TTokenInfo(ProcessedSource.Objects[i]).Line);
          //s := s + ' col: ' + IntToStr(TTokenInfo(ProcessedSource.Objects[i]).Column);
          s := s + #13#10;
        end;
      end;
      ShowMessage(s);
      result := ProcessedSource;
    except
      on E: ECommentException do
      begin
        ShowMessage('A error with a comment occured:'+#10+E.Message);
      end;
      on E: Exception do
      begin
        ShowMessage('A common Exception occured.'+#10+E.Message);
      end;
    end;
  finally
    Lexer.Free;
  end;
end;

end.

