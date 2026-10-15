unit DIFFForm.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, DIFF.ProjectEntries;

type
  TDIFFMainForm = class(TForm)
    ButtonClosedSort: TButton;
    ButtonFavoritesRemoveMissing: TButton;
    ButtonFavoritesSort: TButton;
    ButtonReload: TButton;
    ButtonWriteRegistry: TButton;
    GroupBoxClosed: TGroupBox;
    GroupBoxFavorites: TGroupBox;
    LabelSortPaths: TLabel;
    MemoSortPaths: TMemo;
    PanelBottom: TPanel;
    PanelClosedButtons: TPanel;
    PanelFavoritesButtons: TPanel;
    PanelSortPaths: TPanel;
    SplitterGrids: TSplitter;
    StringGridClosed: TStringGrid;
    StringGridFavorites: TStringGrid;
    procedure ButtonClosedRemoveMissingClick(Sender: TObject);
    procedure ButtonClosedSortClick(Sender: TObject);
    procedure ButtonFavoritesRemoveMissingClick(Sender: TObject);
    procedure ButtonFavoritesSortClick(Sender: TObject);
    procedure ButtonReloadClick(Sender: TObject);
    procedure ButtonWriteRegistryClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure StringGridDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
  strict private
    FFavorites: TProjectEntryList;
    FClosed: TProjectEntryList;
    function GetGridEntries(const AGrid: TStringGrid): TProjectEntryList;
    function GetIniFileName: string;
    function GetSortPaths: TArray<string>;
    procedure AdjustColumnWidths(const AGrid: TStringGrid);
    procedure FillGrid(const AGrid: TStringGrid; const AEntries: TProjectEntryList);
    procedure FillGrids;
    procedure LoadFromRegistry;
    procedure LoadSortPaths;
    procedure RemoveNotFound(const AGrid: TStringGrid; const AEntries: TProjectEntryList);
    procedure SaveSortPaths;
    procedure SortEntries(const AGrid: TStringGrid; const AEntries: TProjectEntryList);
  end;

var
  DIFFMainForm: TDIFFMainForm;

implementation

uses
  System.IniFiles, System.Math, System.UITypes, Winapi.TlHelp32, DIFF.ProjectRegistry;

{$R *.dfm}

const
  INI_SECTION_SORT_PATHS = 'SortPaths';
  INI_KEY_SORT_PATH = 'Path';
  DELPHI_IDE_EXE_NAME = 'bds.exe';

function IsProcessRunning(const AExeName: string): Boolean;
var
  LSnapshot: THandle;
  LEntry: TProcessEntry32;
begin
  Result := False;

  LSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if LSnapshot = INVALID_HANDLE_VALUE then
    Exit;

  try
    LEntry.dwSize := SizeOf(LEntry);

    if Process32First(LSnapshot, LEntry) then
      repeat
        if SameText(string(LEntry.szExeFile), AExeName) then
          Exit(True);
      until not Process32Next(LSnapshot, LEntry);
  finally
    CloseHandle(LSnapshot);
  end;
end;

procedure TDIFFMainForm.FormCreate(Sender: TObject);
begin
  FFavorites := TProjectEntryList.Create;
  FClosed := TProjectEntryList.Create;

  LoadSortPaths;
  LoadFromRegistry;
end;

procedure TDIFFMainForm.FormDestroy(Sender: TObject);
begin
  FClosed.Free;
  FFavorites.Free;
end;

procedure TDIFFMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSortPaths;
end;

function TDIFFMainForm.GetIniFileName: string;
begin
  Result := ChangeFileExt(Application.ExeName, '.ini');
end;

function TDIFFMainForm.GetSortPaths: TArray<string>;
var
  LLine: string;
begin
  Result := [];

  for LLine in MemoSortPaths.Lines do
    if Trim(LLine) <> '' then
      Result := Result + [Trim(LLine)];
end;

function TDIFFMainForm.GetGridEntries(const AGrid: TStringGrid): TProjectEntryList;
begin
  if AGrid = StringGridFavorites then
    Result := FFavorites
  else
    Result := FClosed;
end;

procedure TDIFFMainForm.LoadSortPaths;
var
  LIniFile: TMemIniFile;
  LIndex: Integer;
begin
  MemoSortPaths.Lines.Clear;

  LIniFile := TMemIniFile.Create(GetIniFileName, TEncoding.UTF8);
  try
    LIndex := 0;
    while LIniFile.ValueExists(INI_SECTION_SORT_PATHS, INI_KEY_SORT_PATH + LIndex.ToString) do
    begin
      MemoSortPaths.Lines.Add(LIniFile.ReadString(INI_SECTION_SORT_PATHS, INI_KEY_SORT_PATH + LIndex.ToString, ''));
      Inc(LIndex);
    end;
  finally
    LIniFile.Free;
  end;
end;

procedure TDIFFMainForm.SaveSortPaths;
var
  LIniFile: TMemIniFile;
  LSortPaths: TArray<string>;
  LIndex: Integer;
begin
  LSortPaths := GetSortPaths;

  LIniFile := TMemIniFile.Create(GetIniFileName, TEncoding.UTF8);
  try
    LIniFile.EraseSection(INI_SECTION_SORT_PATHS);

    for LIndex := 0 to High(LSortPaths) do
      LIniFile.WriteString(INI_SECTION_SORT_PATHS, INI_KEY_SORT_PATH + LIndex.ToString, LSortPaths[LIndex]);

    LIniFile.UpdateFile;
  finally
    LIniFile.Free;
  end;
