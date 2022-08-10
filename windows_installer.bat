@echo off

SET SCRIPT_NAME=%~n0%~x0
SET PLUGIN_PATH=%~dp0src\RbxStudioDiscordRPC.lua
SET ROBLOX_PLUGINS_DIR=%LOCALAPPDATA%\Roblox\Plugins\

COPY %PLUGIN_PATH% %ROBLOX_PLUGINS_DIR%
echo %SCRIPT_NAME% - Copied the Plugin into the Roblox\Plugins folder.
echo %SCRIPT_NAME% - Please restart Roblox Studio.

PAUSE