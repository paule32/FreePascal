unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  Menus, ExtCtrls, Buttons, MaskEdit, ButtonPanel, CheckLst, SynEdit,
  SynPopupMenu, SynHighlighterHTML, LCLType;

type
  TNodeInfo = class
    TopicText: String;
    TopicRef : String;
  end;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    btnAddNode: TButton;
    btnDelNode: TButton;
    checkList: TCheckListBox;
    edTopicName: TEdit;
    edProjectName: TEdit;
    edProjectAutor: TEdit;
    edProjectPath: TEdit;
    ImageList1: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    MainMenu1: TMainMenu;
    edTopicRef: TMaskEdit;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    ProgressBar1: TProgressBar;
    ScrollBar1: TScrollBar;
    ScrollBox1: TScrollBox;
    ScrollBox2: TScrollBox;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    Separator1: TMenuItem;
    Separator2: TMenuItem;
    sbHeader: TSpeedButton;
    sbLeft: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    sbContent: TSpeedButton;
    sbFooter: TSpeedButton;
    sbDown: TSpeedButton;
    sbUp: TSpeedButton;
    sbRight: TSpeedButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    StatusBar1: TStatusBar;
    SynEdit1: TSynEdit;
    SynHTMLSyn1: TSynHTMLSyn;
    SynPopupMenu1: TSynPopupMenu;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    ToolBar1: TToolBar;
    sbNew: TToolButton;
    sbOpen: TToolButton;
    sbSaveAs: TToolButton;
    TopicTree: TTreeView;
    procedure btnAddNodeClick(Sender: TObject);
    procedure btnDelNodeClick(Sender: TObject);
    procedure checkListClickCheck(Sender: TObject);
    procedure edProjectPathChange(Sender: TObject);
    procedure edTopicNameChange(Sender: TObject);
    procedure edTopicNameKeyPress(Sender: TObject; var Key: char);
    procedure edTopicRefChange(Sender: TObject);
    procedure edTopicRefKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);
    procedure MenuItem13Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure sbDownClick(Sender: TObject);
    procedure sbHeaderClick(Sender: TObject);
    procedure sbLeftClick(Sender: TObject);
    procedure sbRightClick(Sender: TObject);
    procedure sbUpClick(Sender: TObject);
    procedure setSpeedButtonFontColor(Sender: TObject);
    procedure sbContentClick(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure sbFooterClick(Sender: TObject);
    procedure TopicTreeClick(Sender: TObject);
  private
    UpdatingNumbers: Integer; // Zählt, wie oft die Nummerierung aktiv ist
    procedure checkText;
    procedure MoveNodeUp(Node: TTreeNode);
    procedure MoveNodeDown(Node: TTreeNode);
    procedure MoveNodeLeft(Node: TTreeNode);
    procedure MoveNodeRight(Node: TTreeNode);
    procedure UpdateAllCaptions;
    procedure UpdateTreeViewNumbers;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

uses
  {$IFDEF WINDOWS} Windows {$ENDIF},
  GetText, Translations, DefaultTranslator, LCLTranslator,
  Resource, LResources, globals,
  about;

procedure StoreNodeText(Node: TTreeNode);
var
  TextPtr: PString;
begin
  if Assigned(Node) and (Node.Data = nil) then
  begin
    New(TextPtr);          // Speicher reservieren
    TextPtr^ := Node.Text; // Originaltext speichern
    Node.Data := TextPtr;  // Pointer in Data setzen
  end;
end;

function GetOrCreateRootNode(TreeView: TTreeView): TTreeNode;
begin
  if TreeView.Items.Count = 0 then
    Result := TreeView.Items.Add(nil, 'Hauptthema') // Erstelle Root-Node
  else
    Result := TreeView.Items[0]; // Erste (und einzige) Root-Node abrufen
end;

procedure AddNodeWithHiddenObject(
  TreeView: TTreeView;
  const NodeText: String;
  const TopicRef: string);
var
  NewNode, ParentNode: TTreeNode;
  Info: TNodeInfo;
begin
  if Assigned(TreeView.Selected) then
  ParentNode := TreeView.Selected
  else
  begin
    // Falls keine Node existiert, eine Standard-Root-Node erstellen
    if TreeView.Items.Count = 0 then
      ParentNode := TreeView.Items.Add(nil, '[Themen-Baum]') // Root hinzufügen
    else
      ParentNode := TreeView.Items.GetFirstNode; // Erste Node als Parent verwenden
  end;

  // Neue Node als Child einfügen
  NewNode := TreeView.Items.AddChild(ParentNode, NodeText);

  // Datenobjekt hinzufügen
  Info := TNodeInfo.Create;
  Info.TopicText := NodeText;
  Info.TopicRef := TopicRef;
  NewNode.Data := Info;

  // Setzt das Icon basierend auf der Node-Tiefe
  if ParentNode = nil then
  NewNode.ImageIndex := 0  else
  NewNode.ImageIndex := 1;

  // Gleiche Icons für Auswahl setzen (optional)
  NewNode.SelectedIndex := NewNode.ImageIndex;

  // Neue Node auswählen
  TreeView.Selected := NewNode;
end;

function GetHiddenObjectRef(Node: TTreeNode): string;
var
  Info: TNodeInfo;
begin
  if Assigned(Node) and Assigned(Node.Data) then
  begin
    Info := TNodeInfo(Node.Data);
    Result := Info.TopicRef;
  end
  else
    Result := '';
end;

function GetHiddenObjectText(Node: TTreeNode): string;
var
  Info: TNodeInfo;
begin
  result := '';
  if Assigned(Node) and Assigned(Node.Data) then
  begin
    Info := TNodeInfo(Node.Data);
    Result := Info.TopicText;
  end;
end;

procedure FreeNodeObjects(TreeView: TTreeView);
var
  I: Integer;
begin
  for I := 0 to TreeView.Items.Count - 1 do
    if Assigned(TreeView.Items[I].Data) then
    begin
      TNodeInfo(TreeView.Items[I].Data).Free;
      TreeView.Items[I].Data := nil;
    end;
end;

{ TForm1 }

procedure TForm1.UpdateAllCaptions;
var
  i: Integer;
  Comp: TComponent;
begin
  for i := 0 to ComponentCount - 1 do
  begin
    Comp := Components[i];

    if Comp is TLabel       then TLabel      (Comp).Caption := tr(Comp.Name);
    if Comp is TButton      then TButton     (Comp).Caption := tr(Comp.Name);
    if Comp is TMenuItem    then TMenuItem   (Comp).Caption := tr(Comp.Name);
    if Comp is TSpeedButton then TSpeedButton(Comp).Caption := tr(Comp.Name);
  end;
end;

// Verschiebt die Node nach oben
procedure TForm1.MoveNodeUp(Node: TTreeNode);
var
  PrevNode: TTreeNode;
begin
  if not Assigned(Node) or (Node.Parent = nil) then Exit;

  PrevNode := Node.GetPrevSibling;
  if Assigned(PrevNode) then
  begin
    TopicTree.Items.BeginUpdate;
    try
      Node.MoveTo(PrevNode, naInsert);
      TopicTree.Selected := Node;
    finally
      TopicTree.Items.EndUpdate;
    end;
    UpdateTreeViewNumbers; // Nummerierung nach der Bewegung neu setzen
  end;
end;

procedure TForm1.MoveNodeDown(Node: TTreeNode);
var
  NextNode: TTreeNode;
begin
  if not Assigned(Node) or (Node.Parent = nil) then Exit;

  NextNode := Node.GetNextSibling;
  if Assigned(NextNode) then
  begin
    TopicTree.Items.BeginUpdate;
    try
      Node.MoveTo(NextNode, naInsertBehind);
      TopicTree.Selected := Node;
    finally
      TopicTree.Items.EndUpdate;
    end;
    UpdateTreeViewNumbers;
  end;
end;

procedure TForm1.MoveNodeLeft(Node: TTreeNode);
var
  ParentNode, RootNode: TTreeNode;
begin
  if not Assigned(Node) then Exit; // Keine gültige Node -> Abbrechen

  ParentNode := Node.Parent;
  RootNode := TopicTree.Items.GetFirstNode; // Erste (und einzige) Root-Node holen

  // Falls die Node bereits direkt unter der Root-Node ist, keine Verschiebung nach links erlauben
  if (ParentNode = RootNode) then Exit;

  // Falls die ParentNode ungültig oder bereits Root ist, darf nicht verschoben werden
  if (ParentNode = nil) or (ParentNode.Level = 0) then Exit;

  TopicTree.Items.BeginUpdate;
  try
    Node.MoveTo(ParentNode.Parent, naInsertBehind); // Eine Ebene nach oben verschieben
    TopicTree.Selected := Node; // Selektion beibehalten
  finally
    TopicTree.Items.EndUpdate;
  end;

  UpdateTreeViewNumbers;
end;

procedure TForm1.MoveNodeRight(Node: TTreeNode);
var
  PrevNode: TTreeNode;
begin
  if not Assigned(Node) then Exit;

  PrevNode := Node.GetPrevSibling;
  if Assigned(PrevNode) then
  begin
    TopicTree.Items.BeginUpdate;
    try
      Node.MoveTo(PrevNode, naAddChild);
      TopicTree.Selected := Node;
    finally
      TopicTree.Items.EndUpdate;
    end;
    UpdateTreeViewNumbers;
  end;
end;

procedure TForm1.edProjectPathChange(Sender: TObject);
begin

end;

procedure TForm1.btnAddNodeClick(Sender: TObject);
begin
  AddNodeWithHiddenObject(TopicTree, edTopicName.Text, edTopicRef.Text);
end;

procedure TForm1.btnDelNodeClick(Sender: TObject);
begin
  try
    // free allocated memory...
    if Assigned(TopicTree.Selected.Data) then
    begin
      TNodeInfo(TopicTree.Selected.Data).Free;
      TopicTree.Selected.Data := nil;
    end;

    TopicTree.Items.Delete(TopicTree.Selected);

    edTopicName.Text := '';
    edTopicRef.Text := '';

    btnAddNode.Enabled := false;
    btnDelNode.Enabled := false;
  except
    ShowMessage('No Item available/selected.');
  end;
end;

procedure TForm1.checkListClickCheck(Sender: TObject);
begin
  UpdateTreeViewNumbers;
end;

procedure TForm1.checkText;
begin
  if  (Length(Trim(edTopicName.Text)) < 1) then
  begin
    btnAddNode.Enabled := false;
    btnDelNode.Enabled := false;
    edTopicRef.Enabled := false;
    exit;
  end else
  begin
    edTopicRef.Enabled := true;
  end;
  if (Length(Trim(edTopicRef.Text)) < 1) then
  begin
    btnAddNode.Enabled := false;
    btnDelNode.Enabled := false;
    exit;
  end;
  btnAddNode.Enabled := true;
  btnDelNode.Enabled := true;
end;

procedure TForm1.edTopicNameChange(Sender: TObject);
var
  i: Integer;
  NewText: string;
begin
  checkText;
end;

procedure TForm1.edTopicNameKeyPress(Sender: TObject; var Key: char);
var
  info: TNodeInfo;
begin
  // Maximale Länge: 64 Zeichen
  if (Length(TMaskEdit(Sender).Text) >= 64) then
  Key := #0;

  if  (TopicTree.Selected <> nil)
  and (TopicTree.Selected.Text <> '[Topic Tree]')then
  begin
    info := TNodeInfo(TopicTree.Selected.Data);
    info.TopicText := edTopicName.Text;
  end;

  checkText;
end;

procedure TForm1.edTopicRefChange(Sender: TObject);
var
  i: Integer;
  NewText: string;
begin
  checkText;
end;

procedure TForm1.edTopicRefKeyPress(Sender: TObject; var Key: char);
var
  info: TNodeInfo;
begin
  if  (TopicTree.Selected <> nil)
  and (TopicTree.Selected.Text <> '[Themen-Baum]')then
  begin
    info := TNodeInfo(TopicTree.Selected.Data);
    info.TopicRef := edTopicRef.Text;
  end;

  checkText;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  sbHeader .Font.Color := clNavy;
  sbFooter .Font.Color := clNavy;
  sbContent.Font.Color := clNavy;

  motr := TMoTranslate.Create('de', false);
  UpdateAllCaptions;
  CheckList.Color := HexToTColor('f9f9f9');
end;

procedure TForm1.MenuItem12Click(Sender: TObject);
begin
  motr.Free;
  motr := TMoTranslate.Create('en');
  UpdateAllCaptions;
end;

procedure TForm1.MenuItem13Click(Sender: TObject);
begin
  motr.Free;
  motr := TMoTranslate.Create('de');
  UpdateAllCaptions;
end;

procedure TForm1.MenuItem2Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.MenuItem9Click(Sender: TObject);
begin
  Application.CreateForm(TAboutForm, AboutForm);
  AboutForm.ShowModal;
  AboutForm.Free;
end;

procedure TForm1.setSpeedButtonFontColor(Sender: TObject);
begin
  sbHeader .Font.Color := clNavy;
  sbFooter .Font.Color := clNavy;
  sbContent.Font.Color := clNavy;
end;

procedure TForm1.sbDownClick(Sender: TObject);
begin
  if Assigned(TopicTree.Selected) then
  begin
    MoveNodeDown(TopicTree.Selected);
  end;
end;

procedure TForm1.sbHeaderClick(Sender: TObject);
begin
  setSpeedButtonFontColor(Sender);
  sbHeader.Font.Color := clGreen;

  if Trim(sbHeader.Caption) = tr('Header: ON') then
  begin
    sbHeader.Caption := tr('Header: OFF');
  end else
  if Trim(sbHeader.Caption) = tr('Header: OFF') then
  begin
    sbHeader.Caption := tr('Header: ON');
  end;
end;

procedure TForm1.sbLeftClick(Sender: TObject);
begin
  if Assigned(TopicTree.Selected) then
  begin
    MoveNodeLeft(TopicTree.Selected);
  end;
end;

procedure TForm1.sbRightClick(Sender: TObject);
begin
  if Assigned(TopicTree.Selected) then
  BEGIN
    MoveNodeRight(TopicTree.Selected);
  end;
end;

procedure TForm1.sbUpClick(Sender: TObject);
begin
  if Assigned(TopicTree.Selected) then
  begin
    MoveNodeUp(TopicTree.Selected);
  end;
end;

procedure TForm1.sbContentClick(Sender: TObject);
begin
  setSpeedButtonFontColor(Sender);
  sbContent.Font.Color := clGreen;
end;

procedure TForm1.SpeedButton2Click(Sender: TObject);
var
  dir: String;
begin
  if SelectDirectoryDialog1.Execute then
  begin
    dir := Trim(SelectDirectoryDialog1.FileName);
    if Length(dir) < 1 then
    begin
      ShowMessage('Error:' + #10 + 'Directory not set.');
      exit;
    end;
    if not DirectoryExists(dir) then
    begin
      ShowMessage('Error:' + #10 + 'Directory does not exists.');
      exit;
    end;
    edProjectPath.Text := dir;
  end;
end;

// Aktualisiert die Nummerierung aller Nodes im TreeView
procedure TForm1.UpdateTreeViewNumbers;
var
  Node: TTreeNode;
  LevelCounters: array of Integer;

  procedure NumberNodes(ANode: TTreeNode; Level: Integer);
  var
    Counter: Integer;
    Child: TTreeNode;
    NumberString, OriginalText: string;
  begin
    if Level >= Length(LevelCounters) then
      SetLength(LevelCounters, Level + 1);

    // Root-Node hat KEINE Nummer!
    if Level > 0 then
      Inc(LevelCounters[Level]);

    // Nummerierung erstellen (z.B. "1.2.3")
    NumberString := '';
    if Level > 0 then
    begin
      for Counter := 1 to Level do
      begin
        if Counter > 1 then
        NumberString := NumberString + '.';
        NumberString := NumberString + IntToStr(LevelCounters[Counter]);
      end;
    end;

    // Ursprünglichen Text abrufen
    OriginalText := GetHiddenObjectText(ANode);
    if OriginalText = '' then
    OriginalText := '[Topic Tree]';

    if Level > 0 then
    begin
      if checkList.Checked[0] then
      begin
        ANode.Text := NumberString + ' ' + OriginalText
      end else
      begin
        ANode.Text := OriginalText;
      end;
    end else
    begin
      ANode.Text := OriginalText;
    end;

    // **Setzt das Icon nach der Hierarchie**
    if ANode.Parent = nil then
      ANode.ImageIndex := 0 // Root-Level Icon
    else
      ANode.ImageIndex := 1; // Child-Level Icon

    ANode.SelectedIndex := ANode.ImageIndex; // Falls gewünscht, auch das selektierte Icon setzen

    // Unterknoten rekursiv verarbeiten
    Child := ANode.GetFirstChild;
    while Assigned(Child) do
    begin
      NumberNodes(Child, Level + 1);
      Child := Child.GetNextSibling;
    end;
  end;
begin
  if TopicTree.Items.Count = 0 then Exit;

  SetLength(LevelCounters, 10);
  FillChar(LevelCounters[0], Length(LevelCounters) * SizeOf(Integer), 0);

  TopicTree.Items.BeginUpdate;
  try
    Node := TopicTree.Items.GetFirstNode;
    if Assigned(Node) then
      NumberNodes(Node, 0);
  finally
    TopicTree.Items.EndUpdate;
  end;
end;

procedure TForm1.sbFooterClick(Sender: TObject);
begin
  setSpeedButtonFontColor(Sender);
  sbFooter.Font.Color := clGreen;

  if Trim(sbFooter.Caption) = tr('Footer: OFF') then
  begin
    sbFooter.Caption := tr('Footer: ON');
  end else
  begin
    sbFooter.Caption := tr('Footer: OFF');
  end;

end;

procedure TForm1.TopicTreeClick(Sender: TObject);
begin
  if UpdatingNumbers > 0 then Exit; // Verhindert Endlosschleife

  if TopicTree.Selected <> nil then
  begin
    if TopicTree.Selected.Text <> '[Themen-Baum]' then
    begin
      edTopicName.Text := TopicTree.Selected.Text;
      edTopicRef.Text := GetHiddenObjectRef(TopicTree.Selected);

      btnAddNode.Enabled := true;
      btnDelNode.Enabled := true;
    end else
    begin

    end;
  end;
end;

end.

