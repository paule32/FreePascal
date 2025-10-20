program ChmDarkTocFPC;

{$APPTYPE CONSOLE}
{$mode objfpc}{$H+}

uses
  Windows, SysUtils;

type
  TEnumData = record
    Tree: HWND;
  end;
  PEnumData = ^TEnumData;

type
  TFindArgs = record
    TargetPid: DWORD;
    FoundTree: HWND;
    Verbose:   Boolean;
  end;
  PFindArgs = ^TFindArgs;

var
  Verbose: Boolean;

const
  // TreeView-Messages (manuell, damit keine CommCtrl-Unit nötig ist)
  TVM_SETBKCOLOR   = $1109;
  TVM_SETTEXTCOLOR = $110A;
  TVM_SETLINECOLOR = $1106;

function SetWindowTheme(hWnd: HWND; pszSubAppName, pszSubIdList: PWideChar): HRESULT; stdcall; external 'uxtheme.dll';

// Hilfsfunktion: gehört dieses Fenster zum hh.exe-Prozess?
function WindowBelongsToProcess(h: HWND; ExpectedPid: DWORD): Boolean;
var
  pid: DWORD;
begin
  GetWindowThreadProcessId(h, @pid);
  Result := (pid = ExpectedPid);
end;

function HexCharToByte(c: Char): Byte; inline;
begin
  case c of
    '0'..'9': Result := Byte(Ord(c) - Ord('0'));
    'a'..'f': Result := 10 + Byte(Ord(c) - Ord('a'));
    'A'..'F': Result := 10 + Byte(Ord(c) - Ord('A'));
  else
    Result := 0;
  end;
end;

function ParseHexColor(const SIn: string; Default: DWORD): DWORD;
var
  s: string;
  r, g, b: Byte;
begin
  s := Trim(SIn);
  if (s <> '') and (s[1] = '#') then Delete(s,1,1)
  else if (Length(s) > 2) and ((Copy(s,1,2)='0x') or (Copy(s,1,2)='0X')) then Delete(s,1,2);
  if Length(s) <> 6 then Exit(Default);
  r := (HexCharToByte(s[1]) shl 4) or HexCharToByte(s[2]);
  g := (HexCharToByte(s[3]) shl 4) or HexCharToByte(s[4]);
  b := (HexCharToByte(s[5]) shl 4) or HexCharToByte(s[6]);
  // COLORREF = 0x00BBGGRR
  Result := (DWORD(b) shl 16) or (DWORD(g) shl 8) or DWORD(r);
end;

function EnumChildProcFilter(h: HWND; lParam: LPARAM): BOOL; stdcall;
var
  cls: array[0..63] of Char;
  fa: PFindArgs;
begin
  fa := PFindArgs(lParam);
  GetClassName(h, cls, Length(cls));

  if fa^.Verbose then
  begin
    // kurze, ungefährliche Logzeile (Klasse + gehört zum Prozess?)
    if WindowBelongsToProcess(h, fa^.TargetPid) then
      Writeln('[DBG] Child: ', cls, ' (own pid)')
    else
      Writeln('[DBG] Child: ', cls);
  end;

  if (SameText(cls, 'SysTreeView32')) and WindowBelongsToProcess(h, fa^.TargetPid) then
  begin
    fa^.FoundTree := h;
    Exit(False); // Stop
  end;
  Result := True;
end;

function FindChmTreeViewOfPid(TargetPid: DWORD; out hTree: HWND; Verbose: Boolean; TimeoutMs: Cardinal = 5000): Boolean;
var
  t0: Cardinal;
  hTop: HWND;
  fa: TFindArgs;
