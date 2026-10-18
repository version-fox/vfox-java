# JavaFX builds

[中文](zh-CN/javafx.md) | [English](javafx.md)

Some vendors publish JDKs with JavaFX bundled, as separate packages. Put `-fx` after the distribution to get one:

```bash
vfox install java@21-zulu-fx
vfox install java@25.0.4-librca-fx
vfox use java@21-zulu-fx
```

`vfox search` lists both kinds of build, with `-fx` on the name and a JavaFX note:

```
 - 25.0.4.1+1-zulu-fx (LTS, JavaFX)
 - 25.0.4.1+1-zulu (LTS)
```

The installed name keeps the suffix (`25.0.4+9-librca-fx`), so a build with JavaFX and one without can sit side by side. They are never mixed up:

- `java@21-zulu` installs a build without JavaFX, and `java@21-zulu-fx` one with it. If the distribution has only one of the two for that release, the other fails: `java@21-tem-fx` ends with `No JDK found for 21-tem-fx with JavaFX on linux/amd64`, since Temurin has no JavaFX builds.
- `vfox use java@21-zulu` never selects a `-fx` build, and the other way round.
- A `.sdkmanrc` follows the same rule, see [sdkmanrc.md](sdkmanrc.md).

To check what you got, look for the modules:

```bash
java --list-modules | grep javafx
```

A build with JavaFX lists `javafx.base` and the others, one without lists none.

## Where JavaFX builds exist

As of 2026-10-18 four distributions have them, and not for every platform. The table lists the LTS releases that have a JavaFX build. The releases in between have some too, with gaps.

| Distribution | Linux x64 | Linux arm64 | Alpine x64 | macOS Intel | macOS Apple silicon | Windows x64 | Windows arm64 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Zulu (`zulu`) | 8, 11, 17, 21, 25 | 8, 11, 17, 21, 25 | – | 8, 11, 17, 21, 25 | 8, 11, 17, 21, 25 | 8, 11, 17, 21, 25 | – |
| Liberica (`librca`) | 8, 11, 17, 21, 25 | 11, 17, 21, 25 | 11 | 8, 11, 17, 21, 25 | 8, 11, 17, 21, 25 | 8, 11, 17, 21, 25 | 11, 17, 21, 25 |
| Corretto (`amzn`) | 8 | 8 | – | 8 | – | 8 | – |
| Liberica NIK (`nik`) | 21, 25 | – | – | 25 | 25 | 21, 25 | – |

Nothing has JavaFX for Alpine arm64. Loongnix has JavaFX builds for LoongArch, selected the same way, see [loongnix.md](loongnix.md). To see the current picture for a platform, add `javafx_bundled=true` to a query like the ones in [foojay.md](foojay.md).
