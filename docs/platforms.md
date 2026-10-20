# Platform support

[中文](zh-CN/platforms.md) | [English](platforms.md)

The plugin asks Foojay for packages of the platform it runs on: the operating system, the CPU architecture of the vfox binary and, on Linux, the C library (see [foojay.md](foojay.md) for the request). A distribution that has nothing for that platform fails in `vfox search java bsg` with `no available version`, and installing it fails too:

```
No JDK found for 21-bsg on darwin/arm64. Please check available versions with 'vfox search java'
```

The table shows which platforms each distribution has packages for. It was taken from Foojay on 2026-10-18, and the rows from AdoptOpenJDK on were added on 2026-10-20. ✅ means Foojay lists at least one package the plugin can install there, ❌ means none.

| Distribution | Linux x64 | Linux arm64 | Alpine x64 | Alpine arm64 | macOS Intel | macOS Apple silicon | Windows x64 | Windows arm64 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OpenJDK (`open`) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Temurin (`tem`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Zulu (`zulu`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Liberica (`librca`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Corretto (`amzn`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Microsoft (`ms`) | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Oracle JDK (`oracle`) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Semeru (`sem`) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| SapMachine (`sapmchn`) | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Kona (`kona`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Dragonwell (`albba`) | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |
| BiSheng (`bsg`) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Oracle GraalVM (`graal`) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| GraalVM Community (`graalce`) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Liberica NIK (`nik`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Mandrel (`mandrel`) | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| JetBrains Runtime (`jb`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Trava (`trava`) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| AdoptOpenJDK (`adpt`) | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ |
| AdoptOpenJDK OpenJ9 (`adptj9`) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| Eliya (`eliya`) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| OJDKBuild (`ojdkbld`) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| OpenLogic (`opnlgc`) | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| Red Hat (`rdht`) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Semeru certified (`semcrt`) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Gluon GraalVM (`gln`) | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| GraalVM CE 8 (`grl8`) | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| GraalVM CE 11 (`grl11`) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| GraalVM CE 16 (`grl16`) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| GraalVM CE 17 (`grl17`) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| GraalVM CE 19 (`grl19`) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |

"Alpine" stands for Linux with the musl C library. The plugin takes it as musl when `ldd --version` mentions it, and as glibc otherwise. Loongnix has its own page, [loongnix.md](loongnix.md).

Foojay changes, and the table with it. To get the current one, ask Foojay the way [foojay.md](foojay.md#which-distributions-have-a-build-for-my-platform) shows.

## Only some releases

A ✅ does not mean every release is there. As of the same date:

- Windows on ARM64 has no Java 8 from anyone. Temurin has 21 and 23 there, Zulu 16 to 19, 21 and 25, Liberica 11 and 16 to 27, Microsoft 11, 16, 17, 21 and 25, and JetBrains Runtime 17, 21 and 25.
- On Apple silicon Java 8 comes from Zulu, Liberica, Corretto and Kona. Temurin and Semeru have 11 and 17 to 27 there, and OpenJDK 17 to 27. Mandrel has releases 23.1 to 25, for Java 21 to 25, and Liberica NIK 22.2 to 25, for Java 11, 17 and 20 to 25 (see [their numbers](distributions.md#behavior-of-mandrel-and-liberica-nik)).
- Intel Macs get new releases later or not at all. OpenJDK and Temurin stop at 26 where Linux has 27, SapMachine stops at 24, and Oracle GraalVM and GraalVM Community stop at 25.0.1. Mandrel has no Intel Mac build.
- On Alpine, Temurin has arm64 builds from 21 only. For x64, Microsoft has 11 and 17, SapMachine 17 and 20 to 27, Kona 8 and 21, Dragonwell 11, 17, 21 and 25, and JetBrains Runtime 17. Kona has Java 8 for arm64, and JetBrains Runtime 17 for both.
- Trava has a single build for Linux arm64, 11.0.10+6.
- JavaFX builds exist for fewer platforms than plain ones, see [javafx.md](javafx.md#where-javafx-builds-exist).

For the rows added on 2026-10-20, as of that date:

- AdoptOpenJDK's Alpine x64 builds are Java 16 with HotSpot, and its OpenJ9 builds for Linux arm64 are 8, 11, 15 and 16.
- OJDKBuild has Java 8 and 11 for Linux.
- Red Hat's builds download for Linux x64 only, its one ✅ in the table. Foojay also lists a few for Linux arm64 and one for Windows, which `vfox search` shows, but their downloads answer 404.
- On Apple silicon Gluon GraalVM has 22.1.0.1 and 23+25, GraalVM CE 11 and 17 have GraalVM 22.1 to 22.3.1, and GraalVM CE 19 has 22.3 and 22.3.1.

## Which are x64 only

Every distribution has Linux arm64 builds except OJDKBuild, OpenLogic, Red Hat, Gluon GraalVM and GraalVM CE 8, and Trava has a single one (11.0.10+6). On macOS, Dragonwell, BiSheng, Eliya, OJDKBuild, Red Hat and Semeru certified have neither architecture, Trava, AdoptOpenJDK, OpenLogic, GraalVM CE 8 and GraalVM CE 16 have Intel only, and Mandrel has Apple silicon only.

On Windows almost everything is x64 only. These have an arm64 build besides: Temurin, Zulu, Liberica, Microsoft and JetBrains Runtime. The others are x64 only, with BiSheng, Eliya, Red Hat and Semeru certified not there at all.

## GraalVM

Oracle GraalVM and GraalVM Community have x64 and arm64 builds for Linux and macOS, and x64 only for Windows. They have no Alpine build. For Intel Macs the newest release is 25.0.1, and the monthly feature releases since 25.1 come for Apple silicon on macOS. The e2e suite skips GraalVM Community on arm64 only because its Windows arm64 job would have nothing to install. Linux arm64 has builds.

GraalVM CE 8 to 19 and Gluon GraalVM have no Alpine or Windows ARM64 build either. GraalVM CE has Linux arm64 builds from JDK 11 on, and Gluon GraalVM has none.

## Other CPUs

vfox ships binaries for 32-bit x86 and 32-bit ARM as well as x64, arm64 and loong64. The plugin passes the architecture name of the vfox binary to Foojay (`arm64` as `aarch64`, and `amd64` as `x64` on Windows), so what you get is what Foojay lists. None of this is covered by the e2e suite.

- 32-bit ARM Linux: Corretto, Liberica, Temurin and Zulu, and AdoptOpenJDK with HotSpot.
- 32-bit x86 Linux: Corretto, Liberica, Zulu and JetBrains Runtime, and OpenLogic's Java 8.
- loong64 is unknown to Foojay, and Linux loong64 uses Loongnix instead, see [loongnix.md](loongnix.md).

If you build vfox for riscv64, ppc64le or s390x, Foojay lists riscv64 packages for Dragonwell, Liberica and Temurin, ppc64le for Liberica, SapMachine, Semeru and Temurin, and s390x for Semeru and Temurin. Of the distributions added on 2026-10-20, AdoptOpenJDK, with HotSpot and with OpenJ9, and Semeru certified have ppc64le and s390x packages. Red Hat's ppc64le records answer 404.

## macOS Java home

Some macOS archives hold the JDK in `Contents/Home` or in a vendor-named bundle. After the install the plugin moves the contents up, so `JAVA_HOME` always points at a directory with `bin/java`. The install prints `Checking Java home layout...` for it. An archive with two candidate homes, or one whose files would overwrite each other, is refused before anything is moved.
