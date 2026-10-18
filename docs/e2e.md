# E2E

The offline Lua hook tests (`tests/*_test.lua`) run in the **Test Plugin**
workflow. The end-to-end suite runs in containers against real vfox on Linux
and Windows; each `vfox` x `distribution` combination gets its own throwaway
container. CI runs the suite natively on the stock runners (Docker plus Go
from `actions/setup-go`). Locally, the repository dev container reproduces
that on Linux; on Windows a Docker Compose runner image does, since dev
containers cannot host Windows container images (see below).

## Dev container

`.devcontainer/` opens a Linux development environment that works on all four
host platforms:

| Host                  | How the dev container runs                     |
| --------------------- | ---------------------------------------------- |
| Linux amd64 / arm64   | natively                                       |
| Windows amd64 / arm64 | Docker Desktop in Linux-container mode (WSL 2) |

It carries Go 1.27.1 (the version CI installs), the Docker CLI, stylua,
lua-language-server, and the license tools — all pinned to the versions in
`.github/workflows/lint.yml` and `license.yml` — and mounts the host Docker
daemon socket. The suites then run testcontainers against that daemon
(Docker-out-of-Docker), spawning the same target containers a native CI
runner spawns; this is deliberately not Docker-in-Docker, so image cache and
networking stay the host's. The image needs no workspace files, so the build
context stays at `.devcontainer/`; `postCreateCommand` warms the Go module
cache for `tests/e2e` so the first test run does not stop to download.

Open it with any Dev Containers spec tool — **Dev Containers: Reopen in
Container** in VS Code/Cursor, or the CLI:

```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . bash
```

`TESTCONTAINERS_RYUK_DISABLED=true` is preset: Ryuk publishes a port on the
host daemon and waits for the suite to dial it back, which a
Docker-out-of-Docker container cannot do. The suites terminate every
container explicitly via `t.Cleanup` instead; leftovers from killed runs
share the `vfox-java-e2e-` name prefix for pruning. Rootless Docker users
export `DOCKER_SOCK="$XDG_RUNTIME_DIR/docker.sock"` on the host before
opening the container. On Windows hosts, keeping the checkout inside WSL 2
(e.g. under `\\wsl$`) keeps file and bind-mount access fast; a checkout on
the Windows filesystem works too.

