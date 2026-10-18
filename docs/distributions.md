# Distributions from Foojay

[中文](zh-CN/distributions.md) | [English](distributions.md)

The plugin gets the releases and download links of these 18 distributions from [Foojay](foojay.md). The short name or the long name goes wherever a distribution does: `21-tem`, `21-temurin`, `temurin-21`, `vfox search java tem`.

| Short name | Long name | Distribution | Maintained by |
| --- | --- | --- | --- |
| `open` | `openjdk` | OpenJDK builds from jdk.java.net | Oracle, for the OpenJDK project |
| `tem` | `temurin` | Temurin | Eclipse Adoptium |
| `zulu` | `zulu` | Zulu | Azul |
| `librca` | `liberica` | Liberica | BellSoft |
| `amzn` | `corretto` | Corretto | Amazon |
| `ms` | `microsoft` | Microsoft Build of OpenJDK | Microsoft |
| `oracle` | `oracle` | Oracle JDK | Oracle |
| `sem` | `semeru` | Semeru Runtimes, open edition | IBM |
| `sapmchn` | `sap_machine` | SapMachine | SAP |
| `kona` | `kona` | Tencent Kona JDK | Tencent |
| `albba` | `dragonwell` | Alibaba Dragonwell | Alibaba |
| `bsg` | `bisheng` | BiSheng JDK | Huawei |
| `graal` | `graalvm` | Oracle GraalVM | Oracle |
| `graalce` | `graalvm_community` | GraalVM Community Edition | GraalVM project |
| `nik` | `liberica_native` | Liberica Native Image Kit | BellSoft |
| `mandrel` | `mandrel` | Mandrel | Red Hat |
| `jb` | `jetbrains` | JetBrains Runtime | JetBrains |
| `trava` | `trava` | TravaOpenJDK | community |

The long names are the distribution names Foojay takes, except `openjdk`, which Foojay lists as Oracle OpenJDK and accepts as a synonym. The short names are SDKMAN's, except `jb`, which SDKMAN calls `jbr`. A `.sdkmanrc` accepts `jbr` as well as `jb`, see [sdkmanrc.md](sdkmanrc.md). `lnxabi1` and `lnxabi2` are not in the table because they do not come from Foojay, see [loongnix.md](loongnix.md).

Which operating systems and CPUs each distribution covers is in [platforms.md](platforms.md). `vfox search java <name>` lists what exists for the machine you run it on. Installed names carry the short name, except for OpenJDK, which has none (see [versions.md](versions.md)).

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

[IBM's](https://developer.ibm.com/languages/java/semeru-runtimes/) runtimes: the OpenJDK class library on the Eclipse OpenJ9 virtual machine instead of HotSpot. Only the open edition is offered, not Foojay's `semeru_certified`.

### SapMachine (`sapmchn`)

[SAP's](https://sapmachine.io/) build of OpenJDK. Java 11 onwards.

### Kona (`kona`)

[Tencent's](https://tencent.github.io/konajdk) build of OpenJDK. Java 8, 11, 17, 21 and 25.

### Dragonwell (`albba`)

[Alibaba's](https://dragonwell-jdk.io/) build of OpenJDK. Java 8, 11, 17, 21 and 25 for Linux and Windows. There is no macOS build.

### BiSheng (`bsg`)

[Huawei's](https://www.hikunpeng.com/developer/devkit/compilation_debugging?data=JDK) build of OpenJDK, aimed at ARM servers. Java 8, 11, 17, 21 and 25, for Linux only.

## GraalVM family

### Oracle GraalVM (`graal`)

Oracle's distribution of GraalVM, built on Oracle JDK. Releases carry GraalVM's numbers: `17.0.12-graal`, `25.0.4.1-graal`.

### GraalVM Community (`graalce`)

The open-source edition of GraalVM, built on OpenJDK.

### Liberica Native Image Kit (`nik`)

[BellSoft's](https://bell-sw.com/) distribution for building native images, based on GraalVM. Java 21 to 25, with `-fx` builds on some platforms.

### Mandrel (`mandrel`)

[Red Hat's](https://github.com/graalvm/mandrel) distribution for building Quarkus native executables, which concentrates on `native-image`.

Mandrel and Liberica NIK numbered their releases after themselves up to version 24 (Mandrel `23.1.12`), and number them after the JDK from 25 on (`25.0.4.1`).

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

## Foojay distributions the plugin does not offer

Foojay lists more than these 18: `aoj` and `aoj_openj9` (AdoptOpenJDK, succeeded by Temurin and Semeru), `eliya`, `gluon_graalvm`, `graalvm_ce8`, `graalvm_ce11`, `graalvm_ce16`, `graalvm_ce17`, `graalvm_ce19` (old GraalVM Community releases), `ojdk_build`, `openlogic`, `redhat` and `semeru_certified`. They have no short name here, so `vfox install java@21-openlogic` fails with `Could not extract a valid distribution`. [development.md](development.md#adding-a-distribution) describes how to add one.
