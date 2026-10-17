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
$PSNativeCommandUseErrorActionPreference = $true

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

function Test-Engine {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { return $false }
    $PSNativeCommandUseErrorActionPreference = $false
    & docker version 2>&1 | Out-Null
    $code = $LASTEXITCODE
    $PSNativeCommandUseErrorActionPreference = $true
    return $code -eq 0
}

function Wait-Engine {
    for ($attempt = 1; $attempt -le 60; $attempt++) {
        if (Test-Engine) { return $true }
        Start-Sleep -Seconds 5
    }
    return $false
}

# Whether $Bin holds a whole engine build of $Version: one from an earlier
# run, or the one CI restores from its cache (keyed on this file).
function Test-Build {
    param([string] $Bin, [string] $Version)
    $dockerd = Join-Path $Bin 'dockerd.exe'
    if (-not ((Test-Path $dockerd) -and (Test-Path (Join-Path $Bin 'docker.exe')))) { return $false }
    $PSNativeCommandUseErrorActionPreference = $false
    $banner = (& $dockerd --version 2>&1) -join ''
    return $banner -like "Docker version $Version,*"
}

if ($env:PROCESSOR_ARCHITECTURE -ne 'ARM64') { throw "FAIL this script builds a windows/arm64 engine and needs an arm64 host" }

if (Test-Engine) {
    Write-Output 'PASS docker is already installed'
}
else {
    $mobyVersion = '29.8.1'
    $root = 'C:\vfox-docker'
    New-Item -ItemType Directory -Force -Path $root | Out-Null
    $moby = Join-Path $root 'moby'
    $bin = Join-Path $moby 'bundles'

    if (Test-Build $bin $mobyVersion) {
        Write-Output "Using the docker $mobyVersion build in $bin"
    }
    else {
        Write-Output 'Building docker from source for windows/arm64 ...'

        if (-not (Get-Command go -ErrorAction SilentlyContinue)) { throw 'FAIL go is not on the PATH' }
        $env:GOPATH = Join-Path $root 'gopath'

        # A partial or older build gives way to a fresh clone.
        if (Test-Path $moby) { Remove-Item -Recurse -Force $moby }
        Invoke-Native { git clone --depth 1 --branch "docker-v$mobyVersion" https://github.com/moby/moby.git $moby } 'the moby clone'
        Invoke-Native { go install github.com/tc-hib/go-winres@v0.3.1 } 'the go-winres install'
        $env:DOCKERCLI_VERSION = $mobyVersion
        $env:VERSION = $mobyVersion
        Push-Location $moby
        try {
            & .\hack\make.ps1 -Client -Daemon
        }
        finally {
            Pop-Location
        }
    }

    if (-not (Test-Path (Join-Path $bin 'dockerd.exe'))) { throw 'FAIL the moby build produced no dockerd.exe' }
    if (-not (Test-Path (Join-Path $bin 'docker.exe'))) { throw 'FAIL the moby build produced no docker.exe' }
    $env:PATH = "$bin;$env:PATH"
    if ($env:GITHUB_PATH) { Add-Content -Path $env:GITHUB_PATH -Value $bin }

    # CI points E2E_DOCKER_DATA_ROOT at the runner's local disk
    # (use-local-disk.ps1).
    $dataRoot = if ($env:E2E_DOCKER_DATA_ROOT) { $env:E2E_DOCKER_DATA_ROOT } else { Join-Path $root 'data' }
    $log = Join-Path $root 'dockerd.log'
    $dockerdArgs = "--data-root `"$dataRoot`" --debug --exec-opt isolation=process"
    Start-Process -FilePath (Join-Path $bin 'dockerd.exe') -ArgumentList $dockerdArgs -RedirectStandardOutput $log -RedirectStandardError (Join-Path $root 'dockerd.err.log')
    if (-not (Wait-Engine)) {
        if (Test-Path $log) { Get-Content $log -Tail 40 | ForEach-Object { "dockerd: $_" } }
        throw 'FAIL the docker engine never became ready'
    }
}

$info = ((& docker info --format '{{.OSType}}|{{.Architecture}}') -join '').Trim().ToLowerInvariant()
if ($info -ne 'windows|arm64') { throw "FAIL the docker engine runs $info containers" }
Write-Output 'PASS the docker engine runs windows/arm64 containers'
