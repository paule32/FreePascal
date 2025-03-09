// ----------------------------------------------------------------------------
// File : CreateContent - Hide Header of all Topics.pas
// Autor: Jens Kallup  - paule32 aka Blacky Cat
// Date : 2025 (c) all rights reserved.
//
// Description:
// Create/Combine Topics for a CHM Project. 
// ----------------------------------------------------------------------------
// Customization:
// --------------
// * TEMPLATE_TOPIC => specify the template for the topics.
// ----------------------------------------------------------------------------
const
  TEMPLATE_TOPIC = 1;

var
  // Current topic ID
  aTopicID,
  topicCaption,
  htmlTemplate,
  HtmnlCopy,
  htmlContent,
  htmlCss: String;

begin
  // Get first topic
  aTopicId := HndTopics.GetTopicFirst();
  
  // Loop through all topics
  while aTopicID <> '' do
  begin
    TopicCaption := HndTopics.GetTopicCaption(aTopicID);
    if (TopicCaption = 'Vorlage') or (TopicCaption = 'Template') then
    begin
        htmlTemplate := HndTopics.GetTopicContentAsHtml(aTopicID);
        ShowMessage(htmlTemplate);
    end;
    aTopicID := HndTopics.GetTopicNext(aTopicId);
  end;
  ShowMessage("done.")
end.
