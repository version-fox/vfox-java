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

$pwshArch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }

# A zip, not the MSI: installers took minutes here on arm64, while the zip
# only extracts, and leaves the machine PATH to us. No Git: vfox from main
# is built on the runner (setup.go), and nothing in the containers clones.
$pwshZip = "$env:TEMP\pwsh.zip"
$pwshUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.6.6/PowerShell-7.6.6-win-$pwshArch.zip"
$pwshHome = 'C:\Program Files\PowerShell\7'

Invoke-Native { & curl.exe -fsSL --retry 3 --retry-delay 5 --retry-all-errors -o $pwshZip $pwshUrl } 'the PowerShell download'
New-Item -ItemType Directory -Force -Path $pwshHome | Out-Null
Invoke-Native { & tar.exe -xf $pwshZip -C $pwshHome } 'the PowerShell extraction'
Remove-Item $pwshZip
if (-not (Test-Path "$pwshHome\pwsh.exe")) { throw 'FAIL pwsh.exe is missing after the PowerShell extraction' }
[Environment]::SetEnvironmentVariable('PATH', [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ";$pwshHome", 'Machine')
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force | Out-Null
