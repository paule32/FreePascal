<%

    // Adds the default topic as the home page
    function AddDefaultTopic(var aList: THndTopicsInfoArray): string;
    var
        nLength: integer;
    begin
        Result := HndProjects.GetProjectDefaultTopic();
       	// Try to get the default topic
        Result := HndProjects.GetProjectDefaultTopic();
        // None defined: the first one is the default topic
        if (Result = '') then
            Result := HndTopicsEx.GetTopicNextGenerated(HndTopics.GetProjectTopic(), False);
        if (Result <> '') then
        begin
            // Add the default topic another time
            nLength := Length(aList);
            aList.SetLength(nLength + 1);
            aList[nLength].Id := Result;
            aList[nLength].Caption := HndTopics.GetTopicCaption(Result);
            aList[nLength].HelpId := HndTopics.GetTopicHelpId(Result);
            aList[nLength].HelpContext := HndTopics.GetTopicHelpContext(Result);
            aList[nLength].Kind := HndTopics.GetTopicKind(Result);
            aList[nLength].Visibility := HndTopics.GetTopicVisibility(Result);
        end;
    end;

	// Return the topic extension, starting with a dot
	function GetTopicExtension: string;
	begin
		Result := Trim(HndGeneratorInfo.TemplateInfo.TopicExtension);
		if ((Length(Result) > 0) and (Result[1] <> '.')) then
			Result := '.' + Result;
	end;

begin
    // Init
	var isNextDefaultTheIndex := False;
    var sTopicExtension := GetTopicExtension();

    // Get a list of generated topics
	var aTopicList := HndTopicsEx.GetTopicListGenerated(False, False);

    // Trick to add the default topic as the home page
    var sDefaultTopicId := AddDefaultTopic(aTopicList);
    
	// Each individual topics...
	for var nCurTopic := 0 to length(aTopicList) - 1 do
	begin
		// Notify about the topic being generated
		HndGeneratorInfo.CurrentTopic := aTopicList[nCurTopic].id;

		// Topic kind
		if (aTopicList[nCurTopic].Kind = 1) then continue;  // Empty topic: do not generate anything

        // Setup the file name
        if (HndGeneratorInfo.CurrentTopic <> sDefaultTopicId) then
        begin
		    HndGeneratorInfo.CurrentFile := aTopicList[nCurTopic].HelpId + sTopicExtension;
        end
        // Special handle for default topic
        else begin
            // We will generate the index next time
            if not isNextDefaultTheIndex then
            begin
                // Next time we see the default topic, it will be the index 
                isNextDefaultTheIndex := True;
                // Use the default convention
		        HndGeneratorInfo.CurrentFile := aTopicList[nCurTopic].HelpId + sTopicExtension;
            end
            // We generate the index now
            else begin
                // Use the file chosen by the user
                HndGeneratorInfo.CurrentFile := ExtractFileName(HndGeneratorInfo.OutputFile);
            end;
        end;

        // Header
		if (HndTopics.GetTopicHeaderKind(HndGeneratorInfo.CurrentTopic) <> 2) then
		begin
        	println('# ' + HndTopics.GetTopicHeaderTextCalculated(HndGeneratorInfo.CurrentTopic));
        	println('');
		end;
        
        // Content
        print(HndTopics.GetTopicContentAsMarkdown(HndGeneratorInfo.CurrentTopic));

		// Footer
    	if (not HndGeneratorInfo.GetCustomSettingValue('GenerateCommonFooter')) then
		begin
			if (HndTopics.GetTopicFooterKind(HndGeneratorInfo.CurrentTopic) <> 2) then
			begin
				println('');
				println('***');
				println(HndTopics.GetTopicFooterTextCalculated(HndGeneratorInfo.CurrentTopic));
			end;
		end;
    end;
end.
%>