begin
  Result := False;
  hTree := 0;
  t0 := GetTickCount;

  fa.TargetPid := TargetPid;
  fa.FoundTree := 0;
  fa.Verbose   := Verbose;

  repeat
    // Alle Top-Level-Fenster durchgehen
    hTop := GetWindow(GetDesktopWindow, GW_CHILD);
    while hTop <> 0 do
    begin
      // Nur Fenster, die zum hh.exe-Prozess gehören
      if WindowBelongsToProcess(hTop, TargetPid) then
      begin
        if Verbose then Writeln('[DBG] Top: ', hTop, ' belongs to hh.exe');
        fa.FoundTree := 0;
        EnumChildWindows(hTop, @EnumChildProcFilter, LPARAM(@fa));
        if fa.FoundTree <> 0 then
        begin
          hTree := fa.FoundTree;
          Exit(True);
        end;
      end;
      hTop := GetWindow(hTop, GW_HWNDNEXT);
    end;
    Sleep(50);
  until (GetTickCount - t0 >= TimeoutMs);
end;

// Startet hh.exe und liefert ProcessHandle + PID zurück
function StartHh(const ChmPath: UnicodeString; out hProc: THandle; out Pid: DWORD): Boolean;
var
  si: STARTUPINFOW;
  pi: PROCESS_INFORMATION;
  cmd: UnicodeString;
begin
  ZeroMemory(@si, SizeOf(si)); si.cb := SizeOf(si);
  ZeroMemory(@pi, SizeOf(pi));
  cmd := '"' + 'hh.exe' + '" "' + ChmPath + '"';
  Result := CreateProcessW(nil, PWideChar(cmd), nil, nil, False, NORMAL_PRIORITY_CLASS, nil, nil, si, pi);
  if Result then
  begin
    hProc := pi.hProcess;
    Pid   := pi.dwProcessId;
    CloseHandle(pi.hThread);
  end;
end;

procedure ApplyTreeColors(hTree: HWND; Bg, Fg, Line: DWORD; Verbose: Boolean);
const
  TVM_SETBKCOLOR   = $1109;
  TVM_SETTEXTCOLOR = $110A;
  TVM_SETLINECOLOR = $1106;
begin
  // Theming abschalten & kräftig redrawen
  SetWindowTheme(hTree, '', '');
  if Verbose then Writeln('[DBG] SetWindowTheme done');

  SendMessage(hTree, TVM_SETBKCOLOR,   0, LPARAM(Bg));
  SendMessage(hTree, TVM_SETTEXTCOLOR, 0, LPARAM(Fg));
  SendMessage(hTree, TVM_SETLINECOLOR, 0, LPARAM(Line));
  if Verbose then Writeln('[DBG] Color messages sent');

  // Aggressives Redraw inkl. Frame/Children/Erase
  RedrawWindow(hTree, nil, 0, RDW_INVALIDATE or RDW_ERASE or RDW_FRAME or RDW_ALLCHILDREN or RDW_UPDATENOW);
end;

procedure OpenChmAndDarken(const ChmPath: UnicodeString; Bg, Fg, Line: DWORD; Verbose: Boolean);
var
  hProc: THandle;
  Pid  : DWORD;
  hTree: HWND;
begin
  if not StartHh(ChmPath, hProc, Pid) then
    raise Exception.Create('hh.exe konnte nicht gestartet werden');

  // kurz warten, bis UI steht (bei langsamen Systemen ggf. erhöhen)
  Sleep(300);

  if not FindChmTreeViewOfPid(Pid, hTree, Verbose, 7000) then
  begin
    if hProc <> 0 then CloseHandle(hProc);
    raise Exception.Create('TreeView (SysTreeView32) des hh.exe-Prozesses nicht gefunden');
  end;

  ApplyTreeColors(hTree, Bg, Fg, Line, Verbose);

  if hProc <> 0 then CloseHandle(hProc);
end;

function EnumChildProc(h: HWND; lParam: LPARAM): BOOL; stdcall;
var
  cls: array[0..63] of Char;
  ed: PEnumData;
begin
  ed := PEnumData(lParam);
  GetClassName(h, cls, Length(cls));
  if SameText(cls, 'SysTreeView32') then
  begin
    ed^.Tree := h;
    Exit(False); // stop
  end;
  Result := True;
end;

function FindChmTreeView(out hTree: HWND; TimeoutMs: Cardinal = 4000): Boolean;
var
  ed: TEnumData;
  t0: Cardinal;
  hTop: HWND;
