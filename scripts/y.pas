// automated created - all data will be lost on next run !

// --------------------------------------------------------------------
// \file   helpndoc.pas
// \autor  (c) 2025 by Jens Kallup - paule32
// \copy   all rights reserved.
//
// \detail Read-in an existing Microsoft HTML-Workshop *.hhc file, and
//         extract the topics, generate a HelpNDoc.com Pascal Engine
//         ready Skript for running in/with the Script-Editor.
//         Currently the Text (the Topic Caption's) must occured in
//         numbering like "1. Caption" or "1.1.1. Sub-Caption"
//
// \param  nothing - the Pascal File is created automatically.
// \param  toc.hhc - the HTML Help Chapters (for read-in in Python).
//         The Path to this file must be adjusted.
// \param  TopicTemplate.htm - the HTML Template File that is inserted
//         into the created Topic (Editor). Currently the toc.hhc is
//         assumed in the same directory as this Python Script.
// \param  ProjectName - the name of the Project, default.hnd.  
//
// \return HelpNDoc.com compatible TOC Pascal file - HelpNDocPasFile.
//         Currently assumed in the same Directory as this Python Script
//
// \error  On Error, the User will be informed with the context deepend
//         Error Information's.
// --------------------------------------------------------------------
const HelpNDocTemplateHTM = 'template.htm';
const HelpNDocProjectName = 'default.hnd';
const HelpNDocProjectPath = 'F:\Bücher\projects\DIN_5473\tools';

// --------------------------------------------------------------------
// [End of User Space]
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// there are internal used classes that are stored simplified in a
// TStringList.
// --------------------------------------------------------------------
type
  TEditor = class(TObject)
  private
    ID: TObject;
    Content: String;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Clear;

    procedure LoadFromFile(AFileName: String);
    procedure LoadFromString(AString: String);
    
    procedure SaveToFile(AFileName: String);
    
    function  getContent: String;
    function  getID: TObject;
    
    procedure setContent(AString: String);
  end;

type
  TTopic = class(TObject)
  private
    TopicTitle  : String ;
    TopicLevel  : Integer;
    TopicID     : String ;
    TopicEditor : TEditor;
  public
    constructor Create(AName: String); overload;
    constructor Create(AName: String; ALevel: Integer); overload;
    destructor Destroy; override;
    
    procedure LoadFromFile(AFileName: String);
    procedure LoadFromString(AString: String);
    
    procedure MoveRight;
    
    function getEditor: TEditor;
    function getID: String;
  end;

type
  TTemplate = class(TObject)
  end;

type
  TProject = class(TObject)
  private
    FLangCode: String;
    Title : String;
    ID : String;
    Topics: Array of TTopic;
    Template: TTemplate;
  public
    constructor Create(AName: String); overload;
    constructor Create; overload;
    destructor Destroy; override;
    
    procedure AddTopic(AName: String; ALevel: Integer); overload;
    procedure AddTopic(AName: String); overload;
    
    procedure SaveToFile(AFileName: String);
    
    procedure SetTemplate(AFileName: String);
    procedure CleanUp;
  published
  property
    LanguageCode: String read FLangCode write FLangCode;
  end;

// ---------------------------------------------------------------------------
// common used constants and variables...
// ---------------------------------------------------------------------------
var HelpNDoc_default: TProject;

// ---------------------------------------------------------------------------
// calculates the indent level of the numbering TOC String
// ---------------------------------------------------------------------------
function GetLevel(const TOCString: String): Integer;
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

{ TEditor }

// ---------------------------------------------------------------------------
// \brief This is the constructor for class TEditor. A new Content Editor
//         object will be created. The default state is empty.
// ---------------------------------------------------------------------------
constructor TEditor.Create;
begin
  //inherited Create;
  ID := HndEditor.CreateTemporaryEditor;
  Clear;
end;

// ---------------------------------------------------------------------------
// \brief This is the destructor for class EDitor. Here, we try to remove so
//         much memory as possible that was allocated before.
// ---------------------------------------------------------------------------
destructor TEditor.Destroy;
begin
  Clear;
  HndEditor.DestroyTemporaryEditor(ID);
  inherited Destroy;
end;

// ---------------------------------------------------------------------------
// \brief This function make the current content editor clean for new input.
// ---------------------------------------------------------------------------
procedure TEditor.Clear;
begin
  if not Assigned(ID) then
  raise Exception.Create('Editor not created.');
  
  HndEditorHelper.CleanContent(getID);
  HndEditor.Clear(getID);
end;

