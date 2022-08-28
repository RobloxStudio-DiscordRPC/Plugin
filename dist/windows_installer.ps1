$pluginName = "RbxStudioDiscordRPC.lua"
$pluginPath = (Get-Item .).FullName + "\..\src\$pluginName"
$robloxPluginsDir = $env:LOCALAPPDATA + "\Roblox\Plugins\"

Write-Output ">> Copying $pluginPath to $robloxPluginsDir`n"
Copy-Item -Path $pluginPath -Destination $robloxPluginsDir

if (Test-Path -Path "$robloxPluginsDir$pluginName" -PathType Leaf) {
    Write-Output ">> Successfully copied the Plugin to $robloxPluginsDir"
    Write-Output ">> Please restart Roblox Studio."
}

Pause