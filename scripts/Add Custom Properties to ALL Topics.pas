// ----------------------------------------------------------------------------
// File : AddCustomProperties.pas
// Autor: Jens Kallup  - paule32 aka Blacky Cat
// Date : 2025 (c) all rights reserved.
//
// Description:
// Add custom properties to all Topics.  
// ----------------------------------------------------------------------------
// Customization:
// --------------
// ----------------------------------------------------------------------------
var
  // Current topic ID
  aTopicId: string;
begin
  // Get first topic
  aTopicId := HndTopics.GetTopicFirst();
  // Loop through all topics
  while aTopicId <> '' do
  begin
    // Update the topic property
    //HndTopicsProperties.DeleteAllTopicCustomProperties(aTopicId);
    HndTopicsProperties.DeleteTopicCustomProperty(aTopicId, 'PDF Page BG Color');
    HndTopicsProperties.DeleteTopicCustomProperty(aTopicId, 'PDF Font BG Color');
    HndTopicsProperties.DeleteTopicCustomProperty(aTopicId, 'PDF Font FG Color');
    HndTopicsProperties.DeleteTopicCustomProperty(aTopicId, 'PDF Font Name');
    HndTopicsProperties.DeleteTopicCustomProperty(aTopicId, 'PDF Font Bold');
    //
    HndTopicsProperties.SetTopicCustomPropertyValue(aTopicId, 'PDF Page BG Color', '#ffffff');
    HndTopicsProperties.SetTopicCustomPropertyValue(aTopicId, 'PDF Font BG Color', '#ffffff');
    HndTopicsProperties.SetTopicCustomPropertyValue(aTopicId, 'PDF Font FG Color', '#000000');
    HndTopicsProperties.SetTopicCustomPropertyValue(aTopicId, 'PDF Font Name'    , 'Arial'  );
    HndTopicsProperties.SetTopicCustomPropertyValue(aTopicId, 'PDF Font Bold'    , 'false'  );

    // Get next topic
    aTopicId := HndTopics.GetTopicNext(aTopicId);
  end;
  ShowMessage("done.")
end.
