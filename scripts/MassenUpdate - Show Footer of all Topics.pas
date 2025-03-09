// ----------------------------------------------------------------------------
// File : MassenUpdate - Hide Header of all Topics.pas
// Autor: Jens Kallup  - paule32 aka Blacky Cat
// Date : 2025 (c) all rights reserved.
//
// Description:
// Change/Hide all topic headers in a Project file. 
// ----------------------------------------------------------------------------
// Customization:
// --------------
// * NEW_FOOTER_KIND => specify the new footer kind for the topics.
//   0 => display footer;
//   1 => display a custom footer;
//   2 => hide the footer
// ----------------------------------------------------------------------------
const
  // Specify the new footer kind
  NEW_FOOTER_KIND = 0;

var
  // Current topic ID
  aTopicId: string;

begin
  // Get first topic
  aTopicId := HndTopics.GetTopicFirst();
  // Loop through all topics
  while aTopicId <> '' do
  begin
    // Update the topic
    HndTopics.SetTopicFooterKind(aTopicId, NEW_FOOTER_KIND);
    // Get next topic
    aTopicId := HndTopics.GetTopicNext(aTopicId);
  end;
  ShowMessage("done.")
end.
