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

# CI only: moves Docker's data root off C:, which on GitHub-hosted Windows
# runners is a network-attached OS disk where every file flush takes
# milliseconds, onto the runner's local disk. Extracting image layers and
# whatever the e2e containers write flush file by file, so on C: the
# servercore pull alone took five minutes. windows-latest has a local D:;
# windows-11-arm carries an unformatted local NVMe disk, which this formats.
# A runner with neither keeps Docker on C:.

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

if (-not $env:GITHUB_ACTIONS) { throw 'FAIL this script formats a raw disk; it is for CI runners only' }

Get-PhysicalDisk | Format-Table -AutoSize DeviceId, FriendlyName, MediaType, BusType, Size | Out-String | Write-Output
Get-Volume | Where-Object DriveLetter | Format-Table -AutoSize DriveLetter, FileSystem, Size, SizeRemaining | Out-String | Write-Output

$raw = Get-Disk | Where-Object PartitionStyle -eq 'RAW' | Sort-Object Size -Descending | Select-Object -First 1
# A D: on the disk C: is on would be no faster.
$dDisk = (Get-Partition -DriveLetter D -ErrorAction SilentlyContinue).DiskNumber
if ($raw) {
    $volume = Initialize-Disk -Number $raw.Number -PartitionStyle GPT -PassThru |
        New-Partition -UseMaximumSize -AssignDriveLetter |
        Format-Volume -FileSystem NTFS -NewFileSystemLabel docker -Confirm:$false -Force
    $drive = "$($volume.DriveLetter):"
}
elseif ($null -ne $dDisk -and $dDisk -ne (Get-Partition -DriveLetter C).DiskNumber) {
    $drive = 'D:'
}
else {
    Write-Output 'PASS no local disk here; Docker keeps its data on C:'
    exit 0
}
$dataRoot = "$drive\docker"
New-Item -ItemType Directory -Force -Path $dataRoot | Out-Null

if (Get-Service docker -ErrorAction SilentlyContinue) {
    # The engine windows-latest preinstalls: point its config at the local
    # disk and restart it. It holds no images yet, so nothing has to move.
    $config = 'C:\ProgramData\docker\config\daemon.json'
    $settings = $null
    if (Test-Path $config) { $settings = Get-Content $config -Raw | ConvertFrom-Json }
    if (-not $settings) { $settings = [pscustomobject]@{} }
    $settings | Add-Member -NotePropertyName 'data-root' -NotePropertyValue $dataRoot -Force
    Stop-Service docker
    New-Item -ItemType Directory -Force -Path (Split-Path $config) | Out-Null
    $settings | ConvertTo-Json -Depth 8 | Set-Content -Path $config
    Start-Service docker

    $PSNativeCommandUseErrorActionPreference = $false
    $root = ''
    for ($attempt = 1; $attempt -le 60; $attempt++) {
        $root = (& docker info --format '{{.DockerRootDir}}' 2>$null) -join ''
        if ($LASTEXITCODE -eq 0) { break }
        Start-Sleep -Seconds 2
    }
    $PSNativeCommandUseErrorActionPreference = $true
    if ($root -ne $dataRoot) { throw "FAIL the docker engine keeps its data in '$root', not $dataRoot" }
}
else {
    # windows-11-arm has no engine yet; install-docker-arm64.ps1 starts one
    # with this data root.
    "E2E_DOCKER_DATA_ROOT=$dataRoot" | Add-Content -Path $env:GITHUB_ENV
}
Write-Output "PASS Docker keeps its data on $dataRoot"
