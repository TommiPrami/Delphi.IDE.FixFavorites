unit DIFF.ProjectRegistry;

interface

uses
  DIFF.ProjectEntries;

const
  BDS_REGISTRY_KEY = 'Software\Embarcadero\BDS\37.0';
  FAVORITE_PROJECTS_KEY = BDS_REGISTRY_KEY + '\Favorite Projects';
  CLOSED_PROJECTS_KEY = BDS_REGISTRY_KEY + '\Closed Projects';
  MAX_CLOSED_FILES_VALUE = 'Max Closed Files';

  ///  <summary>
  ///    Reads File_N values of the key (HKEY_CURRENT_USER) into the list, in natural key order.
  ///  </summary>
  procedure LoadProjectEntries(const AKey: string; const AEntries: TProjectEntryList);

  ///  <summary>
  ///    Replaces all File_N values of the key with the entries, renumbered from File_0.
  ///    Writes AMaxCountValueName (if given) as the number of entries.
  ///  </summary>
  procedure SaveProjectEntries(const AKey: string; const AEntries: TProjectEntryList;
    const AMaxCountValueName: string = '');

implementation

uses
  System.Classes, System.StrUtils, System.SysUtils, System.Win.Registry, Winapi.Windows;

procedure LoadProjectEntries(const AKey: string; const AEntries: TProjectEntryList);
var
  LRegistry: TRegistry;
  LNames: TStringList;
  LName: string;
begin
  AEntries.Clear;

  LRegistry := TRegistry.Create(KEY_READ);
  LNames := TStringList.Create;
  try
    LRegistry.RootKey := HKEY_CURRENT_USER;

    if not LRegistry.OpenKeyReadOnly(AKey) then
      Exit;

    LRegistry.GetValueNames(LNames);

    for LName in LNames do
      if StartsText(PROJECT_KEY_PREFIX, LName) and (LRegistry.GetDataType(LName) in [rdString, rdExpandString]) then
        AEntries.Add(TProjectEntry.Create(LName, LRegistry.ReadString(LName)));

    AEntries.SortByKey;
  finally
    LNames.Free;
    LRegistry.Free;
  end;
end;

procedure SaveProjectEntries(const AKey: string; const AEntries: TProjectEntryList;
  const AMaxCountValueName: string = '');
var
  LRegistry: TRegistry;
  LNames: TStringList;
  LName: string;
  LEntry: TProjectEntry;
begin
  // IDE reads File_0..File_(N-1), so there must be no gaps
  AEntries.RenumberKeys;

  LRegistry := TRegistry.Create(KEY_READ or KEY_WRITE);
  LNames := TStringList.Create;
  try
    LRegistry.RootKey := HKEY_CURRENT_USER;

    if not LRegistry.OpenKey(AKey, True) then
      raise ERegistryException.CreateFmt('Cannot open registry key "HKEY_CURRENT_USER\%s" for writing', [AKey]);

    LRegistry.GetValueNames(LNames);

    for LName in LNames do
      if StartsText(PROJECT_KEY_PREFIX, LName) then
        LRegistry.DeleteValue(LName);

    for LEntry in AEntries do
      LRegistry.WriteString(LEntry.Key, LEntry.Value);

    if AMaxCountValueName <> '' then
      LRegistry.WriteInteger(AMaxCountValueName, AEntries.Count);
  finally
    LNames.Free;
    LRegistry.Free;
  end;
end;

end.
