@echo off
powershell -ExecutionPolicy RemoteSigned ./IISSetupInternal.ps1
iisreset
pause