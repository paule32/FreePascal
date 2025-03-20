program helper;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  uCEFApplication,  // WICHTIG: Initialisiert CEF
  Forms, MainForm, about, globals, xmlstream, htmlParser, CommentPreprocessor
  { you can add units after this };

{$R *.res}

begin
  GlobalCEFApp := TCefApplication.Create;

  if not GlobalCEFApp.StartMainProcess then
  begin
    GlobalCEFApp.Free;
    Halt(0);
  end;

  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

