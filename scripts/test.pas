var
  TOCtext: String;

const INDENT_SIZE = 4; // Ein Level entspricht 4 Leerzeichen oder einem Tabulator
const MAX_LEVEL = 10;  // Maximale Anzahl der Hierarchieebenen

type
  TLevelCounter = array[1..MAX_LEVEL] of Integer;

procedure AddTopicLine;
var
  Lines: TStringList;
  i, Level: Integer;
  CurrentTopic, ParentTopic: String;
  TopicStack: array[0..MAX_LEVEL] of String;
begin
  HndTopics.DeleteAllTopics;
  
  // Erstelle eine Liste für die Zeilen
  Lines := TStringList.Create;
  try
    Lines.Text := TOCtext;
    for i := 0 to Lines.Count - 1 do
    begin
      Level := 0;

      // Berechne die Einrückung (4 Leerzeichen pro Stufe)
      while (Level < Length(Lines[i])) and (Lines[i][Level+1] = ' ') do
        Inc(Level);

      Level := Level div 4;

      // Entferne führende Leerzeichen
      Lines[i] := Trim(Lines[i]);

      if Lines[i] <> '' then
      begin
        if Level = 0 then
        begin
          // Hauptthema erstellen
          CurrentTopic := HndTopics.CreateTopic;
          HndTopics.SetTopicCaption(CurrentTopic, Lines[i]);
          TopicStack[0] := CurrentTopic;
          if i < 3 then
          ShowMessage(CurrentTopic + #13#10 + Lines[i]);
        end else
        begin
          CurrentTopic := HndTopics.CreateTopic;
          HndTopics.SetTopicCaption(CurrentTopic, Lines[i]);

          // Unterthema unter dem letzten höheren Thema einfügen
          ParentTopic  := TopicStack[Level - 1];
          HndTopics.MoveTopic(CurrentTopic, ParentTopic, THndTopicsAttachMode.htamAddChild);
          //(Lines[i], ParentTopic);
          TopicStack[Level] := CurrentTopic;
        end;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function CountIndentation(const Line: string): Integer;
var
  i, SpaceCount, Level: Integer;
begin
  i := 1;
  SpaceCount := 0;
  Level := 0;

  while (i <= Length(Line)) and ((Line[i] = #9) or (Line[i] = ' ')) do
  begin
    if Line[i] = #9 then
      Inc(Level) { Ein Tab zählt als ein Level }
    else
    begin
      Inc(SpaceCount);
      if SpaceCount = INDENT_SIZE then
      begin
        Inc(Level); { 4 Leerzeichen zählen als ein Level }
        SpaceCount := 0;
      end;
    end;
    Inc(i);
  end;

  result := Level;
end;

function ProcessIndentedText(var InputText: String): String;
var
  Lines: TStringList;
  LevelCounter: TLevelCounter;
  i, Level, j, k: Integer;
  OutputLine, LevelString, TrimmedLine: string;
begin
  result := '';
  
  { Manuelle Initialisierung von LevelCounter (anstelle von FillChar) }
  for j := 1 to MAX_LEVEL do
    LevelCounter[j] := 0;

  { Zerlege den Eingabetext in Zeilen }
  Lines := TStringList.Create;
  try
    Lines.Text := InputText; { Zerlegt den Text in Zeilen basierend auf #13#10 }

    for i := 0 to Lines.Count - 1 do
    begin
      Level := CountIndentation(Lines[i]);
      TrimmedLine := Trim(Lines[i]); { Entferne führende Leerzeichen/Tabs für die Ausgabe }

      { Aktualisiere die Nummerierung }
      Inc(LevelCounter[Level + 1]);  
      for j := Level + 2 to MAX_LEVEL do
        LevelCounter[j] := 0;  { Alle nachfolgenden Level zurücksetzen }

      { Erzeuge die hierarchische Nummer als String }
      LevelString := '';
      for j := 1 to Level + 1 do
      begin
        if LevelCounter[j] > 0 then
        begin
          if LevelString <> '' then
            LevelString := LevelString + '.';
          LevelString := LevelString + IntToStr(LevelCounter[j]);
        end;
      end;

      { Setze die Einrückung + Nummerierung + Text zusammen }
      for k := 1 to (Level * INDENT_SIZE) do
      OutputLine := OutputLine + ' ';
      OutputLine := OutputLine + LevelString + '  ' + TrimmedLine + #10;
    end;
    result := OutputLine;
    ShowMessage(outputline);
  finally
    Lines.Free;
  end;
end;
  
begin
  TOCtext :=
'Pascal Zeichen und Symbole' + #10+
'    Symbole' + #10+
'    Kommentare' + #10+
'    Reservierte Schlüsselwörter' + #10+
'        Turbo Pascal' + #10+
'        Object Pascal' + #10+
'        Modifikationen' + #10+
'    Kennzeichnungen' + #10+
'    Hinweise für Direktiven' + #10+
'    Zahlen' + #10+
'    Bezeichner' + #10+
'    Zeichenketten' + #10+
'Konstanten' + #10+
'    Gewöhnliche' + #10+
'    Typisierte' + #10+
'    Resourcen Zeichenketten' + #10+
'Typen' + #10+
'    Basis-Typen' + #10+
'        Ordinale Typen' + #10+
'        Ganze Zahlen (Integer)' + #10+
'        Boolesche Typen' + #10+
'        Aufzählungen' + #10+
'        Untermengen' + #10+
'        Zeichen' + #10+
'    Zeichen-Typen' + #10+
'        Char oder AnsiChar' + #10+
'        WideChar' + #10 +
'        Sonstige' + #10+
'        Einzel-Byte Zeichenketten' + #10+
'            ShortString' + #10+
'            AnsiString' + #10+
'            Zeichen-Code Umwandlung' + #10+
'            RawByteString' + #10+
'            UTF8String' + #10+
'        Multi-Byte Zeichenketten' + #10+
'            UnicodeString' + #10+
'            WideString' + #10+
'        Konstante Zeichenketten' + #10+
'        Nullterminierente Zeichenketten (PChar)' + #10+
'        Zeichenketten-Größen' + #10     +
'    Strukturierte Typen' + #10         +
'        Gepackte Struktur-Typen' + #10+
'        Array''s' + #10;

  // Verarbeitung des Texts
  TOCtext := ProcessIndentedText(TOCtext);
  ShowMessage(TOCtext);
  AddTopicLine;  
end.