end;

procedure TDIFFMainForm.LoadFromRegistry;
begin
  LoadProjectEntries(FAVORITE_PROJECTS_KEY, FFavorites);
  LoadProjectEntries(CLOSED_PROJECTS_KEY, FClosed);

  FillGrids;
end;

procedure TDIFFMainForm.FillGrid(const AGrid: TStringGrid; const AEntries: TProjectEntryList);
var
  LIndex: Integer;
begin
  // Grid needs at least one non-fixed row
  AGrid.RowCount := Max(AEntries.Count, 1) + 1;

  AGrid.Cells[0, 0] := 'Key';
  AGrid.Cells[1, 0] := 'Value';

  if AEntries.Count = 0 then
  begin
    AGrid.Cells[0, 1] := '';
    AGrid.Cells[1, 1] := '';
  end;

  for LIndex := 0 to AEntries.Count - 1 do
  begin
    AGrid.Cells[0, LIndex + 1] := AEntries[LIndex].Key;
    AGrid.Cells[1, LIndex + 1] := AEntries[LIndex].Value;
  end;

  // Vertical scroll bar may have appeared or disappeared
  AdjustColumnWidths(AGrid);
  AGrid.Invalidate;
end;

procedure TDIFFMainForm.FillGrids;
begin
  FillGrid(StringGridFavorites, FFavorites);
  FillGrid(StringGridClosed, FClosed);
end;

procedure TDIFFMainForm.RemoveNotFound(const AGrid: TStringGrid; const AEntries: TProjectEntryList);
begin
  AEntries.RemoveNotFound;

  FillGrid(AGrid, AEntries);
end;

procedure TDIFFMainForm.SortEntries(const AGrid: TStringGrid; const AEntries: TProjectEntryList);
begin
  SaveSortPaths;

  AEntries.SortByPaths(GetSortPaths);

  FillGrid(AGrid, AEntries);
end;

procedure TDIFFMainForm.StringGridDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
var
  LGrid: TStringGrid;
  LEntries: TProjectEntryList;
  LText: string;
  LTextRect: TRect;
begin
  if (ARow < 1) or (gdSelected in State) then
    Exit;

  LGrid := Sender as TStringGrid;
  LEntries := GetGridEntries(LGrid);

  if (ARow > LEntries.Count) or LEntries[ARow - 1].IsFound then
    Exit;

  // Path and/or file not found from the disk: redraw text in gray, same layout as TStringGrid.DrawCell
  LText := LGrid.Cells[ACol, ARow];
  LGrid.Canvas.Brush.Color := LGrid.Color;
  LGrid.Canvas.FillRect(Rect);
  LGrid.Canvas.Font.Color := clGrayText;

  LTextRect := Rect;
  LTextRect.Inflate(-1, -1);
  LGrid.Canvas.TextRect(LTextRect, LTextRect.Left + 5,
    LTextRect.Top + (LTextRect.Height - LGrid.Canvas.TextHeight(LText)) div 2, LText);
end;

procedure TDIFFMainForm.FormResize(Sender: TObject);
begin
  // TStringGrid does not publish OnResize, grids follow the form width
  AdjustColumnWidths(StringGridFavorites);
  AdjustColumnWidths(StringGridClosed);
end;

procedure TDIFFMainForm.AdjustColumnWidths(const AGrid: TStringGrid);
begin
  // Value column fills the rest of the grid
  AGrid.ColWidths[1] := Max(AGrid.ClientWidth - AGrid.ColWidths[0] - AGrid.GridLineWidth * 2, 100);
end;

procedure TDIFFMainForm.ButtonFavoritesRemoveMissingClick(Sender: TObject);
begin
  RemoveNotFound(StringGridFavorites, FFavorites);
end;

procedure TDIFFMainForm.ButtonFavoritesSortClick(Sender: TObject);
begin
  SortEntries(StringGridFavorites, FFavorites);
end;

procedure TDIFFMainForm.ButtonClosedRemoveMissingClick(Sender: TObject);
begin
  RemoveNotFound(StringGridClosed, FClosed);
end;

procedure TDIFFMainForm.ButtonClosedSortClick(Sender: TObject);
begin
  SortEntries(StringGridClosed, FClosed);
end;

procedure TDIFFMainForm.ButtonReloadClick(Sender: TObject);
begin
  LoadFromRegistry;
end;

procedure TDIFFMainForm.ButtonWriteRegistryClick(Sender: TObject);
begin
  // IDE writes these keys when it exits, which would overwrite our changes
  if IsProcessRunning(DELPHI_IDE_EXE_NAME) then
  begin
    MessageDlg('Delphi IDE (' + DELPHI_IDE_EXE_NAME + ') is running.' + sLineBreak + sLineBreak +
      'Close it first, it overwrites these values when it exits.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if MessageDlg('Write Favorite Projects and Closed Projects to the registry?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  SaveProjectEntries(FAVORITE_PROJECTS_KEY, FFavorites);
  SaveProjectEntries(CLOSED_PROJECTS_KEY, FClosed, MAX_CLOSED_FILES_VALUE);

  FillGrids;

  MessageDlg('Written to the registry.', mtInformation, [mbOK], 0);
end;

end.
