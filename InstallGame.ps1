function global:installGame() {
    $selection = $PlayniteApi.MainView.SelectedGames
    <#  check that only one game is selected #>
    if ($selection.Count -gt 1) {
        $PlayniteApi.Dialogs.ShowErrorMessage("Only one game can be installed at a time.","Too Many Games Selected")
        break
    }
    $selectedGame = $selection[0]
    $gameImagePath = $selectedGame.GameImagePath
    <#  check if the ISO Path box is empty. if it is, provide the user with the opportunity to enter the
        location of the installation media to install the game. 
        Also check if the existing ISO Path for the game is actually valid.    
    #>
    if ($null -eq $gameImagePath) {
        $response = $PlayniteApi.Dialogs.ShowMessage("The installation path is empty.`nDo you want to specify the location of the installation media?","No Installation Path",[System.Windows.MessageBoxButton]::YesNo)
        if ($response -eq [System.Windows.MessageBoxResult]::Yes) {
            $gameImagePath = $PlayniteApi.Dialogs.SelectFolder()
        }
        if ($gameImagePath -eq '') {break}
    } elseif (-not (Test-Path $gameImagePath)) {
        $PlayniteApi.Dialogs.ShowErrorMessage("The file/folder specified in the installation path does not exist.","Invalid Path")
        break
    } 
    <#  check if the ISO Path is a disk image file (.iso). if so, mount the .iso to a drive letter 
        and run the installer (setup.exe) located there. then dismount the image
    #>
    if (Test-Path -Path $gameImagePath -PathType Leaf -Include "*.iso") {
        $mountedDisk = Mount-DiskImage -ImagePath $gameImagePath
        $driveLetter = ($mountedDisk | Get-Volume).DriveLetter
        $installSource = "$($driveLetter):\"

        global:runInstaller -Game $selectedGame -Path $installSource -FindSetup
        Dismount-DiskImage -ImagePath $mountedDisk.ImagePath
    }
    <#  check if the ISO Path is an executable file (.exe). if so, run the executable to install the game #>
    elseif (Test-Path -Path $gameImagePath -PathType Leaf -Include "*.exe") {
        global:runInstaller -Game $selectedGame -Path $gameImagePath
    }
    <#  check if the ISO Path is a folder location. if so, run the installer (setup.exe) located there #>
    elseif (Test-Path -Path $gameImagePath -PathType Container) {
        global:runInstaller -Game $selectedGame -Path $gameImagePath -FindSetup
    } 
    <#  if all other checks failed, display an error #>
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
            Set-Location $Path
            & $setupFile.FullName | Out-Null
        } catch {
            $PlayniteApi.Dialogs.ShowErrorMessage("Setup failed to run! Did you run Playnite as Administrator?","Setup Failed")
        }
        $installLocation = global:findGameFolder -Game $Game
        
        $gameExe = $PlayniteApi.Dialogs.SelectFile("Game Executable|*.exe")
        if ($gameExe) {
            $action = [Playnite.SDK.Models.GameAction]::New()
            $action.Type = [Playnite.SDK.Models.GameActionType]::File
            $action.Path = $gameExe
            $Game.PlayAction = $action
            $Game.IsInstalled = $true
            $Game.InstallDirectory = Split-Path -Path $gameExe -Parent
            $PlayniteApi.Database.Games.Update($Game)    
        }
    } else {
        $PlayniteApi.Dialogs.ShowErrorMessage("Setup.exe was not found in the installation path.","Setup Not Found")
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