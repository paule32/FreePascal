<%

	function EscapeValue(Value: string): string;
	begin
		Result := StringReplace(Value, '"', '\"', [rfReplaceAll]);
	end;

begin
%>
function hnd_ut(a){
a.TRANSLATIONS['Search term too short'] = "<% print(EscapeValue(HndGeneratorInfo.GetCustomSettingValue('TranslationSearchTooShort'))); %>";
a.TRANSLATIONS['No results'] = "<% print(EscapeValue(HndGeneratorInfo.GetCustomSettingValue('TranslationNoResults'))); %>";
a.TRANSLATIONS['Please enter more characters'] = "<% print(EscapeValue(HndGeneratorInfo.GetCustomSettingValue('TranslationMoreChars'))); %>";
a.TRANSLATIONS['Word list not ready yet. Please wait until the word list is fully downloaded'] = "<% print(EscapeValue(HndGeneratorInfo.GetCustomSettingValue('TranslationListNotDownloaded'))); %>";
a.TRANSLATIONS['Incorrect or corrupt search data. Please check your HelpNDoc template'] = "<% print(EscapeValue(HndGeneratorInfo.GetCustomSettingValue('TranslationIncorrectSearchData'))); %>";
a.TRANSLATIONS['Related topics...'] = "<% print(EscapeValue(HndGeneratorInfo.GetCustomSettingValue('TranslationRelatedTopics'))); %>";
a.TRANSLATIONS['Loading...'] = "<% print(EscapeValue(HndGeneratorInfo.GetCustomSettingValue('TranslationLoading'))); %>";
a.TRANSLATIONS['Close'] = "<% print(EscapeValue(HndGeneratorInfo.GetCustomSettingValue('TranslationClose'))); %>";
}
<%
end.
%>