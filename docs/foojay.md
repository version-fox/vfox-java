# Querying Foojay

[中文](zh-CN/foojay.md) | [English](foojay.md)

[Foojay](https://foojay.io/) runs the Disco API, a public index of JDK builds from many vendors (source: [foojayio/discoapi](https://github.com/foojayio/discoapi)). Except on Linux loong64, the plugin gets every list of versions and every download link from it. What `vfox search` shows is Foojay's data, and Foojay is where to look when a build you expect is missing.

You can ask it yourself in the browser. The [Swagger UI](https://api.foojay.io/swagger-ui) of the API has the endpoints, and its spec is [foojay-discoapi-3.0.yml](https://api.foojay.io/swagger/foojay-discoapi-3.0.yml). Open `GET /disco/v3.0/packages/jdks`, press "Try it out", fill in the parameters and press "Execute". The page shows the `curl` command it ran and the JSON that came back.

## What the plugin asks

`vfox install java@21.0.8-tem` on Linux x64 sends:

```
https://api.foojay.io/disco/v3.0/packages/jdks
  ?version=21.0.8
  &distribution=temurin
  &architecture=amd64
  &archive_type=tar.gz
  &operating_system=linux
  &lib_c_type=glibc
  &directly_downloadable=true
```

| Parameter | Value |
| --- | --- |
| `distribution` | the long name, see [distributions.md](distributions.md) |
| `version` | empty for `vfox search`, else the version part of what you typed. A `+` is percent-encoded, because Foojay reads a bare one as a space and drops the build. `28.ea.19` becomes `28-ea+19` |
| `architecture` | `aarch64` for arm64, `x64` on Windows x64, `amd64` for x64 elsewhere, and the name vfox reports for other CPUs |
| `operating_system` | `linux`, `macos` or `windows` |
| `archive_type` | `tar.gz`, and `zip` plus `tar.gz` on Windows. Elsewhere `tar.xz` comes in for Red Hat, and `zip` for OJDKBuild, OpenLogic and Gluon GraalVM |
| `lib_c_type` | `glibc` or `musl` on Linux, empty elsewhere |
| `directly_downloadable` | always `true` |
| `latest` | `available`, added only when the version is a bare major such as `21` |

Without `latest=available`, `version=21` matches the 21 GA build only (`21+35`). With it Foojay picks the newest 21.x, which is what `java@21-tem` installs. Longer versions match as they are.

The answer is a list of packages. The plugin names a release after `java_version`, adds `-fx` where `javafx_bundled` is true, marks it LTS where `term_of_support` is `lts`, and prefers a `zip` over a `tar.gz` of the same version on Windows. It leaves out the JREs, installer bundles and RHEL 6 builds that Foojay lists among OJDKBuild's Windows JDKs, and the JDK 11 builds of Gluon GraalVM's 22.x releases, see [distributions.md](distributions.md). For the install it then fetches the package's `links.pkg_info_uri` and downloads its `direct_download_uri`, which is a vendor's own server (GitHub Releases for Temurin). That record also holds a `checksum`. The plugin does not pass it on, so vfox prints `WARNING: Checksum is not provided, skip verify...` and does not verify the download.

`vfox search` differs from the raw list in a few ways. It lists a name once where Foojay has two records for it, and it leaves the LTS note off GraalVM's feature releases (see [distributions.md](distributions.md#behavior-of-oracle-graalvm-and-graalvm-community)). It only lists GA releases.

## Which distributions have a build for my platform

`latest=per_distro` returns the newest package of every distribution that has one. Do not combine it with `version`, which it ignores.

```bash
# Windows on ARM64
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?architecture=aarch64&operating_system=windows&archive_type=zip&archive_type=tar.gz&directly_downloadable=true&latest=per_distro' \
  | jq -r '.result[].distribution' | sort -u
```

```
jetbrains
liberica
microsoft
temurin
zulu
```

For another platform change the three parameters that name it. Linux needs `lib_c_type=glibc` or `musl` as well:

| Platform | Parameters |
| --- | --- |
| Linux arm64 | `architecture=aarch64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz` |
| Alpine x64 | `architecture=amd64&operating_system=linux&lib_c_type=musl&archive_type=tar.gz` |
| macOS Apple silicon | `architecture=aarch64&operating_system=macos&archive_type=tar.gz` |
| macOS Intel | `architecture=amd64&operating_system=macos&archive_type=tar.gz` |
| Windows x64 | `architecture=x64&operating_system=windows&archive_type=zip&archive_type=tar.gz` |

The names in the answer are the long names in [distributions.md](distributions.md), except `oracle_open_jdk`, which the plugin calls `openjdk` (`open`). With `archive_type=tar.gz` alone the answer misses Red Hat and OJDKBuild on Linux, and OpenLogic on macOS, which ship tar.xz or zip there. The plugin asks for those types for them, see the table above.

## Which distributions have a release for my platform

```bash
# Java 27 on Intel Macs
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?version=27&latest=available&architecture=amd64&operating_system=macos&archive_type=tar.gz&directly_downloadable=true' \
  | jq -r '.result[].distribution' | sort -u
```

On 2026-10-18 this printed `corretto liberica oracle semeru zulu`. Temurin and OpenJDK were not among them: they stopped at 26 there. Use `latest=available` for a bare major, as the plugin does, and leave it out for a longer version.

## The versions of one distribution

This is what `vfox search java tem` shows, for the machine you run it on:

```bash
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?distribution=temurin&architecture=aarch64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz&directly_downloadable=true' \
  | jq -r '.result[].java_version'
```

```
27+35
26.0.2.1+1
26.0.2+10
...
```

Add `version=21.0.8` for one release, and `javafx_bundled=true` for the JavaFX builds only. A record looks like this:

```bash
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?distribution=temurin&version=21.0.8&architecture=amd64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz&directly_downloadable=true' \
  | jq -c '.result[] | {java_version, distribution_version, term_of_support, javafx_bundled, archive_type, filename}'
```

```
{"java_version":"21.0.8+9","distribution_version":"21.0.8","term_of_support":"lts","javafx_bundled":false,"archive_type":"tar.gz","filename":"OpenJDK21U-jdk_x64_linux_hotspot_21.0.8_9.tar.gz"}
```

`java_version` is Java's version and the one the plugin uses. `distribution_version` is the vendor's own (Zulu's `27.28.101` for Java `27+35`).

## Releases and support terms

```bash
curl -s 'https://api.foojay.io/disco/v3.0/major_versions?ea=false&ga=true&maintained=true' \
  | jq -r '.result[] | [.major_version, .term_of_support] | @tsv'
```

lists the feature releases that are still maintained and whether each is LTS or STS. Early-access builds need `release_status=ea` or an explicit version such as `version=28-ea`.

## Notes

- Some HTTP clients get `403` from Foojay with their default User-Agent. Python's `urllib` does. `curl` does not, and neither does vfox.
- The examples use `jq`, which you may have to install. Any JSON tool will do.
- vfox keeps the result of `vfox search` for 12 hours, so a change in Foojay may take that long to show up.
- Data problems, such as a missing or wrongly marked build, belong to Foojay: [foojayio/discoapi](https://github.com/foojayio/discoapi). Problems with how this plugin reads the data belong in this repository.