begin
  Result := False; hTree := 0;
  t0 := GetTickCount;
  repeat
    hTop := GetWindow(GetDesktopWindow, GW_CHILD);
    while hTop <> 0 do
    begin
      ed.Tree := 0;
      EnumChildWindows(hTop, @EnumChildProc, LPARAM(@ed));
      if ed.Tree <> 0 then begin hTree := ed.Tree; Exit(True); end;
      hTop := GetWindow(hTop, GW_HWNDNEXT);
    end;
    Sleep(50);
  until GetTickCount - t0 >= TimeoutMs;
end;

procedure ForceDarkTree(hTree: HWND; Bg, Fg, Line: DWORD);
begin
  // Visual Styles deaktivieren, damit Farbmessages greifen
  SetWindowTheme(hTree, '', '');
  SendMessage(hTree, TVM_SETBKCOLOR,   0, LPARAM(Bg));
  SendMessage(hTree, TVM_SETTEXTCOLOR, 0, LPARAM(Fg));
  SendMessage(hTree, TVM_SETLINECOLOR, 0, LPARAM(Line));
  InvalidateRect(hTree, nil, True);
  UpdateWindow(hTree);
end;

function StartHhAndGetProcess(const ChmPath: UnicodeString; out hProc: THandle): Boolean;
var
  si: STARTUPINFOW;
  pi: PROCESS_INFORMATION;
  cmd: UnicodeString;
begin
  ZeroMemory(@si, SizeOf(si));
  si.cb := SizeOf(si);
  ZeroMemory(@pi, SizeOf(pi));
  // Befehl: "hh.exe" "C:\Pfad\hilfe.chm"
  cmd := '"' + 'hh.exe' + '" "' + ChmPath + '"';
  Result := CreateProcessW(
              nil, PWideChar(cmd),
              nil, nil, False,
              NORMAL_PRIORITY_CLASS,
              nil, nil, si, pi);
  if Result then
  begin
    hProc := pi.hProcess;
    // Thread-Handle sofort schließen, wir brauchen ihn nicht
    CloseHandle(pi.hThread);
  end;
end;

procedure PrintUsage;
begin
  Writeln('Verwendung:');
  Writeln('  ChmDarkTocFPC <PfadZurCHM> [--bg=#RRGGBB] [--fg=#RRGGBB] [--line=#RRGGBB]');
  Writeln('Beispiel:');
  Writeln('  ChmDarkTocFPC "C:\Doku\hilfe.chm" --bg=#121212 --fg=#E0E0E0 --line=#555555');
end;

var
  i: Integer;
  ChmPath: UnicodeString;
  BgCol, FgCol, LnCol: DWORD;
begin
  try
    Verbose := False;

    if ParamCount < 1 then begin PrintUsage; Halt(1); end;
    ChmPath := ParamStr(1);
    if not FileExists(ChmPath) then
        raise Exception.Create('CHM nicht gefunden: ' + ChmPath);

    // Defaults
    BgCol := ParseHexColor('#121212', $121212);
    FgCol := ParseHexColor('#E0E0E0', $E0E0E0);
    LnCol := ParseHexColor('#555555', $555555);

    // Optionen
    i := 2;
    while i <= ParamCount do
    begin
      if Pos('--bg=', ParamStr(i))=1 then
        BgCol := ParseHexColor(Copy(ParamStr(i),6,MaxInt), BgCol)
      else if Pos('--fg=', ParamStr(i))=1 then
        FgCol := ParseHexColor(Copy(ParamStr(i),6,MaxInt), FgCol)
      else if Pos('--line=', ParamStr(i))=1 then
        LnCol := ParseHexColor(Copy(ParamStr(i),8,MaxInt), LnCol);
      Inc(i);
    end;

    OpenChmAndDarken(ChmPath, BgCol, FgCol, LnCol, Verbose);
    Writeln('OK: TOC gefärbt.');
  except
    on E: Exception do begin Writeln('Fehler: ', E.Message); Halt(1); end;
  end;
end.
