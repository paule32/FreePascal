{$mode ObjFPC}{$H+}
unit xmlstream;
interface
uses
  Classes, SysUtils, DOM, XMLRead, XMLWrite;

type
  TInfoObject = class
  private
    FName: string;
    FAge: Integer;
    FMemo: TStringList; // Memo-Text als TStringList
  public
    constructor Create(AName: string = ''; AAge: Integer = 0; AMemo: string = '');
    destructor Destroy; override;
    procedure ShowInfo;
    function GetMemoAsString: string;
    procedure SetMemoFromString(const MemoText: string);
  end;

  TInfoObjectList = class
  private
    FList: TList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddInfoObject(AInfoObject: TInfoObject);
    procedure SaveToXML(const Filename: string);
    procedure LoadFromXML(const Filename: string);
  end;

implementation

{ TPerson Implementierung }

constructor TInfoObject.Create(AName: string; AAge: Integer; AMemo: string);
begin
  FName := AName;
  FAge := AAge;
  FMemo := TStringList.Create;

  SetMemoFromString(AMemo);
end;

destructor TInfoObject.Destroy;
begin
  FMemo.Free;
  inherited Destroy;
end;

procedure TInfoObject.ShowInfo;
begin
  WriteLn('Name: ', FName, ', Alter: ', FAge);
  WriteLn('Memo:');
  WriteLn(FMemo.Text);
end;

// Wandelt den Memo-Text in eine einzige Zeichenkette um
function TInfoObject.GetMemoAsString: string;
begin
  Result := FMemo.Text;
end;

// Setzt den Memo-Text aus einer Zeichenkette
procedure TInfoObject.SetMemoFromString(const MemoText: string);
begin
  FMemo.Text := MemoText;
end;

{ TPersonList Implementierung }
constructor TInfoObjectList.Create;
begin
  FList := TList.Create;
end;

destructor TInfoObjectList.Destroy;
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
    TObject(FList[I]).Free;
  FList.Free;
  inherited Destroy;
end;

procedure TInfoObjectList.AddInfoObject(AInfoObject: TInfoObject);
begin
  FList.Add(AInfoObject);
end;

procedure TInfoObjectList.SaveToXML(const Filename: string);
var
  Doc: TXMLDocument;
  RootNode, InfoObjectNode, MemoNode: TDOMElement;
  I: Integer;
  InfoObj: TInfoObject;
begin
  Doc := TXMLDocument.Create;
  try
    RootNode := Doc.CreateElement('Object');
    Doc.AppendChild(RootNode);

    for I := 0 to FList.Count - 1 do
    begin
      InfoObj := TInfoObject(FList[I]);
      InfoObjectNode := Doc.CreateElement('Object');
      InfoObjectNode.SetAttribute('Name', InfoObj.FName);
      InfoObjectNode.SetAttribute('Age', IntToStr(InfoObj.FAge));

      // Memo-Abschnitt als separates XML-Element hinzufügen
      MemoNode := Doc.CreateElement('Memo');
      MemoNode.AppendChild(Doc.CreateTextNode(InfoObj.GetMemoAsString));
      InfoObjectNode.AppendChild(MemoNode);

      RootNode.AppendChild(InfoObjectNode);
    end;

    WriteXMLFile(Doc, Filename);
  finally
    Doc.Free;
  end;
end;

procedure TInfoObjectList.LoadFromXML(const Filename: string);
var
  Doc: TXMLDocument;
  RootNode, InfoObjectNode, MemoNode: TDOMNode;
  InfoObj: TInfoObject;
begin
  // Erst alte Liste leeren
  while FList.Count > 0 do
  begin
    TObject(FList.Last).Free;
    FList.Delete(FList.Count - 1);
  end;

  ReadXMLFile(Doc, Filename);
  try
    RootNode := Doc.DocumentElement;
    InfoObjectNode := RootNode.FirstChild;

    while Assigned(InfoObjectNode) do
    begin
      if InfoObjectNode.NodeName = 'Object' then
      begin
        InfoObj := TInfoObject.Create;
        InfoObj.FName := InfoObjectNode.Attributes.GetNamedItem('Name').NodeValue;
        InfoObj.FAge := StrToIntDef(InfoObjectNode.Attributes.GetNamedItem('Age').NodeValue, 0);

        // Memo-Text auslesen
        MemoNode := InfoObjectNode.FindNode('Memo');
        if Assigned(MemoNode) then
          InfoObj.SetMemoFromString(MemoNode.TextContent);

        AddInfoObject(InfoObj);
      end;
      InfoObjectNode := InfoObjectNode.NextSibling;
    end;
  finally
    Doc.Free;
  end;
end;

end.

