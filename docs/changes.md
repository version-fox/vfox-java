# Changes

[中文](zh-CN/changes.md) | [English](changes.md)

What changed in each release, as a user notices it. GitHub's release pages list the pull requests. The newest release at the time of writing is 0.6.2, and `main` is ahead of it by everything under "Unreleased". [install-from-source.md](install-from-source.md) gets you those changes now.

## Unreleased

- 13 more distributions, the rest of what Foojay lists: AdoptOpenJDK (`adpt`, `adptj9`), Eliya (`eliya`), OJDKBuild (`ojdkbld`), OpenLogic (`opnlgc`), Red Hat (`rdht`), Semeru certified (`semcrt`), Gluon GraalVM (`gln`) and GraalVM CE for JDK 8 to 19 (`grl8`, `grl11`, `grl16`, `grl17`, `grl19`). Red Hat installs from tar.xz, and OJDKBuild on Linux, OpenLogic on macOS and Gluon GraalVM before 22.1 from zips. A `.sdkmanrc` takes SDKMAN's old identifiers for them, such as `11.0.10.j9-adpt` and `22.3.3.r17-grl`. See [distributions.md](distributions.md).
- Mandrel and Liberica NIK install by the GraalVM version they carry again: `java@23.1.12-mandrel` and `java@23.1.8-nik` work, `vfox search java mandrel` lists every release, and `java@23-mandrel` installs the newest 23.x, `23.1.12.1-mandrel`, which runs Java 21. In October 2026 Foojay moved that version from `java_version` to `distribution_version`, and since then release 0.6.2 fails on such versions with `No JDK found`, lists one Mandrel per Java major and installs Mandrel 23.1.8 for `java@21-mandrel`. Installs it made since then keep names after the Java version (`21-mandrel`, `21.0.12.1+2-nik`), and vfox still finds them by those names; uninstall one to get what the spec means now. See [distributions.md](distributions.md#behavior-of-mandrel-and-liberica-nik) ([#106](https://github.com/version-fox/vfox-java/issues/106)).
- A `.sdkmanrc` takes SDKMAN's identifiers of Mandrel and Liberica NIK with the JDK after `.r`: `java=25.0.4.r25-nik` selects `25.0.4-nik`, where release 0.6.2 selects the newest installed release of the major. Of a release that comes for two JDKs, the plugin installs only the newer one's build, so `22.1.r11-mandrel` selects nothing. See [sdkmanrc.md](sdkmanrc.md#sdkmans-spellings) ([#109](https://github.com/version-fox/vfox-java/issues/109)).
- The notes printed by `vfox add java`, `vfox update java` and `vfox info java` are a link to the README, which lists every short name and shows how to search a distribution. Release 0.6.2 gives five short names there but not how to list their versions, while `vfox search java` lists OpenJDK only ([vfox#390](https://github.com/version-fox/vfox/issues/390)).
- Oracle GraalVM and GraalVM Community go by GraalVM's own version, which Foojay has given as `distribution_version` since October 2026. Release 0.6.2 reads `java_version`, which now holds the JDK's version. So it installs the feature release 25.4.4.1.1 for `java@25.0.4.1-graal`, and for `java@25-graal` whenever a feature release is out on the JDK of the newest 25.0 build, and `vfox search java graal` lists no feature release. Now `java@25-graal` installs the newest build of the 25.0 line (`25.0.5-graal` on 2026-10-20), `java@25.0.4.1-graal` installs GraalVM 25.0.4.1, and the feature release is `java@25.4.4.1.1-graal`. `java@25-graalce` installs `25.4.4.1.1-graalce` from Oracle's GraalVM Download Service, where 0.6.2 installed the same file from GitHub as `25.4.4.1-graalce` ([#105](https://github.com/version-fox/vfox-java/issues/105)).
- A 25.0 name that release 0.6.2 installed after Foojay's change can hold a feature release: `25.0.4.1-graal` is GraalVM 25.4.4.1.1, `25.0.4-graal` is 25.2.4 and `25.0.3-graal` is 25.1.3, and the same goes for these names with `-graalce`. vfox does not install a name it already has, so if the GraalVM version that `java -version` prints differs from the name, `vfox uninstall` it and install it again. `25.0.4.1-graalce`, `25.0.4-graalce` and `25.0.3-graalce` no longer install at all, as GraalVM Community's 25.0 line ends with `25.0.2`.

## 0.6.2 (2026-10-18)

- `.sdkmanrc` works under vfox 1.x again. Release 0.6.1 fails with `expected 0 arguments for func() []string, got 1` under vfox 1.x (tested with 1.0.12 and 1.0.13), and vfox hides the error ([#65](https://github.com/version-fox/vfox-java/pull/65)).
- `vfox use java@21`, a bare major, works under vfox 1.0.13. Release 0.6.1 fails there with `cannot unmarshal string into plugin.PreUseHookResult` ([#65](https://github.com/version-fox/vfox-java/pull/65)).
- `.sdkmanrc` matches SDKMAN's `jbr` and JavaFX identifiers ([#78](https://github.com/version-fox/vfox-java/pull/78)), zero-padded releases ([#85](https://github.com/version-fox/vfox-java/pull/85)) and early-access identifiers ([#88](https://github.com/version-fox/vfox-java/pull/88), [#96](https://github.com/version-fox/vfox-java/pull/96)). It selects the JDK it names when several of the same major are installed ([#84](https://github.com/version-fox/vfox-java/pull/84)). See [sdkmanrc.md](sdkmanrc.md).
- A bare major installs the newest release. `java@21-tem` is `21.0.12.1+1-tem` and not `21+35-tem` ([#74](https://github.com/version-fox/vfox-java/pull/74)). `java@25-graal` installs `25.0.4.1-graal`, the newest build of the 25.0 line, where release 0.6.1 installed `25-graal` ([#101](https://github.com/version-fox/vfox-java/pull/101)).
- `vfox use java@21.0.8-tem` finds the installed `21.0.8+9-tem` ([#76](https://github.com/version-fox/vfox-java/pull/76)). The same goes for OpenJDK names with `-open` or `openjdk-` ([#77](https://github.com/version-fox/vfox-java/pull/77)) and for zero-padded releases ([#92](https://github.com/version-fox/vfox-java/pull/92)).
- `java@21.0.5+63130-jb` and `java@28.ea.15-open` install the build they name and not the newest build of the release ([#83](https://github.com/version-fox/vfox-java/pull/83)).
- `vfox search` on Windows lists releases that ship only as tar.gz ([#81](https://github.com/version-fox/vfox-java/pull/81)).
- The plugin no longer sets `GRAALVM_HOME` ([#93](https://github.com/version-fox/vfox-java/pull/93)).
- `java@tem` and `java@-tem`, a distribution without a version, ask for one. Release 0.6.1 stops with `attempt to index a non-table object(nil) with key 'match'` for the first and installs the newest release for the second ([#99](https://github.com/version-fox/vfox-java/pull/99)).
- `vfox search` no longer marks GraalVM's monthly feature releases as LTS ([#100](https://github.com/version-fox/vfox-java/pull/100)).
- The repository has a container e2e suite for Linux and Windows, see [e2e.md](e2e.md) ([#65](https://github.com/version-fox/vfox-java/pull/65), [#82](https://github.com/version-fox/vfox-java/pull/82)).

## 0.6.1 (2026-09-12)

- On macOS the Java home is found by its `bin/java`, so archives with a vendor-named bundle or `Contents/Home` work ([#63](https://github.com/version-fox/vfox-java/pull/63)).

## 0.6.0 (2026-09-12)

- JDKs for Linux loong64 from the Loongnix archive, see [loongnix.md](loongnix.md) ([#62](https://github.com/version-fox/vfox-java/pull/62)).
- `vfox use` keeps the `-fx` of a JavaFX build ([#60](https://github.com/version-fox/vfox-java/pull/60)).
- JetBrains Runtime installs on Windows 11 ([#58](https://github.com/version-fox/vfox-java/pull/58)).

## 0.5.4 (2026-06-01)

- Early-access builds are installed as `java@26.ea.1-graal` ([#57](https://github.com/version-fox/vfox-java/pull/57)).

## 0.5.3 (2026-01-19)

- JavaFX builds with the `-fx` suffix ([#48](https://github.com/version-fox/vfox-java/pull/48)), see [javafx.md](javafx.md).
- Alpine and other musl systems get musl builds ([#50](https://github.com/version-fox/vfox-java/pull/50)).
- Windows x64 asks Foojay for `x64` again. 0.5.2 sent `amd64` there ([#52](https://github.com/version-fox/vfox-java/pull/52)).

## 0.5.2 (2026-01-18)

- arm64 asks Foojay for `aarch64`, which is what it expects ([#46](https://github.com/version-fox/vfox-java/pull/46), [#47](https://github.com/version-fox/vfox-java/pull/47)).

## 0.5.1 (2026-01-02)

- `vfox use java@21` is left to vfox, which matches a bare major against the installed versions.

## 0.5.0 (2025-09-29)

- Version strings in asdf's order work, `java@temurin-21` ([#17](https://github.com/version-fox/vfox-java/pull/17)).

## 0.4.x (2024-04)

- 0.4.0 reads `.sdkmanrc`.
- 0.4.3 asks Foojay for glibc builds on Linux ([#14](https://github.com/version-fox/vfox-java/pull/14)).

## 0.1.x and 0.2.x (2024-04)

- 0.1.0 is the first release, with 17 distributions.
- 0.1.2 adds `vfox search java all` ([#5](https://github.com/version-fox/vfox-java/pull/5)) and makes `open` the default distribution ([#6](https://github.com/version-fox/vfox-java/pull/6)).
- 0.2.1 adds Liberica Native Image Kit ([#10](https://github.com/version-fox/vfox-java/pull/10)).
