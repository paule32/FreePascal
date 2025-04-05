<%
var
	nCnt: integer;
var
	aTopicList: THndTopicsInfoArray;
var
	sHelpId: string;
var
	nHelpContext: integer;
	
begin
	aTopicList := HndTopicsEx.GetTopicListGenerated(False, False);
	for nCnt := 0 to length(aTopicList) - 1 do
	begin
		sHelpId := aTopicList[nCnt].HelpId;
		nHelpContext := HndTopics.GetTopicHelpContext(aTopicList[nCnt].id);
		if (sHelpId <> '') then
			printfln('#define %s %d', [sHelpId, nHelpContext]);
	end;
end.
%>