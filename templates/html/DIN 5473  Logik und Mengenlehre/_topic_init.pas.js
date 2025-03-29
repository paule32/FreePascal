<%

    function GetCustomJs: string;
    begin
        Result := HndGeneratorInfo.GetCustomSettingValue('CustomJs');
        if (Result <> '') then
            Result := 'try{' + #13#10 + Result + #13#10 + '}catch(e){console.warn("Exception in custom JavaScript Code:", e);}';
    end;

%>

$(function() {
    // Create the app
    var app = new Hnd.App({
      searchEngineMinChars: <% print(HndGeneratorInfo.GetCustomSettingValue('SearchEngineMinChars')); %>
    });
    // Update translations
    hnd_ut(app);
    // Instanciate imageMapResizer
    imageMapResize();
    // Custom JS
    <% print(GetCustomJs()); %>
    // Boot the app
    app.Boot();
});