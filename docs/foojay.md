# Querying Foojay

[中文](zh-CN/foojay.md) | [English](foojay.md)

[Foojay](https://foojay.io/) runs the Disco API, a public index of JDK builds from many vendors (source: [foojayio/discoapi](https://github.com/foojayio/discoapi)). Except on Linux loong64, the plugin gets every list of versions and every download link from it. What `vfox search` shows is Foojay's data, and Foojay is where to look when a build you expect is missing.

You can ask it yourself in the browser. The [Swagger UI](https://api.foojay.io/swagger-ui) of the API has the endpoints, and its spec is [foojay-discoapi-3.0.yml](https://api.foojay.io/swagger/foojay-discoapi-3.0.yml). Open `GET /disco/v3.0/packages/jdks`, press "Try it out", fill in the parameters and press "Execute". The page shows the `curl` command it ran and the JSON that came back.

The examples below use `curl` and `jq`, which you may have to install. Any JSON tool will do. Some HTTP clients get `403` from Foojay with their default User-Agent. Python's `urllib` does. `curl` does not, and neither does vfox. What the plugin itself asks is under [What the plugin asks](#what-the-plugin-asks), and how it verifies a download under [Checksums](#checksums).

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

The names in the answer are the long names in [distributions.md](distributions.md), except `oracle_open_jdk`, which the plugin calls `openjdk` (`open`). With `archive_type=tar.gz` alone the answer misses Red Hat and OJDKBuild on Linux, and OpenLogic on macOS, which ship tar.xz or zip there. The plugin asks for those types for them, see [What the plugin asks](#what-the-plugin-asks).

## Which distributions have a release for my platform

```bash
# Java 27 on Intel Macs
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?version=27&latest=available&architecture=amd64&operating_system=macos&archive_type=tar.gz&directly_downloadable=true' \
  | jq -r '.result[].distribution' | sort -u
```

On 2026-11-03 this printed `corretto liberica oracle semeru zulu`. Temurin and OpenJDK were not among them: they stopped at 26 there. Use `latest=available` for a bare major, as the plugin does, and leave it out for a longer version.

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

`java_version` is Java's version and the one the plugin uses. `distribution_version` is the vendor's own (Zulu's `27.28.101` for Java `27+35`), which the plugin uses for Mandrel and Liberica NIK, see [below](#mandrel-and-liberica-nik), and for Oracle GraalVM and GraalVM Community.

For Oracle GraalVM and GraalVM Community, since October 2026, `distribution_version` is GraalVM's own version and `java_version` the JDK's, which a monthly feature release shares with a build of the 25.0 line:

```bash
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?distribution=graalvm&version=25.0.4.1&architecture=amd64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz&directly_downloadable=true' \
  | jq -r '.result[] | [.java_version, .distribution_version, .filename] | join(" ")'
```

```
25.0.4.1 25.4.4.1.1 graalvm-jdk-25i4-25.0.4.1.1_linux-x64_bin.tar.gz
25.0.4.1 25.3.4.1 graalvm-jdk-25i3-25.0.4.1_linux-x64_bin.tar.gz
25.0.4.1 25.0.4.1.1 graalvm-jdk-25.0.4.1.1_linux-x64_bin.tar.gz
25.0.4.1 25.0.4.1 graalvm-jdk-25.0.4.1_linux-x64_bin.tar.gz
```

`version` cannot tell those apart, and `distribution_version` matches whole leading components (`25.0.4.1` also lists `25.0.4.1.1`). So the plugin asks for every package, as `vfox search` does, picks the release itself, and names it after GraalVM's version: the newer of a package's `java_version` and `distribution_version`, as GraalVM Community's feature releases are also listed the old way round, with GraalVM's version as `java_version`. `vfox search` lists them newest first by that version, and a file that Foojay lists under two versions once.

## Releases and support terms

```bash
curl -s 'https://api.foojay.io/disco/v3.0/major_versions?ea=false&ga=true&maintained=true' \
  | jq -r '.result[] | [.major_version, .term_of_support] | @tsv'
```

lists the feature releases that are still maintained and whether each is LTS or STS. Early-access builds need `release_status=ea` or an explicit version such as `version=28-ea`.

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
| `version` | empty for `vfox search` and for a bare major such as `21`, else the version part of what you typed. A `+` is percent-encoded, because Foojay reads a bare one as a space and drops the build. `28.ea.19` becomes `28-ea+19`. Always empty for Mandrel and Liberica NIK, and for the GA releases of Oracle GraalVM and GraalVM Community |
| `architecture` | `aarch64` for arm64, `x64` on Windows x64, `amd64` for x64 elsewhere, and the name vfox reports for other CPUs |
| `operating_system` | `linux`, `macos` or `windows` |
| `archive_type` | `tar.gz`, and `zip` plus `tar.gz` on Windows. Elsewhere `tar.xz` comes in for Red Hat, and `zip` for OJDKBuild, OpenLogic and Gluon GraalVM |
| `lib_c_type` | `glibc` or `musl` on Linux, empty elsewhere |
| `directly_downloadable` | always `true` |

For a bare major such as `21` the answer lists every release, and the plugin takes the newest 21.x itself, which is what `java@21-tem` installs: `version=21` would match the 21 GA build only (`21+35`). Longer versions match as they are.

A bare major asks what searching asks so that installing sees the builds `vfox search` lists. Foojay's answers are cached per question, and two questions can get answers of different ages: half an hour after Oracle GraalVM 25.0.5 reached Foojay on 2026-10-20, GitHub's runners got it from a lookup with `distribution_version=25` but not from a search, and `vfox install java@25-graal` took a build that `vfox search java graal` did not list ([#113](https://github.com/version-fox/vfox-java/issues/113)).

The answer is a list of packages. The plugin names a release after `java_version` (Mandrel and Liberica NIK after `distribution_version`, Oracle GraalVM and GraalVM Community after GraalVM's own version), adds `-fx` where `javafx_bundled` is true, marks it LTS where `term_of_support` is `lts`, and prefers a `zip` over a `tar.gz` of the same version on Windows. It leaves out the JREs, installer bundles and RHEL 6 builds that Foojay lists among OJDKBuild's Windows JDKs, and the JDK 11 builds of Gluon GraalVM's 22.x releases, see [distributions.md](distributions.md). For the install it then fetches the package's `links.pkg_info_uri` and downloads its `direct_download_uri`, which is a vendor's own server (GitHub Releases for Temurin). The same record says how to check the download, see [Checksums](#checksums). A download from GitHub can go through a mirror, see [mirror.md](mirror.md).

`vfox search` differs from the raw list in a few ways. It lists a name once where Foojay has two records for it, and it leaves the LTS note off GraalVM's feature releases (see [distributions.md](distributions.md#behavior-of-oracle-graalvm-and-graalvm-community)). It only lists GA releases.

### Mandrel and Liberica NIK

Foojay gives the GraalVM version these two carry as `distribution_version`, and the Java version as `java_version`, for Mandrel the major only (2026-10-20):

```bash
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?distribution=mandrel&distribution_version=23.1.12&architecture=amd64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz&directly_downloadable=true' \
  | jq -r '.result[] | [.java_version, .distribution_version, .filename] | @tsv'
```

```
21	23.1.12.1	mandrel-java21-linux-amd64-23.1.12.1-Final.tar.gz
21	23.1.12	mandrel-java21-linux-amd64-23.1.12.0-Final.tar.gz
```

So the plugin asks for every package of these two, as `vfox search` does, and picks the release by `distribution_version` itself: the one named, or for a bare major the newest of the major. Foojay's own matching does neither: `distribution_version=23.1.12` lists 23.1.12.1 as well, as above, and with `distribution_version=23`, `latest=available` answered with 23.1.8 and two builds of 23.0.1.2, although 23.1.12.1 was out. Where a release comes for several Java versions the plugin takes the build for the newest, and of two Liberica NIK builds for the same Java the later one, which only the file name tells apart (`...-25.0.3+2-linux-amd64.tar.gz`). Searching sorts them by `distribution_version`, newest first.

## Checksums

The record that `links.pkg_info_uri` points to also says how to check the download. `checksum_type` is the algorithm, and the digest is in the record as `checksum`, or in a file of the vendor that `checksum_uri` points to. GraalVM Community 25.0.2 has the file only (2026-11-03):

```bash
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?distribution=graalvm_community&version=25.0.2&architecture=amd64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz&directly_downloadable=true' \
  | jq -r '.result[0].links.pkg_info_uri' | xargs curl -s | jq -c '.result[0] | {checksum_type, checksum, checksum_uri}'
```

```
{"checksum_type":"sha256","checksum":"","checksum_uri":"https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-25.0.2/graalvm-community-jdk-25.0.2_linux-x64_bin.tar.gz.sha256"}
```

Temurin's record holds the digest itself (`f2dc5418...9219` for 21.0.8 on Linux x64), next to the address of the vendor's file.

The plugin hands vfox the digest under the name of its algorithm (`sha256 = "..."` in what `PreInstall` returns). vfox hashes the file it downloaded and compares the two before it unpacks anything. It prints `Verifying checksum e0be791c...` and goes on, or stops with `Checksum error`, see [troubleshooting.md](troubleshooting.md#checksum-error). vfox verifies `sha256`, `sha512`, `sha1` and `md5`, and the packages use all four. Foojay names others too (`sha3_256`), which vfox cannot verify.

The digest in Foojay's record goes first. It comes from Foojay and not from the vendor's download site, which may be a mirror, and it costs no request. The plugin fetches the file only where the record has no digest, from GitHub through the mirror ([mirror.md](mirror.md)) like the download. These files do not all write a digest the same way, and the plugin reads three forms:

- the digest alone (GraalVM Community, OpenJDK, Oracle),
- `sha256sum`'s `<digest>  <name>`, with a `*` before the name for a binary file (Microsoft, JetBrains, Semeru, SAP Machine),
- BSD's `MD5 (<name>) = <digest>` (Tencent Kona).

A file that lists several packages gives the line of the one being installed. One that lists others only gives none: Microsoft's file for its EA build of 11.0.14 for macOS names the GA build, and that digest would fail an install that is fine.

Which packages come with a checksum varies by release, and Foojay holds none for some distributions. For the newest releases (2026-11-03):

| Foojay lists | Short names |
| --- | --- |
| the digest in the record | `tem`, `zulu`, `librca`, `nik`, `eliya`, `rdht`, `mandrel` from 25, the newest `graal` and `graalce` |
| a file of the vendor | `open`, `oracle`, `ms`, `sapmchn`, `sem`, `semcrt`, `jb`, `kona`, `ojdkbld`, `grl8`, `grl11`, `grl16`, `grl17`, `grl19`, and the older `graal` and `graalce` |
| no checksum | `albba`, `bsg`, `trava`, `adpt`, `adptj9`, `gln`, `opnlgc`, `amzn`, and the older releases of several of the others |

For a package with none, vfox prints `WARNING: Checksum is not provided, skip verify...` and trusts the download.

Where Foojay lists a checksum that the plugin cannot use, the install goes on without it, as it did before the plugin read checksums, and the plugin says why: `Cannot verify the download: https://example.org/x.tar.gz.sha256 has no digest for x.tar.gz`. The file may not answer, it may hold no digest for the package, or the algorithm may be one vfox does not verify. A checksum that cannot be had stops nothing. A download that does not match one does. Foojay gives the link and the checksum alike, so the check catches a damaged or substituted file, not a wrong record.

## Notes

- vfox keeps the result of `vfox search` for 12 hours, so a change in Foojay may take that long to show up.
- Data problems, such as a missing or wrongly marked build, belong to Foojay: [foojayio/discoapi](https://github.com/foojayio/discoapi). Problems with how this plugin reads the data belong in this repository.
