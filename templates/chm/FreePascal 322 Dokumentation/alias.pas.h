<%
var
	nCnt: integer;
var
	aTopicList: THndTopicsInfoArray;
var
	sHelpId: string;

	// Return the topic extension, starting with a dot
	function GetTopicExtension: string;
	begin
		Result := Trim(HndGeneratorInfo.TemplateInfo.TopicExtension);
		if ((Length(Result) > 0) and (Result[1] <> '.')) then
			Result := '.' + Result;
	end;
	
begin
	aTopicList := HndTopicsEx.GetTopicListGenerated(False, False);
	for nCnt := 0 to length(aTopicList) - 1 do
	begin
		// Only "normal" and "file" topics can have an alias
		if (HndTopics.GetTopicKind(aTopicList[nCnt].Id) in [0, 3]) then
		begin
			sHelpId := aTopicList[nCnt].HelpId;
			printfln('%s=%s%s', [sHelpId, sHelpId, GetTopicExtension()]);
		end;
	end;
end.
%>