@echo Off
PUSHD %~dp0
Powershell.exe -ExecutionPolicy Bypass -File "\\storagedept\Dept\ITUserServices\Utilities\RemoteDeploy\RemoteDeploy.ps1" -RunAs
POPD