<%

	// Return the topic extension, starting with a dot
	function GetTopicExtension: string;
	begin
		Result := Trim(HndGeneratorInfo.TemplateInfo.TopicExtension);
		if ((Length(Result) > 0) and (Result[1] <> '.')) then
			Result := '.' + Result;
	end;

begin
    HndGeneratorInfo.CurrentFile := ExtractFileName(HndGeneratorInfo.OutputFile);

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
        else sTopicUrl := format('%s%s', [aTopicList[nCurTopic].HelpId, GetTopicExtension()]);  // Normal topic

        // Indentation
        for var nLevel := 2 to HndTopics.GetTopicLevel(HndGeneratorInfo.CurrentTopic) do
            print('  ');

        // Caption
        printfln('- [%s](<%s>)', [HndTopics.GetTopicCaption(HndGeneratorInfo.CurrentTopic), sTopicUrl]);
    end;
end.
%>