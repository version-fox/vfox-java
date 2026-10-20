# vfox-java

[中文](README_CN.md) | [English](README.md)

Java plugin for [vfox](https://vfox.dev/).

It installs JDKs from 31 distributions, among them Temurin, Zulu, Liberica, Corretto, Microsoft and GraalVM, looked up through [Foojay](https://foojay.io/). On Linux loong64 it installs from the Loongnix archive instead.

## Install

After installing [vfox](https://github.com/version-fox/vfox), install the plugin by running:

```bash
vfox add java
```

vfox has to be hooked into your shell for `java` to be on the `PATH`, see its [quick start](https://vfox.dev/guides/quick-start.html).

### Example

```bash
vfox add java
vfox install java@21-tem
vfox use --global java@21-tem
```

You can verify this using the following command:

```bash
java -version
```

`vfox search java tem` lists the Temurin releases, and in an interactive terminal it lets you pick one and installs it.

## Versions and names

A version is `<version>-<distribution>`, such as `21.0.8-tem`, with `-fx` after it for JavaFX. Without a distribution you get OpenJDK from jdk.java.net, which has nothing newer than 17.0.2 for 17 and 21.0.2 for 21. See [docs/versions.md](docs/versions.md) for details.

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

The short names follow SDKMAN's identifiers, with a few differences: SDKMAN calls JetBrains Runtime `jbr`, and it wrote the virtual machine or JDK of AdoptOpenJDK and GraalVM CE into the version (`11.0.10.j9-adpt`, `22.3.3.r17-grl`), where the plugin has a name for each (`adptj9`, `grl17`). Eliya, OJDKBuild, OpenLogic, Red Hat and Semeru certified have no SDKMAN identifier, so their short names are the plugin's own. See [docs/distributions.md](docs/distributions.md) for all the differences and for what each distribution is, and [docs/loongnix.md](docs/loongnix.md) for the last row.

## Platforms

Not every distribution has builds for arm64, Alpine or Windows on ARM. Only Temurin, Zulu, Liberica, Microsoft and JetBrains Runtime have Windows ARM64 builds, 11 of the 31 have Alpine x64 builds and 7 have Alpine arm64. GraalVM has neither Windows ARM64 nor Alpine. See [docs/platforms.md](docs/platforms.md) for the table.

## JavaFX

Zulu, Liberica, Liberica NIK and Corretto (Java 8 only) have builds with JavaFX bundled. Add `-fx` after the distribution, as in `java@21-zulu-fx`. See [docs/javafx.md](docs/javafx.md) for details.

## `.sdkmanrc`

vfox reads the `java=` line of SDKMAN's `.sdkmanrc` through this plugin and selects a JDK that is already installed. See [docs/sdkmanrc.md](docs/sdkmanrc.md) for details.

## GitHub mirror

Most distributions download from GitHub. If that is slow where you are, `export VFOX_JAVA_GITHUB_MIRROR=https://gh-proxy.org/` sends these downloads through a mirror. See [docs/mirror.md](docs/mirror.md) for details.

## Querying Foojay

To see which JDKs exist for your platform, ask Foojay yourself. [docs/foojay.md](docs/foojay.md) has the Swagger UI and the commands.

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for the messages the plugin prints, proxies and where the JDK is.

## Install from source

See [docs/install-from-source.md](docs/install-from-source.md) for details.

## Development

See [docs/development.md](docs/development.md) for how the plugin works and how to change it, and [docs/e2e.md](docs/e2e.md) for the container tests.

## Releasing this plugin

Maintainers can publish from **Actions → Plugin → Run workflow** on the default
branch by entering a stable plugin version without the `v` prefix. The shared
workflow updates `metadata.lua`, creates the version commit and tag, and publishes
the ZIP and manifest in this repository. No local tag or extra release token is
needed. Pull requests run checks only; PR titles no longer trigger publication.

Existing version-tag pushes are supported when `PLUGIN.version` already matches
the tag. If publication fails, re-run the original failed job to resume it.

The workflow follows the shared `@v1` release-tool version. Updating the tool does
not release this plugin. See the [shared workflow documentation](https://github.com/version-fox/plugin-manifest-action)
for the package contract and first-rollout requirements.

## Thanks

- [SDKMAN](https://github.com/sdkman/), whose identifiers the short names and `.sdkmanrc` support follow
- [Foojay](https://github.com/foojayio/discoapi), where the JDK data comes from
