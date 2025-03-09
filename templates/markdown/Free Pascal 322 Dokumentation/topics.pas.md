<%
var topicContent: String;

	// Return the topic extension, starting with a dot
	function GetTopicExtension: string;
	begin
		Result := Trim(HndGeneratorInfo.TemplateInfo.TopicExtension);
		if ((Length(Result) > 0) and (Result[1] <> '.')) then
			Result := '.' + Result;
	end;

begin
    // Get a list of generated topics
	var aTopicList := HndTopicsEx.GetTopicListGenerated(False, False);

    // Default topic
    var sDefaultTopicId := HndProjects.GetProjectDefaultTopic();
    
	// Each individual topics...
	for var nCurTopic := 0 to length(aTopicList) - 1 do
	begin
		// Notify about the topic being generated
		HndGeneratorInfo.CurrentTopic := aTopicList[nCurTopic].id;

		// Topic kind
		if (aTopicList[nCurTopic].Kind = 1) then continue;  // Empty topic: do not generate anything

        // Setup the file name
        HndGeneratorInfo.CurrentFile := aTopicList[nCurTopic].HelpId + GetTopicExtension();

        // Title
        println('# ' + HndTopics.GetTopicCaption(HndGeneratorInfo.CurrentTopic));
        println('');

        topicContent := StringReplace(
                        HndTopics.GetTopicContentAsMarkdown(HndGeneratorInfo.CurrentTopic),
                        '***\[::TemplateMDnewLine::\]***',
                        #10#10,
                        [rfReplaceAll]);

//        if HndTopics.GetTopicCaption(HndGeneratorInfo.CurrentTopic) = 'Lizenz - Bitte lesen !!!' then
//        begin
//          ShowMessage(HndTopics.GetTopicContentAsMarkdown(HndGeneratorInfo.CurrentTopic));
//          ShowMessage(topicContent);
//        end;
        // Content
        print(topicContent);
    end;
end.
%>