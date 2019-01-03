@echo Off
PUSHD %~dp0
Powershell.exe -ExecutionPolicy Bypass -File ".\RemoteDeploy.ps1" -RunAs
POPD