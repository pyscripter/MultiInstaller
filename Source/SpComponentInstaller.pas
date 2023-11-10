unit SpComponentInstaller;

{==============================================================================
Version 3.5.3

The contents of this package are licensed under a disjunctive tri-license
giving you the choice of one of the three following sets of free
software/open source licensing terms:
  - Mozilla Public License, version 1.1
  - GNU General Public License, version 2.0
  - GNU Lesser General Public License, version 2.1

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The initial developer of this code is Robert Lee.
http://www.silverpointdevelopment.com

Development notes:
  - All the Delphi IDE changes are marked with: [IDE-Change].
  - All the Delphi IDE update changes are marked with: [IDE-Change-Update].
  - dcc32.exe won't execute if -Q option is not used.
    But it works fine without -Q if ShellExecute is used:
      ShellExecute(Application.Handle, 'open', DCC, ExtractFileName(PackageFilename), ExtractFilePath(PackageFilename), SW_SHOWNORMAL);
    There must be something wrong with SpExecuteDosCommand.
  - It seems that deleting the previous bpl and dcp files are not necessary.
  - Undocumented dcc32.exe -JL compiler switch, used to make Hpp files
    required for C++Builder 2006 and above.
    http://groups.google.com/group/borland.public.cppbuilder.ide/browse_thread/thread/456bece4c5665459/0c4c61ecec179ca8

History:
21 May 2016 - version 2.5.3
  - Added support for RAD Studio XE8, RAD Studio 10 Seattle and RAD Studio 10.1 Berlin

28 October 2014 - version 3.5.2
  - Added RAD Studio XE7 support.

26 May 2014 - version 3.5.1
  - Added RAD Studio XE6 support.

18 March 2014 - version 3.5
  - Added RAD Studio XE4 and XE5 support.

20 April 2013 - version 3.4.8
  - Added Delphi XE3 and C++ Builder XE3 support.

7 February 2012 - version 3.4.7
  - Added Delphi XE2 and C++ Builder XE2 support.

25 June 2011 - version 3.4.6
  - Added Delphi XE and C++ Builder XE support.

29 August 2009 - version 3.4.5
  - Added Delphi 2010 and C++ Builder 2010 support.

15 March 2009 - version 3.4.4
  - MultiInstaller is now tri-licensed, you can choose between
    MPL, GPL and LGPL.

1 March 2009 - version 3.4.3
  - Stéphane Wierzbicki improved the SpExecuteDosCommand utility
    function and added multiple SearchPaths handling, like
    the Includes parameter, the SearchPath parameter should either
    contain one source directory or multiple ones. For the later,
    strings must be enclosed by double quotes and separated by comma.

17 January 2009 - version 3.4.2
  - Fixed incorrect French translation of the RAD Studio Project
    directory, thanks to Stéphane Wierzbicki for reporting it.

26 September 2008 - version 3.4.1
  - Added Delphi 2009 and C++ Builder 2009 support.

4 September 2007 - version 3.4
  - Added Delphi 2007 and C++ Builder 2007 support.

24 November 2006 - version 3.3.1
  - Added extra check to use -JL compiler switch, it will be used
    only if the C++Builder personality is installed.

27 August 2006 - version 3.3
  - Minor fixes.

27 June 2006 - version 3.2
  - Added multilanguage support for Delphi and C++Builder, it
    now supports English, French, German and Japanese IDEs.

15 June 2006 - version 3.1
  - Added Environment Variables Overrides support, thanks to
    Wyk for implementing this.
  - Added -R dcc32.exe compiler switch support to make the
    components source directory the default *.dcr search
    folder, thanks to Wyk for reporting this.
  - Improved the "Intallable" directive, it is now possible to install a
    package that doesn't have components, this is useful when installing
    utility libraries, for example GraphicEx, GDI+, DirectX, etc.

27 February 2006 - version 3.0
  - Added support for C++Builder 2006.

10 February 2006 - version 2.0
  - Added support for BDS 2006.
  - Added support for $LIBSUFFIX package compiler directive.
  - Replaced the zip library with Abbrevia.

18 August 2005 - version 1.0
  - Initial release.

==============================================================================}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$WARN UNIT_PLATFORM OFF}
{$BOOLEVAL OFF} // Unit depends on short-circuit boolean evaluation

uses
  Windows, Messages, SysUtils, Classes, Forms, Contnrs;

resourcestring
  SLogStartUnzip   = '=========================================' + #13#10 +
                     'Unzipping - Cloning' + #13#10 +
                     '=========================================';
  SLogStartExecute = '=========================================' + #13#10 +
                     'Executing patches' + #13#10 +
                     '=========================================';
  SLogStartCompile = '=========================================' + #13#10 +
                     'Compiling and installing:' + #13#10 +
                     '%s' + #13#10 +
                     '=========================================';
  SLogEnd          = '=========================================' + #13#10 +
                     'Finished' + #13#10 +
                     '=========================================';

  SLogInvalidPath = 'Error: %s doesn''t exist.';
  SNoZipFile = 'No zip file for %s.  Proceeding without unzipping';
  SLogInvalidIDE = 'Error: %s is not installed.';
  SLogInvalidZip = 'Error: %s doesn''t exist.';
  SLogNotAZip = 'Error: %s is not a zip file.';
  SLogNotAGit = 'Error: %s is not a Git repository.';
  SGitCloneCommand = 'git clone %s %s';
  SLogCorruptedZip = 'Error: %s is corrupted.';
  SLogGitCloneFailed = 'Error: in git clone %s';

  SLogErrorCopying = 'Error copying %s to %s';
  SLogErrorDeleting = 'Error deleting %s';
  SLogErrorExecuting = 'Error executing %s';
  SLogErrorCompiling = 'Error compiling %s';

  SLogCopying = 'Copying:' +  #13#10 + '     %s' + #13#10 + 'To:' + #13#10 + '     %s';
  SLogExecuting = 'Executing:' +  #13#10 + '     %s';
  SLogExtracting = 'Extracting:' +  #13#10 + '     %s' + #13#10 + 'To:' + #13#10 + '     %s';
  SLogCloning = 'Cloning:' +  #13#10 + '     %s' + #13#10 + 'To:' + #13#10 + '     %s';
  SLogCompiling = 'Compiling Package: %s';
  SLogInstalling = 'Installing Package: %s';
  SLogFinished = 'All the component packages have been successfully installed.' + #13#10 + 'Elapsed time: %f secs.';

type
  TSpIDEType = (        // [IDE-Change-Update]
    ideNone,            //
    ideDelphi7,         // D7
    ideDelphi2005,      // D9
    ideDelphi2006,      // D10
    ideDelphi2007,      // D11
    ideDelphi2009,      // D12
    ideDelphi2010,      // D14
    ideDelphiXE,        // D15
    ideDelphiXE2,       // D16
    ideDelphiXE3,       // D17
    ideDelphiXE4,       // D18
    ideDelphiXE5,       // D19
    ideDelphiXE6,       // D20
    ideDelphiXE7,       // D21
    ideDelphiXE8,       // D22
    ideDelphiSeattle,   // D23
    ideDelphiBerlin,    // D24
    ideDelphiTokyo,     // D25
    ideDelphiRio,       // D26
    ideDelphiDenali,    // D27
    ideDelphiAlexandria,// D28
    ideDelphiAthens     // D29
  );

  TSpPlatform = (
    pltWin32,
    pltWin64
  );

  TSpIDETypeRec = record
    IDEVersion: string;
    IDEName: string;
    IDERegistryPath: string;
    IDERADStudioVersion: string;
  end;

