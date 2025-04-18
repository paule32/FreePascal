
(* lexical analyzer template (TP Lex V3.0), V1.0 3-2-91 AG *)

(* global definitions: *)

function yylex : Integer;

procedure yyaction ( yyruleno : Integer );
  (* local definitions: *)

begin
  (* actions: *)
  case yyruleno of
  1:
                begin yylval.yyInteger := StrToInt(yytext); yyruleno := NUMBER; end;
  2:
                begin end;
  3:
                begin yyruleno := Ord(yytext[1]); end;
  4:
                begin end;
  5:
                begin yyerror('Unerwartetes Zeichen'); end;

  end;
end(*yyaction*);

(* DFA table: *)

type YYTRec = record
                cc : set of Char;
                s  : Integer;
              end;

const

yynmarks   = 9;
yynmatches = 9;
yyntrans   = 12;
yynstates  = 8;

yyk : array [1..yynmarks] of Integer = (
  { 0: }
  { 1: }
  { 2: }
  1,
  5,
  { 3: }
  2,
  5,
  { 4: }
  3,
  5,
  { 5: }
  4,
  { 6: }
  5,
  { 7: }
  1
);

yym : array [1..yynmatches] of Integer = (
{ 0: }
{ 1: }
{ 2: }
  1,
  5,
{ 3: }
  2,
  5,
{ 4: }
  3,
  5,
{ 5: }
  4,
{ 6: }
  5,
{ 7: }
  1
);

yyt : array [1..yyntrans] of YYTrec = (
{ 0: }
  ( cc: [ #1..#8,#11..#31,'!'..'''',',','.',':'..#255 ]; s: 6),
  ( cc: [ #9,' ' ]; s: 3),
  ( cc: [ #10 ]; s: 5),
  ( cc: [ '('..'+','-','/' ]; s: 4),
  ( cc: [ '0'..'9' ]; s: 2),
{ 1: }
  ( cc: [ #1..#8,#11..#31,'!'..'''',',','.',':'..#255 ]; s: 6),
  ( cc: [ #9,' ' ]; s: 3),
  ( cc: [ #10 ]; s: 5),
  ( cc: [ '('..'+','-','/' ]; s: 4),
  ( cc: [ '0'..'9' ]; s: 2),
{ 2: }
  ( cc: [ '0'..'9' ]; s: 7),
{ 3: }
{ 4: }
{ 5: }
{ 6: }
{ 7: }
  ( cc: [ '0'..'9' ]; s: 7)
);

yykl : array [0..yynstates-1] of Integer = (
{ 0: } 1,
{ 1: } 1,
{ 2: } 1,
{ 3: } 3,
{ 4: } 5,
{ 5: } 7,
{ 6: } 8,
{ 7: } 9
);

yykh : array [0..yynstates-1] of Integer = (
{ 0: } 0,
{ 1: } 0,
{ 2: } 2,
{ 3: } 4,
{ 4: } 6,
{ 5: } 7,
{ 6: } 8,
{ 7: } 9
);

yyml : array [0..yynstates-1] of Integer = (
{ 0: } 1,
{ 1: } 1,
{ 2: } 1,
{ 3: } 3,
{ 4: } 5,
{ 5: } 7,
{ 6: } 8,
{ 7: } 9
);

yymh : array [0..yynstates-1] of Integer = (
{ 0: } 0,
{ 1: } 0,
{ 2: } 2,
{ 3: } 4,
{ 4: } 6,
{ 5: } 7,
{ 6: } 8,
{ 7: } 9
);

yytl : array [0..yynstates-1] of Integer = (
{ 0: } 1,
{ 1: } 6,
{ 2: } 11,
{ 3: } 12,
{ 4: } 12,
{ 5: } 12,
{ 6: } 12,
{ 7: } 12
);

yyth : array [0..yynstates-1] of Integer = (
{ 0: } 5,
{ 1: } 10,
{ 2: } 11,
{ 3: } 11,
{ 4: } 11,
{ 5: } 11,
{ 6: } 11,
{ 7: } 12
);


var yyn : Integer;

label start, scan, action;

begin

start:

  (* initialize: *)

  yynew;

scan:

  (* mark positions and matches: *)

  for yyn := yykl[yystate] to     yykh[yystate] do yymark(yyk[yyn]);
  for yyn := yymh[yystate] downto yyml[yystate] do yymatch(yym[yyn]);

  if yytl[yystate]>yyth[yystate] then goto action; (* dead state *)

  (* get next character: *)

  yyscan;

  (* determine action: *)

  yyn := yytl[yystate];
  while (yyn<=yyth[yystate]) and not (yyactchar in yyt[yyn].cc) do inc(yyn);
  if yyn>yyth[yystate] then goto action;
    (* no transition on yyactchar in this state *)

  (* switch to new state: *)

  yystate := yyt[yyn].s;

  goto scan;

action:

  (* execute action: *)

  if yyfind(yyrule) then
    begin
      yyaction(yyrule);
      if yyreject then goto action;
    end
  else if not yydefault and yywrap() then
    begin
      yyclear;
      return(0);
    end;

  if not yydone then goto start;

  yylex := yyretval;

end(*yylex*);

