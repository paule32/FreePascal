unit MainForm;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  Menus, ExtCtrls, Buttons, MaskEdit, ButtonPanel, CheckLst, SynEdit,
  SynPopupMenu, SynHighlighterHTML, LCLType;

type
  TNodeInfo = class
    TopicText: String;
    TopicRef : String;

    Header: Boolean;
    Footer: Boolean;

    CustomHeaderContent: String;
    CustomFooterContent: String;
    CustomCSSContent: String;
    CustomJSContent: String;
  end;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    btnAddNode: TButton;
    btnDelNode: TButton;
    checkList: TCheckListBox;
    edProjectAutor: TEdit;
    edProjectName: TEdit;
    edProjectPath: TEdit;
    globalCheckList: TCheckListBox;
    edTopicName: TEdit;
    ImageList1: TImageList;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lbCustomJS: TLabel;
    lbHeaderContent: TLabel;
    lbFooterContent: TLabel;
    lbCustomCSS: TLabel;
    lbTopicName: TLabel;
    lbTopicReference: TLabel;
    ListBox1: TListBox;
    ListBox2: TListBox;
    MainMenu1: TMainMenu;
    edTopicRef: TMaskEdit;
    Memo1: TMemo;
    MenuFile: TMenuItem;
    MenuSettings: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuFileExitApp: TMenuItem;
    MenuFileNew: TMenuItem;
    MenuFileOpen: TMenuItem;
    MenuFileSave: TMenuItem;
    MenuFileSaveAs: TMenuItem;
    MenuFileOpenConfiguration: TMenuItem;
    MenuHelp: TMenuItem;
    MenuItem9: TMenuItem;
    PageControl1: TPageControl;
    PageControl2: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    ProgressBar1: TProgressBar;
    sbLoadFromFile1: TSpeedButton;
    ScrollBar1: TScrollBar;
    ScrollBox1: TScrollBox;
    ScrollBox2: TScrollBox;
    ScrollBox3: TScrollBox;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    Separator1: TMenuItem;
    Separator2: TMenuItem;
    sbHeader: TSpeedButton;
    sbLeft: TSpeedButton;
    sbApplyHeaderContent: TSpeedButton;
    sbLoadFromFile: TSpeedButton;
    sbContent: TSpeedButton;
    sbFooter: TSpeedButton;
    sbDown: TSpeedButton;
    sbUp: TSpeedButton;
    sbRight: TSpeedButton;
    sbApplyFooterContent: TSpeedButton;
    sbApplyCustomCSS: TSpeedButton;
    sbApplyCustomJS: TSpeedButton;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    Splitter4: TSplitter;
    Splitter5: TSplitter;
    StatusBar1: TStatusBar;
    SynEdit1: TSynEdit;
    SynEditCustomJS: TSynEdit;
    synEditHeaderContent: TSynEdit;
    SynEditFooterContent: TSynEdit;
    synEditCustomCSS: TSynEdit;
    SynHTMLSyn1: TSynHTMLSyn;
    SynPopupMenu1: TSynPopupMenu;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    ToolBar1: TToolBar;
    sbNew: TToolButton;
    sbOpen: TToolButton;
    sbSaveAs: TToolButton;
    TopicTreePanel: TPanel;
    TopicTree: TTreeView;
    procedure btnAddNodeClick(Sender: TObject);
    procedure btnDelNodeClick(Sender: TObject);
    procedure checkListClick(Sender: TObject);
    procedure checkListClickCheck(Sender: TObject);
    procedure edProjectPathChange(Sender: TObject);
    procedure edTopicNameChange(Sender: TObject);
    procedure edTopicNameKeyPress(Sender: TObject; var Key: char);
    procedure edTopicRefChange(Sender: TObject);
    procedure edTopicRefKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);
    procedure MenuItem13Click(Sender: TObject);
    procedure MenuFileExitAppClick(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure sbApplyCustomCSSClick(Sender: TObject);
    procedure sbApplyCustomJSClick(Sender: TObject);
    procedure sbApplyFooterContentClick(Sender: TObject);
    procedure sbApplyHeaderContentClick(Sender: TObject);
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

function GetOrCreateRootNode(TopicTree: TTreeView): TTreeNode;
begin
  if TopicTree.Items.Count = 0 then
    Result := TopicTree.Items.Add(nil, 'Hauptthema') // Erstelle Root-Node
  else
    Result := TopicTree.Items[0]; // Erste (und einzige) Root-Node abrufen
end;

procedure AddNodeWithHiddenObject(
  TopicTree: TTreeView;
  const NodeText: String;
  const TopicRef: string);
var
  NewNode, ParentNode: TTreeNode;
  Info: TNodeInfo;
begin
  if Assigned(TopicTree.Selected) then
  ParentNode := TopicTree.Selected
  else
  begin
    // Falls keine Node existiert, eine Standard-Root-Node erstellen
    if TopicTree.Items.Count = 0 then
      ParentNode := TopicTree.Items.Add(nil, tr('[Topic Tree]')) // Root hinzufügen
    else
      ParentNode := TopicTree.Items.GetFirstNode; // Erste Node als Parent verwenden
  end;

  // Neue Node als Child einfügen
  NewNode := TopicTree.Items.AddChild(ParentNode, NodeText);

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
  TopicTree.Selected := NewNode;
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

function GetHiddenObject(Node: TTreeNode): TNodeInfo;
var
  Info: TNodeInfo;
begin
  result := nil;
  if Assigned(Node) and Assigned(Node.data) then
  begin
    Info := TNodeInfo(Node.Data);
    Result := Info;
  end;
end;

procedure FreeNodeObjects(TopicTree: TTreeView);
var
  I: Integer;
begin
  for I := 0 to TopicTree.Items.Count - 1 do
    if Assigned(TopicTree.Items[I].Data) then
    begin
      TNodeInfo(TopicTree.Items[I].Data).Free;
      TopicTree.Items[I].Data := nil;
    end;
end;

{ TForm1 }

procedure TForm1.UpdateAllCaptions;
begin
  sbHeader .Caption  := tr(sbHeader.Caption);
  sbFooter .Caption  := tr(sbFooter.Caption);
  sbContent.Caption  := tr(sbContent.Caption);

  lbTopicName.Caption := tr(lbTopicName.Caption);
  lbTopicReference.Caption := tr(lbTopicReference.Caption);

  checkList.Items[0] := tr(checkList.Items[0]);
  checkList.Items[1] := tr(checkList.Items[1]);
  checkList.Items[2] := tr(checkList.Items[2]);

  checkList.Checked[0] := False;
  checkList.Checked[1] := False;
  checkList.Checked[2] := False;

  TabSheet1.Caption := tr(TabSheet1.Caption);
  TabSheet2.Caption := tr(TabSheet2.Caption);
  TabSheet3.Caption := tr(TabSheet3.Caption);

  btnAddNode.Caption := tr(btnAddNode.Caption);
  btnDelNode.Caption := tr(btnDelNode.Caption);

  lbHeaderContent.Caption := tr(lbHeaderContent.Caption);
  lbFooterContent.Caption := tr(lbFooterContent.Caption);

  sbApplyHeaderContent.Caption := tr(sbApplyHeaderContent.Caption);
  sbApplyFooterContent.Caption := tr(sbApplyFooterContent.Caption);
  sbApplyCustomCSS    .Caption := tr(sbApplyCustomCSS    .Caption);
  sbApplyCustomJS     .Caption := tr(sbApplyCustomJS     .Caption);

  lbCustomCSS.Caption := tr(lbCustomCSS.Caption);
  lbCustomJs .Caption := tr(lbCustomJs .Caption);

  sbLoadFromFile.Caption := tr(sbLoadFromFile.Caption);

  globalCheckList.Items[0] := tr(globalCheckList.Items[0]);
  globalCheckList.Items[1] := tr(globalCheckList.Items[1]);
  globalCheckList.Items[2] := tr(globalCheckList.Items[2]);
  globalCheckList.Items[3] := tr(globalCheckList.Items[3]);

  menuFile.Caption := tr(menuFile.Caption);
  menuFileNew.Caption := tr(menuFileNew.Caption);
  menuFileOpen.Caption := tr(menuFileOpen.Caption);
  menuFileSave.Caption := tr(menuFileSave.Caption);
  menuFileSaveAs.Caption := tr(menuFileSaveAs.Caption);
  menuFileExitApp.Caption := tr(menuFileExitApp.Caption);

  menuSettings.Caption := tr(menuSettings.Caption);

  menuHelp.Caption := tr(menuHelp.Caption);
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
var
  info: TNodeInfo;
begin
  AddNodeWithHiddenObject(TopicTree, edTopicName.Text, edTopicRef.Text);
  info := GetHiddenObject(TopicTree.Selected);
  if Assigned(info) then
  begin
    info.CustomHeaderContent := synEditHeaderContent.Lines.Text;
    info.CustomFooterContent := synEditFooterContent.Lines.Text;
  end;
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

procedure TForm1.checkListClick(Sender: TObject);
begin

end;

procedure TForm1.checkListClickCheck(Sender: TObject);
var
  index: Integer;
begin
  if TopicTree.Selected <> nil then
  begin
    index := checkList.ItemIndex;
    if index <> -1 then
    begin
      if index = 1 then
      begin
        checkList.Items[1] := ifThenStr(
        checkList.Items[1] = tr('All Header: ON'),
        tr('All Header: OFF'),
        tr('All Header: ON'));
      end else
      if index = 2 then
      begin
        checkList.Items[2] := ifThenStr(
        checkList.Items[2] = tr('All Footer: ON'),
        tr('All Footer: OFF'),
        tr('All Footer: ON'));
      end;
    end;
  end;

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
  and (TopicTree.Selected.Text <> tr('[Topic Tree]')) then
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

  CheckList.Color := HexToTColor('f9f9f9');
  globalCheckList.Color := HexToTColor('f9f9f9');

  motr := TMoTranslate.Create('de', false);
  UpdateAllCaptions;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
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

procedure TForm1.MenuFileExitAppClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.MenuItem9Click(Sender: TObject);
begin
  Application.CreateForm(TAboutForm, AboutForm);
  AboutForm.ShowModal;
  AboutForm.Free;
end;

procedure TForm1.PageControl1Change(Sender: TObject);
begin
  if TopicTree.Selected <> nil then
  begin
    if TopicTree.Selected.Text = tr('[Topic Tree]') then
    begin
      TopicTree.Selected := TopicTree.Selected.getFirstChild;
    end;
  end;
end;

procedure TForm1.sbApplyCustomCSSClick(Sender: TObject);
var
  info: TNodeInfo;
begin
  info := GetHiddenObject(TopicTree.Selected);
  if info <> nil then
  begin
    info.CustomCSSContent := synEditCustomCSS.Lines.Text;
  end;
end;

procedure TForm1.sbApplyCustomJSClick(Sender: TObject);
var
  info: TNodeInfo;
begin
  info := GetHiddenObject(TopicTree.Selected);
  if info <> nil then
  begin
    info.CustomJSContent := synEditCustomJS.Lines.Text;
  end;
end;

procedure TForm1.sbApplyFooterContentClick(Sender: TObject);
var
  info: TNodeInfo;
begin
  info := GetHiddenObject(TopicTree.Selected);
  if info <> nil then
  begin
    info.CustomFooterContent := synEditFooterContent.Lines.Text;
  end;
end;

procedure TForm1.sbApplyHeaderContentClick(Sender: TObject);
var
  info: TNodeInfo;
begin
  info := GetHiddenObject(TopicTree.Selected);
  if info <> nil then
  begin
    info.CustomHeaderContent := synEditHeaderContent.Lines.Text;
  end;
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
var
  info: TNodeInfo;
begin
  setSpeedButtonFontColor(Sender);
  sbHeader.Font.Color := clGreen;

  if TopicTree.Selected <> nil then
  begin
    info := GetHiddenObject(TopicTree.Selected);
    if Trim(sbHeader.Caption) = tr('Header: OFF') then
    begin
      sbHeader.Caption := tr('Header: ON');
      if Assigned(info) then
      begin
        info.Header := True;
        SynEditHeaderContent.Enabled := True;
        SynEditHeaderContent.Lines.Text := info.CustomHeaderContent;
      end;
    end else
    if Trim(sbHeader.Caption) = tr('Header: ON') then
    begin
      sbHeader.Caption := tr('Header: OFF');
      if Assigned(info) then
      begin
        info.Footer := False;
        SynEditHeaderContent.Lines.Text := '';
        SynEditHeaderContent.Enabled := False;
      end;
    end;
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

// Aktualisiert die Nummerierung aller Nodes im TopicTree
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
var
  info: TNodeInfo;
begin
  setSpeedButtonFontColor(Sender);
  sbFooter.Font.Color := clGreen;

  if TopicTree.Selected <> nil then
  begin
    info := GetHiddenObject(TopicTree.Selected);
    if Trim(sbFooter.Caption) = tr('Footer: OFF') then
    begin
      sbFooter.Caption := tr('Footer: ON');
      if Assigned(info) then
      begin
        info.Footer := True;
      end;
    end else
    begin
      sbFooter.Caption := tr('Footer: OFF');
      if Assigned(info) then
      begin
        info.Footer := False;
      end;
    end;
  end;
end;

procedure TForm1.TopicTreeClick(Sender: TObject);
var
  info: TNodeInfo;
begin
  if UpdatingNumbers > 0 then Exit; // Verhindert Endlosschleife

  if TopicTree.Selected <> nil then
  begin
    if TopicTree.Selected.Text <> tr('[Topic Tree]') then
    begin
      info := GetHiddenObject(TopicTree.Selected);
      edTopicName.Text   := info.TopicText;
      edTopicRef .Text   := info.TopicRef;

      btnAddNode.Enabled := true;
      btnDelNode.Enabled := true;

      synEditHeaderContent.Lines.Clear;
      synEditFooterContent.Lines.Clear;

      synEditHeaderContent.Lines.Text := info.CustomHeaderContent;
      synEditFooterContent.Lines.Text := info.CustomFooterContent;

      synEditCustomCSS.Lines.Text := info.CustomCSSContent;
      synEditCustomJS .Lines.Text := info.CustomJSContent;

      if PageControl1.ActivePage <> TabSheet3 then
      begin
        PageControl1.ActivePage := TabSheet1;
      end else
      begin
        if info.Header then
        sbHeader.Caption := tr('Header: ON') else
        sbHeader.Caption := tr('Header: OFF');

        if info.Footer then
        sbFooter.Caption := tr('Footer: ON') else
        sbFooter.Caption := tr('Footer: OFF');
      end;
    end else
    begin
      PageControl1.ActivePage := TabSheet2;
    end;
  end;
end;

end.

