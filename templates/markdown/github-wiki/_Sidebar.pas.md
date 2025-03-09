<%

begin
    // Do we generate a sidebar ?
    if (not HndGeneratorInfo.GetCustomSettingValue('GenerateSidebar')) then
        Exit;

    println('# ' + HndTopics.GetTopicCaption(HndTopics.GetProjectTopic()));
    println('');

    println('## ' + HndGeneratorInfo.GetCustomSettingValue('TranslationTableOfContents'));
    println('');

    // Get a list of generated topics
	var aTopicList := HndTopicsEx.GetTopicListGenerated(False, False);

	// Each individual topics...
	for var nCurTopic := 0 to length(aTopicList) - 1 do
	begin
		// Notify about the topic being generated
		HndGeneratorInfo.CurrentTopic := aTopicList[nCurTopic].id;

		// Topic kind
		if (aTopicList[nCurTopic].Kind = 1) then continue;  // Empty topic: do not generate anything

        // URL
        var sTopicUrl := '';
        if aTopicList[nCurTopic].Kind = 2 then sTopicUrl := HndTopics.GetTopicUrlLink(HndGeneratorInfo.CurrentTopic)  // Link to URL
        else if aTopicList[nCurTopic].Kind = 1 then sTopicUrl := ''  // Empty
        else sTopicUrl := format('%s', [aTopicList[nCurTopic].HelpId]);  // Normal topic

        // Indentation
        for var nLevel := 2 to HndTopics.GetTopicLevel(HndGeneratorInfo.CurrentTopic) do
            print('  ');

        // Caption
        printfln('- [%s](<%s>)', [HndTopics.GetTopicCaption(HndGeneratorInfo.CurrentTopic), sTopicUrl]);
    end;
end.
%>