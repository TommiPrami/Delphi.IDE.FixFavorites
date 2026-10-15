program DelphiIDEFixFavorites;

uses
  Vcl.Forms,
  DIFFForm.Main in 'Source\Forms\DIFFForm.Main.pas' {DIFFMainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDIFFMainForm, DIFFMainForm);
  Application.Run;
end.