Windows *container* coverage (`tests/e2e/windows`) cannot run in a dev
container: the Dev Containers spec does not support Windows container images
([vscode-remote-release#445](https://github.com/microsoft/vscode-remote-release/issues/445)),
and Windows containers only run on a Windows daemon. That suite keeps its
Docker Compose runner on a Windows host; see [Windows 11](#windows-11) below.

## What the suite verifies

Every combination runs the same flow (one long-lived container per combo,
driven from Go through `docker exec`-style calls); the target images carry no
JDK, so `java` can only come from what vfox installs:

1. vfox is installed from the requested channel — the latest release
   (`latest`) or built from source (`main`) — and the local `java` plugin is
   registered from this checkout. On Windows, the runner builds `main` once,
   while the `latest` combinations run, and the `main` containers start from
   the e2e image plus that `vfox.exe`.
2. A distribution without a version, alone or after an empty one
   (`java@tem`, `java@-tem`), fails both `vfox install` and `vfox use` with
   an error asking for one. The hooks stopped with a Lua error on the first,
   while `PreInstall` sent the empty version to Foojay, which lists every
   release, and installed the newest one.
   A release no distribution has published (`<major>.0.99`) fails to install,
   with `PreInstall` naming the platform it searched (`linux/amd64`,
   `windows/arm64`, ...), so the Foojay lookup is checked to target the
   runner. So does a build of the pinned release that was never published
   (`<version>+99`, e.g. `21.0.8+99-tem`), proving the lookup keeps the
   build number: Foojay reads an unencoded `+` as a space and drops the
   build, and the release's newest build would install instead.
3. The pinned release installs under the name `PreInstall` gives it: the
   requested version plus the build number (`21.0.8-tem` installs as
   `21.0.8+9-tem`). `vfox search java <distribution>` (the `Available` hook)
   lists that same name as installed, noting JavaFX on `-fx` builds. On
   Windows that includes JetBrains Runtime 21.0.5, which ships only as
   tar.gz there.
4. Before any `vfox use`, a `.sdkmanrc` holding the SDKMAN identifier
   without the build number selects the JDK through `ParseLegacyFile`:
   `java=21.0.8-tem`, `java=21.0.5-jbr` (SDKMAN's name for JetBrains) or
   `java=25.0.4.fx-librca` (its spelling of JavaFX builds). So does one
   padding the release with a zero, as `sdk list java` shows many:
   `java=21.0.8.0+9-tem`, `java=25.0.4.0-fx+9-librca` (Foojay, and so the
   installed name, has no such zero). So does one holding the installed
   version (`java=21.0.8+9-tem`). All run next to an empty install of
   another release whose version starts with the pinned one
   (`21.0.80+1-tem`): vfox sorts installed versions as strings, descending,
   so `vfox list java` must show it first. `ParseLegacyFile` used to take it
   as the first one starting with the release, and, for the padded release,
   as the newest release of the major. Then SDKMAN's identifier of an
   early-access build of the pinned major, spelled as `sdk list java` shows
   OpenJDK's (`28.0.0.0+ea.20-open`), must select that build:
   `java=21.0.0.0+ea.1-tem` selects `21-ea+1-tem`, not the release, which
   `ParseLegacyFile` took while it understood only SDKMAN's older
   `21.ea.1-tem`. So must the installed name itself (`java=21-ea+1-tem`),
   for which `ParseLegacyFile`, unable to parse it, selected nothing, while
   `vfox use` selects it. jdk.java.net removes each early-access build within
   weeks, so that install is faked: its `bin` holds a stand-in `java` that
   only prints the name. On Windows the file is written with CRLF line
   endings.
5. After `vfox use --global`, the JDK on `PATH` reports the requested
   `java.version`, the runner's `os.arch` (`amd64` / `aarch64`, which also
   catches an x64 JDK emulated on Windows ARM64) and the distribution's
   `java.vendor`. `JAVA_HOME` holds that same JDK, `javac` compiles a
   program that `java` then runs, the module list carries JavaFX exactly for
   `-fx` builds, and `vfox current java` reports the installed version. A
   `GRAALVM_HOME` set beforehand keeps its value, as users point it at a
   GraalVM of their own; for GraalVM, the plugin used to replace it with
   the JDK in use.
6. `PreUse` maps the spellings users type to the installed version without
   another download: the bare major (`java@21`, left to vfox core's fuzzy
   matching), the spec the JDK was installed with (`java@21.0.8-tem`, whose
   build number `PreUse` finds among the installed versions) and the
   asdf-style `<long-name>-<version>[-fx]` (`java@temurin-21.0.8+9`,
   rewritten to `21.0.8+9-tem`; `java@openjdk-25.0.2+10` to `25.0.2+10`).
   So does the release padded with a zero, as SDKMAN writes releases
   (`java@21.0.8.0-tem`, `java@21.0.8.0+9-tem`), which `vfox install` must
   first find already installed: `PreInstall` passes the zero on to Foojay,
   which leaves it out, while `PreUse` looked for an installed version
   starting with the padded release and reported it not installed.

The default matrix runs every distribution against both vfox channels
(`latest`, `main`):

| Distribution | Release | Covers                                                   | amd64 | arm64 |
| ------------ | ------- | -------------------------------------------------------- | ----- | ----- |
| `open`       | 25.0.2  | the default distribution, versions without a suffix      | ✓     |       |
| `tem`        | 21.0.8  | the common path (tar.gz on Linux, zip on Windows)        | ✓     | ✓     |
| `librca-fx`  | 25.0.4  | JavaFX bundled builds (`-fx`)                            | ✓     | ✓     |
| `jb`         | 21.0.5  | the tar.gz path on Windows, which has no zip for it      | ✓     | ✓     |
| `graalce`    | 25.0.2  | a `GRAALVM_HOME` set beforehand keeps its value          | ✓     |       |

Every pinned release is published through Foojay for each platform its row
runs on. OpenJDK and GraalVM Community ship no `windows-aarch64` build, so
arm64 runs the other three on both Linux and Windows.

## Environment knobs

| Variable             | Default                    | Meaning                                                                 |
| -------------------- | -------------------------- | ----------------------------------------------------------------------- |
| `VFOX_VERSION`       | `latest main`              | Space-separated vfox channels (`latest`, `main`)                        |
| `DISTRIBUTION`       | see matrix above           | Space-separated plugin distributions, `-fx` for JavaFX (`tem zulu-fx`)  |
| `JAVA_VERSION`       | per distribution           | Release installed for every selected distribution (Java 9+ numbering)   |
| `E2E_MAX_JOBS`       | `3` (Linux), `2` (Windows) | Parallel containers per host                                            |
| `E2E_RETRY_ATTEMPTS` | `3`                        | Attempts per network-touching exec (linear 10s backoff)                 |

`JAVA_VERSION` must be a release `java.version` reports verbatim (e.g.
`21.0.8`, not Java 8's `1.8.0_462` scheme). Distributions outside the
default matrix still run every check except the `java.vendor` assertion and
the asdf-style `PreUse` spelling, which need facts the suite only keeps for
the defaults (`tests/e2e/common`).

## Linux (Ubuntu 26.04)

Inside the dev container, from the repository root:

```bash
cd tests/e2e
go test -v -timeout 55m -run TestE2E ./linux
```

Scope it down while iterating the same way:

```bash
VFOX_VERSION=latest DISTRIBUTION=tem E2E_MAX_JOBS=1 go test -v -timeout 55m -run TestE2E ./linux
```

On a native host the same command works with two prerequisites — Docker
Engine (rootful or rootless) and Go 1.27.1 — which is exactly what CI
provisions. Rootless Docker users point the Docker client at their socket
(`export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"`); the dev
container's socket mount covers that case for you.

## Windows 11

Windows containers cannot be emulated across architectures, so the ARM64
suite needs an ARM64 host (a Copilot+ PC or the `windows-11-arm` CI runner).

There is no dev container for this suite — the Dev Containers spec rejects
Windows container images (see [Dev container](#dev-container)) — so it keeps
its Docker Compose runner. The runner image (`Dockerfile-runner`: stock
servercore plus the pinned Go, which also builds vfox `main`) drives the host
daemon through the mounted named pipe; the host requirement is Docker in
Windows-container mode plus the Compose v5 plugin (installed once per machine
below). Go never touches the host, so it cannot conflict with a vfox-managed
toolchain.

The `windows-11-arm` runner has no Windows Hypervisor Platform feature, so
Hyper-V isolation is unavailable; process isolation needs only the
Containers feature.

CI skips the runner image: extracting its Go took two and a half minutes on
`windows-11-arm`, where `actions/setup-go` already provides the same Go. It
runs `go test ./windows` on the runner with `E2E_MAX_JOBS=3`, after
`use-local-disk.ps1` moves Docker's data root, Go's caches and the temp
directory off the runners' network-attached C: onto a local disk:
`windows-latest`'s D:, or the unformatted NVMe disk of `windows-11-arm`,
which it formats. Image layers and the containers' files are written file by
file, so on C: the servercore pull alone took five minutes. The script
refuses to run outside GitHub Actions.

Every combination runs with `VFOX_HOME` pointing inside a path containing a
space (`C:\Users\John Doe\.vfox`), mirroring
[vfox-flutter#33](https://github.com/version-fox/vfox-flutter/issues/33).
vfox handles such paths since 1.0.13
([vfox#712](https://github.com/version-fox/vfox/pull/712)), so the `latest`
release and `main` both run against it.

### x64

All commands below run in PowerShell 7. If it is not installed yet, install
it first (this single bootstrap command may run in the built-in Windows
PowerShell):

```powershell
winget install --id Microsoft.PowerShell --source winget --exact
```

1. Execute in PowerShell 7,

```powershell
winget install --id Git.Git --source winget --exact
# Configure Git appropriately.

curl.exe -fsSL `
    "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1" `
    -o ./install-docker-ce.ps1
```

2. Execute in PowerShell 7 with administrator privileges,

```powershell
./install-docker-ce.ps1
```

3. Execute in PowerShell 7,

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.docker\cli-plugins" | Out-Null

curl.exe -fsSL `
    "https://github.com/docker/compose/releases/download/v5.5.1/docker-compose-windows-x86_64.exe" `
    -o "$env:USERPROFILE\.docker\cli-plugins\docker-compose.exe"

git clone git@github.com:version-fox/vfox-java.git
cd ./vfox-java/
docker compose -f tests/e2e/windows/compose.amd64.yaml run --rm --build e2e
```

### arm64

All commands below run in PowerShell 7. If it is not installed yet, install
it first (this single bootstrap command may run in the built-in Windows
PowerShell):

```powershell
winget install --id Microsoft.PowerShell --source winget --exact
```

1. Execute in PowerShell 7,

```powershell
winget install --id Git.Git --source winget --exact
# Configure Git appropriately.
winget install --id GoLang.Go --source winget --exact
git clone git@github.com:version-fox/vfox-java.git
cd ./vfox-java/
pwsh -NoProfile -File .\tests\e2e\windows\install-docker-arm64.ps1
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.docker\cli-plugins" | Out-Null

curl.exe -fsSL `
    "https://github.com/docker/compose/releases/download/v5.5.1/docker-compose-windows-aarch64.exe" `
    -o "$env:USERPROFILE\.docker\cli-plugins\docker-compose.exe"

docker compose -f tests/e2e/windows/compose.arm64.yaml run --rm --build e2e
```

On arm64, Go is also what builds the engine, so `install-docker-arm64.ps1`
runs before the suite; the compose runner image then carries its own pinned
Go for the tests, and the host Go is not used again. The script reuses an
engine of its pinned version that it built before; CI restores one from a
cache keyed on the script. Scope the run down with
`$env:VFOX_VERSION = 'latest'; $env:DISTRIBUTION = 'tem'` in front of the
compose command, as on the other platforms.

## Local checks

Execute from the dev container — everything below is preinstalled and pinned
to the versions the workflows use — or provision the same tools on a host.

```bash
# Lua and Go checks (.github/workflows/lint.yml).
cd tests/e2e
go test -short ./...
test -z "$(gofmt -l .)"
go vet ./...
cd ../..

stylua --check .
lua-language-server --check . --checklevel=Warning
```

```bash
# Offline hook tests (.github/workflows/test.yml).
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/pre_install_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/pre_use_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/parse_legacy_file_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/loongnix_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/post_install_test.lua
```

```bash
# License headers (.github/workflows/license.yml).
license-eye header check
license-eye header fix
addlicense -check -f .license.tpl tests/e2e/windows/*.ps1
addlicense -f .license.tpl tests/e2e/windows/*.ps1
```

On a Docker-only host the license checks run as containers instead (the same
images CI uses):

```bash
docker run --rm -v "$PWD:/work" -w /work apache/skywalking-eyes:0.9.0 header check
docker run --rm -v "$PWD:/work" -w /work apache/skywalking-eyes:0.9.0 header fix
docker run --rm -v "$PWD:/src" ghcr.io/google/addlicense:v1.2.0 -check -f .license.tpl tests/e2e/windows/*.ps1
docker run --rm -v "$PWD:/src" ghcr.io/google/addlicense:v1.2.0 -f .license.tpl tests/e2e/windows/*.ps1
```
