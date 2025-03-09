// ----------------------------------------------------------------------------
// File : MassenUpdate - Hide Header and Footer of all Topics.pas
// Autor: Jens Kallup  - paule32 aka Blacky Cat
// Date : 2025 (c) all rights reserved.
//
// Description:
// copies the template Topic code to the current topic. 
// ----------------------------------------------------------------------------
// Customization:
// --------------
// ----------------------------------------------------------------------------
var aTopicID: string;
var cTopicID: string;
var sTopicID: string;

var aEditor : TObject;
var mems: TMemoryStream;

begin
  aTopicID := HndTopics.GetTopicFirst;
  cTopicID := HndUI.GetCurrentTopic;
  try
    while aTopicID <> '' do
    begin
      sTopicID := HndTopics.GetTopicCaption(aTopicID);
      if sTopicID = 'Vorlage' then
      begin
        ShowMessage(aTopicID + #13 + cTopicID);
        if aTopicID == cTopicID then
        begin
          ShowMessage('can not copy content to itself topic.');
          break;
        end;
        aEditor := HndEditor.CreateTemporaryEditor();
        mems := TMemoryStream.Create;
        try
          mems := HndTopics.GetTopicContent(aTopicID);
          HndEditor.Clear(aEditor);
          if HndEditor.InsertStream(aEditor, mems) = False then
          begin
            ShowMessage('Error: can not insert content.');
            break;
          end;
          HndEditor.SetAsTopicContent(aEditor, aTopicId);
          break;
        except
          ShowMessage('Error: memory object creation.');
          exit;
        end;
      end;
      aTopicId := HndTopics.GetTopicNext(aTopicId);
    end;
  finally
    HndEditor.DestroyTemporaryEditor(aEditor);
    ShowMessage("done.")
  end;
end.
