unit GenericTemplate;

interface

type
  TVariantType = (
    vtEmpty,
    vtBoolean,
    vtChar,
    vtInteger,
    vtString );

  TVariant = record
    VarType = record
      vtBoolean: Boolean;
      vtChar:    Char;
      vtInteger: Integer;
      vtString:  String;
    end;
  end;

type
  TStringNode = class(TObject)
  public
    data: string;
    prev, next: TStringNode;
    constructor Create(const p: TStringNode; const n: TStringNode); overload;
    constructor Create(const p: TStringNode); overload;
    constructor Create; overload;
  end;

type
  TStringArray = class(TObject)
  private
      PNode: TStringNode;
      Head: TStringNode;
      FCount: Integer;
  public
    constructor Create(InitialSize: Integer = 0);
    procedure Add(const AValue: String);
(*    function Get(Index: Integer): String;
    procedure SetValue(Index: Integer; const Value: String);*)
    function Count: Integer;
  end;

implementation

{ TStringNode }

constructor TStringNode.Create;
begin
  inherited Create;
  prev := nil;
  next := nil;
end;

constructor TStringNode.Create(const p: TStringNode);
begin
  inherited Create;
  if p = nil then raise Exception.Create('TStringNode is nil');
  prev := p;
  next := nil;
end;

constructor TStringNode.Create(const p: TStringNode; const n: TStringNode);
begin
  inherited Create;
  if p = nil then raise Exception.Create('TStringNode parent is nil.');
  if n = nil then raise Exception.Create('TStringNode next is nil.');
  prev := p;
  next := n;
end;

{ TStringArray }

constructor TStringArray.Create(InitialSize: Integer);
var
  idx: Integer;
begin
  inherited Create;
  for idx := 0 to initialsize do
  begin
    Print(idx);
    Add(IntToStr(idx) + ': 11');
  end;
end;

procedure TStringArray.Add(const AValue: String);
var
  n, p: TStringNode;
begin
  if PNode = nil then
  PNode  := TStringNode.Create;
  p      := PNode;
    
  n      := TStringNode.Create; 
  n.data := AValue;
  
  PNode.next := n;
  PNode.prev := p;
end;

function TStringArray.Count: Integer;
var
  p: TStringNode;
begin
  p := PNode;
  while True do
  begin
    if p.prev = nil then break;
    print(p.data);
    p := PNode.prev;
  end;
  
  result := FCount;
end;

initialization
var
  sa: TStringArray;
  
  Print('start...');    
  sa := TStringArray.Create(2);
  try
    sa.count;
  finally
    sa.Free;
    Print('done.');
  end;
end.