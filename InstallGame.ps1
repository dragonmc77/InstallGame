function global:installGame() {
    <#  #>
    $selection = $PlayniteApi.MainView.SelectedGames
    if ($selection.Count -gt 1) {
        #TODO: display warning to select only one game and exit
        $PlayniteApi.Dialogs.ShowErrorMessage("Only one game can be installed at a time.","Too Many Games Selected")
        break
    }
    $selectedGame = $selection[0]
    $gameImagePath = $selectedGame.GameImagePath

    if ($null -eq $gameImagePath) {
        #TODO: Prompt user for path to installation source
        $PlayniteApi.Dialogs.ShowErrorMessage("The installation path is empty.","No Installation Path")
        break
    } elseif (-not (Test-Path $gameImagePath)) {
        $PlayniteApi.Dialogs.ShowErrorMessage("The file/folder specified in the installation path does not exist.","Invalid Path")
        break
    } 

    if (Test-Path -Path $gameImagePath -PathType Leaf -Include "*.iso") {
        $mountedDisk = Mount-DiskImage -ImagePath $gameImagePath
        $driveLetter = ($mountedDisk | Get-Volume).DriveLetter
        $installSource = "$($driveLetter):\"

        global:runInstaller -Game $selectedGame -Path $installSource -FindSetup
        Dismount-DiskImage -ImagePath $mountedDisk.ImagePath
    }
    elseif (Test-Path -Path $gameImagePath -PathType Leaf -Include "*.exe") {
        global:runInstaller -Game $selectedGame -Path $gameImagePath
    }
    elseif (Test-Path -Path $gameImagePath -PathType Container) {
        global:runInstaller -Game $selectedGame -Path $gameImagePath -FindSetup
    } 
    else {
        $PlayniteApi.Dialogs.ShowErrorMessage("The file in the installation path is not recognized.","Unrecognized file")
    }
}
function global:runInstaller() {
    param ([Playnite.SDK.Models.Game]$Game, [string]$Path, [switch]$FindSetup)

    if ($FindSetup) {
        $setupFile = Get-ChildItem -Path $Path -Filter "setup.exe" | Select-Object -First 1
    } else {
        $setupFile = Get-Item -Path $Path
    }

    if ($setupFile) {
        try {
            & $setupFile.FullName | Out-Null
        } catch {
            $PlayniteApi.Dialogs.ShowErrorMessage("Setup failed to run! Did you run Playnite as Administrator?","Setup Failed")
        }
        $installLocation = global:findGameFolder -Game $Game
        if ($installLocation) {
            $gameExe = $PlayniteApi.Dialogs.SelectFile("Game Executable|*.exe")
            if ($gameExe) {
                $action = [Playnite.SDK.Models.GameAction]::New()
                $action.Type = [Playnite.SDK.Models.GameActionType]::File
                $action.Path = $gameExe
                $Game.PlayAction = $action
                $Game.IsInstalled = $true
                $Game.InstallDirectory = $installLocation
                $PlayniteApi.Database.Games.Update($Game)    
            }
        }
    } else {
        $PlayniteApi.Dialogs.ShowErrorMessage("Setup.exe was not found in the isntallation path.","Setup Not Found")
    }
}

function global:findGameFolder() {
    param([Playnite.SDK.Models.Game]$Game)
    $registryLocations = @( 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
                            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall')
    $installLocation = $registryLocations | 
        Where-Object {Test-Path $_} | 
        Get-ChildItem | 
        Where-Object {$_.GetValue("DisplayName") -like $Game.Name} |
        Select-Object -First 1 |
        ForEach-Object {$_.GetValue("InstallLocation")}
    return $installLocation
}