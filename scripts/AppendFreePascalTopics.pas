const TemplatePageFile = 'F:\Bücher\projects\DIN_5473\tools\template.htm';
type
  TThema = class(TObject)
    Title: String;
    Level: Integer;
    ID: String;
  public
    constructor Create(AValue: Integer);
  end;

type
  TProject = class(TObject)
  private
    FLangCode: String;
    Title : String;
    Topics: Array of TThema;
  public
    constructor Create(AName: String)
    destructor Destroy; override;
  published
  property
    LanguageCode: String read FLangCode write FLangCode;
  end;

const MAX_TOPICS = 1024;
var Thema: Array [0..MAX_TOPICS] of TThema;
var toplist: THndTopicsInfoArray;

constructor TThema.Create(AValue: Integer);
begin
ShowMessage(inttostr(AValue))
end;
procedure test;
var testPro: TProject;
begin
  testPro := TProject.Create;
  testPro.Topics := [
    TThema.Create(1),
    TThema.Create(2)
  ];
  ShowMessage(HndProjects.SetProjectLanguageCode);
  testpro.topics := testpro.topics + [TThema.Create(4)];
end;

function GetLevel(const nummerierterTitel: String): Integer;
var
  i, count: Integer;
begin
  count := 0;
  for i := 1 to Length(nummerierterTitel) do
    if nummerierterTitel[i] = '.' then
    Inc(count);
  Result := count;
end;

function ExtractTitel(const nummerierterTitel: String): String;
var
  posSpace: Integer;
begin
  // -------------------------------------
  // find white space after numbering ...
  // -------------------------------------
  posSpace := Pos(' ', nummerierterTitel);
  if posSpace > 0 then
    Result := Copy(nummerierterTitel, posSpace + 1, Length(nummerierterTitel))
  else
    // --------------------
    // if no white space...
    // --------------------
    Result := nummerierterTitel;
end;

// ---------------------------------------------------------------------------
// calculates the indent level of the numbering TOC String
// ---------------------------------------------------------------------------
function GetLevelFromTOCString(const TOCString: String): Integer;
var
  i, count: Integer;
begin
  count := 0;
  // ---------------------------
  // count dot's to get level...
  // ---------------------------
  for i := 1 to Length(TOCString) do
  if TOCString[i] = '.' then
  Inc(count);

  // ------------------------------
  // count of dot's is indent level
  // ------------------------------
  Result := count;
end;

procedure CreateTableOfContents;
var i, p, g: Integer;
var aEditor: TObject;
var ThemenPage : TStringList;
var ThemenListe: TStringList;
begin
  toplist := HndTopics.GetTopicList(false);
  ThemenListe := TStringList.Create;
  ThemenPage  := TStringList.Create;
  try
    ThemenPage.LoadFromFile(TemplatePageFile);
    aEditor := HndEditor.CreateTemporaryEditor;
    HndEditorHelper.CleanContent(aEditor);
    HndEditor.InsertContentFromHTML(aEditor, ThemenPage.Text);

    print('1. pre-processing data...');
    Thema[0] := TThema.Create(1);
    Thema[0].Title := '1. Lizenz - Bitte lesen !!!';
    Thema[0].ID := HndTopics.CreateTopic;
    Thema[0].Level := GetLevel(Thema[0].Title);
    ThemenListe.AddObject('Thema0', Thema[0]);
    HndEditor.SetAsTopicContent(aEditor, Thema[0].ID);

    // Thema 2: Überblich
    Thema[1] := TThema.Create(2);
    Thema[1].Title := '1.1. Überblich';
    Thema[1].ID := HndTopics.CreateTopic;
    Thema[1].Level := GetLevel(Thema[1].Title);
    ThemenListe.AddObject('Thema1', Thema[1]);

    print('2.  generate tree...');
    for p := 0 to MAX_TOPICS do
    begin
      if Assigned(Thema[p]) then
      begin
        HndTopics.SetTopicCaption(
        Thema[p].ID,
        Thema[p].Title);
        if Thema[p].Level > 1 then
        begin
          for g := 1 to Thema[p].Level do
          HndTopics.MoveTopicRight(Thema[p].ID);
        end;
      end;
    end;
  finally
    print('3.  clean up memory...');
    for i := High(Thema) downto Low(Thema) do
    begin
      if Assigned(Thema[i]) then
      Thema[i].Free;
    end;
    ThemenListe.Clear;
    ThemenListe.Free;
    ThemenListe := nil;
    
    ThemenPage.Clear;
    ThemenPage.Free;
    ThemenPage := nil;
    
    HndEditorHelper.CleanContent(aEditor);
    HndEditor.Clear(aEditor);
    HndEditor.DestroyTemporaryEditor(aEditor);
    
    print('4.  done.');
  end;
end;

begin
  try
    try
    test;
      CreateTableOfContents;
    except
      on E: Exception do
      begin
        ShowMessage('Error:' + #13#10 + E.Message);
      end;
    end;
  finally
  end;
end.
