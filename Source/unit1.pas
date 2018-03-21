unit Unit1;

interface

{$WARN SYMBOL_PLATFORM OFF}
{$WARN UNIT_PLATFORM OFF}
{$BOOLEVAL OFF} // Unit depends on short-circuit boolean evaluation

{.$DEFINE SPDEBUGMODE} // Uncomment to debug

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, ActnList, CheckLst, Contnrs,
  IniFiles, Actions, SpComponentInstaller;

const
  rvMultiInstallerVersion = 'Silverpoint MultiInstaller 3.5.4';
  rvMultiInstallerLink = 'http://www.silverpointdevelopment.com';

resourcestring
  SWelcomeTitle = 'Welcome to the Silverpoint MultiInstaller Setup Wizard';
  SDestinationTitle = 'Select Destination Folder';
  SInstallingTitle = 'Installing...';
  SFinishTitle = 'Completing the MultiInstaller Setup Wizard';

  SCloseDelphi = 'Close Delphi to continue.';
  SErrorLabel = 'There were errors found in the setup, check the log.';
  SErrorInvalidBasePath = 'The directory doesn''t exist.';

  SErrorDetectingBDSPROJECTSDIR = 'Silverpoint MultiInstaller couldn''t detect the $(BDSPROJECTSDIR) directory.' + #13#10 +
                                  'You are probably using the Japanese version of Delphi 2009.' + #13#10 +
                                  'Please, send a bug report to the author: ' + rvMultiInstallerLink;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    Panel1: TPanel;
    ButtonNext: TButton;
    ButtonBack: TButton;
    Panel2: TPanel;
    LabelTitle: TLabel;
    Label1: TLabel;
    ButtonCancel: TButton;
    InstallFolderEdit: TEdit;
    ButtonBrowse: TButton;
    Label2: TLabel;
    ActionList1: TActionList;
    aBack: TAction;
    aNext: TAction;
    aCancel: TAction;
    aBrowse: TAction;
    RadioGroup1: TRadioGroup;
    CompileCheckbox: TCheckBox;
    Label3: TLabel;
    FinishLabel: TLabel;
    ButtonFinish: TButton;
    Bevel1: TBevel;
    Button1: TButton;
    aSaveLog: TAction;
    aFinish: TAction;
    SaveDialog1: TSaveDialog;
    LogMemo: TMemo;
    CheckListBox1: TCheckListBox;
    Timer1: TTimer;
    Bevel2: TBevel;
    PaintBoxLabel: TPaintBox;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure aBrowseExecute(Sender: TObject);
    procedure aBackExecute(Sender: TObject);
    procedure aNextExecute(Sender: TObject);
    procedure aCancelExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure CompileCheckboxClick(Sender: TObject);
    procedure aSaveLogExecute(Sender: TObject);
    procedure aFinishExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CheckListBox1DrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure CheckListBox1MeasureItem(Control: TWinControl;
      Index: Integer; var Height: Integer);
    procedure CheckListBox1ClickCheck(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure PaintBoxLabelPaint(Sender: TObject);
    procedure PaintBoxLabelClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    AppPath: string;
    Installer: TSpMultiInstaller;
    procedure FillCheckListBox;
    procedure FillRadioGroup;
    function ValidateCheckListBox: Boolean;
    function ChangePage(Next: Boolean): Boolean;
    function Install: Boolean;
    procedure CloseDelphi;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  System.UITypes;

const
  rvSetupIni = 'Setup.Ini';
  crIDC_HAND = 32649;

//WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM
{ Form UI }

procedure TForm1.FormCreate(Sender: TObject);
begin
  Screen.Cursors[crIDC_HAND] := LoadCursor(0, IDC_HAND);
  PaintBoxLabel.Cursor := crIDC_HAND;
  AppPath := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));

  Installer := TSpMultiInstaller.Create(AppPath + rvSetupIni);
  PageControl1.ActivePageIndex := 0;
  LabelTitle.Caption := SWelcomeTitle;
  SaveDialog1.InitialDir := AppPath;
  FillCheckListBox;
  FillRadioGroup;
  ValidateCheckListBox;

  {$IFDEF SPDEBUGMODE}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Installer.Free;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  CloseDelphi;

  if DirectoryExists(Installer.ComponentPackages.DefaultInstallFolder) then begin
    InstallFolderEdit.Text := Installer.ComponentPackages.DefaultInstallFolder;
    if CompileCheckbox.Checked then begin
      PageControl1.ActivePageIndex := PageControl1.PageCount - 1;
      Timer1.Enabled := True; // Delay it a little for UI responsiveness
    end;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  Install;