// ---------------------------------------------------------------------------
// \brief This function loads the HTML Content for the current content editor
//         Warning: Existing Code will be overwrite through this function !
// ---------------------------------------------------------------------------
procedure TEditor.LoadFromFile(AFileName: String);
var strList: TStringList;
begin
  if not Assigned(ID) then
  raise Exception.Create('Error: Editor ID unknown.');
  try
    try
      strList := TStringList.Create;
      strList.LoadFromFile(AFileName);
      Content := Trim(strList.Text);
      
      HndEditor.InsertContentFromHTML(getID, Content);
    except
      on E: Exception do
      raise Exception.Create('Error: editor content can not load from file.');
    end;
  finally
    strList.Clear;
    strList.Free;
    strList := nil;
  end;
end;

// ---------------------------------------------------------------------------
// \brief This function load the HTML Content for the current Content Editor
//         by the given AString HTML code.
//         Warning: Existing Code will be overwrite throug this function !
// ---------------------------------------------------------------------------
procedure TEditor.LoadFromString(AString: String);
begin
  if not Assigned(getID) then
  raise Exception.Create('Error: editor ID unknown.');
  try
    Content := Trim(AString);
    HndEditor.InsertContentFromHTML(getID, AString);
  except
    on E: Exception do
    raise Exception.Create('Error: editor content could not set.');
  end;
end;

procedure TEditor.SaveToFile(AFileName: String);
begin
  //GetContentAsHtml()
end;

function  TEditor.getContent: String ; begin result := Content; end;
function  TEditor.getID     : TObject; begin result := ID;      end;

procedure TEditor.setContent(AString: String);
begin
  Content := AString;
  HndEditor.InsertContentFromHTML(getID, getContent);
end;

{ TTopic }

// ---------------------------------------------------------------------------
// \brief This is the constructor for class TTopic. It creates a new fresh
//         Topic with given AName and a indent with ALevel.
// ---------------------------------------------------------------------------
constructor TTopic.Create(AName: String; ALevel: Integer);
begin
  //inherited Create;
  
  TopicTitle  := AName;
  TopicLevel  := ALevel;
  TopicID     := HndTopics.CreateTopic;
  
  HndTopics.SetTopicCaption(TopicID, TopicTitle);
  //MoveRight;
  
  TopicEditor := TEditor.Create;
end;

// ---------------------------------------------------------------------------
// \brief This is a overloaded constructor for class TTopic. It creates a new
//         fresh Topic if the given AName, and a indent which is automatically
//         filled in.
// ---------------------------------------------------------------------------
constructor TTopic.Create(AName: String);
begin
//  inherited Create;
  
  TopicTitle  := AName;
  TopicLevel  := GetLevel(TopicTitle);
  TopicID     := HndTopics.CreateTopic;
  
  HndTopics.SetTopicCaption(TopicID, TopicTitle);
  MoveRight;
  
  TopicEditor := TEditor.Create;
end;

// ---------------------------------------------------------------------------
// \brief This is the destructor for class TTopic. Here we try to remove so
//         much memory as possible is allocated before.
// ---------------------------------------------------------------------------
destructor TTopic.Destroy;
begin
  TopicEditor.Free;
  TopicEditor := nil;
  
  inherited Destroy;
end;

// ---------------------------------------------------------------------------
// \brief This is a place holder function to reduce code redundance.
// ---------------------------------------------------------------------------
procedure TTopic.MoveRight;
var idx: Integer;
begin
  if TopicLevel > 1 then
  begin
    for idx := 1 to TopicLevel do
    HndTopics.MoveTopicRight(TopicID);
  end;
end;

// ---------------------------------------------------------------------------
// \brief This function loads the Topic Content from a File and fill it into
//         the Content Editor.
// ---------------------------------------------------------------------------
procedure TTopic.LoadFromFile(AFileName: String);
var strList: TStringList;
begin
  try
    try
      strList := TStringList.Create;
      strList.LoadFromFile(AFileName);
      getEditor.setContent(Trim(strList.Text));
    except
      on E: Exception do
      raise Exception.Create('Error: editor content can not load from file.');
    end;
  finally
    strList.Clear;
    strList.Free;
    strList := nil;
  end;
end;

procedure TTopic.LoadFromString(AString: String);
begin
end;

function TTopic.getEditor: TEditor; begin result := TopicEditor; end;
function TTopic.getID    : String ; begin result := TopicID;     end;

{ TProject }

// ---------------------------------------------------------------------------
// \brief This is the constructor for class TProject. It creates a new fresh
//         Project with the given AName.
// ---------------------------------------------------------------------------
constructor TProject.Create(AName: String);
begin
//  inherited Create;
  
  try
    Title     := AName;
    ID        := HndProjects.NewProject(AName + '.hnd');
    FLangCode := 'en-us';
    
