; Build with .github/scripts/build-installer.ps1 after compiling Mi.exe.
#ifndef MyAppVersion
  #error MyAppVersion must be supplied from Cargo.toml
#endif
#ifndef MyAppBinaryPath
  #define MyAppBinaryPath SourcePath + "..\target\release\Mi.exe"
#endif

#define MyAppName "Mi"
#define MyAppPublisher "Sqhh99"
#define MyAppURL "https://github.com/Sqhh99/Mi"
#define MyAppExeName "Mi.exe"

[Setup]
; Preserve the installation identity for upgrades within the same install scope.
AppId={{B7E72028-FD9F-4C37-BA5B-B22CEE167851}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
VersionInfoVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
DisableDirPage=no
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
LicenseFile={#SourcePath}\..\LICENSE
SetupIconFile={#SourcePath}\..\resources\appIcon.ico
OutputDir={#SourcePath}\..\dist
OutputBaseFilename=Mi-{#MyAppVersion}-windows-x64-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MyAppBinaryPath}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{userprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{userdesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
