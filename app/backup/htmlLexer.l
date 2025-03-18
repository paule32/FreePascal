%{
%}
%%

[0-9]+          begin
  ShowMessage('---->  ' + yytext);
  yylval.yyInteger := StrToInt(yytext);
  yyruleno := NUMBER;
end;
[ \t]           begin end;
[-+*/()]        begin yyruleno := Ord(yytext[1]); end;
\n              begin end;
.               begin yyerror('Unerwartetes Zeichen'); end;

%%


