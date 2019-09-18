# InstallGame
InstallGame Extension for Playnite

Install as any extension:
1. Create a folder called InstallGame in %appdata%\Playnite\Extensions.
2. Copy the two files (InstallGame.ps1 and extension.yaml) to the folder.
3. Make sure the extension is enabled in Playnite -> Settings -> Extensions.

To use, select a game and run the appropriate command from the Extensions menu.

History:
I have my entire game library on Playnite, not just my currently installed games. Because my library consists of over 1000 games, most of the games in the library are not installed.
Also, since I don't want to damage my game disks, I have converted all my games to ISO files and keep them in some location on a server. For each game, I put the path to its .ISO image in the "Image, ROM, or ISO Path" box of the Installation tab of that game in Playnite.
Traditionally when I wanted to install a game, I would go into the game details, copy the path to the .ISO, mount it as a drive letter in Windows, then run the setup executable to install the game. I would then edit the game details with the appropriate paths for the Play Action and other relevant data.
Because I found this cumbersome, I wrote this extension, which does all of the above automatically. 

NOTES:
Select a game, then click Install from the Extensions menu. The extension will then mount the .ISO specified in the ISO Path and run the setup executable automatically. After the game is installed, it will prompt for the location of the game executable. Once specified, it will add the Play Action for that game, update the Installation Directory path, and mark it as installed.

REQUIREMENTS:
Because the extension calls an executable file, Playnite must be run with elevated privileges (Run as Administrator).
This extension was thoroughly tested on Windows 10, but no testing was done on Windows 7. Because there may be differences in PowerShell versions on Windows 7, it unlikely this extension will work on that OS. Specifically, the method used to mount disk images may only work on Win10. Win7 compatibility may be something I address in the future.