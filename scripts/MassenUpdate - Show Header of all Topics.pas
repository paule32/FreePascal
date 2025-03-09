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
// * NEW_HEADER_KIND => specify the new header kind for the topics.
//   0 => display topic title;
//   1 => display a custom header;
//   2 => hide the header
// ----------------------------------------------------------------------------
const
  // Specify the new header kind
  NEW_HEADER_KIND = 1;

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
    HndTopics.SetTopicHeaderKind(aTopicId, NEW_HEADER_KIND);
    // Get next topic
    aTopicId := HndTopics.GetTopicNext(aTopicId);
  end;
  ShowMessage("done.")
end.
