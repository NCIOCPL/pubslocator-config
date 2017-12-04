@echo off
powershell -ExecutionPolicy RemoteSigned ./IISSetupExternal.ps1
iisreset
pause