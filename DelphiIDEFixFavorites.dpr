program DelphiIDEFixFavorites;

uses
  Vcl.Forms,
  DIFFForm.Main in 'Source\Forms\DIFFForm.Main.pas' {DIFFMainForm},
  DIFF.ProjectEntries in 'Source\DIFF.ProjectEntries.pas',
  DIFF.ProjectRegistry in 'Source\DIFF.ProjectRegistry.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDIFFMainForm, DIFFMainForm);
  Application.Run;
end.
