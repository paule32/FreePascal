// ----------------------------------------------------------------------------
// \file : CreateTOC.pas - This file is part of my HelpNDoc.com tools.
// \autor: Jens Kallup   - paule32 aka Blacky Cat aka Jens Kallup
// \date : 2025 (c) all rights reserved.
//
// \detail
// Create a TOC - table of content list for the current open project.
// The structure of the TOC string/file is as follow:
//
// You don't need to write the Index of the topic level - it will be create and
// add automatically.
// The default indent size is 4 chars: #32.
// 
// level_one
//     level_one_one
// level_two
//     level_two_one
//     level_two_two
//         level_two_two_one
// ... 
// ----------------------------------------------------------------------------
// Customization:
// --------------
// IDENT_SIZE = ident size (default: 4 chars)
// MAX_LEVEL  = maximal indent level's
// ----------------------------------------------------------------------------
const INDENT_SIZE =  4; // Ein Level entspricht 4 Leerzeichen oder einem Tabulator
const MAX_LEVEL   = 10; // Maximale Anzahl der Hierarchieebenen

const IN_SCRIPT_EDITOR = true; // important for script/built run !

type
  TLevelCounter = array[1..MAX_LEVEL] of Integer;

type
  // Klasse für eine einzelne INI-Sektion
  THndIniSection = class
  private
    FValues: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure  Add(Key, Value: string);
    function   Get(Key: string): string;
  end;

type
  THndIniParser = class
  private
    FSections: TStringList;
    FCurrentSection: string;
    
    function GetSection(const Section: string): THndIniSection;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure LoadFromFile(const FileName: string);
    function  ReadString(const Section, Key, Default: string): string;
    function  ReadInteger(const Section, Key: string; Default: Integer): Integer;
  end;

type
  THndCreateProject = class(TObject)
  private
    FTOCtext: TStringList;
    FActiveCustomTOC: Boolean;
    FParamStr: TStringList;
//    FiniFile: TIniFile;
    
    function CountIndentation(const Line: string): Integer;
    function ProcessIndentedText: String;
  public
    constructor Create(AString: String); overload;
    constructor Create; overload;
    destructor Destroy; override;

    procedure setAsString(AString: String);
    procedure setAsStream(AStream: TStream);
        
    function  getAsString: String;
    function  getAsStream: TStream;
    
    function  getCustomPath: String;

    procedure LoadFromString(AString: String);    
    procedure LoadFromFile(AString: String);
    procedure LoadFromStream(AStream: TStream);
    procedure LoadFromVariable(AString: String);

    function isEmpty: Boolean;
        
    procedure AddTOC;
  end;


{ THndIniSection }

constructor THndIniSection.Create;
begin
  inherited Create;
  FValues := TStringList.Create;
end;
destructor THndIniSection.Destroy;
begin
  FValues.Clear;
  FValues.Free;
end;

procedure THndIniSection.Add(Key, Value: string);
var
  Index: Integer;
begin
  Index := FValues.IndexOfName(Key);
  if Index = -1 then
    FValues.Add(Key + '=' + Value)  // new item
  else
  raise Exception.Create('IniSection key: "' + key + '" already exists.');
//    FValues.Values[Key] := Value;   // overwrite existing item
end;

function THndIniSection.Get(Key: string): string;
begin
  Result := FValues.Values[Key];
end;

{ THndIniParser }

constructor THndIniParser.Create;
begin
  inherited Create;
  FSections := TStringList.Create;
  FSections.Duplicates := dupIgnore;
  FSections.Sorted := False;
  FCurrentSection := '';
end;

destructor THndIniParser.Destroy;
var
  i: Integer;
begin
  // Alle Sektionen freigeben
  for i := 0 to FSections.Count - 1 do
    TObject(FSections.Objects[i]).Free;
  FSections.Free;
  inherited;
end;

function THndIniParser.GetSection(const Section: string): THndIniSection;
var
  Index: Integer;
begin
  Index := FSections.IndexOf(Section);
  if Index = -1 then
  begin
    Result := THndIniSection.Create;
    FSections.AddObject(Section, Result);
  end
  else
    Result := THndIniSection(FSections.Objects[Index]);
end;

procedure THndIniParser.LoadFromFile(const FileName: string);
var
  Lines: TStringList;
  Line, Key, Value, FullValue: string;
  P, i: Integer;
  InMultiLine: Boolean;
begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FileName);
    InMultiLine := False;
    FullValue := '';

    for i := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[i]);
      if (Line = '') or (Line[1] = ';') or (Line[1] = '#') then
        Continue; // Kommentar oder leere Zeile ignorieren

      if (Line[1] = '[') and (Line[Length(Line)] = ']') then
      begin
        // Neue Sektion gefunden
        FCurrentSection := Copy(Line, 2, Length(Line) - 2);
        Continue;
      end;

      // Schlüssel-Wert-Paar verarbeiten
      P := Pos('=', Line);
      if P > 0 then
      begin
        if InMultiLine then
        begin
          // Falls ein vorheriger Wert mehrzeilig war, speichern und fortfahren
          GetSection(FCurrentSection).Add(Key, FullValue);
          InMultiLine := False;
        end;

        Key := Trim(Copy(Line, 1, P - 1));
        Value := Trim(Copy(Line, P + 1, Length(Line) - P));

        if (Value <> '') and (Value[Length(Value)] = '\') then
        begin
          // Falls der Wert mit `\` endet, als mehrzeilig kennzeichnen
          FullValue := Copy(Value, 1, Length(Value) - 1);
          InMultiLine := True;
        end
        else
          GetSection(FCurrentSection).Add(Key, Value);
      end
      else if InMultiLine then
      begin
        // Mehrzeilige Fortsetzung ohne neuen Key
        FullValue := FullValue + ' ' + Trim(Line);
      end;
    end;

    // Falls am Ende noch ein mehrzeiliger Wert offen ist, speichern
    if InMultiLine then
      GetSection(FCurrentSection).Add(Key, FullValue);
  finally
    Lines.Free;
  end;
end;

function THndIniParser.ReadString(const Section, Key, Default: string): string;
var
  SectionObj: THndIniSection;
begin
  SectionObj := GetSection(Section);
  if Assigned(SectionObj) then
  begin
    Result := SectionObj.Get(Key);
    if Result = '' then
      Result := Default;
  end
  else
    Result := Default;
end;

function THndIniParser.ReadInteger(const Section, Key: string; Default: Integer): Integer;
var
  s: string;
begin
  s := ReadString(Section, Key, '');
  if s = '' then
    Result := Default
  else
    Result := StrToIntDef(s, Default);
end;

{ THndCreateProject }

// ----------------------------------------------------------------------------
// \brief This is the CTOR of the class THndCreateProject
// ----------------------------------------------------------------------------
constructor THndCreateProject.Create(AString: String);
begin
  inherited Create;
  FActiveCustomTOC := false;
  try
    FTOCtext := TStringList.Create;
    FTOCtext.Text := AString;
  except
    raise Exception.Create('StringList could not be created !');
  end;
end;

// ----------------------------------------------------------------------------
// \brief This is the CTOR for the class THndCreateProject
// ----------------------------------------------------------------------------
constructor THndCreateProject.Create;
begin
  inherited Create;
  FActiveCustomTOC := false;
  try
    FTOCtext := TStringList.Create;
    FTOCtext.Text := '';
  except
    raise Exception.Create('StringList could not be created !');
  end;
end;

// ----------------------------------------------------------------------------
// \brief This is the DTOR for the class THndCreateProject
// ----------------------------------------------------------------------------
destructor THndCreateProject.Destroy;
begin
  FTOCtext.Clear;
  FTOCtext.Free;
  
  inherited Destroy;
end;

// ----------------------------------------------------------------------------
// \brief  Get the TOC string assigned from a String or File.
// \param  Nothing
// \return String
// ----------------------------------------------------------------------------
function THndCreateProject.getAsString: String;
begin
  result := '';
  if not Assigned(FTOCtext) then
  begin
    try
      FTOCtext := TStringList.Create;
    except
      on E: Exception do
      begin
        ShowMessage('Error:'+#10+E.Message);
      end;
    end;
  end else
  result := FTOCtext.Text;
end;

// ----------------------------------------------------------------------------
// \brief  Get the TOC as stream.
// \param  Nothing
// \return TStream
// ----------------------------------------------------------------------------
function THndCreateProject.getAsStream: TStream;
begin
  result := nil;
end;

function THndCreateProject.getCustomPath: String;
var
  AString: String;
begin
  result := '';
  AString := Trim(HndGeneratorInfo.GetCustomSettingValue('CustomPath'));
  if Length(AString) < 1 then
  raise Exception.Create('CustomPath must be set !') else
  result := AString; 
end;

// ----------------------------------------------------------------------------
// \brief This member set the internal representation by a given string.
// \param AString - String
// ----------------------------------------------------------------------------
procedure THndCreateProject.setAsString(AString: String);
begin
  if not Assigned(FTOCtext) then
  FTOCtext := TStringList.Create;
  FTOCtext.Clear;
  FTOCtext.Text := AString;
end;

procedure THndCreateProject.setAsStream(AStream: TStream);
begin
// todo
end;

// ----------------------------------------------------------------------------
// \brief  Read the TOC structure from a given file name.
// \param  AString - String: The file name to be open and read.
// ----------------------------------------------------------------------------
procedure THndCreateProject.LoadFromFile(AString: String);
var
  FileContents: TStringList;
begin
  FileContents := TStringList.Create;
  try
    if FileExists(AString) then
    begin
      FileContents.LoadFromFile(AString);
      setAsString(FileContents.Text)
    end else
    raise Exception.Create('File "' + AString + '" could not be found !');
  finally
    FileContents.Free;
  end;
end;

// ----------------------------------------------------------------------------
// \brief Load the TOC from a given string.
// \param AString - String
// ----------------------------------------------------------------------------
procedure THndCreateProject.LoadFromString(AString: String);
begin
  setAsString(AString);
end;

// ----------------------------------------------------------------------------
// \brief Load the TOC from a given stream.
// \param AStream - TStream
// ----------------------------------------------------------------------------
procedure THndCreateProject.LoadFromStream(AStream: TStream);
begin
// todo
end;

// ----------------------------------------------------------------------------
// \brief Load the TOC from a given HelpNDoc variable.
// \param AString - String.
// ----------------------------------------------------------------------------
procedure THndCreateProject.LoadFromVariable(AString: String);
var
  dst: String;
begin
  dst := Trim(HndGeneratorInfo.GetCustomSettingValue('ActivateCustomTOC'));
  if (Length(dst) < 1) and (IN_SCRIPT_EDITOR = false) then
  begin
    raise Exception.Create('ActivateCustomTOC is empty or does not exists !');
  end else
  if (Length(dst) > 0) and (IN_SCRIPT_EDITOR = false) then
  begin  
    if LowerCase(dst) = 'false' then
    begin
      FTOCtext.Text := '';
      ShowMessage('false');
    end else
    if LowerCase(dst) = 'true' then
    begin
      dst := Trim(HndGeneratorInfo.GetCustomSettingValue('CustomTOCString'));
      if Length(dst) < 1 then
      begin
        dst := Trim(HndGeneratorInfo.GetCustomSettingValue('CustomTOCFile'));
        if Length(dst) < 1 then
        raise Exception.Create('CustomTOC String/File is empty or does not exists !');
        LoadFromFile(dst);
        exit;
      end;
      LoadFromString(dst);
    end;
  end else
  if (Length(dst) < 1) and (IN_SCRIPT_EDITOR = true) then
  begin
//  showmessage(THndGeneratorInfo.OutputDir);
    raise Exception.Create('Anot exists !');
  end;
end;

function THndCreateProject.isEmpty: Boolean;
begin
  result := true;
  if not Assigned(FTOCtext) or (Length(FTOCtext.Text) > 1) then
  result := false;
end;

// ----------------------------------------------------------------------------
// \brief Add a new topic from the current topic level/line ...
// ----------------------------------------------------------------------------
procedure THndCreateProject.AddTOC;
var
  Lines: TStringList;
  i, Level: Integer;
  CurrentTopic, ParentTopic: String;
  TopicStack: array[0..MAX_LEVEL] of String;
begin
  HndTopics.DeleteAllTopics;

  if not Assigned(FTOCtext) then
  raise Exception.Create('No Topics to add.');
    
  ProcessIndentedText;

  // ----------------------------  
  // create a list for the lines
  // ----------------------------
  Lines := TStringList.Create;
  try
    Lines.Text := getAsString;
    for i := 0 to Lines.Count - 1 do
    begin
      Level := 0;

      // ----------------------------------------
      // calculate the indent's
      // (default: 4 white spaces for each level
      // ----------------------------------------
      while (Level < Length(Lines[i])) and (Lines[i][Level+1] = ' ') do
        Inc(Level);

      Level := Level div 4;

      // -----------------------------
      // delete trailing white spaces
      // -----------------------------
      Lines[i] := Trim(Lines[i]);

      if Lines[i] <> '' then
      begin
        if Level = 0 then
        begin
          // ------------------
          // create root topic
          // ------------------
          CurrentTopic := HndTopics.CreateTopic;
          HndTopics.SetTopicCaption(CurrentTopic, Lines[i]);
          TopicStack[0] := CurrentTopic;
          if i < 3 then
          ShowMessage(CurrentTopic + #13#10 + Lines[i]);
        end else
        begin
          CurrentTopic := HndTopics.CreateTopic;
          HndTopics.SetTopicCaption(CurrentTopic, Lines[i]);

          // -------------------------------
          // add sub-topic under the parent
          // -------------------------------
          ParentTopic  := TopicStack[Level - 1];
          HndTopics.MoveTopic(CurrentTopic, ParentTopic, THndTopicsAttachMode.htamAddChild);
          TopicStack[Level] := CurrentTopic;
        end;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

// ----------------------------------------------------------------------------
// \brief  This function calculates the indent spaces of the parent and child.
// \param  Line - const String
// \return Integer
// ----------------------------------------------------------------------------
function THndCreateProject.CountIndentation(const Line: string): Integer;
var
  i, SpaceCount, Level: Integer;
begin
  i := 1;
  SpaceCount := 0;
  Level := 0;

  while (i <= Length(Line)) and ((Line[i] = #9) or (Line[i] = ' ')) do
  begin
    if Line[i] = #9 then
      Inc(Level) // a Tab for indention of a level
    else
    begin
      Inc(SpaceCount);
      if SpaceCount = INDENT_SIZE then
      begin
        Inc(Level); // 4 white spaces for a level
        SpaceCount := 0;
      end;
    end;
    Inc(i);
  end;

  result := Level;
end;

// ----------------------------------------------------------------------------
// \brief This function handle the indents and the text for the current level.
// ----------------------------------------------------------------------------
function THndCreateProject.ProcessIndentedText: String;
var
  Lines: TStringList;
  LevelCounter: TLevelCounter;
  i, Level, j, k: Integer;
  OutputLine, LevelString, TrimmedLine: string;
begin
  result := '';
  
  // --------------------------------------------------------------
  // manuell initial of LevelCounter (instead of missing FillChar)
  // --------------------------------------------------------------
  for j := 1 to MAX_LEVEL do
    LevelCounter[j] := 0;

  // --------------------------------------------------------------
  // split the input text into lines
  // --------------------------------------------------------------
  Lines := TStringList.Create;
  try
    // ------------------------------------------------------------
    // split the text in each line based on newline: #13#10
    // ------------------------------------------------------------
    Lines.Text := FTOCtext.Text;

    for i := 0 to Lines.Count - 1 do
    begin
      // ----------------------------------------------------------
      // remove trailing white spaces/tabs for the output
      // ----------------------------------------------------------
      Level := CountIndentation(Lines[i]);
      TrimmedLine := Trim(Lines[i]);

      // ----------------------------------------------------------
      // refresh/update the numbering
      // ----------------------------------------------------------
      Inc(LevelCounter[Level + 1]);  
      for j := Level + 2 to MAX_LEVEL do
        LevelCounter[j] := 0;  // reset all levels

      // ----------------------------------------------------------
      // create the hieracial number as string
      // ----------------------------------------------------------
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

      // ----------------------------------------------------------
      // combine the indent + numbering + text together
      // ----------------------------------------------------------
      for k := 1 to (Level * INDENT_SIZE) do
      OutputLine := OutputLine + ' ';
      OutputLine := OutputLine + LevelString + '  ' + TrimmedLine + #10;
    end;
    result := OutputLine;
  finally
    Lines.Free;
  end;
end;

// ----------------------------------------------------------------------------
// \brief This is the main block for this script. It will gattering infos for
//        creating a HelpNDoc.com Project.
// ----------------------------------------------------------------------------
var TOC: THndCreateProject;
var ini: THndIniParser;

{$include 'main.pas'}
begin
  ini := THndIniParser.Create;
  TOC := THndCreateProject.Create;
  try
    try
      ini.LoadFromFile()
(*      TOC.LoadFromVariable('');
      
      if TOC.isEmpty then
      raise Exception.Create('No Topics String/File.');

      TOC.AddTOC;
*)
    except
      on E: Exception do
      begin
        ShowMessage('Error:' + #10 + E.Message);
      end;
    end;
  finally
    TOC.Free;
    ini.Free;
  end;  
end.