//    HndProjects.SetProjectModified(True);
//    HndProjects.SetProjectLanguage(850);
//    HndProjects.SaveProject;
  except
    on E: Exception do
    raise Exception.Create('Error: project file .');
  end;
end;

// ---------------------------------------------------------------------------
// \brief This is the overloaded constructor to create a new Project with the
//         default settings.
// ---------------------------------------------------------------------------
constructor TProject.Create;
begin
  //inherited Create;
  
  try
    Title     := 'default.hnd';
    ID        := HndProjects.NewProject(Title);
    FLangCode := 'en-us';
    
    HndProjects.SetProjectModified(True);
    HndProjects.SetProjectLanguage(850);
    HndProjects.SaveProject;
  except
    on E: Exception do
    raise Exception.Create('Error: Project could not be loaded.');
  end;
end;

// ---------------------------------------------------------------------------
// \brief This is the destructor of class TProject. Here we try to remove so
//         much memory as possible is allocated before.
// ---------------------------------------------------------------------------
destructor TProject.Destroy;
var index: Integer;
begin
//  CleanUp;
  
  HndProjects.CloseProject;
  inherited Destroy;
end;

procedure TProject.CleanUp;
var index: Integer;
begin
  for index := High(Topics) downto Low(Topics) do
  begin
    Topics[index].Free;
    Topics[index] := nil;
  end;
  Topics := nil;
end;

// ---------------------------------------------------------------------------
// \brief This function save the HTML Content and Project Data to storage.
// ---------------------------------------------------------------------------
procedure TProject.SaveToFile(AFileName: String);
begin
  if Length(Trim(ID)) < 1 then
  raise Exception.Create('Error: Project ID is nil.');
  
  if Length(Trim(AFileName)) > 0 then
  HndProjects.CopyProject(AFileName, false) else
  HndProjects.SaveProject;
end;

// ---------------------------------------------------------------------------
// \brief add an new Topic with AName and ALevel
// ---------------------------------------------------------------------------
procedure TProject.AddTopic(AName: String; ALevel: Integer);
var
  Topic: TTopic;
begin
  try
    Topic  := TTopic.Create(AName, ALevel);
    HndEditor.SetAsTopicContent(Topic.getEditor.getID, Topic.getID);
    Topics := Topics + [Topic];
  except
    on E: Exception do
    raise Exception.Create('Error: can not create topic.');
  end;
end;

// ---------------------------------------------------------------------------
// \brief add a new Topic with AName. the level is getting by GetLevel
// ---------------------------------------------------------------------------
procedure TProject.AddTopic(AName: String);
var
  Topic: TTopic;
begin
  try
    Topic  := TTopic.Create(AName, GetLevel(AName));
    //showmessage(ANAME + #13#10 + Topic.getID);

    HndEditor.SetAsTopicContent(Topic.getEditor.getID, Topic.getID);
    Topics := Topics + [Topic];
  except
    on E: Exception do
    raise Exception.Create('Error: can not create topic.');
  end;
end;

procedure TProject.SetTemplate(AFileName: String);
begin
end;

// ---------------------------------------------------------------------------
// \brief This function extracts the Topic Caption/Titel of the given String.
// ---------------------------------------------------------------------------
function ExtractTitel(const TOCString: String): String;
var
  posSpace: Integer;
begin
  // -------------------------------------
  // find white space after numbering ...
  // -------------------------------------
  posSpace := Pos(' ', TOCString);
  if posSpace > 0 then
  Result := Copy(TOCString, posSpace + 1, Length(TOCString)) else
  
  // --------------------
  // if no white space...
  // --------------------
  Result := TOCString;
end;

// ---------------------------------------------------------------------------
// \brief This function create the Table of Contents (TOC).
// ---------------------------------------------------------------------------
procedure CreateTableOfContents;
var i, p, g: Integer;
begin
  HelpNDoc_default := TProject.Create('F:\default9');
  try
    print('1. pre-processing data...');
    //HelpNDoc_default.SetTemplate(HelpNDocTemplateHTM);

    HelpNDoc_default.AddTopic('Syntax Diagramme');
    HelpNDoc_default.AddTopic('Über die Sprache Pascal');
    HelpNDoc_default.AddTopic('1.  Pascal Zeichen und Symbole');
    HelpNDoc_default.AddTopic('1.1  Symbole');
    HelpNDoc_default.AddTopic('1.2  Kommentare');
    HelpNDoc_default.AddTopic('1.3  Reservierte Schlüsselwörter');
    HelpNDoc_default.AddTopic('1.3.1.  Turbo Pascal');

  finally
    print('3.  clean up memory...');
    
    HelpNDoc_default.Free;
    //HelpNDoc_default := nil;
    
    print('4.  done.');
  end;
end;
begin
  try
    try
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
