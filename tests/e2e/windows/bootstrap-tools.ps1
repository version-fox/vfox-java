<#
 Copyright 2026 Han Li and contributors

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
#>

$ErrorActionPreference = 'Stop'

# Local copy of the native-command guard. Fails unless the command exits 0.
function Invoke-Native {
    param(
        [Parameter(Mandatory)] [scriptblock] $Cmd,
        [Parameter(Mandatory)] [string] $What,
        [int[]] $Ok = 0
    )
    $prev = $PSNativeCommandUseErrorActionPreference
    $PSNativeCommandUseErrorActionPreference = $false
    & $Cmd
    $code = $LASTEXITCODE
    $PSNativeCommandUseErrorActionPreference = $prev
    if ($null -eq $code) { throw "FAIL $What did not run" }
    if ($code -notin $Ok) { throw "FAIL $What exited with code $code" }
}

$IsArm64 = $env:PROCESSOR_ARCHITECTURE -eq 'ARM64'
$pwshArch = if ($IsArm64) { 'arm64' } else { 'x64' }
$gitAsset = if ($IsArm64) { 'Git-2.55.0.5-arm64.exe' } else { 'Git-2.55.0.5-64-bit.exe' }

$pwshInstaller = "$env:TEMP\pwsh.msi"
$pwshUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.6.6/PowerShell-7.6.6-win-$pwshArch.msi"
$gitInstaller = "$env:TEMP\git-installer.exe"
$gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.5/$gitAsset"

Invoke-Native { & curl.exe -fsSL --retry 3 --retry-delay 5 --retry-all-errors -o $pwshInstaller $pwshUrl } 'the PowerShell download'
Invoke-Native { & curl.exe -fsSL --retry 3 --retry-delay 5 --retry-all-errors -o $gitInstaller $gitUrl } 'the Git download'
$pwshSetup = Start-Process msiexec.exe -Wait -PassThru -ArgumentList '/i', "`"$pwshInstaller`"", '/quiet', '/norestart'
if ($pwshSetup.ExitCode -notin 0, 3010) { throw "FAIL the PowerShell MSI install exited with code $($pwshSetup.ExitCode)" }
$gitSetup = Start-Process $gitInstaller -Wait -PassThru -ArgumentList '/VERYSILENT', '/NORESTART', '/SP-', '/SUPPRESSMSGBOXES'
if ($gitSetup.ExitCode -ne 0) { throw "FAIL the Git installer exited with code $($gitSetup.ExitCode)" }
if (-not (Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe')) { throw 'FAIL pwsh.exe is missing after the PowerShell MSI install' }
if (-not (Test-Path 'C:\Program Files\Git\cmd\git.exe')) { throw 'FAIL git.exe is missing after the Git installer' }
Invoke-Native { & 'C:\Program Files\Git\cmd\git.exe' config --system core.longpaths true } 'enable system-wide git long paths'
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force | Out-Null