end;

function TForm1.ChangePage(Next: Boolean): Boolean;
var
  I, C: Integer;
begin
  Result := False;
  I := PageControl1.ActivePageIndex;
  C := PageControl1.PageCount - 1;

  if Next then begin
    if I = C then Exit
    else
      if I = 1 then
        if not DirectoryExists(InstallFolderEdit.Text) then begin
          MessageDlg(SErrorInvalidBasePath, mtWarning, [mbOK], 0);
          Exit;
        end;
  end
  else
    if I = 0 then Exit;

  Result := True;
  if Next then inc(I)
  else dec(I);
  PageControl1.ActivePageIndex := I;

  ButtonBack.Enabled := I > 0;
  case I of
    0: LabelTitle.Caption := SWelcomeTitle;
    1: LabelTitle.Caption := SDestinationTitle;
    2: begin
         LabelTitle.Caption := SInstallingTitle;
         Timer1.Enabled := True; // Delay it a little for UI responsiveness
       end;
  else
    LabelTitle.Caption := '';
  end;
end;

procedure TForm1.CompileCheckboxClick(Sender: TObject);
begin
  RadioGroup1.Enabled := CompileCheckbox.Checked;
end;

procedure TForm1.FillCheckListBox;
var
  I, G, P: Integer;
begin
  for I := 0 to Installer.ComponentPackages.Count - 1 do begin
    P := -1;
    G := Installer.ComponentPackages[I].GroupIndex;
    if G > 0 then begin
      P := CheckListBox1.Items.IndexOfObject(Pointer(G));
      if P > -1 then
        CheckListBox1.Items[P] := CheckListBox1.Items[P] + #13#10 + Installer.ComponentPackages[I].Name
    end;

    if P = -1 then begin
      P := CheckListBox1.Items.AddObject(Installer.ComponentPackages[I].Name, Pointer(G));
      CheckListBox1.Checked[P] := True;
    end;
  end;
end;

procedure TForm1.FillRadioGroup;
var
  IDE: TSpIDEType;
begin
  RadioGroup1.ItemIndex := -1;

  for IDE := Low(TSpIDEType) to High(TSpIDEType) do
    if IDE >= Installer.ComponentPackages.MinimumIDE then
      if SpIDEInstalled(IDE) then begin
        RadioGroup1.Items.AddObject(IDETypes[IDE].IDEName, Pointer(Ord(IDE)));
        if IDE = Installer.ComponentPackages.DefaultInstallIDE then
          RadioGroup1.ItemIndex := RadioGroup1.Items.Count - 1;
      end;

  if RadioGroup1.ItemIndex = -1 then
    RadioGroup1.ItemIndex := RadioGroup1.Items.Count - 1
  else
    CompileCheckbox.Checked := True;
end;

function TForm1.ValidateCheckListBox: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to CheckListBox1.Count - 1 do
    if CheckListBox1.Checked[I] then begin
      Result := True;
      Break;
    end;

  ButtonNext.Enabled := Result;
end;

procedure TForm1.CheckListBox1ClickCheck(Sender: TObject);
begin
  ValidateCheckListBox;
end;

procedure TForm1.CheckListBox1MeasureItem(Control: TWinControl;
  Index: Integer; var Height: Integer);
var
  R: TRect;
begin
  if Index > -1 then
    Height := DrawText(CheckListBox1.Canvas.Handle, PChar(CheckListBox1.Items[Index]), -1, R, DT_CALCRECT) + 4;
end;

procedure TForm1.CheckListBox1DrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin
  if Index > -1 then begin
    CheckListBox1.Canvas.FillRect(Rect);
  OffsetRect(Rect, 8, 2);
    DrawText(CheckListBox1.Canvas.Handle, PChar(CheckListBox1.Items[Index]), -1, Rect, 0);
  end;
