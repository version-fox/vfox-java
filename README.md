# vfox-java

[中文](README_CN.md) | [English](README.md)

Java plugin for [vfox](https://vfox.dev/).

It installs JDKs from 31 distributions, among them Temurin, Zulu, Liberica, Corretto, Microsoft and GraalVM, looked up through [Foojay](https://foojay.io/). On Linux loong64 it installs from the Loongnix archive instead.

## Install

After installing [vfox](https://github.com/version-fox/vfox), install the plugin and a JDK, and select the JDK:

```bash
vfox add java
vfox install java@21-tem
vfox use --global java@21-tem
java -version
```

`java -version` shows the JDK that is selected. For `java` to be on the `PATH`, vfox has to be hooked into your shell, see its [quick start](https://vfox.dev/guides/quick-start.html).

`vfox search java tem` lists the Temurin releases, and in an interactive terminal it lets you pick one and installs it.

## Versions and names

A version is `<version>-<distribution>`, such as `21.0.8-tem`, with `-fx` after it for JavaFX:

```bash
vfox install java@21-tem          # newest Temurin 21
vfox install java@21.0.8-tem      # Temurin 21.0.8
vfox install java@21-zulu-fx      # Zulu 21 with JavaFX
```

Without a distribution you get OpenJDK from jdk.java.net, which has nothing newer than 17.0.2 for 17 and 21.0.2 for 21, so name a distribution. See [docs/versions.md](docs/versions.md) for installing, using, searching and early-access builds.

## Distributions

| Short name | Distribution |
| --- | --- |
| `open` | OpenJDK builds from jdk.java.net, the default |
| `tem` | Temurin (Eclipse Adoptium) |
| `zulu` | Zulu (Azul) |
| `librca` | Liberica (BellSoft) |
| `amzn` | Corretto (Amazon) |
| `ms` | Microsoft Build of OpenJDK |
| `oracle` | Oracle JDK |
| `sem` | Semeru (IBM) |
| `sapmchn` | SapMachine (SAP) |
| `kona` | Kona (Tencent) |
| `albba` | Dragonwell (Alibaba) |
| `bsg` | BiSheng (Huawei) |
| `graal` | Oracle GraalVM |
| `graalce` | GraalVM Community Edition |
| `nik` | Liberica Native Image Kit (BellSoft) |
| `mandrel` | Mandrel (Red Hat) |
| `jb` | JetBrains Runtime |
| `trava` | TravaOpenJDK |
| `adpt`, `adptj9` | AdoptOpenJDK with HotSpot, with OpenJ9 |
| `eliya` | Eliya JDK (Asymm Systems) |
| `ojdkbld` | OJDKBuild |
| `opnlgc` | OpenLogic OpenJDK |
| `rdht` | Red Hat build of OpenJDK |
| `semcrt` | Semeru, certified edition (IBM) |
| `gln` | Gluon GraalVM |
| `grl8`, `grl11`, `grl16`, `grl17`, `grl19` | GraalVM CE for JDK 8 to 19 |
| `lnxabi1`, `lnxabi2` | Loongnix, Linux loong64 only |

The short names follow the identifiers of [SDKMAN](https://sdkman.io/), with these differences:

- JetBrains Runtime is `jb` and BiSheng is `bsg`, which SDKMAN calls `jbr` and `bisheng`.
- SDKMAN wrote the virtual machine or JDK of AdoptOpenJDK and GraalVM CE into the version (`11.0.10.j9-adpt`, `22.3.3.r17-grl`). The plugin has a name for each (`adptj9`, `grl17`).
- Eliya, OJDKBuild, OpenLogic, Red Hat and Semeru certified have no SDKMAN identifier, so their short names are the plugin's own.

See [docs/distributions.md](docs/distributions.md) for all the differences and for what each distribution is, and [docs/loongnix.md](docs/loongnix.md) for the last row.

## Platforms

Not every distribution has builds for arm64, Alpine or Windows on ARM. Only Temurin, Zulu, Liberica, Microsoft and JetBrains Runtime have Windows ARM64 builds, 11 of the 31 have Alpine x64 builds and 7 have Alpine arm64. GraalVM has neither Windows ARM64 nor Alpine. See [docs/platforms.md](docs/platforms.md) for the table.

## JavaFX

Zulu, Liberica, Liberica NIK and Corretto (Java 8 only) have builds with JavaFX bundled. Add `-fx` after the distribution, as in `java@21-zulu-fx`. See [docs/javafx.md](docs/javafx.md) for details.

## Native Image

A GraalVM installs and runs like any other JDK. Only `native-image`, which builds native executables, needs a C compiler and zlib's headers on top, and a minimal Ubuntu, such as its container image, has neither. Install them once, before the first native build:

```bash
sudo apt install --assume-yes build-essential zlib1g-dev
```

GraalVM CE 8 to 19 come without `native-image` and need it added first. See [docs/native-image.md](docs/native-image.md) for what `native-image` prints without these packages, for other systems, and for adding it.

## `.sdkmanrc`

vfox reads the `java=` line of SDKMAN's `.sdkmanrc` through this plugin and selects a JDK that is already installed. See [docs/sdkmanrc.md](docs/sdkmanrc.md) for details.

## GitHub mirror

Most distributions download from GitHub. If that is slow where you are, `export VFOX_JAVA_GITHUB_MIRROR=https://gh-proxy.org/` sends these downloads through a mirror. See [docs/mirror.md](docs/mirror.md) for details.

## Coming from SDKMAN

[SDKMAN](https://sdkman.io/) installs several JDKs side by side and switches between them for one shell, for a project or for every new shell. So does this plugin, with SDKMAN's short names, and it reads `.sdkmanrc`, so SDKMAN users and vfox users can share a project.

It also works where SDKMAN does not. SDKMAN is a set of bash scripts, so on Windows it needs WSL or Git Bash and cannot be used in PowerShell, not even in the Windows PowerShell 5.1 that comes with Windows. vfox is a native program with a hook for PowerShell, and there the plugin takes SDKMAN's place. The commands side by side:

| | SDKMAN | vfox |
| --- | --- | --- |
| Install | `sdk install java 21.0.8-tem` | `vfox install java@21.0.8-tem` |
| Use in the current shell only | `sdk use java 21.0.8-tem` | `vfox use java@21.0.8-tem` |
| Use in every new shell | `sdk default java 21.0.8-tem` | `vfox use --global java@21.0.8-tem` |

See [docs/sdkman.md](docs/sdkman.md) for when to use the plugin, the other commands and what differs.

## Documentation

**Using the plugin**

- [Versions and names](docs/versions.md): how to write a version, and installing, using, searching and early-access builds
- [Distributions](docs/distributions.md): what each distribution is, its long name, and how GraalVM, Mandrel and Liberica NIK are numbered
- [Platforms](docs/platforms.md): which distribution has builds for which operating system and CPU
- [Querying Foojay](docs/foojay.md): asking Foojay yourself which JDKs exist for your platform, what the plugin asks it, and how downloads are verified
- [JavaFX](docs/javafx.md): the `-fx` builds and where they exist
- [Native Image](docs/native-image.md): the C compiler and zlib that `native-image` needs
- [`.sdkmanrc`](docs/sdkmanrc.md): which JDK a SDKMAN project file selects
- [SDKMAN and vfox](docs/sdkman.md): when to use the plugin, the commands side by side, what differs
- [GitHub mirror](docs/mirror.md): downloading through a mirror when github.com is slow
- [Loongnix](docs/loongnix.md): JDKs for Linux loong64
- [Troubleshooting](docs/troubleshooting.md): the messages the plugin and `native-image` print, proxies and where the JDK is
- [Changes](docs/changes.md): what each release changed

**Working on the plugin**

- [Install from source](docs/install-from-source.md): trying `main` before the next release
- [Development](docs/development.md): how the plugin works, how to change it and how to release it
- [E2E tests](docs/e2e.md): the container tests

## Thanks

- [SDKMAN](https://github.com/sdkman/), whose identifiers the short names and `.sdkmanrc` support follow
- [Foojay](https://github.com/foojayio/discoapi), where the JDK data comes from
