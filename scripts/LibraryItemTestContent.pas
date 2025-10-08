var kind_type: Integer;
var kind_id: String;
var kind_str: String;
begin
  kind_id := HndLibraryItems.GetItemByCaption('TopicCenterText');
  kind_type := HndLibraryItems.GetItemKind(kind_id);
  if kind_type = 13 then 
  begin
    kind_str := HndLibraryItems.GetItemContentAsText(kind_id);
    ShowMessage(kind_str)
  end;
end.