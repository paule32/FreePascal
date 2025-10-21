(*
  Build Action: Pre-build (nur dem PDF-Profil zuweisen)
  Ersetzt [[HR]] durch ein Bild aus der Bibliothek (LineHR), ohne TMemoryStream.WriteBuffer
*)

const
  PLACEHOLDER    = '[[HR]]';
  LIB_IMAGE_NAME = 'LineHR';   // Bildname in der Bibliothek (PNG/SVG etc.)

function GetLibraryImageUrlAbsolute(const ItemCaption: string): string;
var
  itemId: string;
begin
  // Bibliotheks-Item per Anzeigename finden und absolute URL holen
  itemId := HndLibraryItems.GetItemWithCaption(ItemCaption);
  if itemId <> '' then
    Result := HndLibraryItems.GetItemUrlFileAbsolute(itemId)
  else
    Result := '';
end;

procedure ReplacePlaceholderWithImg(const TopicId, ImgUrl: string);
var
  ed: TObject;
  css, html, newHtml, imgTag: string;
begin
  ed := HndEditor.CreateTemporaryEditor;
  try
    // Topic-Inhalt in Editor laden
    HndEditor.InsertTopicContent(ed, TopicId);

    // HTML als String holen
    html := HndEditor.GetContentAsHtml(ed, css);

    if Pos(PLACEHOLDER, html) > 0 then
    begin
      // Einfaches IMG; Größe bei Bedarf anpassen (style-Attribut)
      imgTag := '<img alt="hr" src="' + HndUtils.HTMLEncode(ImgUrl) + '" style="width:100%;height:2px;" />';

      // Platzhalter ersetzen
      newHtml := StringReplace(html, PLACEHOLDER, imgTag, [rfReplaceAll]);

      // Editor leeren und neuen HTML-String setzen
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
  imgUrl: string;
begin
  // Bild-URL aus der Bibliothek bestimmen
  imgUrl := GetLibraryImageUrlAbsolute(LIB_IMAGE_NAME);
  if imgUrl = '' then Exit; // kein Bild gefunden ? nix tun

  // Alle Topics abklappern und ersetzen
  topics := HndTopics.GetTopicList(True);
  for i := 0 to Length(topics)-1 do
    ReplacePlaceholderWithImg(topics[i].Id, imgUrl);
end;

begin
  Main;
end.
