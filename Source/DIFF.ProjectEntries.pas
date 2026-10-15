unit DIFF.ProjectEntries;

interface

uses
  System.Classes, System.Generics.Collections, System.SysUtils;

const
  PROJECT_KEY_PREFIX = 'File_';

type
  ///  <summary>
  ///    One registry value of the Favorite Projects or Closed Projects key, e.g.
  ///    File_0 = TBaseProject,'C:\Path\Project.dproj',1,1,1,1,1
  ///  </summary>
  TProjectEntry = class(TObject)
  strict private
    FKey: string;
    FValue: string;
    FProjectType: string;
    FFullFileName: string;
    FPath: string;
    FFileName: string;
    FParams: TArray<string>;
    FIsParsed: Boolean;
    FPathExists: Boolean;
    FFileExists: Boolean;
    procedure Parse;
  public
    constructor Create(const AKey, AValue: string);

    procedure CheckExistence;
    function IsFound: Boolean;

    property Key: string read FKey write FKey;
    property Value: string read FValue;
    property ProjectType: string read FProjectType;
    property FullFileName: string read FFullFileName;
    property Path: string read FPath;
    property FileName: string read FFileName;
    property Params: TArray<string> read FParams;
    property IsParsed: Boolean read FIsParsed;
    property PathExists: Boolean read FPathExists;
    property FileExists: Boolean read FFileExists;
  end;

  TProjectEntryList = class(TObjectList<TProjectEntry>)
  public
    constructor Create;

    procedure SortByKey;
    procedure SortByPaths(const ASortPaths: TArray<string>);
    procedure RenumberKeys;
    function RemoveNotFound: Integer;
  end;

  function NaturalCompare(const ALeft, ARight: string): Integer;

implementation

uses
  System.Generics.Defaults, System.StrUtils, Winapi.ShLwApi;

function NaturalCompare(const ALeft, ARight: string): Integer;
begin
  // Same "logical" ordering as Windows Explorer: D7.dpr < D13.dpr, File_2 < File_10
  Result := StrCmpLogicalW(PChar(ALeft), PChar(ARight));
end;

function NormalizePath(const APath: string): string;
begin
  Result := Trim(APath).Replace('/', '\');

  if Result <> '' then
    Result := IncludeTrailingPathDelimiter(Result);
end;

{ TProjectEntry }

constructor TProjectEntry.Create(const AKey, AValue: string);
begin
  inherited Create;

  FKey := AKey;
  FValue := AValue;

  Parse;
  CheckExistence;
end;

procedure TProjectEntry.Parse;
var
  LIndex: Integer;
  LLength: Integer;
  LCommaPos: Integer;
  LFileName: string;
  LRest: string;
begin
  FIsParsed := False;
  FProjectType := '';
  FFullFileName := '';
  FPath := '';
  FFileName := '';
  FParams := [];

  // TBaseProject,'C:\Path\Project.dproj',1,1,1,1,1
  LCommaPos := Pos(',', FValue);
  if LCommaPos < 2 then
    Exit;

  LLength := Length(FValue);
  LIndex := LCommaPos + 1;
  if (LIndex > LLength) or (FValue[LIndex] <> '''') then
    Exit;

  // Quoted file name, quote inside the name is doubled ('')
  Inc(LIndex);
  LFileName := '';
  while LIndex <= LLength do
  begin
    if FValue[LIndex] = '''' then
    begin
      if (LIndex < LLength) and (FValue[LIndex + 1] = '''') then
      begin
        LFileName := LFileName + '''';
        Inc(LIndex, 2);
        Continue;
      end;

      Break;
    end;

    LFileName := LFileName + FValue[LIndex];
    Inc(LIndex);
  end;

  // No closing quote
  if (LIndex > LLength) or (LFileName = '') then
    Exit;

  // Skip closing quote and the comma after it
  LRest := Copy(FValue, LIndex + 2, MaxInt);

  FProjectType := Trim(Copy(FValue, 1, LCommaPos - 1));
  FFullFileName := LFileName;
  FPath := ExtractFilePath(LFileName);
  FFileName := ExtractFileName(LFileName);
  if LRest <> '' then
    FParams := LRest.Split([',']);
  FIsParsed := True;
end;

procedure TProjectEntry.CheckExistence;
begin
  FPathExists := FIsParsed and DirectoryExists(FPath);
  FFileExists := FPathExists and System.SysUtils.FileExists(FFullFileName);
end;

function TProjectEntry.IsFound: Boolean;
begin
  Result := FPathExists and FFileExists;
end;

{ TProjectEntryList }

constructor TProjectEntryList.Create;
begin
  inherited Create(True);
end;

procedure TProjectEntryList.SortByKey;
begin
  Sort(TComparer<TProjectEntry>.Construct(
    function(const ALeft, ARight: TProjectEntry): Integer
    begin
      Result := NaturalCompare(ALeft.Key, ARight.Key);
    end));
end;

procedure TProjectEntryList.SortByPaths(const ASortPaths: TArray<string>);
var
  LSortPaths: TArray<string>;
  LSortPath: string;

  // Index of the sort path the entry is under, longest match wins so a more specific
  // path can be listed too. Entries not under any sort path go last.
  function GetSortGroup(const AEntry: TProjectEntry): Integer;
  var
    LIndex: Integer;
    LBestLength: Integer;
    LPath: string;
  begin
    Result := Length(LSortPaths);
    LBestLength := 0;
    LPath := NormalizePath(AEntry.Path);

    if LPath = '' then
      Exit;

    for LIndex := 0 to High(LSortPaths) do
      if (Length(LSortPaths[LIndex]) > LBestLength) and StartsText(LSortPaths[LIndex], LPath) then
      begin
        Result := LIndex;
        LBestLength := Length(LSortPaths[LIndex]);
      end;
  end;

var
  LGroups: TDictionary<TProjectEntry, Integer>;
  LEntry: TProjectEntry;
begin
  LSortPaths := [];
  for LSortPath in ASortPaths do
    if Trim(LSortPath) <> '' then
      LSortPaths := LSortPaths + [NormalizePath(LSortPath)];

  LGroups := TDictionary<TProjectEntry, Integer>.Create;
  try
    for LEntry in Self do
      LGroups.Add(LEntry, GetSortGroup(LEntry));

    Sort(TComparer<TProjectEntry>.Construct(
      function(const ALeft, ARight: TProjectEntry): Integer
      begin
        Result := LGroups[ALeft] - LGroups[ARight];

        if Result = 0 then
          Result := NaturalCompare(ALeft.FileName, ARight.FileName);

        if Result = 0 then
          Result := NaturalCompare(ALeft.Value, ARight.Value);
      end));
  finally
    LGroups.Free;
  end;

  RenumberKeys;
end;

procedure TProjectEntryList.RenumberKeys;
var
  LIndex: Integer;
begin
  for LIndex := 0 to Count - 1 do
    Items[LIndex].Key := PROJECT_KEY_PREFIX + LIndex.ToString;
end;

function TProjectEntryList.RemoveNotFound: Integer;
var
  LIndex: Integer;
begin
  Result := 0;

  for LIndex := Count - 1 downto 0 do
    if not Items[LIndex].IsFound then
    begin
      Delete(LIndex);
      Inc(Result);
    end;

  if Result > 0 then
    RenumberKeys;
end;

end.
