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
  inherited Create;
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
  inherited Create;
  
  TopicTitle  := AName;
  TopicLevel  := ALevel;
  TopicID     := HndTopics.CreateTopic;
  
  HndTopics.SetCurrentTopic(TopicID);
  HndTopics.SetTopicCaption(TopicID, TopicTitle);
  MoveRight;
  
  TopicEditor := TEditor.Create;
end;

// ---------------------------------------------------------------------------
// \brief This is a overloaded constructor for class TTopic. It creates a new
//         fresh Topic if the given AName, and a indent which is automatically
//         filled in.
// ---------------------------------------------------------------------------
constructor TTopic.Create(AName: String);
begin
  inherited Create;
  
  TopicTitle  := AName;
  TopicLevel  := GetLevel(TopicTitle);
  TopicID     := HndTopics.CreateTopic;
  
  HndTopics.SetCurrentTopic(TopicID);
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
  if TopicLevel >= 0 then
  begin
    for idx := 0 to TopicLevel-1 do
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
  inherited Create;
  
  try
    Title     := AName;
    //ID        := HndProjects.NewProject(AName);
    FLangCode := 'en-us';
    
    HndProjects.SetProjectModified(True);
    HndProjects.SetProjectLanguage(850);
    //HndProjects.SaveProject;
  except
    on E: Exception do
    raise Exception.Create('Project file could not be created.');
  end;
end;

// ---------------------------------------------------------------------------
// \brief This is the overloaded constructor to create a new Project with the
//         default settings.
// ---------------------------------------------------------------------------
constructor TProject.Create;
begin
  inherited Create;
  
  try
    Title     := 'default.hnd';
    //ID        := HndProjects.NewProject(Title);
    FLangCode := 'en-us';
    
    HndProjects.SetProjectModified(True);
    HndProjects.SetProjectLanguage(850);
    //HndProjects.SaveProject;
  except
    on E: Exception do
    raise Exception.Create('Error: project could not be loaded.');
  end;
end;

