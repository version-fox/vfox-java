# Distributions from Foojay

[中文](zh-CN/distributions.md) | [English](distributions.md)

The plugin gets the releases and download links of these 31 distributions from [Foojay](foojay.md), all that Foojay listed on 2026-10-20. The short name or the long name goes wherever a distribution does: `21-tem`, `21-temurin`, `temurin-21`, `vfox search java tem`.

Unreleased: release 0.6.2 lacks `adpt`, `adptj9`, `eliya`, `gln`, `grl8`, `grl11`, `grl16`, `grl17`, `grl19`, `ojdkbld`, `opnlgc`, `rdht` and `semcrt`. For those its `vfox install` stops with `Could not extract a valid distribution` and `vfox search` with `Unsupported distribution`.

| Short name | Long name | Distribution | Maintained by |
| --- | --- | --- | --- |
| `adpt` | `aoj` | AdoptOpenJDK with HotSpot | AdoptOpenJDK |
| `adptj9` | `aoj_openj9` | AdoptOpenJDK with OpenJ9 | AdoptOpenJDK |
| `albba` | `dragonwell` | Alibaba Dragonwell | Alibaba |
| `amzn` | `corretto` | Corretto | Amazon |
| `bsg` | `bisheng` | BiSheng JDK | Huawei |
| `eliya` | `eliya` | Eliya JDK | Asymm Systems |
| `gln` | `gluon_graalvm` | Gluon GraalVM | Gluon |
| `graal` | `graalvm` | Oracle GraalVM | Oracle |
| `graalce` | `graalvm_community` | GraalVM Community Edition | GraalVM project |
| `grl8` | `graalvm_ce8` | GraalVM CE for JDK 8 | GraalVM project |
| `grl11` | `graalvm_ce11` | GraalVM CE for JDK 11 | GraalVM project |
| `grl16` | `graalvm_ce16` | GraalVM CE for JDK 16 | GraalVM project |
| `grl17` | `graalvm_ce17` | GraalVM CE for JDK 17 | GraalVM project |
| `grl19` | `graalvm_ce19` | GraalVM CE for JDK 19 | GraalVM project |
| `jb` | `jetbrains` | JetBrains Runtime | JetBrains |
| `kona` | `kona` | Tencent Kona JDK | Tencent |
| `librca` | `liberica` | Liberica | BellSoft |
| `mandrel` | `mandrel` | Mandrel | Red Hat |
| `ms` | `microsoft` | Microsoft Build of OpenJDK | Microsoft |
| `nik` | `liberica_native` | Liberica Native Image Kit | BellSoft |
| `ojdkbld` | `ojdk_build` | OJDKBuild | community |
| `open` | `openjdk` | OpenJDK builds from jdk.java.net | Oracle, for the OpenJDK project |
| `opnlgc` | `openlogic` | OpenLogic OpenJDK | OpenLogic |
| `oracle` | `oracle` | Oracle JDK | Oracle |
| `rdht` | `redhat` | Red Hat build of OpenJDK | Red Hat |
| `sapmchn` | `sap_machine` | SapMachine | SAP |
| `sem` | `semeru` | Semeru Runtimes, open edition | IBM |
| `semcrt` | `semeru_certified` | Semeru Runtimes, certified edition | IBM |
| `tem` | `temurin` | Temurin | Eclipse Adoptium |
| `trava` | `trava` | TravaOpenJDK | community |
| `zulu` | `zulu` | Zulu | Azul |

The long names are the distribution names Foojay takes, except `openjdk`, which Foojay lists as Oracle OpenJDK and accepts as a synonym. `lnxabi1` and `lnxabi2` are not in the table because they do not come from Foojay, see [loongnix.md](loongnix.md).

Which operating systems and CPUs each distribution covers is in [platforms.md](platforms.md). `vfox search java <name>` lists what exists for the machine you run it on. Installed names carry the short name, except for OpenJDK, which has none (see [versions.md](versions.md)).

## Short names and SDKMAN