const
  // [IDE-Change-Update]
  IDETypes: array [TSpIDEType] of TSpIDETypeRec = (
    (IDEVersion: 'None'; IDEName: 'None'; IDERegistryPath: 'None'; IDERADStudioVersion: ''),
    (IDEVersion: 'D7'; IDEName: 'Delphi 7'; IDERegistryPath: 'SOFTWARE\Borland\Delphi\7.0'; IDERADStudioVersion: ''),
    (IDEVersion: 'D9'; IDEName: 'Delphi 2005'; IDERegistryPath: 'SOFTWARE\Borland\BDS\3.0'; IDERADStudioVersion: '3.0'),
    (IDEVersion: 'D10'; IDEName: 'Developer Studio 2006'; IDERegistryPath: 'SOFTWARE\Borland\BDS\4.0'; IDERADStudioVersion: '4.0'),
    (IDEVersion: 'D11'; IDEName: 'RAD Studio 2007'; IDERegistryPath: 'SOFTWARE\Borland\BDS\5.0'; IDERADStudioVersion: '5.0'),
    (IDEVersion: 'D12'; IDEName: 'RAD Studio 2009'; IDERegistryPath: 'SOFTWARE\CodeGear\BDS\6.0'; IDERADStudioVersion: '6.0'),
    (IDEVersion: 'D14'; IDEName: 'RAD Studio 2010'; IDERegistryPath: 'SOFTWARE\CodeGear\BDS\7.0'; IDERADStudioVersion: '7.0'),
    (IDEVersion: 'D15'; IDEName: 'RAD Studio XE';  IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\8.0'; IDERADStudioVersion: '8.0'),
    (IDEVersion: 'D16'; IDEName: 'RAD Studio XE2'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\9.0'; IDERADStudioVersion: '9.0'),
    (IDEVersion: 'D17'; IDEName: 'RAD Studio XE3'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\10.0'; IDERADStudioVersion: '10.0'),
    (IDEVersion: 'D18'; IDEName: 'RAD Studio XE4'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\11.0'; IDERADStudioVersion: '11.0'),
    (IDEVersion: 'D19'; IDEName: 'RAD Studio XE5'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\12.0'; IDERADStudioVersion: '12.0'),
    (IDEVersion: 'D20'; IDEName: 'RAD Studio XE6'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\14.0'; IDERADStudioVersion: '14.0'),
    (IDEVersion: 'D21'; IDEName: 'RAD Studio XE7'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\15.0'; IDERADStudioVersion: '15.0'),
    (IDEVersion: 'D22'; IDEName: 'RAD Studio XE8'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\16.0'; IDERADStudioVersion: '16.0'),
    (IDEVersion: 'D23'; IDEName: 'RAD Studio 10 Seattle'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\17.0'; IDERADStudioVersion: '17.0'),
    (IDEVersion: 'D24'; IDEName: 'RAD Studio 10.1 Berlin'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\18.0'; IDERADStudioVersion: '18.0'),
    (IDEVersion: 'D25'; IDEName: 'RAD Studio 10.2 Tokyo'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\19.0'; IDERADStudioVersion: '19.0'),
    (IDEVersion: 'D26'; IDEName: 'RAD Studio 10.3 Rio'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\20.0'; IDERADStudioVersion: '20.0'),
    (IDEVersion: 'D27'; IDEName: 'RAD Studio 10.4 Denali'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\21.0'; IDERADStudioVersion: '21.0'),
    (IDEVersion: 'D28'; IDEName: 'RAD Studio 11 Alexandria'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\22.0'; IDERADStudioVersion: '22.0'),
    (IDEVersion: 'D29'; IDEName: 'RAD Studio 12 Athens'; IDERegistryPath: 'SOFTWARE\Embarcadero\BDS\23.0'; IDERADStudioVersion: '23.0')
  );

type
  TSpIDEPersonality = (persDelphiWin32, persDelphiNET, persCPPBuilder);  // [IDE-Change]

  TSpActionType = (satNone, satCopy, satCopyRun);

  TSpInstallType = (sitNotInstallable, sitInstallable, sitSearchPathOnly);

  TSpExecuteEntry = class
    Action: TSpActionType;
    Origin: string;
    Destination: string;
  end;

  TSpExecuteList = class(TObjectList)
  private
    function GetItems(Index: Integer): TSpExecuteEntry;
    procedure SetItems(Index: Integer; const Value: TSpExecuteEntry);
  public
    procedure LoadFromIni(Filename, Section: string);
    function ExecuteAll(BaseFolder: string; Log: TStrings): Boolean;
    property Items[Index: Integer]: TSpExecuteEntry read GetItems write SetItems; default;
  end;

  TSpComponentPackage = class
    Name: string;
    ZipFile: string;
    Git : string;
    Destination: string;
    SearchPath: string;
    Includes: string;
    Installable: TSpInstallType;
    LibSuffix : string;
    GroupIndex: Integer;
    ExecuteList: TSpExecuteList;
    PackageList: array [TSpIDEType] of string; // Array of commatext for each TSpIDEType i.e. ("Packages\SpTBXLib_XE8.dpk", "Packages\SpTBXLibDsgn_XE8.dpk")
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  TSpComponentPackageList = class(TObjectList)
  private
    FDefaultInstallIDE: TSpIDEType;
    FDefaultInstallFolder: string;
    FMinimumIDE: TSpIDEType;
    function GetItems(Index: Integer): TSpComponentPackage;
    procedure SetItems(Index: Integer; const Value: TSpComponentPackage);
  public
    procedure LoadFromIni(Filename: string);
    function ExtractAllZips(Source, Destination: string; Log: TStrings): Boolean;
    function ExecuteAll(BaseFolder: string; Log: TStrings): Boolean;
    function CompileAll(BaseFolder: string; IDE: TSpIDEType; Log: TStrings): Boolean;
    property DefaultInstallIDE: TSpIDEType read FDefaultInstallIDE write FDefaultInstallIDE;
    property DefaultInstallFolder: string read FDefaultInstallFolder write FDefaultInstallFolder;
    property Items[Index: Integer]: TSpComponentPackage read GetItems write SetItems; default;
    property MinimumIDE: TSpIDEType read FMinimumIDE;
  end;

  TSpMultiInstaller = class
  protected
    FComponentPackages: TSpComponentPackageList;
    FInstalling: Boolean;
  public
    constructor Create(IniFilename: string); virtual;
    destructor Destroy; override;
    function Install(ZipPath, BaseFolder: string; IDE: TSpIDEType; Log: TStrings): Boolean;
    property ComponentPackages: TSpComponentPackageList read FComponentPackages;
  end;

{ Misc }
procedure SpOpenLink(URL: string);
function SpStringSearch(S, SubStr: string; Delimiter: Char = ';'): Boolean;
procedure SpWriteLog(Log: TStrings; ResourceS, Arg1: string; Arg2: string = '');

{ Files }
function SpGetParameter(const ParamName: string; out ParamValue: string): Boolean;
function SpExecuteDosCommand(CommandLine, WorkDir: string; out OutputString: string): Cardinal;
function SpExtractZip(ZipFilename, DestinationPath: string): Boolean;
function SpCloneGit(AGit, DestinationPath, WorkDir: string; Log: TStrings): Boolean;
function SpFileOperation(Origin, Destination: string; Operation: Cardinal): Boolean;
function SpGetMyDocumentsFolder: string;
function SpGetCommonDocumentsFolder: string;
procedure SpGetWinDirs(out Windows, System, Temp: string);
function SpSelectDirectory(const Caption: string; const Root: WideString; var Directory: string): Boolean;

{ Ini and Registry }
function SpReadRegValue(Key, Name: string; out Value: string): Boolean;
function SpReadRegKey(Key: string; NamesAndValues: TStringList): Boolean;
function SpWriteRegValue(Key, Name, Value: string): Boolean;
procedure SpIniLoadStringList(L: TStringList; IniFilename, Section: string; NamePrefix: string = '');
procedure SpIniSaveStringList(L: TStringList; IniFilename, Section: string; NamePrefix: string = '');
function SpParseEntryValue(S: string; ValueList: TStringList; MinimumCount: Integer = 0): Boolean;

{ IDE }
function SpActionTypeToString(A: TSpActionType): string;
function SpStringToActionType(S: string): TSpActionType;
function SpStringToIDEType(S: string): TSpIDEType;
procedure SpIDEPersonalityTypeToString(A: TSpIDEPersonality; out IDERegName: string);
function SpIDEDir(IDE: TSpIDEType): string;
function SpIDEDCC32Path(IDE: TSpIDEType): string;
function SpIDEInstalled(IDE: TSpIDEType): Boolean;
function SpIDEPersonalityInstalled(IDE: TSpIDEType; IDEPersonality: TSpIDEPersonality): Boolean;
function SpIDESearchPath(IDE: TSpIDEType; CPPBuilderPath: Boolean; APlatform: TSpPlatform = pltWin32): string;
procedure SpIDEAddToSearchPath(SourcesL: TStrings; IDE: TSpIDEType);
function SpIDEBDSCommonDir(IDE: TSpIDEType): string;
function SpIDEBDSProjectsDir(IDE: TSpIDEType): string;
function SpIDEGetEnvironmentVars(IDE: TSpIDEType; IDEEnvVars: TStringList): Boolean;
function SpIDEExpandMacros(S: string; IDE: TSpIDEType): string;

{ Delphi Packages }
function SpGetPackageOptions(PackageFilename, LibSuffix, BPLDir: string; out RunTime, DesignTime: Boolean; out BPLFilename, Description: string): Boolean;
function SpCompilePackage(PackageFilename, DCC: string; IDE: TSpIDEType; SourcesL, IncludesL, Log: TStrings; LibSuffix: string; TempDir: string = ''): Boolean;
function SpRegisterPackage(PackageFilename, LibSuffix, BPLDir: string; IDE: TSpIDEType; Log: TStrings): Boolean;

implementation

uses
  ActiveX, ShellApi, ShlObj, IniFiles, Registry,
  System.Zip, // Abbrevia is not needed anymore
  StrUtils;

const
  rvCount = 'Count';
  rvPackageIniSectionPrefix = 'Package -';
  rvName = 'Name';
  rvZip = 'Zip';
  rvGit = 'Git';
  rvFolder = 'Folder';
  rvSearchPath = 'SearchPath';
  rvGroupIndex = 'GroupIndex';
  rvIncludes = 'Includes';
  rvInstallable = 'Installable';
  rvLibSuffix = 'LibSuffix';
  rvExecuteIniPrefix = 'Execute';
  rvBaseFolder = '$BaseFolder';
  rvOptionsIniSection = 'Options';
  rvDefaultInstallIDE = 'DefaultInstallIDE';
  rvDefaultInstallFolder = 'DefaultInstallFolder';
  rvMinimumIDE = 'MinimumIDEVersion';
  ActionTypes: array [TSpActionType] of string = ('none', 'copy', 'copyandrun');
  IDEPersonalityRegNameTypes: array [TSpIDEPersonality] of string = ('Delphi.Win32', 'Delphi.NET', 'BCB');

//WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM
{ Helpers }

procedure SpOpenLink(URL: string);
begin
  ShellExecute(Application.Handle, 'open', PChar(URL), '', '', SW_SHOWNORMAL);
end;

function SpStringSearch(S, SubStr: string; Delimiter: Char): Boolean;
var
  L: TStringList;
begin
  L :=  TStringList.Create;
  try
    L.StrictDelimiter := True;
    L.Delimiter := Delimiter;
    L.DelimitedText := S;
    Result := L.IndexOf(SubStr) > -1;
  finally
    L.free;
  end;
end;

procedure SpWriteLog(Log: TStrings; ResourceS, Arg1: string; Arg2: string = '');
begin
  if Assigned(Log) then begin
    Log.Add(Format(ResourceS, [Arg1, Arg2]));
    Log.Add('');
  end;
end;

//WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM
{ Files }

function SpGetParameter(const ParamName: string; out ParamValue: string): Boolean;
{ Determines whether a string was passed as a command line parameter to the
  application, and returns the parameter value if there is one.

  For example:
  File.exe /param1 c:\windows\internet files /param2 /param3
  File.exe /param1 "c:\windows\internet files" /param2 /param3
  File.exe -param1 c:\windows\internet files -param2 -param3
  File.exe -param1 "c:\windows\internet files" -param2 -param3

  SpGetParameter('param1', S) returns S = c:\windows\internet files }
var
  I: Integer;
  S: string;
begin
  Result := False;
  ParamValue := '';

  for I := 1 to ParamCount do begin
    S := ParamStr(I);
    if (S <> '') and ((S[1] = '/') or (S[1] = '-')) then begin
      if Result then
        Break  // Next switch reached
      else begin
        Delete(S, 1, 1);
        if (S <> '') and SameText(S, ParamName) then
          Result := True;  // Set flag
      end;
    end
    else
      if Result then
        ParamValue := ParamValue + S
  end;
end;

function SpExecuteDosCommand(CommandLine, WorkDir: string; out OutputString: string): Cardinal;
// Executes a DOS file, waits until it terminates and logs the output.
// CommandLine param can be a file name with params, for example: CMD.exe /c dir D:\mp3
// Ported by Stephane Wierzbicki from JclSysUtils.InternalExecute
const
  BufferSize = 255;
  NativeLineFeed       = Char(#10);
  NativeCarriageReturn = Char(#13);
  NativeCrLf           = string(#13#10);
var
  Buffer: array [0..BufferSize] of AnsiChar;
  TempOutput: string;
  PipeBytesRead: Cardinal;

  function MuteCRTerminatedLines(const RawOutput: string): string;
  const
    Delta = 1024;
  var
    BufPos, OutPos, LfPos, EndPos: Integer;
    C: Char;
  begin
    SetLength(Result, Length(RawOutput));
    OutPos := 1;
    LfPos := OutPos;
    EndPos := OutPos;
    for BufPos := 1 to Length(RawOutput) do
    begin
      if OutPos >= Length(Result)-2 then
        SetLength(Result, Length(Result) + Delta);
      C := RawOutput[BufPos];
      case C of
        NativeCarriageReturn:
          OutPos := LfPos;
        NativeLineFeed:
          begin
            OutPos := EndPos;
            Result[OutPos] := NativeCarriageReturn;
            Inc(OutPos);
            Result[OutPos] := C;
            Inc(OutPos);
            EndPos := OutPos;
            LfPos := OutPos;
          end;
      else
        Result[OutPos] := C;
        Inc(OutPos);
        EndPos := OutPos;
      end;
    end;
    SetLength(Result, OutPos - 1);
  end;

  function CharIsReturn(const C: Char): Boolean;
  begin
    Result := (C = NativeLineFeed) or (C = NativeCarriageReturn);
  end;

  procedure ProcessLine(LineEnd: Integer);
  begin
    if (TempOutput[LineEnd] <> NativeCarriageReturn) then
    begin
      while (LineEnd > 0) and CharIsReturn(TempOutput[LineEnd]) do
        Dec(LineEnd);
    end;
  end;

  procedure ProcessBuffer;
  begin
    Buffer[PipeBytesRead] := #0;
    TempOutput := TempOutput + string(Buffer);
  end;

// "outsourced" from Win32ExecAndRedirectOutput
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  SecurityAttr: TSecurityAttributes;
  PipeRead, PipeWrite: THandle;
  PWorkDirChar : PChar;
begin
  Result := $FFFFFFFF;
  SecurityAttr.nLength := SizeOf(SecurityAttr);
  SecurityAttr.lpSecurityDescriptor := nil;
  SecurityAttr.bInheritHandle := True;
  if not CreatePipe(PipeRead, PipeWrite, @SecurityAttr, 0) then
  begin
    Result := GetLastError;
    Exit;
  end;
  FillChar(StartupInfo, SizeOf(TStartupInfo), #0);
  StartupInfo.cb := SizeOf(TStartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
  StartupInfo.wShowWindow := SW_HIDE;
  StartupInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
  StartupInfo.hStdOutput := PipeWrite;
  StartupInfo.hStdError := PipeWrite;

  if WorkDir = '' then PWorkDirChar := nil
  else PWorkDirChar := PChar(WorkDir);

  if CreateProcess(nil, PChar(CommandLine), nil, nil, True, NORMAL_PRIORITY_CLASS,
    nil, PWorkDirChar, StartupInfo, ProcessInfo) then
  begin
    CloseHandle(PipeWrite);

    while ReadFile(PipeRead, Buffer, BufferSize, PipeBytesRead, nil) and (PipeBytesRead > 0) do
      ProcessBuffer;
    if (WaitForSingleObject(ProcessInfo.hProcess, INFINITE) = WAIT_OBJECT_0) and
      not GetExitCodeProcess(ProcessInfo.hProcess, Result) then
        Result := $FFFFFFFF;
    CloseHandle(ProcessInfo.hThread);
    CloseHandle(ProcessInfo.hProcess);
  end
  else
    CloseHandle(PipeWrite);
  CloseHandle(PipeRead);

  if TempOutput <> '' then
    OutputString := OutputString + MuteCRTerminatedLines(TempOutput);
end;

function SpExtractZip(ZipFilename, DestinationPath: string): Boolean;
begin
  if not DirectoryExists(DestinationPath) then
    CreateDir(DestinationPath);
  TZipFile.ExtractZipFile(ZipFilename, DestinationPath);
  Result := True;
end;

function SpCloneGit(AGit, DestinationPath, WorkDir: string; Log: TStrings): Boolean;
Var
  DosOutput : string;
begin
  if SpExecuteDosCommand(Format(SGitCloneCommand, [AGit, DestinationPath]), WorkDir, DosOutput) = 0 then
    Result := True
  else
    Result := False;
  if Assigned(Log) then
    Log.Text := Log.Text + DosOutput + #13#10;
end;

function SpFileOperation(Origin, Destination: string; Operation: Cardinal): Boolean;
var
  F: TShFileOpStruct;
begin
   Result := False;
   // Operation can be: FO_COPY, FO_MOVE, FO_DELETE, FO_RENAME
   if not (Operation in [FO_MOVE..FO_RENAME]) then Exit;

   Origin := Origin + #0#0;
   Destination := Destination + #0#0;

   FillChar(F, SizeOf(F), #0);
   F.Wnd := Application.Handle;
   F.wFunc := Operation;
   F.pFrom := PChar(Origin);
   F.pTo := PChar(Destination);
   F.fFlags := FOF_SILENT or FOF_NOCONFIRMATION or FOF_NOCONFIRMMKDIR;
   Result := SHFileOperation(F) = 0;
end;

function SpGetMyDocumentsFolder: string;
var
  TargetPIDL: PItemIDList;
  S: string;
begin
  Result := '';
  if Succeeded(SHGetSpecialFolderLocation(Application.Handle, CSIDL_PERSONAL, TargetPIDL)) then
  begin
    SetLength(S, MAX_PATH);
    FillChar(PChar(S)^, MAX_PATH, #0);
    if SHGetPathFromIDList(TargetPIDL, PChar(S)) then begin
      SetLength(S, StrLen(PChar(S)));
      Result := IncludeTrailingPathDelimiter(S);
    end;
  end;
end;

function SpGetCommonDocumentsFolder: string;
// Gets All Users\Documents folder.
// Gets Public\Documents folder on Vista
var
  TargetPIDL: PItemIDList;
  S: string;
begin
  Result := '';
  if Succeeded(SHGetSpecialFolderLocation(Application.Handle, CSIDL_COMMON_DOCUMENTS, TargetPIDL)) then
  begin
    SetLength(S, MAX_PATH);
    FillChar(PChar(S)^, MAX_PATH, #0);
    if SHGetPathFromIDList(TargetPIDL, PChar(S)) then begin
      SetLength(S, StrLen(PChar(S)));
      Result := IncludeTrailingPathDelimiter(S);
    end;
  end;
end;

procedure SpGetWinDirs(out Windows, System, Temp: string);
var
  S: string;
begin
  Windows := '';
  System := '';
  Temp := '';

  SetLength(S, MAX_PATH);
  if GetWindowsDirectory(PChar(S), MAX_PATH) <> 0 then begin
    SetLength(S, StrLen(PChar(S)));
    Windows := S;
  end;

  SetLength(S, MAX_PATH);
  if GetSystemDirectory(PChar(S), MAX_PATH) <> 0 then begin
    SetLength(S, StrLen(PChar(S)));
    System := S;
  end;

  SetLength(S, MAX_PATH);
  if GetTempPath(MAX_PATH, PChar(S)) <> 0 then begin
    SetLength(S, StrLen(PChar(S)));
    Temp := S;
  end;
end;

function SpSelectDirCB(Wnd: HWND; uMsg: UINT; lParam, lpData: LPARAM): Integer stdcall;
begin
  if (uMsg = BFFM_INITIALIZED) and (lpData <> 0) then
    SendMessage(Wnd, BFFM_SETSELECTION, Integer(True), lpdata);
  result := 0;
end;

function SpSelectDirectory(const Caption: string; const Root: WideString;
  var Directory: string): Boolean;
// SelectDirectory with new UI, Edit box and 'Create Folder' button
const
  BIF_NEWDIALOGSTYLE = $0040;
  BIF_USENEWUI = (BIF_NEWDIALOGSTYLE or BIF_EDITBOX);
var
  WindowList: Pointer;
  BrowseInfo: TBrowseInfo;
  Buffer: PChar;
  OldErrorMode: Cardinal;
  RootItemIDList, ItemIDList: PItemIDList;
  ShellMalloc: IMalloc;
  IDesktopFolder: IShellFolder;
  Eaten, Flags: LongWord;
begin
  Result := False;
  if not DirectoryExists(Directory) then
    Directory := '';
  FillChar(BrowseInfo, SizeOf(BrowseInfo), 0);
  if (ShGetMalloc(ShellMalloc) = S_OK) and (ShellMalloc <> nil) then
  begin
    Buffer := ShellMalloc.Alloc(MAX_PATH);
    try
      RootItemIDList := nil;
      if Root <> '' then
      begin
        SHGetDesktopFolder(IDesktopFolder);
        IDesktopFolder.ParseDisplayName(Application.Handle, nil,
          POleStr(Root), Eaten, RootItemIDList, Flags);
      end;
      with BrowseInfo do
      begin
        hwndOwner := Application.Handle;
        pidlRoot := RootItemIDList;
        pszDisplayName := Buffer;
        lpszTitle := PChar(Caption);
        ulFlags := BIF_RETURNONLYFSDIRS;
        if Win32MajorVersion >= 5 then
          ulFlags := ulFlags or BIF_USENEWUI;

        if Directory <> '' then
        begin
          lpfn := SpSelectDirCB;
          lParam := Integer(PChar(Directory));
        end;
      end;
      WindowList := DisableTaskWindows(0);
      OldErrorMode := SetErrorMode(SEM_FAILCRITICALERRORS);
      try
        ItemIDList := ShBrowseForFolder(BrowseInfo);
      finally
        SetErrorMode(OldErrorMode);
        EnableTaskWindows(WindowList);
      end;
      Result :=  ItemIDList <> nil;
      if Result then
      begin
        ShGetPathFromIDList(ItemIDList, Buffer);
        ShellMalloc.Free(ItemIDList);
        Directory := Buffer;
      end;
    finally
      ShellMalloc.Free(Buffer);
    end;
  end;
end;

//WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM
{ Ini and Registry }

function SpDeleteRegValue(Key, Name: string): Boolean;
var
  R: TRegistry;
begin
  Result := False;
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKey(Key, False) then
      if R.ValueExists(Name) then
        Result := R.DeleteValue(Name);
  finally
    R.Free;
  end;
end;

function SpReadRegValue(Key, Name: string; out Value: string): Boolean;
var
  R: TRegistry;
begin
  Result := False;
  Value := '';
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKey(Key, False) then
      if R.ValueExists(Name) then begin
        Value := R.ReadString(Name);
        Result := True;
      end;
  finally
    R.Free;
  end;
end;

function SpReadRegKey(Key: string; NamesAndValues: TStringList): Boolean;
var
  R: TRegistry;
  Names: TStringList;
  I: Integer;
begin
  Result := False;
  if not Assigned(NamesAndValues) then Exit;
  NamesAndValues.Clear;

  R := TRegistry.Create;
  Names := TStringList.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKey(Key, False) then begin
      R.GetValueNames(Names);
      for I := 0 to Names.Count - 1 do
        if R.ValueExists(Names[I]) then
          NamesAndValues.Values[Names[I]] := R.ReadString(Names[I]);
      Result := True;
    end;
  finally
    R.Free;
    Names.Free;
  end;
end;

function SpWriteRegValue(Key, Name, Value: string): Boolean;
var
  R: TRegistry;
begin
  Result := False;
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKey(Key, True) then begin
      R.WriteString(Name, Value);
      Result := True;
    end;
  finally
    R.Free;
  end;
end;

procedure SpIniLoadStringList(L: TStringList; IniFilename, Section: string; NamePrefix: string = '');
var
  F: TMemIniFile;
  I, C: integer;
begin
  if not Assigned(L) then Exit;
  F := TMemIniFile.Create(IniFilename);
  try
    L.Clear;
    C := F.ReadInteger(Section, NamePrefix + rvCount, -1);
    for I := 0 to C - 1 do
      L.Add(F.ReadString(Section, NamePrefix + inttostr(I), ''));
  finally
    F.Free;
  end;
end;

procedure SpIniSaveStringList(L: TStringList; IniFilename, Section: string; NamePrefix: string = '');
var
  F: TMemIniFile;
  I: integer;
begin
  if not Assigned(L) then Exit;
  F := TMemIniFile.Create(IniFilename);
  try
    F.EraseSection(Section);
    if L.Count > 0 then begin
      F.WriteInteger(Section, NamePrefix + rvCount, L.Count);
      for I := 0 to L.Count - 1 do
        F.WriteString(Section, NamePrefix + IntToStr(I), L[I]);
      F.UpdateFile;
    end;
  finally
    F.Free;
  end;
end;

function SpParseEntryValue(S: string; ValueList: TStringList; MinimumCount: Integer = 0): Boolean;
begin
  ValueList.Clear;
  ValueList.CommaText := S;
  if MinimumCount < 1 then
    Result := ValueList.Count >= MinimumCount
  else
    Result := True;
end;

//WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM
{ IDE }

function SpActionTypeToString(A: TSpActionType): string;
begin
  Result := ActionTypes[A];
end;

function SpStringToActionType(S: string): TSpActionType;
var
  A: TSpActionType;
begin
  Result := satNone;
  S := LowerCase(S);
  for A := Low(ActionTypes) to High(ActionTypes) do
    if AnsiCompareText(S, ActionTypes[A]) = 0 then begin
      Result := A;
      Exit;
    end;
end;

function SpStringToIDEType(S: string): TSpIDEType;
var
  A: TSpIDEType;
begin
  Result := ideNone;
  for A := Low(IDETypes) to High(IDETypes) do
    if AnsiCompareText(S, IDETypes[A].IDEVersion) = 0 then begin
      Result := A;
      Exit;
    end;
end;

procedure SpIDEPersonalityTypeToString(A: TSpIDEPersonality; out IDERegName: string);
begin
  IDERegName := IDEPersonalityRegNameTypes[A];
end;

function SpIDEDir(IDE: TSpIDEType): string;
begin
  SpReadRegValue(IDETypes[IDE].IDERegistryPath, 'RootDir', Result);
end;

function SpIDEDCC32Path(IDE: TSpIDEType): string;
begin
  SpReadRegValue(IDETypes[IDE].IDERegistryPath, 'App', Result);
  if Result <> '' then
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(Result)) + 'dcc32.exe';
end;

function SpIDEInstalled(IDE: TSpIDEType): Boolean;
begin
  if IDE = ideNone then
    Result := False
  else
    Result := FileExists(SpIDEDCC32Path(IDE));
end;

function SpIDEPersonalityInstalled(IDE: TSpIDEType; IDEPersonality: TSpIDEPersonality): Boolean;
var
  S, PersReg: string;
begin
  Result := False;
  if IDE = ideNone then Exit;

  S := '';
  PersReg := '';

  if IDE >= ideDelphi2006 then begin
    SpIDEPersonalityTypeToString(IDEPersonality, PersReg);
    SpReadRegValue(IDETypes[IDE].IDERegistryPath + '\Personalities',  PersReg, S);
    if S <> ''then
      Result := True;
  end;
end;

procedure SpIDESearchPathRegKey(IDE: TSpIDEType; out Key, Name: string; CPPBuilderPath: Boolean; APlatform: TSpPlatform = pltWin32);
begin
  Key := '';
  Name := '';
  if IDE = ideNone then Exit;

  // [IDE-Change]
  Key := IDETypes[IDE].IDERegistryPath;
  if CPPBuilderPath and (IDE >= ideDelphi2006) then begin
    if IDE = ideDelphi2006 then begin
      // '\CppPaths\SearchPath' with no space in the middle for C++Builder 2006
      Key := Key + '\CppPaths';
      Name := 'SearchPath';
    end
    else begin
      Name := 'LibraryPath';
      if (IDE >= ideDelphiXE2) and (APlatform = pltWin32) then
        Key := Key + '\C++\Paths\Win32' // '\C++\Paths\Win32\LibraryPath' with no space in the middle for C++Builder XE2 and above
      else if (IDE >= ideDelphiXE2) and (APlatform = pltWin64) then
        Key := Key + '\C++\Paths\Win64' // '\C++\Paths\Win32\LibraryPath' with no space in the middle for C++Builder XE2 and above
      else
        Key := Key + '\C++\Paths';   // '\C++\Paths\LibraryPath' with no space in the middle for C++Builder 2009 and above
    end;
  end
  else begin
    Name := 'Search Path';
    if (IDE >= ideDelphiXE2) and (APlatform = pltWin32) then
      Key := Key + '\Library\Win32'
    else if (IDE >= ideDelphiXE2) and (APlatform = pltWin64) then
      Key := Key + '\Library\Win64'
    else
      Key := Key + '\Library';
  end;
end;

function SpIDESearchPath(IDE: TSpIDEType; CPPBuilderPath: Boolean; APlatform: TSpPlatform = pltWin32): string;
var
  Key, Name: string;
begin
  Result := '';
  if IDE <> ideNone then begin
    SpIDESearchPathRegKey(IDE, Key, Name, CPPBuilderPath, APlatform);
    SpReadRegValue(Key, Name, Result);
  end;
end;

procedure SpIDEAddToSearchPath(SourcesL: TStrings; IDE: TSpIDEType);
var
  I : Integer;
  S, Key, Name: string;
begin
  for I := 0 to SourcesL.Count - 1 do begin
    SourcesL[I] := SpIDEExpandMacros(ExcludeTrailingPathDelimiter(SourcesL[I]), IDE);

    // Add the directory to the Delphi Win32 search path registry entry
    S := SpIDESearchPath(IDE, False);
    if (S <> '') and (SourcesL[I] <> '') then
      if not SpStringSearch(S, SourcesL[I]) then begin
        if S[Length(S)] <> ';' then
          S := S + ';';
        S := S + SourcesL[I];
        SpIDESearchPathRegKey(IDE, Key, Name, False);
        SpWriteRegValue(Key, Name, S)
      end;

    // Add the directory to the C++Builder search path registry entry
    if IDE >= ideDelphi2006 then begin
      S := SpIDESearchPath(IDE, True);
      if (S <> '') and (SourcesL[I] <> '') then
        if not SpStringSearch(S, SourcesL[I]) then begin
          if S[Length(S)] <> ';' then
            S := S + ';';
          S := S + SourcesL[I];
          SpIDESearchPathRegKey(IDE, Key, Name, True);
          SpWriteRegValue(Key, Name, S)
        end;
    end;

    // Add Win64 search paths
    if IDE >= ideDelphiXE2 then
    begin
      S := SpIDESearchPath(IDE, False, pltWin64);
      if (S <> '') and (SourcesL[I] <> '') then
        if not SpStringSearch(S, SourcesL[I]) then begin
          if S[Length(S)] <> ';' then
            S := S + ';';
          S := S + SourcesL[I];
          SpIDESearchPathRegKey(IDE, Key, Name, False, pltWin64);
          SpWriteRegValue(Key, Name, S)
        end;

      // Add the directory to the C++Builder search path registry entry
      S := SpIDESearchPath(IDE, True, pltWin64);
      if (S <> '') and (SourcesL[I] <> '') then
        if not SpStringSearch(S, SourcesL[I]) then begin
          if S[Length(S)] <> ';' then
            S := S + ';';
          S := S + SourcesL[I];
          SpIDESearchPathRegKey(IDE, Key, Name, True, pltWin64);
          SpWriteRegValue(Key, Name, S)
        end;
    end;
  end;
end;

function SpIDEBDSCommonDir(IDE: TSpIDEType): string;
var
  S: string;
begin
  Result := '';
  // [IDE-Change]
  if IDE >= ideDelphi2007 then begin
    // The BDSCOMMONDIR can be pointing to a different directory according to how you install Delphi:
    // If you choose All Users during installation: "All Users\Documents", or "Public\Documents" on Vista
    // If you choose Just Me during installation: My Documents, or Documents on Vista

    // XE6 and up starts from 14 (13 doesn't exist), and the dir name is Embarcadero\Studio
    if IDE >= ideDelphiXE6 then
      S := 'Embarcadero\Studio\' // Embarcadero\Studio\14.0
    else
      S := 'RAD Studio\'; // RAD Studio\5.0
    S := S + IDETypes[IDE].IDERADStudioVersion;

    // First try to find it on All Users
    Result := SpGetCommonDocumentsFolder + S;
    if not DirectoryExists(Result) then begin
      // If it's not found try it on My Documents
      Result := SpGetMyDocumentsFolder + S;
      if not DirectoryExists(Result) then
        Result := '';
    end;
  end;
end;

function SpIDEBDSProjectsDir(IDE: TSpIDEType): string;
const
  // English, German, French strings
  DirArrayBDS: array [0..2] of string = ('Borland Studio Projects', 'Borland Studio-Projekte', 'Projets Borland Studio');
  DirArrayRAD: array [0..2] of string = ('Projects', 'Projekte', 'Projets');
var
  R, MyDocs: string;
  I: Integer;
begin
  Result := '';
  // [IDE-Change]
  if IDE >= ideDelphi2005 then begin
    // $(BDSPROJECTSDIR) = ...\My Documents\Borland Studio Projects
    // Unfortunately 'Borland Studio Projects' string is localized in the
    // French, German and Japanese versions of the IDE.
    // This macro can be overrided by adding a string value called
    // 'DefaultProjectsDirectory' containing a different directory to:
    // HKCU\Software\Borland\BDS\4.0\Globals
    R := IDETypes[IDE].IDERegistryPath;
    SpReadRegValue(R + '\Globals', 'DefaultProjectsDirectory', Result);
    if not DirectoryExists(Result) then begin
      // The IDE user can override it on the Environment Options menu,
      // the value is stored on the 'BDSPROJECTSDIR' key name on:
      // HKCU\Software\Borland\BDS\4.0\Environment Variables
      SpReadRegValue(R + '\Environment Variables', 'BDSPROJECTSDIR', Result);
      if not DirectoryExists(Result) then begin
        // Since BDSPROJECTSDIR is not defined in the registry we have to find it
        // manually, looking for all the localized dir names.
        MyDocs := SpGetMyDocumentsFolder;
        if IDE in [ideDelphi2005, ideDelphi2006] then begin
          // For older BDS check if it's My Documents\Borland Studio Projects
          for I := 0 to High(DirArrayBDS) do begin
            Result := MyDocs + DirArrayBDS[I];
            if DirectoryExists(Result) then Break;
          end;
        end
        else begin
          // For XE6 or newer versions check if it's My Documents\Embarcadero\Studio\Projects
          // or My Documents\RAD Studio\Projects
          for I := 0 to High(DirArrayRAD) do begin
            if IDE >= ideDelphiXE6 then
              Result := MyDocs + 'Embarcadero\Studio\' + DirArrayRAD[I]
            else
              Result := MyDocs + 'RAD Studio\' + DirArrayRAD[I];
            if DirectoryExists(Result) then Break;
          end;
        end;

        if not DirectoryExists(Result) then
          Result := '';
      end;
    end;
  end;
end;

function SpIDEGetEnvironmentVars(IDE: TSpIDEType; IDEEnvVars: TStringList): Boolean;
begin
  Result := SpReadRegKey(IDETypes[IDE].IDERegistryPath + '\Environment Variables', IDEEnvVars);
end;

function SpIDEExpandMacros(S: string; IDE: TSpIDEType): string;
// Replace $(Delphi), $(BDS), $(BDSPROJECTSDIR) macros and
// IDE Environment Variables Overrides with real directories
var
  I: Integer;
  IDEDir: string;
  BDSProjectsDir, BDSCommonDir: string;
  L: TStringList;
begin
  Result := S;
  if IDE = ideNone then Exit;

  L := TStringList.Create;
  try
    // Get the Environment Variables Overrides
    SpIDEGetEnvironmentVars(IDE, L);

    // Add the default $(Delphi), $(BDS), $(BDSPROJECTSDIR) and $(BDSCOMMONDIR) macros
    // if there're no overrides for them
    IDEDir := SpIDEDir(IDE);
    I := L.IndexOfName('Delphi');
    if I = -1 then L.Values['Delphi'] := IDEDir;
    if IDE >= ideDelphi2005 then begin
      I := L.IndexOfName('BDS');
      if I = -1 then L.Values['BDS'] := IDEDir;
      BDSProjectsDir := SpIDEBDSProjectsDir(IDE);
      if BDSProjectsDir <> '' then
        L.Values['BDSPROJECTSDIR'] := BDSProjectsDir;

      if IDE >= ideDelphi2007 then begin
        BDSCommonDir := SpIDEBDSCommonDir(IDE);
        if BDSCommonDir <> '' then
          L.Values['BDSCOMMONDIR'] := BDSCommonDir;
      end;
    end;

    // Replace all
    for I := 0 to L.Count - 1 do
      Result := StringReplace(Result, '$(' + L.Names[I] + ')', ExcludeTrailingPathDelimiter(L.ValueFromIndex[I]), [rfReplaceAll, rfIgnoreCase]);
  finally
    L.Free;
  end;
end;

//WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM
{ Delphi Packages }

function SpGetPackageOptions(PackageFilename, LibSuffix, BPLDir: string; out RunTime, DesignTime: Boolean; out BPLFilename, Description: string): Boolean;
var
  L: TStringList;
  P, P2: Integer;
  BPLSuffix: string;
begin
  Result := False;
  RunTime := False;
  DesignTime := False;

  Description := '';
  BPLFilename := BPLDir + ChangeFileExt(ExtractFileName(PackageFilename), '.bpl');
  BPLSuffix := '';
  if FileExists(PackageFilename) then begin
    L := TStringList.Create;
    try
      L.LoadFromFile(PackageFilename);
      P := Pos('{$RUNONLY}', L.Text);
      if P > 0 then
        RunTime := True;
      P := Pos('{$DESIGNONLY}', L.Text);
      if P > 0 then
        DesignTime := True;
      P := Pos('{$DESCRIPTION ''', L.Text); // {$DESCRIPTION 'Package Description'}
      if P > 0 then begin
        P := P + Length('{$DESCRIPTION ''');
        P2 := PosEx('''}', L.Text, P);
        if P2 > 0 then
          Description := Copy(L.Text, P, P2 - P);
      end;
      if LibSuffix = '' then
      begin
        P := Pos('{$LIBSUFFIX ''', L.Text); // {$LIBSUFFIX '100'}  //  file100.bpl
        if P > 0 then begin
          P := P + Length('{$LIBSUFFIX ''');
          P2 := PosEx('''}', L.Text, P);
          if P2 > 0 then begin
            BPLSuffix := Copy(L.Text, P, P2 - P);
          end;
        end;
      end
      else
        BPLSuffix := LibSuffix;

      if BPLSuffix <> '' then
      begin
        // Rename BPL filename to include the suffix
        P := LastDelimiter('.', BPLFilename);
        if P > 0 then
          BPLFilename := Copy(BPLFilename, 1, P - 1) + BPLSuffix + Copy(BPLFilename, P, MaxInt);
      end;

      Result := True;
    finally
      L.Free;
    end;
  end;
end;

function SpIsDesignTimePackage(PackageFilename: string): Boolean;
var
  L: TStringList;
  P: Integer;
begin
  Result := False;

  if FileExists(PackageFilename) then begin
    L := TStringList.Create;
    try
      L.LoadFromFile(PackageFilename);
      P := Pos('{$DESIGNONLY}', L.Text);
      if P > 0 then
        Result := True;
    finally
      L.Free;
    end;
  end;
end;

function SpCompilePackage(PackageFilename, DCC: string; IDE: TSpIDEType;
  SourcesL, IncludesL, Log: TStrings; LibSuffix: string; TempDir: string = ''): Boolean;
// PackageFilename = full path of the package, e.g. 'C:\MyCompos\Compo\Packages\D7Runtime.dpk
// DCC = full path of dcc32.exe, e.g. 'C:\Program Files\Borland\Delphi7\Bin\dcc32.exe
// IDE = IDE version to compile with
// Install = True if the package is DesignTime only, otherwise False.
// SourcesL = list of source folders of the component package to add to the Library Search Path
// IncludesL = list of includes folder paths, e.g. 'C:\MyCompos\AnotherCompo\Source'
// Log = Log strings
// TempDir = Temp dir where the package dcu will be copied, e.g. 'C:\Windows\Temp\MyCompos'
var
  CommandLine, WorkDir, BPLDir, DOSOutput, DCCConfig: string;
  L: TStringList;
  I: Integer;
  S, R: string; // Auxiliary strings
  EmptyRes, ResFile : string;
begin
  Result := False;
  if IDE = ideNone then Exit;
  if not FileExists(PackageFilename) then begin
    if Assigned(Log) then
      SpWriteLog(Log, SLogInvalidPath, PackageFilename);
    Exit;
  end
  else begin
    // [IDE Bug]: dcc32.exe won't execute if -Q option is not used
    // But it works fine without -Q if ShellExecute is used:
    // ShellExecute(Application.Handle, 'open', DCC, ExtractFileName(PackageFilename), ExtractFilePath(PackageFilename), SW_SHOWNORMAL);
    // There must be something wrong with SpExecuteDosCommand
    CommandLine := DCC + ' -Q  ' + ExtractFileName(PackageFilename);
    WorkDir := ExtractFilePath(PackageFilename);

    L := TStringList.Create;
    try
      // Add the SourcesL directories to the registry
      SpIDEAddToSearchPath(SourcesL, IDE);

      // Expand SearchPath, replace $(Delphi) and $(BDS) with real directories
      // and enclose the paths with " " to transform it to a valid
      // comma delimited string for the -U switch.
      L.Text := SpIDEExpandMacros(SpIDESearchPath(IDE, False), IDE);
      L.Text := StringReplace(L.Text, ';', #13#10, [rfReplaceAll, rfIgnoreCase]);
      for I := 0 to L.Count - 1 do
        L[I] := '"' + L[I] + '"';
      S := StringReplace(L.Text, #13#10, ';', [rfReplaceAll, rfIgnoreCase]);
      if S[Length(S)] = ';' then
        Delete(S, Length(S), 1);

      // Save the DCC32.CFG file on the Package directory
      DCCConfig := IncludeTrailingPathDelimiter(WorkDir) + 'DCC32.CFG';
      R := IDETypes[IDE].IDERegistryPath;
      L.Clear;
      // SearchPath
      L.Add('-U' + S);
      // IncludePath
      L.Add('-I' + S);
      // Resource directories, add the source folder as the default *.dcr search folder
      S := '';
      for I := 0 to SourcesL.Count - 1 do
        S := S + ';' + SourcesL[I];
      if S <> '' then begin
        Delete(S, 1, 1);
        S := '"' + S + '"';
        L.Add('-R' + S);
      end;
      // BPL Output
      if IDE >= ideDelphiXE2 then
        SpReadRegValue(R + '\Library\Win32', 'Package DPL Output', S)
      else
        SpReadRegValue(R + '\Library', 'Package DPL Output', S);
      S := SpIDEExpandMacros(S, IDE);
      L.Add('-LE"' + S + '"');
      BPLDir := IncludeTrailingPathDelimiter(S);
      // DCP Output
      if IDE >= ideDelphiXE2 then
        SpReadRegValue(R + '\Library\Win32', 'Package DCP Output', S)
      else
        SpReadRegValue(R + '\Library', 'Package DCP Output', S);
      S := SpIDEExpandMacros(S, IDE);
      L.Add('-LN"' + S + '"');
      // BPI Output for the compiled packages, required for C++Builder 2006 and above
      if IDE >= ideDelphi2006 then
        L.Add('-NB"' + S + '"');
      // Unit namespaces for Delphi XE2:
      if IDE >= ideDelphiXE2 then
        L.Add('-NSSystem.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Datasnap;Web;Soap;Winapi');
      // Includes, dcc32.exe accepts Includes as a semicolon separated string
      // enclosed by double quotes, e.g. "C:\dir1;C:\dir2;C:\dir3"
      S := '';
      for I := 0 to IncludesL.Count - 1 do
        S := S + ';' + IncludesL[I];
      if S <> '' then begin
        Delete(S, 1, 1);
        S := '"' + S + '"';
        L.Add('-I' + S);
      end;
      // DCU Output for the compiled packages
      if TempDir <> '' then
        L.Add('-N"' + TempDir + '"');
      // Add -JL compiler switch to make Hpp files required for C++Builder 2006 and above
      // This switch is undocumented:
      // http://groups.google.com/group/borland.public.cppbuilder.ide/browse_thread/thread/456bece4c5665459/0c4c61ecec179ca8
      if IDE >= ideDelphi2006 then
        if SpIDEPersonalityInstalled(IDE, persCPPBuilder) then
          L.Add('-JL');

      L.SaveToFile(DCCConfig);
    finally
      L.Free;
    end;
    // Check res file exists
    ResFile := ChangeFileExt(PackageFilename, '.res');
    if not FileExists(ResFile) then begin
      EmptyRes := ExtractFilePath(Application.ExeName) + 'empty.res';
      if not SpFileOperation(EmptyRes, ResFile, FO_COPY) then  begin
        SpWriteLog(Log, SLogErrorCopying, EmptyRes, ResFile);
        Exit;
      end;
    end;

    // Compile
    SpWriteLog(Log, SLogCompiling, PackageFilename);
    try
      Result := SpExecuteDosCommand(CommandLine, WorkDir, DOSOutput) = 0;
      if Assigned(Log) then
        Log.Text := Log.Text + DosOutput + #13#10;
      if Result then
        Result := SpRegisterPackage(PackageFilename, LibSuffix, BPLDir, IDE, Log);
    finally
      DeleteFile(DCCConfig);
    end;
  end;

  if not Result and Assigned(Log) then
    SpWriteLog(Log, SLogErrorCompiling, PackageFilename, '');
end;

function SpRegisterPackage(PackageFilename, LibSuffix, BPLDir: string; IDE: TSpIDEType; Log: TStrings): Boolean;
var
  RunTime, DesignTime: Boolean;
  BPLFilename, Description, RegKey: string;
begin
  Result := False;
  if IDE = ideNone then Exit;

  BPLDir := IncludeTrailingPathDelimiter(BPLDir);
  SpGetPackageOptions(PackageFilename, LibSuffix, BPLDir, RunTime, DesignTime, BPLFilename, Description);

  RegKey := IDETypes[IDE].IDERegistryPath + '\Known Packages';

  if RunTime then begin
    SpDeleteRegValue(RegKey, BPLFilename);
    Result := True
  end
  else begin
    if FileExists(BPLFilename) then begin
      if SpWriteRegValue(RegKey, BPLFilename, Description) then begin
        SpWriteLog(Log, SLogInstalling, PackageFilename);
        Result := True;
      end;
    end;
  end;
end;

//WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM
{ TSpComponentPackage }

constructor TSpComponentPackage.Create;
begin
  inherited;
  ExecuteList := TSpExecuteList.Create;
end;

destructor TSpComponentPackage.Destroy;
begin
  ExecuteList.Free;
  inherited;
end;

//WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM
{ TSpComponentPackageList }

function TSpComponentPackageList.GetItems(Index: Integer): TSpComponentPackage;
begin
  Result := TSpComponentPackage(inherited Items[Index]);
end;

procedure TSpComponentPackageList.SetItems(Index: Integer; const Value: TSpComponentPackage);
begin
  inherited Items[Index] := Value;
end;

procedure TSpComponentPackageList.LoadFromIni(Filename: string);
var
  F: TMemIniFile;
  L: TStringList;
  Entry: TSpComponentPackage;
  I, Aux: integer;
  S: string;
  A: TSpIDEType;
begin
  L := TStringList.Create;
  F := TMemIniFile.Create(Filename);
  try
    S := F.ReadString(rvOptionsIniSection, rvDefaultInstallIDE, '');
    FDefaultInstallIDE := SpStringToIDEType(S);
    FDefaultInstallFolder := F.ReadString(rvOptionsIniSection, rvDefaultInstallFolder, '');

    S := F.ReadString(rvOptionsIniSection, rvMinimumIDE, '');
    FMinimumIDE := SpStringToIDEType(S);
    if FMinimumIDE = ideNone then
      FMinimumIDE := ideDelphi7;

    F.ReadSections(L);
    for I := 0 to L.Count - 1 do
      if Length(L[I]) > Length(rvPackageIniSectionPrefix) then begin
        S := Copy(L[I], 1, Length(rvPackageIniSectionPrefix));
        if AnsiCompareText(S, rvPackageIniSectionPrefix) = 0 then begin
          Entry := TSpComponentPackage.Create;
          Entry.Name := F.ReadString(L[I], rvName, '');
          Entry.ZipFile := F.ReadString(L[I], rvZip, '');
          Entry.Git := F.ReadString(L[I], rvGit, '');
          Entry.Destination := F.ReadString(L[I], rvFolder, '');
          Entry.LibSuffix := F.ReadString(L[I], rvLibSuffix, '');
          Entry.SearchPath := F.ReadString(L[I], rvSearchPath, '');
          Entry.GroupIndex := F.ReadInteger(L[I], rvGroupIndex, 0);
          Aux := F.ReadInteger(L[I], rvInstallable, 1);
          if Aux < 0 then Aux := 0;
          if Aux > Ord(High(TSpInstallType)) then Aux := 1;
          Entry.Installable := TSpInstallType(Aux);
          Entry.Includes := F.ReadString(L[I], rvIncludes, '');

          // [IDE-Change]
          if Entry.Installable = sitInstallable then begin
            for A := Low(TSpIDEType) to High(TSpIDEType) do
              Entry.PackageList[A] := F.ReadString(L[I], IDETypes[A].IDEVersion, '');
              // Entry.D22 := F.ReadString(L[I], 'D22', '');
          end;

          Entry.ExecuteList.LoadFromIni(Filename, L[I]);

          Add(Entry);
        end;
      end;
  finally
    L.Free;
    F.Free;
  end;
end;

function TSpComponentPackageList.ExtractAllZips(Source, Destination: string;
  Log: TStrings): Boolean;
var
  I: integer;
  Item: TSpComponentPackage;
begin
  Result := False;
  SpWriteLog(Log, SLogStartUnzip, '');

  Source := IncludeTrailingPathDelimiter(Source);
  Destination := IncludeTrailingPathDelimiter(Destination);

  // Check if the files exist
  if not DirectoryExists(Destination) then begin
    SpWriteLog(Log, SLogInvalidPath, Destination);
    Exit;
  end;
  for I := 0 to Count - 1 do begin
    Item := Items[I];
    // Expand ZipFile
    Item.ZipFile := Source + Item.ZipFile;
    // Expand Destination
    Item.Destination := IncludeTrailingPathDelimiter(Destination + Item.Destination);
    if FileExists(Item.ZipFile) then begin
      if UpperCase(ExtractFileExt(Item.ZipFile)) <> '.ZIP' then begin
        SpWriteLog(Log, SLogNotAZip, Item.ZipFile);
        Exit;
      end;
    end else if Item.Git <> '' then begin
      Item.ZipFile := '';
      if UpperCase(RightStr(Item.Git, 4)) <> '.GIT' then begin
        SpWriteLog(Log, SLogNotAGit, Item.Git);
        Exit;
      end;
    end else if DirectoryExists(Item.Destination) then
    begin
      Item.ZipFile := '';
    end
    else
    begin
      SpWriteLog(Log, SLogInvalidPath, Item.ZipFile);
      Exit;
    end;
  end;

  // Unzip - Clone
  for I := 0 to Count - 1 do begin
    Item := Items[I];

    if Item.ZipFile <> '' then begin
      SpWriteLog(Log, SLogExtracting, Item.ZipFile, Item.Destination);
      if not SpExtractZip(Item.ZipFile, Item.Destination) then begin
        SpWriteLog(Log, SLogCorruptedZip, Item.ZipFile);
        Exit;
      end;
    end else if Item.Git <> '' then begin
      SpWriteLog(Log, SLogCloning, Item.Git, Item.Destination);
      if not SpCloneGit(Item.Git, Item.Destination, Destination, Log) then begin
        SpWriteLog(Log, SLogGitCloneFailed, Item.Git);
        Exit;
      end;
    end else if DirectoryExists(Item.Destination) then
    begin
      SpWriteLog(Log, SNoZipFile, Item.Name);
    end;
  end;
  Result := True;
end;

function TSpComponentPackageList.ExecuteAll(BaseFolder: string; Log: TStrings): Boolean;
var
  I: Integer;
begin
  Result := True;
  if Count > 0 then begin
    SpWriteLog(Log, SLogStartExecute, '');
    for I := 0 to Count - 1 do begin
      Result := Items[I].ExecuteList.ExecuteAll(BaseFolder, Log);
      if not Result then Exit;
      Application.ProcessMessages;
    end;
  end;
end;

function TSpComponentPackageList.CompileAll(BaseFolder: string; IDE: TSpIDEType; Log: TStrings): Boolean;
var
  DCC, TempDir: string;
  I, J: integer;
  Item: TSpComponentPackage;
  SourcesL, CompileL, IncludesL: TStringList;
  Aux1, Aux2: string; // Auxiliary strings
  LibSuffix : string;
begin
  Result := False;
  if IDE = ideNone then begin
    Result := True;
    Exit;
  end
  else
    if not SpIDEInstalled(IDE) then begin
      SpWriteLog(Log, SLogInvalidIDE, IDETypes[IDE].IDEName);
      Exit;
    end;

  // Create TempDir
  SpGetWinDirs(Aux1, Aux2, TempDir);
  TempDir := IncludeTrailingPathDelimiter(TempDir) + 'SpMultiInstall';
  CreateDir(TempDir);

  DCC := SpIDEDCC32Path(IDE);
  CompileL := TStringList.Create;
  IncludesL := TStringList.Create;
  SourcesL := TStringList.Create;
  try
    for I := 0 to Count - 1 do begin
      Item := Items[I];
      SpWriteLog(Log, SLogStartCompile, Item.Name);

      // Expand Search Path
      if Item.SearchPath <> '' then begin
        SourcesL.CommaText := Item.SearchPath;
        // Add the destination search path
        for J := 0 to SourcesL.Count - 1 do
          SourcesL[J] := Item.Destination + SourcesL[J];
      end
      else
        SourcesL.Add(Item.Destination);
      Item.SearchPath := SourcesL.CommaText;

      if Item.Installable = sitInstallable then begin
        CompileL.Clear;
        IncludesL.Clear;

        // Packages
        CompileL.CommaText := Item.PackageList[IDE];
        // Expand Packages
        for J := 0 to CompileL.Count - 1 do
          CompileL[J] := Item.Destination + CompileL[J];

        // Runtime packages must be compiled first
        // There should be a better way of detecting this, checking
        // package dependencies when there are more than 2 packages
        // on the list
        if CompileL.Count = 2 then
          for J := 0 to CompileL.Count - 1 do
            if SpIsDesignTimePackage(CompileL[J]) then begin
              Aux1 := CompileL[J];
              CompileL[J] := CompileL[CompileL.Count - 1];
              CompileL[CompileL.Count - 1] := Aux1;
            end;

        // Expand Includes
        IncludesL.CommaText := StringReplace(Item.Includes, rvBaseFolder, ExcludeTrailingPathDelimiter(BaseFolder), [rfReplaceAll, rfIgnoreCase]);

        if Item.LibSuffix <> '' then
          LibSuffix := Format(Item.LibSuffix, [Copy(IDETypes[IDE].IDEVersion,2,3)])
        else
          LibSuffix := '';

        // Compile and Install
        for J := 0 to CompileL.Count - 1 do
          if not SpCompilePackage(CompileL[J], DCC, IDE, SourcesL, IncludesL, Log, LibSuffix, TempDir) then
            Exit;
      end
      else
        if Item.Installable = sitSearchPathOnly then begin
          // If the package is not installable add the SearchPath to the registry
          // This is useful when installing utility libraries that doesn't have
          // components to install, for example GraphicEx, GDI+, DirectX, etc
          SpIDEAddToSearchPath(SourcesL, IDE);
        end;
      Application.ProcessMessages;
    end;
    Result := True;
  finally
    CompileL.Free;
    IncludesL.Free;
    SourcesL.Free;
    SpFileOperation(TempDir, '', FO_DELETE);
  end;
end;

//WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM
{ TSpExecuteList }

function TSpExecuteList.GetItems(Index: Integer): TSpExecuteEntry;
begin
  Result := TSpExecuteEntry(inherited Items[Index]);
end;

procedure TSpExecuteList.SetItems(Index: Integer; const Value: TSpExecuteEntry);
begin
  inherited Items[Index] := Value;
end;

procedure TSpExecuteList.LoadFromIni(Filename, Section: string);
var
  L, V: TStringList;
  ExecuteEntry: TSpExecuteEntry;
  Action: TSpActionType;
  I: integer;
begin
  L := TStringList.Create;
  V := TStringList.Create;
  try
    Clear;
    SpIniLoadStringList(L, Filename, Section, rvExecuteIniPrefix);
    for I := 0 to L.Count - 1 do
      if SpParseEntryValue(L[I], V, 3) then begin
        Action := SpStringToActionType(V[0]);
        if Action <> satNone then begin
          ExecuteEntry := TSpExecuteEntry.Create;
          ExecuteEntry.Action := Action;
          ExecuteEntry.Origin := V[1];
          ExecuteEntry.Destination := V[2];
          Add(ExecuteEntry);
        end;
      end;
  finally
    L.Free;
    V.Free;
  end;
end;

function TSpExecuteList.ExecuteAll(BaseFolder: string; Log: TStrings): Boolean;
var
  I: Integer;
  Item: TSpExecuteEntry;
  S, DosOutput: string;
begin
  Result := False;

  // Check if the files exist
  for I := 0 to Count - 1 do begin
    Item := Items[I];
    Item.Origin := StringReplace(Item.Origin, rvBaseFolder, ExcludeTrailingPathDelimiter(BaseFolder), [rfReplaceAll, rfIgnoreCase]);
    Item.Destination := StringReplace(Item.Destination, rvBaseFolder, ExcludeTrailingPathDelimiter(BaseFolder), [rfReplaceAll, rfIgnoreCase]);
    if not FileExists(Item.Origin) then begin
      SpWriteLog(Log, SLogInvalidPath, Item.Origin);
      Exit;
    end;
  end;

  // Execute
  for I := 0 to Count - 1 do begin
    Item := Items[I];
    case Item.Action of
      satCopy, satCopyRun:
        if SpFileOperation(Item.Origin, Item.Destination, FO_COPY) then begin
          SpWriteLog(Log, SLogCopying, Item.Origin, Item.Destination);
          if Item.Action = satCopyRun then begin
            // Run it if it's a a valid file
            S := ExtractFileName(Item.Origin);
            if S <> '' then begin
              S := IncludeTrailingPathDelimiter(Item.Destination) + S;
              SpWriteLog(Log, SLogExecuting, S);
              if SpExecuteDosCommand(S, Item.Destination, DosOutput) = 0 then
                Log.Text := Log.Text + DosOutput + #13#10
              else begin
                SpWriteLog(Log, SLogErrorExecuting, Item.Origin, '');
                Exit;
              end;
            end;
          end;
        end
        else begin
          SpWriteLog(Log, SLogErrorCopying, Item.Origin, Item.Destination);
          Exit;
        end;
    end;
  end;

  Result := True;
end;

//WMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM
{ TSpMultiInstaller }

constructor TSpMultiInstaller.Create(IniFilename: string);
begin
  FComponentPackages := TSpComponentPackageList.Create;
  FComponentPackages.LoadFromIni(IniFilename);
end;

destructor TSpMultiInstaller.Destroy;
begin
  FComponentPackages.Free;
  inherited;
end;

function TSpMultiInstaller.Install(ZipPath, BaseFolder: string; IDE: TSpIDEType; Log: TStrings): Boolean;
var
  N, Secs: Single;
begin
  Result := False;
  FInstalling := True;
  try
    Log.Clear;
    N := GetTickCount;
    if ComponentPackages.ExtractAllZips(ZipPath, BaseFolder, Log) then
      if ComponentPackages.ExecuteAll(BaseFolder, Log) then
        if ComponentPackages.CompileAll(BaseFolder, IDE, Log) then begin
          Secs := (GetTickCount - N) / 1000;
          SpWriteLog(Log, SLogEnd, '');
          Log.Add(Format(SLogFinished, [Secs]));

          // [IDE-Change]
          if IDE >= ideDelphi2007 then begin
            // From the Delphi 2007 readme:
            // If you your component installer updates paths in Delphi's registry to include paths
            // to your components, you should add the following registry key:
            // HKCU\Software\Borland\BDS\5.0\Globals\ForceEnvOptionsUpdate with a string value "1"
            // After adding this registry key the next time the IDE is run, it will update
            // the EnvOptions.proj file on disk to include the paths that your installer added.
            // The EnvOptions.proj file is the mechanism by which the new MSBuild build engine
            // in the IDE is able to include paths that are listed on the Library - Win32 page in
            // the IDE's Tools > Options dialog.
            // The EnvOptions.proj file is in:
            // XP: C:\Documents and Settings\...\AppData\Borland\BDS\5.0
            //     C:\Documents and Settings\...\AppData\CodeGear\BDS\6.0
            // Vista/7/8: C:\Users\...\AppData\Roaming\Borland\BDS\5.0
            //            C:\Users\...\AppData\Roaming\Embarcadero\BDS\15.0
            SpWriteRegValue(IDETypes[IDE].IDERegistryPath + '\Globals', 'ForceEnvOptionsUpdate', '1');
          end;

          Result := True;
        end;
  finally
    FInstalling := False;
  end;
end;

end.