end;

procedure TForm1.PaintBoxLabelPaint(Sender: TObject);
var
  C: TCanvas;
begin
  C := PaintBoxLabel.Canvas;
  C.Brush.Style := bsClear;
  C.Font.Color := clBtnHighlight;
  C.TextOut(1, 1, rvMultiInstallerVersion);
  C.Font.Color := clBtnShadow;
  C.TextOut(0, 0, rvMultiInstallerVersion);
end;

procedure TForm1.PaintBoxLabelClick(Sender: TObject);
begin
  SpOpenLink(rvMultiInstallerLink);
end;

//WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM
{ Actions }

procedure TForm1.aBackExecute(Sender: TObject);
begin
  ChangePage(False);
end;

procedure TForm1.aNextExecute(Sender: TObject);
begin
  ChangePAge(True);
end;

procedure TForm1.aCancelExecute(Sender: TObject);
begin
  Close;
end;

procedure TForm1.aFinishExecute(Sender: TObject);
begin
  Close;
end;

procedure TForm1.aSaveLogExecute(Sender: TObject);
begin
  if SaveDialog1.Execute then
    LogMemo.Lines.SaveToFile(SaveDialog1.FileName);
end;

procedure TForm1.aBrowseExecute(Sender: TObject);
var
  D: string;
begin
  D := ExtractFileDir(Application.ExeName);
  if SpSelectDirectory('', '', D) then
    InstallFolderEdit.Text := D;
end;

//WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM
{ Install }

procedure TForm1.CloseDelphi;
var
  Cancel: Boolean;
begin
  {$IFDEF SPDEBUGMODE}
  Exit;
  {$ENDIF}

  Cancel := False;
  while not Cancel and ((FindWindow('TAppBuilder', nil) <> 0) or (FindWindow('TAppBuilder', nil) <> 0)) do
    Cancel := MessageDlg(SCloseDelphi, mtWarning, [mbOK, mbCancel], 0) = mrCancel;
  if Cancel then
    Close;
end;

function TForm1.Install: Boolean;
var
  I, J, G: Integer;
  IDE: TSpIDEType;
begin
  Result := False;

  // Get IDE version
  IDE := ideNone;
  I := RadioGroup1.ItemIndex;
  if (CompileCheckbox.Checked) and (I > -1) and Assigned(RadioGroup1.Items.Objects[I]) then begin
    IDE := TSpIDEType(RadioGroup1.Items.Objects[I]);
    // Try to detect BDS Project Dir
    // BDS doesn't define $(BDSPROJECTSDIR) in the registry we have to detect it
    if IDE > ideDelphi7 then
      if SpIDEBDSProjectsDir(IDE) = '' then begin
        MessageDlg(SErrorDetectingBDSPROJECTSDIR, mtError, [mbOK], 0);
        Close;
        Exit;
      end;
  end;

  // Delete unchecked components from the ComponentPackages list
  for I := 0 to CheckListBox1.Count - 1 do
    if not CheckListBox1.Checked[I] then begin
      G := Integer(CheckListBox1.Items.Objects[I]);
      for J := Installer.ComponentPackages.Count - 1 downto 0 do
        if (G > 0) and (Installer.ComponentPackages[J].GroupIndex = G) then
          Installer.ComponentPackages.Delete(J)
        else
          if CheckListBox1.Items[I] = Installer.ComponentPackages[J].Name then
            Installer.ComponentPackages.Delete(J);
    end;

  CloseDelphi;
  try
    aFinish.Visible := True;
    aSaveLog.Visible := True;
    aBack.Visible := False;
    aNext.Visible := False;
    aCancel.Visible := False;
    Application.ProcessMessages;

    // Check, Unzip, Patch, Compile, Install
    if Installer.Install(AppPath, InstallFolderEdit.Text, IDE, LogMemo.Lines) then
      Result := True;
  finally
    LabelTitle.Caption := SFinishTitle;
    aFinish.Enabled := True;
    aSaveLog.Enabled := True;
    if not Result then begin
      FinishLabel.Font.Color := clRed;
      FinishLabel.Caption := SErrorLabel;
    end;
    FinishLabel.Visible := True;
  end;
end;

end.