// ---------------------------------------------------------------------------
// \brief This is the destructor of class TProject. Here we try to remove so
//         much memory as possible is allocated before.
// ---------------------------------------------------------------------------
destructor TProject.Destroy;
var index: Integer;
begin
  CleanUp;
  
  //HndProjects.CloseProject;
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
    Topic.LoadFromFile(HelpNDocProjectPath + '\' + HelpNDocTemplateHTM);
    
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
// \brief  This function create a fresh new Project. If a Project with the
//         name already exists, then it will be overwrite !
//
// \param  projectName - String: The name of the Project.
// ---------------------------------------------------------------------------
procedure CreateProject(const projectName: String);
var projectID: String;
begin
  HelpNDoc_default := TProject.Create(projectName);
end;

// ---------------------------------------------------------------------------
// \brief This function create the Table of Contents (TOC).
// ---------------------------------------------------------------------------
procedure CreateTableOfContents;
var i, p, g: Integer;
begin
  HelpNDoc_default := TProject.Create('default');
  try
    print('1. pre-processing data...');
    HelpNDoc_default.SetTemplate(HelpNDocTemplateHTM);

    HelpNDoc_default.AddTopic('Lizenz - Bitte lesen !!!');
    HelpNDoc_default.AddTopic('Überblich');
    HelpNDoc_default.AddTopic('Inhalt');
    HelpNDoc_default.AddTopic('Liste der Tabellen');
    HelpNDoc_default.AddTopic('Über dieses Handbuch');
    HelpNDoc_default.AddTopic('Bezeichnungen');
    HelpNDoc_default.AddTopic('Syntax Diagramme');
    HelpNDoc_default.AddTopic('Über die Sprache Pascal');
    HelpNDoc_default.AddTopic('1.  Pascal Zeichen und Symbole');
    HelpNDoc_default.AddTopic('1.1  Symbole');
    HelpNDoc_default.AddTopic('1.2  Kommentare');
    HelpNDoc_default.AddTopic('1.3  Reservierte Schlüsselwörter');
    HelpNDoc_default.AddTopic('1.3.1.  Turbo Pascal');
    HelpNDoc_default.AddTopic('1.3.2.  Object Pascal');
    HelpNDoc_default.AddTopic('1.3.3.  Modifikationen');
    HelpNDoc_default.AddTopic('1.4.  Kennzeichnungen');
    HelpNDoc_default.AddTopic('1.5.  Hinweise und Direktiven');
    HelpNDoc_default.AddTopic('1.6.  Zahlen');
    HelpNDoc_default.AddTopic('1.7.  Bezeichner');
    HelpNDoc_default.AddTopic('1.8.  Zeichenketten');
    HelpNDoc_default.AddTopic('2.  Konstanten');
    HelpNDoc_default.AddTopic('2.1.  Gewöhnliche Konstanten');
    HelpNDoc_default.AddTopic('2.2.  Typisierte Konstanten');
    HelpNDoc_default.AddTopic('2.3.  Resourcen Zeichenketten');
    HelpNDoc_default.AddTopic('3.  Typen');
    HelpNDoc_default.AddTopic('3.1.  Basistypen');
    HelpNDoc_default.AddTopic('3.1.1.  Ordinale Typen');
    HelpNDoc_default.AddTopic('3.1.2.  Ganze Zahlen (Integer)');
    HelpNDoc_default.AddTopic('3.1.3.  Boolesche Typen');
    HelpNDoc_default.AddTopic('3.1.4.  Aufzählungen');
    HelpNDoc_default.AddTopic('3.1.5.  Untermengen');
    HelpNDoc_default.AddTopic('3.1.6.  Zeichen');
    HelpNDoc_default.AddTopic('3.2.  Zeichen-Typen');
    HelpNDoc_default.AddTopic('3.2.1.  Char oder AnsiChar');
    HelpNDoc_default.AddTopic('3.2.2.  WideChar');
    HelpNDoc_default.AddTopic('3.2.3.  Sonstige');
    HelpNDoc_default.AddTopic('3.2.4.  Einzel-Byte Zeichenketten');
    HelpNDoc_default.AddTopic('3.2.4.1.  ShortString');
    HelpNDoc_default.AddTopic('3.2.4.2.  AnsiString');
    HelpNDoc_default.AddTopic('3.2.4.3.  Zeichen-Code Umwandlung');
    HelpNDoc_default.AddTopic('3.2.4.4.  RawByteString');
    HelpNDoc_default.AddTopic('3.2.4.5.  UTF8String');
    HelpNDoc_default.AddTopic('3.2.5.  Multi-Byte Zeichenketten');
    HelpNDoc_default.AddTopic('3.2.5.1.  UnicodeString');
    HelpNDoc_default.AddTopic('3.2.5.2.  WideString');
    HelpNDoc_default.AddTopic('3.2.6.  Konstante Zeichenketten');
    HelpNDoc_default.AddTopic('3.2.7.  Nullterminierente Zeichenketten (PChar)');
    HelpNDoc_default.AddTopic('3.2.8.  Zeichenketten-Größen');
    HelpNDoc_default.AddTopic('3.3.  Strukturierte Typen');
    HelpNDoc_default.AddTopic('3.3.1.  Gepackte Struktur-Typen');
    HelpNDoc_default.AddTopic('3.3.2.  Array''s');
    HelpNDoc_default.AddTopic('3.3.2.1.  Statische Array''s');
    HelpNDoc_default.AddTopic('3.3.2.2.  Dynamische Array''s');
    HelpNDoc_default.AddTopic('3.3.2.3:  Typen-Kompatibilität dynamischer Array''s');
    HelpNDoc_default.AddTopic('3.3.2.4.  Constuctor dynamischer Array''s');
    HelpNDoc_default.AddTopic('3.3.2.5.  Feldkonstanten-Ausdrücke dynamiscer Array''s');
    HelpNDoc_default.AddTopic('3.3.2.6.  Packen und Entpacken eines Array''s');
    HelpNDoc_default.AddTopic('3.3.3.  Record''s');
    HelpNDoc_default.AddTopic('3.3.3.1.  Layout und Größe');
    HelpNDoc_default.AddTopic('3.3.3.2.  Bemerkungen und Beispiele');
    HelpNDoc_default.AddTopic('3.3.4.  Mengen-Typen');
    HelpNDoc_default.AddTopic('3.3.5.  Datei-Typen');
    HelpNDoc_default.AddTopic('3.4.  Zeiger');
    HelpNDoc_default.AddTopic('3.5.  Forward-Deklarationen');
    HelpNDoc_default.AddTopic('3.6.  Prozedur-Typen');
    HelpNDoc_default.AddTopic('3.7.  Variant''s');
    HelpNDoc_default.AddTopic('3.7.1.  Definition');
    HelpNDoc_default.AddTopic('3.7.2.  Variant''s in Zuweisungen und Ausdrücken');
    HelpNDoc_default.AddTopic('3.7.3.  Variant''s im Interface-Teil');
    HelpNDoc_default.AddTopic('3.8.  Alias-Typen');
    HelpNDoc_default.AddTopic('3.9.  Verwaltete Typen');
    HelpNDoc_default.AddTopic('4.  Variablen');
    HelpNDoc_default.AddTopic('4.1.  Definition');
    HelpNDoc_default.AddTopic('4.2.  Erklärung');
    HelpNDoc_default.AddTopic('4.3.  Geltungssbereich');
    HelpNDoc_default.AddTopic('4.4.  Initialisierte Variablen');
    HelpNDoc_default.AddTopic('4.5.  Initialisierte Variablen mit Standard-Wert');
    HelpNDoc_default.AddTopic('4.6.  Thread-Variablen');
    HelpNDoc_default.AddTopic('4.7.  Eigenschaften');
    HelpNDoc_default.AddTopic('5.  Objekte');
    HelpNDoc_default.AddTopic('5.1.  Deklaration');
    HelpNDoc_default.AddTopic('5.2.  Abtrakte und Sealed Objekte');
    HelpNDoc_default.AddTopic('5.3.  Felder');
    HelpNDoc_default.AddTopic('5.4.  Klassen oder statische Felder');
    HelpNDoc_default.AddTopic('5.5.  Constructor und Destructor');
    HelpNDoc_default.AddTopic('5.6.  Methoden');
    HelpNDoc_default.AddTopic('5.6.1.  Erklärung');
    HelpNDoc_default.AddTopic('5.6.2.  Methoden-Aufruf');
    HelpNDoc_default.AddTopic('5.6.2.1.  Statische Methoden');
    HelpNDoc_default.AddTopic('5.6.2.2.  Virtuelle Methoden');
    HelpNDoc_default.AddTopic('5.6.2.3.  Abstrakte Methoden');
    HelpNDoc_default.AddTopic('5.6.2.4.  Klassen-Methoden oder statische Methoden');
    HelpNDoc_default.AddTopic('5.7.  Sichtbarkeit');
    HelpNDoc_default.AddTopic('6.  Klassen');
    HelpNDoc_default.AddTopic('6.1.  Klassen-Definitionen');
    HelpNDoc_default.AddTopic('6.2.  Abstrakte und Sealed Klassen');
    HelpNDoc_default.AddTopic('6.3.  Normale und statische Felder');
    HelpNDoc_default.AddTopic('6.3.1.  Normalisierte Felder / Variablen');
    HelpNDoc_default.AddTopic('6.3.2.  Klassen-Felder / Variablen');
    HelpNDoc_default.AddTopic('6.4.  Klassen - CTOR (constructor)');
    HelpNDoc_default.AddTopic('6.5.  Klassen - DTOR (destructor)');
    HelpNDoc_default.AddTopic('6.6.  Methoden');
    HelpNDoc_default.AddTopic('6.6.1.  Erklärung');
    HelpNDoc_default.AddTopic('6.6.2.  Aufrufen');
    HelpNDoc_default.AddTopic('6.6.3.  Virtuelle Methoden');
    HelpNDoc_default.AddTopic('6.6.4.  Klassen - Methoden');
    HelpNDoc_default.AddTopic('6.6.5.  Klassen CTOR und DTOR');
    HelpNDoc_default.AddTopic('6.6.6.  Statische Klassen - Methoden');
    HelpNDoc_default.AddTopic('6.6.7.  Nachrichten - Methoden');
    HelpNDoc_default.AddTopic('6.6.8.  Vererbung');
    HelpNDoc_default.AddTopic('6.7.  Eigenschaften');
    HelpNDoc_default.AddTopic('6.7.1.  Definition');
    HelpNDoc_default.AddTopic('6.7.2.  Indezierte Eigenschaften');
    HelpNDoc_default.AddTopic('6.7.3.  Array basierte Eigenschaften');
    HelpNDoc_default.AddTopic('6.7.4.  Standard - Eigenschaften (public)');
    HelpNDoc_default.AddTopic('6.7.5.  Veröffentlichte - Eigenschaften (published)');
    HelpNDoc_default.AddTopic('6.7.6.  Speicherinformationen');
    HelpNDoc_default.AddTopic('6.7.7.  Eigenschaften überschreiben und neu deklarieren');
    HelpNDoc_default.AddTopic('6.8.  Klassen - Eigenschaften');
    HelpNDoc_default.AddTopic('6.9.  Verschachtelte Typen, Konstanten, und Variablen');
    HelpNDoc_default.AddTopic('7.  Schnittstellen (Interface''s)');
    HelpNDoc_default.AddTopic('7.1.  Definition');
    HelpNDoc_default.AddTopic('7.2.  Identifikation');
    HelpNDoc_default.AddTopic('7.3.  Implementierung');
    HelpNDoc_default.AddTopic('7.4.  Vererbung');
    HelpNDoc_default.AddTopic('7.5.  Delegation');
    HelpNDoc_default.AddTopic('7.6.  COM');
    HelpNDoc_default.AddTopic('7.7.  CORBA und andere Schnittstellen');
    HelpNDoc_default.AddTopic('7.8.  Referenzzählung');
    HelpNDoc_default.AddTopic('8.  Generics');
    HelpNDoc_default.AddTopic('8.1.  Einführung');
    HelpNDoc_default.AddTopic('8.2.  Get''ter Typ - Definition');
    HelpNDoc_default.AddTopic('8.3.  Typen - Spezialisierung');
    HelpNDoc_default.AddTopic('8.4.  Einschränkungen');
    HelpNDoc_default.AddTopic('8.5.  Kompatibilität zu Delphi');
    HelpNDoc_default.AddTopic('8.5.1.  Syntax - Elemente');
    HelpNDoc_default.AddTopic('8.5.2.  Einschränkungen für Record''s');
    HelpNDoc_default.AddTopic('8.5.3.  Typen - Überladung(en)');
    HelpNDoc_default.AddTopic('8.5.4.  Überlegungen für Namensbereiche');
    HelpNDoc_default.AddTopic('8.6.  Typen-Kompatibilität');
    HelpNDoc_default.AddTopic('8.7.  Verwendung der eingebauten Funktionen');
    HelpNDoc_default.AddTopic('8.8.  Überlegungen zum Geltungsbereich');
    HelpNDoc_default.AddTopic('8.9.  Operator-Überladung und Generics');
    HelpNDoc_default.AddTopic('9.  Erweiterte Record''s');
    HelpNDoc_default.AddTopic('9.1.  Definition');
    HelpNDoc_default.AddTopic('9.2.  Erweiterte Record-Aufzähler');
    HelpNDoc_default.AddTopic('9.3.  Record-Operationen');
    HelpNDoc_default.AddTopic('10.  Klassen, Record''s, und Typen-Helfer');
    HelpNDoc_default.AddTopic('10.1.  Definition');
    HelpNDoc_default.AddTopic('10.2.  Einschränkungen bei Klassen Helfer');
    HelpNDoc_default.AddTopic('10.3.  Einschränkungen bei Record  Helfer');
    HelpNDoc_default.AddTopic('10.4.  Überlegungen zu einfachen Helper');
    HelpNDoc_default.AddTopic('10.5.  Anmerkungen zu Umfang und Lebensdauer von Record-Helper');
    HelpNDoc_default.AddTopic('10.6.  Vererbung');
    HelpNDoc_default.AddTopic('10.7.  Verwendung');
    HelpNDoc_default.AddTopic('11.  Objektorientierte Pascal - Klassen');
    HelpNDoc_default.AddTopic('11.1.  Einführung');
    HelpNDoc_default.AddTopic('11.2.  Klassendeklarationen');
    HelpNDoc_default.AddTopic('11.3.  Formele Deklaration');
    HelpNDoc_default.AddTopic('11.4.  Instanzen zuteilen und zuordnen');
    HelpNDoc_default.AddTopic('11.5.  Protokolldefinitionen');
    HelpNDoc_default.AddTopic('11.6.  Kategorien');
    HelpNDoc_default.AddTopic('11.7.  Namensumfang und Bezeichner');
    HelpNDoc_default.AddTopic('11.8.  Selektoren');
    HelpNDoc_default.AddTopic('11.9.  Der ID Typ');
    HelpNDoc_default.AddTopic('11.10. Aufzählungen in Objective-C Klassen');
    HelpNDoc_default.AddTopic('12.  Ausdrücke');
    HelpNDoc_default.AddTopic('12.1.  Ausdrucks - Syntax');
    HelpNDoc_default.AddTopic('12.2.  Funktionsaufrufe');
    HelpNDoc_default.AddTopic('12.3.  Mengen - CTOR');
    HelpNDoc_default.AddTopic('12.4.  Typ-Casting von Werten');
    HelpNDoc_default.AddTopic('12.5.  Typ-Casting von Variablen');
    HelpNDoc_default.AddTopic('12.6.  Sonstige Typ-Casting''s');
    HelpNDoc_default.AddTopic('12.7.  Der @ - Operator');
    HelpNDoc_default.AddTopic('12.8.  Operatoren');
    HelpNDoc_default.AddTopic('12.8.1.  Arithmetische Operatoren');
    HelpNDoc_default.AddTopic('12.8.2.  Logische Operatoren');
    HelpNDoc_default.AddTopic('12.8.3.  Boolesche Operatoren');
    HelpNDoc_default.AddTopic('12.8.4.  Zeichenketten Operatoren');
    HelpNDoc_default.AddTopic('12.8.5.  Operatoren bei dynamischen Array''s');
    HelpNDoc_default.AddTopic('12.8.6.  Mengen - Operatoren');
    HelpNDoc_default.AddTopic('12.8.7.  Relationale Operatoren');
    HelpNDoc_default.AddTopic('12.8.8.  Klassen - Operatoren');
    HelpNDoc_default.AddTopic('13.  Anweisungen');
    HelpNDoc_default.AddTopic('13.1.  Einfache Anweisungen');
    HelpNDoc_default.AddTopic('13.1.1.  Zuweisungen');
    HelpNDoc_default.AddTopic('13.1.2.  Prozeduren - PROCEDURE');
    HelpNDoc_default.AddTopic('13.1.3.  Sprungs - Anweisung GOTO');
    HelpNDoc_default.AddTopic('13.2.  Strukturierte Anweisungen');
    HelpNDoc_default.AddTopic('13.2.1.  Zusammengesetzte Anweisungen');
    HelpNDoc_default.AddTopic('13.2.2.  CASE');
    HelpNDoc_default.AddTopic('13.2.3.  IF ... THEN');
    HelpNDoc_default.AddTopic('13.2.4.  FOR ... TO / DOWNTO ... DO');
    HelpNDoc_default.AddTopic('13.2.5.  FOR .. IN .. DO');
    HelpNDoc_default.AddTopic('13.2.6.  REPEAT ... UNTIL');
    HelpNDoc_default.AddTopic('13.2.7.  WHILE ... DO');
    HelpNDoc_default.AddTopic('13.2.8.  WITH');
    HelpNDoc_default.AddTopic('13.2.9.  Ausnahmen (EXCEPT)');
    HelpNDoc_default.AddTopic('13.3.  Assembler Anweisungen');
    HelpNDoc_default.AddTopic('14.  Benutzung von Funktionen und Prozeduren');
    HelpNDoc_default.AddTopic('14.1.  FUNCTION Deklarationen');
    HelpNDoc_default.AddTopic('14.2.  PROCEDURE Deklarationen');
    HelpNDoc_default.AddTopic('14.3.  Funktion Rückgabewert mittels RESULT');
    HelpNDoc_default.AddTopic('14.4.  Parameter Listen');
    HelpNDoc_default.AddTopic('14.4.1.  Werte');
    HelpNDoc_default.AddTopic('14.4.2.  Variablen');
    HelpNDoc_default.AddTopic('14.4.3.  Ausgabe Parameter');
    HelpNDoc_default.AddTopic('14.4.4.  Konstante Parameter');
    HelpNDoc_default.AddTopic('14.4.5.  Offene Array''s');
    HelpNDoc_default.AddTopic('14.4.6.  Array of Const');
    HelpNDoc_default.AddTopic('14.4.7.  Untypisierte Parameter');
    HelpNDoc_default.AddTopic('14.4.8.  Verwaltete Typen und Referenzzähler');
    HelpNDoc_default.AddTopic('14.5.  Überladung von Funktionen');
    HelpNDoc_default.AddTopic('14.6.  Mit FORWARD deklarierte Funktionen');
    HelpNDoc_default.AddTopic('14.7.  Externe Funktionen');
    HelpNDoc_default.AddTopic('14.8.  Assembler Funktionen');
    HelpNDoc_default.AddTopic('14.9.  Modifikatoren');
    HelpNDoc_default.AddTopic('14.9.1.  alias');
    HelpNDoc_default.AddTopic('14.9.2.  cdecl');
    HelpNDoc_default.AddTopic('14.9.3.  cppdecl');
    HelpNDoc_default.AddTopic('14.9.4.  export');
    HelpNDoc_default.AddTopic('14.9.5.  hardfloat');
    HelpNDoc_default.AddTopic('14.9.6.  inline');
    HelpNDoc_default.AddTopic('14.9.7.  interrupt');
    HelpNDoc_default.AddTopic('14.9.8.  iocheck');
    HelpNDoc_default.AddTopic('14.9.9.  local');
    HelpNDoc_default.AddTopic('14.9.10.  MS_ABI_Default');
    HelpNDoc_default.AddTopic('14.9.11.  MS_ABI_CDecl');
    HelpNDoc_default.AddTopic('14.9.12.  MWPascal');
    HelpNDoc_default.AddTopic('14.9.13.  noreturn');
    HelpNDoc_default.AddTopic('14.9.14.  nostackframe');
    HelpNDoc_default.AddTopic('14.9.15.  overload');
    HelpNDoc_default.AddTopic('14.9.16.  pascal');
    HelpNDoc_default.AddTopic('14.9.17.  public');
    HelpNDoc_default.AddTopic('14.9.18.  register');
    HelpNDoc_default.AddTopic('14.9.19.  safecall');
    HelpNDoc_default.AddTopic('14.9.20.  saveregisters');
    HelpNDoc_default.AddTopic('14.9.21.  softfloat');
    HelpNDoc_default.AddTopic('14.9.22.  stdcall');
    HelpNDoc_default.AddTopic('14.9.23.  SYSV_ABI_Default');
    HelpNDoc_default.AddTopic('14.9.24.  SYSV_ABI_CDecl');
    HelpNDoc_default.AddTopic('14.9.25.  VectorCall');
    HelpNDoc_default.AddTopic('14.9.26.  varargs');
    HelpNDoc_default.AddTopic('14.9.27.  winapi');
    HelpNDoc_default.AddTopic('14.10.  Nicht unterstützte Modifikatoren');
    HelpNDoc_default.AddTopic('15.  Operatoren Überladung');
    HelpNDoc_default.AddTopic('15.1.  Einleitung');
    HelpNDoc_default.AddTopic('15.2.  Operatoren - Deklarationen');
    HelpNDoc_default.AddTopic('15.3.  Operator - Zuweisung');
    HelpNDoc_default.AddTopic('15.4.  Arithmetische Operatoren');
    HelpNDoc_default.AddTopic('15.5.  Vergleichende Operatoren');
    HelpNDoc_default.AddTopic('15.6.  In Operator');
    HelpNDoc_default.AddTopic('15.7.  Logik Operatoren');
    HelpNDoc_default.AddTopic('15.8.  Auf- und Ab-Zählungs Operatoren');
    HelpNDoc_default.AddTopic('15.9.  Aufzählungs - Operator');
    HelpNDoc_default.AddTopic('16.  Programme, Module und Blöcke');
    HelpNDoc_default.AddTopic('16.1.  Programme');
    HelpNDoc_default.AddTopic('16.2.  Module (Unit''s)');
    HelpNDoc_default.AddTopic('16.3.  Namensräume');
    HelpNDoc_default.AddTopic('16.4.  Abhängigkeiten von Modulen');
    HelpNDoc_default.AddTopic('16.5.  Blöcke');
    HelpNDoc_default.AddTopic('16.6.  Anwendungsbereiche (Scope)');
    HelpNDoc_default.AddTopic('16.6.1.  Blöcke');
    HelpNDoc_default.AddTopic('16.6.2.  Record''s');
    HelpNDoc_default.AddTopic('16.6.3.  Klassen');
    HelpNDoc_default.AddTopic('16.6.4.  Unit''s');
    HelpNDoc_default.AddTopic('16.7.  Bibliotheken');
    HelpNDoc_default.AddTopic('17.  Ausnahmen');
    HelpNDoc_default.AddTopic('17.1.  Die RAISE Anweisung');
    HelpNDoc_default.AddTopic('17.2.  Ausnahme-Behandlung und Verschachtelung');
    HelpNDoc_default.AddTopic('18.  Assembler');
    HelpNDoc_default.AddTopic('18.1.  Anweisungen');
    HelpNDoc_default.AddTopic('18.2.  Prozeduren und Funktionen');
    HelpNDoc_default.AddTopic('Anhang');
    HelpNDoc_default.AddTopic('Syntax');

  finally
    print('3.  clean up memory...');
    
    HelpNDoc_default.Free;
    HelpNDoc_default := nil;
    
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
