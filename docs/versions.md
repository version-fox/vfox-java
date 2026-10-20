# Versions and names

[中文](zh-CN/versions.md) | [English](versions.md)

The part after `java@` in `vfox install` and `vfox use` is a version and a distribution, joined with `-`:

```bash
vfox install java@21-tem            # newest Temurin 21
vfox install java@21.0.8-tem        # Temurin 21.0.8
vfox install java@21.0.8+9-tem      # that exact build
vfox install java@21-zulu-fx        # Zulu 21 with JavaFX
vfox install java@temurin-21        # same as 21-tem, distribution first
vfox install java@21                # no distribution: OpenJDK from jdk.java.net
```

The distribution is a short name (`tem`) or a long name (`temurin`). Both lists are in [distributions.md](distributions.md). `-fx` goes last and asks for a JavaFX build, see [javafx.md](javafx.md).

## Without a distribution

`java@21` means OpenJDK as published on [jdk.java.net](https://jdk.java.net/), and its installed name has no suffix (`21.0.2+13`). That site carries the newest releases and the last build of older ones: 17 stops at `17.0.2`, 21 at `21.0.2`. So `vfox install java@17.0.17` fails, while `java@17.0.17-tem` works. For a release that is still maintained, name a distribution.

## Installing

`vfox install` asks the plugin which package matches, then vfox downloads and unpacks it.

- A bare major (`21`, `21-tem`) installs the newest release of that major the distribution lists, for example `21.0.12.1+1-tem` on 2026-10-18.
- A longer version must match a release the distribution lists. `21.0.8-tem` installs `21.0.8+9-tem`, the newest build of 21.0.8. A release nobody published fails with `No JDK found for 21.0.99-tem on linux/amd64`.
- A build number selects that build: `21.0.5+63130-jb`.
- A release padded with zeros, as SDKMAN writes it, is accepted: `27.0.0-librca` installs `27+36-librca`.
- Oracle GraalVM's bare major installs the newest build of its 25.0 line, not one of the monthly feature releases, which have to be named in full (`25.4.4.1.1-graal`). Unreleased: release 0.6.2 can install a feature release for the bare major. See [GraalVM](distributions.md#graalvm-family).
- With `-fx` only JavaFX builds are considered, without it only builds without JavaFX. The two are never mixed.
- Mandrel and Liberica NIK go by the GraalVM version they carry, for a bare major too: `java@23-mandrel` installs `23.1.12.1-mandrel`, which runs Java 21. See [Mandrel and Liberica NIK](distributions.md#behavior-of-mandrel-and-liberica-nik).
- On Windows a release shipped as zip and as tar.gz installs from the zip.
- A distribution without a version (`java@tem`, `java@-tem`, `java@zulu-fx`) is rejected with a message that asks for one.

An install that finds the name already present prints `java@21.0.12.1+1-tem is already installed` and downloads nothing.

## Installed names

The plugin names an install after the `java_version` that Foojay reports, or the `distribution_version` for Mandrel and Liberica NIK, and GraalVM's own version for Oracle GraalVM and GraalVM Community. `vfox search` prints the same names:

```
<java_version>[-<short name>][-fx]
```

| Installed name | What it is |
| --- | --- |
| `21.0.12.1+1-tem` | Temurin |
| `25.0.4+9-librca-fx` | Liberica with JavaFX |
| `25.0.2+10` | OpenJDK, no suffix |
| `17.0.12-graal` | GraalVM, which has no build number |
| `25.4.4.1.1-graal` | GraalVM's version, not `java_version`, for Oracle GraalVM and GraalVM Community, here a monthly feature release, see [GraalVM](distributions.md#behavior-of-oracle-graalvm-and-graalvm-community) |
| `8.0.482+8-zulu` | Java 8 is `8.0.<update>+<build>` |
| `23.1.12.1-mandrel` | Mandrel, numbered after GraalVM: it runs Java 21 |
| `28-ea+19` | early-access build, see below |

These are the names `vfox list java` shows and `vfox uninstall` needs:

```bash
vfox uninstall java@21.0.8+9-tem
```

`vfox uninstall java@21.0.8-tem` answers `is not installed`. When you uninstall the version in use, vfox switches to the first entry left in `vfox list java`, which can be another major.

## Using

`vfox use` maps what you type to an installed name without downloading anything, so the build number and the release can be left out:

| You type | Selects |
| --- | --- |
| `21.0.8-tem` | the newest installed build of that release, `21.0.8+9-tem` |
| `21-tem` | the newest installed Temurin 21 |
| `temurin-21.0.8` | `21.0.8+9-tem` |
| `25.0.2-open`, `openjdk-25.0.2` | `25.0.2+10`, OpenJDK has no suffix |
| `21` | vfox's own match: the highest installed 21.x, from any distribution |

If you name a build or a release, it does not cross over to another one (`21.0.12-tem` does not select `21.0.12.1+1-tem`). It does not cross to another distribution, between JavaFX and plain, or between early-access and GA either. A name that matches nothing is reported as `java@99-tem is not installed`.

vfox's own match for `21` goes by the version alone, so it also takes GraalVM CE 8 to 19, Gluon GraalVM, Mandrel and Liberica NIK, whose versions are GraalVM's: `21.3.1-grl11` runs Java 11, and `vfox use java@21` selects it over `21.0.12.1+1-tem`. See [distributions.md](distributions.md#versions-numbered-after-graalvm).

Pick the scope with `vfox use`'s flags: `--global`, `--project` or `--session`, the default. In a shell without vfox's hook, Windows switches to the global scope with a warning, while Linux and macOS stop with `vfox requires hook support`. `--project` writes a `.vfox.toml` that holds the installed name (`java = "17.0.10+7-tem"`). A `.sdkmanrc` is read as well, see [sdkmanrc.md](sdkmanrc.md).

## Early-access builds

Spell the build as `<major>.ea[.<build>]`:

```bash
vfox install java@28.ea-open       # newest early-access build, 28-ea+19 on 2026-10-18
vfox install java@28.ea.15-open    # 28-ea+15
```

The installed name uses Foojay's spelling, `28-ea+19`, and `vfox use java@28-ea+19` takes it as it is. `vfox search` lists GA releases only. Foojay lists early-access builds for OpenJDK, Temurin, Zulu, SapMachine, GraalVM and GraalVM Community, among others. Vendors remove old ones from their servers while Foojay keeps the record, so an old build may fail to download.

## Searching

```bash
vfox search java            # OpenJDK, the default
vfox search java tem        # one distribution, short or long name
vfox search java all        # every distribution, about 2,500 lines on Linux x64
```

Each line is a name that can follow `java@`, newest first, with notes for LTS and JavaFX (see [javafx.md](javafx.md)) and a mark for versions that are installed:

```
$ vfox search java tem
Available versions:
 - 27+35-tem
 - 26.0.2.1+1-tem
 ...
 - 25.0.4+7-tem (LTS)
 ...
 - 21.0.12.1+1-tem (LTS) (installed)
```

The list holds what exists for the machine you run it on, see [platforms.md](platforms.md). In an interactive terminal `vfox search java tem` lets you pick a version and installs it, elsewhere it only prints. vfox caches the result for 12 hours (`vfox config cache.availableHookDuration`), so a release published a minute ago may be missing.

`vfox install java tem` does not select Temurin: arguments separated by spaces are several SDKs. Write `java@21-tem`.

The LTS note is Foojay's, except that GraalVM's monthly feature releases (`25.4.4.1.1-graal`) carry none, though Foojay marks some of them LTS.