The short names follow the identifiers of [SDKMAN](https://sdkman.io/), where Temurin 21.0.8 is `21.0.8-tem` too. These are the differences, against SDKMAN's list of 2026-10-20:

- JetBrains Runtime is `jb`, which SDKMAN calls `jbr`, and BiSheng is `bsg`, which SDKMAN calls `bisheng`, the plugin's long name for it. A `.sdkmanrc` takes SDKMAN's spellings, see [sdkmanrc.md](sdkmanrc.md).
- SDKMAN no longer lists Dragonwell, TravaOpenJDK, AdoptOpenJDK, Gluon GraalVM or the GraalVM CE builds numbered after GraalVM. It called the last three `adpt`, `gln` and `grl`, and wrote the virtual machine or the JDK into the version: `11.0.10.hs-adpt` with HotSpot, `11.0.10.j9-adpt` with OpenJ9, `22.3.3.r17-grl` on JDK 17. Here each Foojay distribution has a name of its own, so that part moved into the name: `11.0.10-adpt`, `11.0.10-adptj9`, `22.3.3-grl17`. A `.sdkmanrc` with SDKMAN's spelling selects them.
- SDKMAN has no identifier for Eliya, OJDKBuild, OpenLogic, Red Hat or Semeru certified. Their short names are the plugin's own, made the way SDKMAN makes its names: a short vendor name stays whole (`eliya`, like `zulu`), and a longer one is cut down, mostly by dropping vowels (`ojdkbld`, `opnlgc`, `rdht`, like `librca` and `sapmchn`). `semcrt` is SDKMAN's `sem` with certified. Eliya's own install instructions give `sdk install java 25.0.3-eliya`, and its site says the SDKMAN registration is in progress, but SDKMAN did not list it.

## OpenJDK builds

### OpenJDK (`open`)

The builds on [jdk.java.net](https://jdk.java.net/), under GPLv2 with the Classpath Exception. This is what a version without a distribution means. The site carries the newest releases and the last build of older ones, which makes it a poor choice for 17 or 21, see [versions.md](versions.md#without-a-distribution). It publishes early-access builds too.

### Temurin (`tem`)

The builds of the [Eclipse Adoptium](https://adoptium.net/temurin/releases) project, which grew out of AdoptOpenJDK. Java 8, 11 and 16 onwards, with early-access builds.

### Zulu (`zulu`)

[Azul's](https://www.azul.com/downloads/?package=jdk) builds of OpenJDK. Java 6 and 7 are there as well as the current releases, and there are JavaFX builds (`-fx`).

### Liberica (`librca`)

[BellSoft's](https://bell-sw.com/) builds of OpenJDK, with JavaFX builds (`-fx`). It is one of five distributions with Windows on ARM64.

### Corretto (`amzn`)

[Amazon's](https://aws.amazon.com/corretto/) build of OpenJDK. Java 8, 11 and 15 onwards.

### Microsoft Build of OpenJDK (`ms`)

[Microsoft's](https://www.microsoft.com/openjdk) build. Java 11, 16, 17, 21 and 25, for Linux, macOS and Windows on x64 and arm64.

### Oracle JDK (`oracle`)

[Oracle's](https://www.oracle.com/java/) own JDK, from Java 17. The licence is Oracle's, not an open-source one, and its terms differ between releases. Read the ones for the release you install.

### Semeru (`sem`)

[IBM's](https://developer.ibm.com/languages/java/semeru-runtimes/) runtimes: the OpenJDK class library on the Eclipse OpenJ9 virtual machine instead of HotSpot. This is the open edition. The certified edition is `semcrt`, see [below](#semeru-certified-semcrt).

### SapMachine (`sapmchn`)

[SAP's](https://sapmachine.io/) build of OpenJDK. Java 11 onwards.

### Kona (`kona`)

[Tencent's](https://tencent.github.io/konajdk) build of OpenJDK. Java 8, 11, 17, 21 and 25.

### Dragonwell (`albba`)

[Alibaba's](https://dragonwell-jdk.io/) build of OpenJDK. Java 8, 11, 17, 21 and 25 for Linux and Windows. There is no macOS build.

### BiSheng (`bsg`)

[Huawei's](https://www.hikunpeng.com/developer/devkit/compilation_debugging?data=JDK) build of OpenJDK, aimed at ARM servers. Java 8, 11, 17, 21 and 25, for Linux only.

### AdoptOpenJDK (`adpt`, `adptj9`)

The builds of the [AdoptOpenJDK](https://adoptopenjdk.net/) project from before it moved to the Eclipse Foundation, with the HotSpot virtual machine (`adpt`) or with Eclipse OpenJ9 (`adptj9`). Java 8 to 16, up to 2021. Foojay marks both as no longer maintained. Temurin (`tem`) carries on the HotSpot builds and Semeru (`sem`) the OpenJ9 ones.

### Eliya (`eliya`)

[Asymm Systems'](https://asymm.systems/product/eliya) build of OpenJDK 25, whose `-XX:EliyaProfile=Production` turns on production settings such as a heap dump on `OutOfMemoryError`. Foojay lists one release, 25.0.3, for Linux x64 and arm64.

### OJDKBuild (`ojdkbld`)

The builds of the [ojdkbuild](https://github.com/ojdkbuild/ojdkbuild) project: Java 8 to 15 and 17 for Windows x64, and 8 and 11 for Linux x64, which come as zips. The project stopped in 2022, with 17.0.3. Among its Windows JDKs Foojay also lists JREs, installer bundles and RHEL 6 builds for Linux, which the plugin leaves out.

### OpenLogic (`opnlgc`)

[OpenLogic's](https://www.openlogic.com/openjdk-downloads) builds of OpenJDK. Java 8, 11, 17, 21, 22 and 25, for Linux x64, macOS Intel and Windows x64. The macOS builds come as zips.

### Red Hat build of OpenJDK (`rdht`)

[Red Hat's](https://developers.redhat.com/products/openjdk/overview) portable builds. Java 8, 11, 17 and 21 for Linux x64, as tar.xz. Foojay has 21.0.8 (July 2025) as the newest. It lists builds for Linux arm64 and one for Windows as well, but their downloads answer 404 (`source file not found`), and so do 11.0.15 and 11.0.16 for Linux x64.

### Semeru certified (`semcrt`)

IBM Semeru Runtime Certified Edition: Semeru's OpenJ9 runtimes, certified against the Java Compatibility Kit (JCK) and released under an IBM licence, not an open-source one. Java 11, 17, 21 and 25. Foojay has no macOS or Windows build of it.

## GraalVM family

### Oracle GraalVM (`graal`)

Oracle's distribution of GraalVM, built on Oracle JDK. Releases carry GraalVM's numbers: `17.0.12-graal`, `25.0.4.1-graal`.

### GraalVM Community (`graalce`)

The open-source edition of GraalVM, built on OpenJDK.

### Liberica Native Image Kit (`nik`)

[BellSoft's](https://bell-sw.com/) distribution for building native images, based on GraalVM. Releases 21 to 25, which run Java 11, 17 and 20 to 25, with `-fx` builds on some platforms.

### Mandrel (`mandrel`)

[Red Hat's](https://github.com/graalvm/mandrel) distribution for building Quarkus native executables, which concentrates on `native-image`. Releases 20.3 to 25, which run Java 11, 17 and 20 to 25.

### Behavior of Mandrel and Liberica NIK

- Both carry the version of the GraalVM they are built from, and their installs are named after it: `23.1.12.1-mandrel`, `23.1.8-nik`. Up to 24 that is not the Java version. 23.1 runs Java 21, 24.0 Java 22, 24.1 Java 23 and 24.2 Java 24, and older releases run Java 11, 17 or 20. From 25 on the two agree (`25.0.4.1`).
- A bare major is GraalVM's as well: `java@23-mandrel` installs the newest 23.x, `23.1.12.1-mandrel`, which runs Java 21, and `java@21-mandrel` installs `21.3.6-mandrel`, which runs Java 17. A longer version installs the release it names: `java@23.1.12-mandrel` is 23.1.12, not 23.1.12.1, and `java@23.1-mandrel` is the first 23.1 release, 23.1.0. A build number finds nothing (`java@23.1.8+1-nik`).
- The releases ending in `.0.0` are listed under the bare major (`24-mandrel` is Mandrel 24.0.0) and install with a longer version, `java@24.0.0-mandrel`. Once one is installed, vfox finds `java@24-mandrel` by that name, for `vfox install` and `vfox use` alike.
- Some releases come for several Java versions under one number, such as Mandrel 21.3.6 for Java 11 and 17. The plugin installs the build for the newest Java, which for Mandrel 23.0.1.2 and Liberica NIK 23.0.1 is Java 20, not 17. Liberica NIK built a few releases twice for the same Java (`25.0.3`), and the later build installs. The name shows neither the Java version nor BellSoft's build, so the other builds cannot be installed.
- Unreleased: release 0.6.2 names them after Foojay's `java_version`, which held these numbers until Foojay put the Java version there in October 2026. Since then 0.6.2 fails on `java@23.1.12-mandrel` and `java@23.1.8-nik` with `No JDK found`, lists Mandrel in `vfox search` as one name per Java major (`21-mandrel`), installs Mandrel 23.1.8 for `java@21-mandrel` and Liberica NIK 24.1.2, built for Java 23, for `java@23-nik`.

### GraalVM CE 8 to 19 (`grl8`, `grl11`, `grl16`, `grl17`, `grl19`)

GraalVM Community Edition up to 22.3, from before it numbered its releases after the JDK. Foojay has one distribution per JDK: `grl8` (GraalVM 19.3 to 21.3.1), `grl11` (19.3 to 22.3.3), `grl16` (21.1 and 21.2), `grl17` (21.3 to 22.3.3) and `grl19` (22.3 and 22.3.1). GraalVM Community (`graalce`) followed them.

### Gluon GraalVM (`gln`)

[Gluon's](https://docs.gluonhq.com/#_graalvm) build of GraalVM, for compiling JavaFX applications into native images. 21.1 and 21.2 run on JDK 11. The 22.x releases, 22 to 22.1.0.1, come for JDK 11 and for JDK 17 under one version, and the plugin installs the JDK 17 build. 23+25 is a development build on JDK 23. Linux x64, macOS and Windows x64, with Apple silicon from 22.1.0.1.

### Versions numbered after GraalVM

GraalVM CE 8 to 19, Gluon GraalVM before 23, and Mandrel and Liberica NIK before 25 carry GraalVM's version numbers, not Java's: `22.3.3-grl17` is GraalVM 22.3.3 and runs Java 17.0.8, `21.3.1-grl11` runs Java 11, and `23.1.12.1-mandrel` runs Java 21. For a bare major vfox takes the highest installed version that starts with it, from any distribution, so with `21.3.1-grl11` and `21.0.12.1+1-tem` installed, `vfox use java@21` selects `21.3.1-grl11`. Name the distribution, as in `java@21-tem`.

### Behavior of Oracle GraalVM and GraalVM Community

- Since 25.1 (June 2026) GraalVM puts out a feature release every month next to its 25.0 line: `25.1.3`, `25.2.4`, `25.3.4.1`, `25.4.4.1`. Each is replaced within about a month. Foojay marks them LTS because the JDK they build on is LTS, and `vfox search` leaves the LTS note off them.
- `java@25-graal` installs the newest build of the 25.0 line (`25.0.4.1-graal`), the line Oracle's own `25/latest` download follows. A feature release needs its full version: `java@25.4.4.1-graal`.
- GraalVM Community's 25.0 line ended with `25.0.2`, and the feature releases are all it still ships. `java@25-graalce` installs the newest of them, `25.4.4.1-graalce` on 2026-10-18.
- The plugin sets `JAVA_HOME` and `PATH`, and no `GRAALVM_HOME`. A `GRAALVM_HOME` that points at a GraalVM of your own stays as it is, and the native-image build plugins fall back to `JAVA_HOME` when it is unset.
- There is no Windows ARM64 and no Alpine build, and Intel Macs get nothing after 25.0.1. See [platforms.md](platforms.md#graalvm).

## Others

### JetBrains Runtime (`jb`)

The [fork of OpenJDK](https://github.com/JetBrains/JetBrainsRuntime) that JetBrains' IDEs run on. Java 11, 17, 21 and 25. On Windows some releases ship only as tar.gz. The plugin installs those, and `vfox search` lists them.

### TravaOpenJDK (`trava`)

[OpenJDK with DCEVM](https://github.com/TravaOpenJDK) and a bundled HotswapAgent, for replacing classes in a running program. Java 8 and 11. Foojay marks it as no longer maintained. It has no Apple silicon build and one for Linux arm64 (`11.0.10+6`).
