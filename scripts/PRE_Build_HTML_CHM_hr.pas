(*
  Build Action: Pre-build (HTML- und CHM-Profile zuweisen)
  Ersetzt [[HR]] durch <hr> – ohne TMemoryStream.WriteBuffer
*)

const
  PLACEHOLDER = '[[HR]]';

procedure ReplacePlaceholderWithHr(const TopicId: string);
var
  ed: TObject;
  css, html, newHtml: string;
begin
  ed := HndEditor.CreateTemporaryEditor;
  try
    // Topic-Inhalt in den Editor laden
    HndEditor.InsertTopicContent(ed, TopicId);

    // HTML als String holen
    html := HndEditor.GetContentAsHtml(ed, css);

    if Pos(PLACEHOLDER, html) > 0 then
    begin
      // Platzhalter ersetzen
      newHtml := StringReplace(html, PLACEHOLDER, '<hr class="hr-yellow">', [rfReplaceAll]);

      // Editor leeren und neuen HTML-String einfügen
      HndEditor.Clear(ed);
      HndEditor.InsertContentFromHTML(ed, newHtml);

      // zurück ins Topic schreiben
      HndEditor.SetAsTopicContent(ed, TopicId);
    end;
  finally
    HndEditor.DestroyTemporaryEditor(ed);
  end;
end;

procedure Main;
var
  topics: THndTopicsInfoArray;
  i: Integer;
begin
  topics := HndTopics.GetTopicList(True);
  for i := 0 to Length(topics)-1 do
    ReplacePlaceholderWithHr(topics[i].Id);
end;

begin
  Main;
end.
