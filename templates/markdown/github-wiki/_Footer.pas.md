<%
    // Do we generate a sidebar ?
    if (not HndGeneratorInfo.GetCustomSettingValue('GenerateCommonFooter')) then
        Exit;

    println(HndProjects.GetProjectCopyright());
%>