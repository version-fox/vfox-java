# Loongnix JDKs

[中文](zh-CN/loongnix.md) | [English](loongnix.md)

Foojay has no packages for LoongArch and rejects the architecture. On Linux loong64 the plugin therefore reads the JDKs from the [Loongnix archive](https://ftp.loongnix.cn/Java/) of Loongson, and does not talk to Foojay at all. It is the only JDK source of the plugin that is not Foojay. On every other platform `lnxabi1` and `lnxabi2` fail with `Loongnix JDKs require linux/loong64`, and on loong64 the distributions in [distributions.md](distributions.md) are not available:

```
$ vfox search java tem
Foojay does not support loong64; use vfox search java loongnix
```

## Choose the ABI

The archive holds two kinds of builds, and the plugin does not guess which one fits:

| Short name | Long name | Build | For |
| --- | --- | --- | --- |
| `lnxabi1` | `loongnix_abi1` | Linux 4.19 UAPI | Loongnix 20, Loongnix Server 8.4 |
| `lnxabi2` | `loongnix_abi2` | Linux 5.10 UAPI, `glibc2.34` in the upstream file names | Debian 12, openEuler |

Take the choice from [Loongson's compatibility notes](https://www.loongnix.cn/zh/api/java/) for your system, and not from the kernel version alone.

## Use

```bash
vfox search java lnxabi2                   # the ABI2 builds
vfox install java@21-lnxabi2-fx            # newest Java 21 with JavaFX, ABI2
vfox install java@21.0.12+8-lnxabi2-fx     # one build
vfox use java@21.0.12+8-lnxabi2-fx
```

`vfox search java` without a name lists the builds of both ABIs, as `vfox search java loongnix` and `vfox search java all` do. A result looks like this:

```
 - 26+35-lnxabi2-fx (JDK 26+35; ABI2 (Linux 5.10 UAPI, glibc 2.34); JavaFX)
 - 25.0.4+7-lnxabi2-fx (JDK 25.0.4+7; ABI2 (Linux 5.10 UAPI, glibc 2.34); JavaFX)
```

An install needs the ABI in its name. `vfox install java@21` and `java@21-tem` end with `Choose a Loongnix ABI explicitly: run vfox search java and select lnxabi1 or lnxabi2`. Picking a result from `vfox search` in an interactive terminal supplies it.

The version is Java's version and build number, `21.0.12+8`, and not Loongson's release number (`loongson21.12.26` in the file name). A release that Loongson published more than once is taken from the newest. `21` and `21.0.12` match by prefix and take the newest build, `21.0.1` does not match `21.0.12`. `vfox use` keeps the ABI and the `-fx` of what you type, so `21-lnxabi2-fx` selects the newest installed one and never an `lnxabi1` build.

## JavaFX

Most of Loongson's packages are JavaFX builds, which carry `fx-` in the upstream file name and `-fx` here. All of Java 21 and later are, and so are most of 8, 11 and 17, apart from a few early builds. Without `-fx` you only get a build that has no JavaFX, so `java@21-lnxabi2` fails with `No Loongnix JDK found for 21-lnxabi2` and `java@21-lnxabi2-fx` installs.

## Limits

- Only the general-availability LoongArch tarballs of the archive are offered. Early-access builds, installers, checksum files and the MIPS packages are skipped.
- The archive has glibc builds and no musl builds.
- The plugin does not verify the download.
- It reads the HTML directory listing of the archive. If Loongson changes its layout, the plugin stops with `No Loongnix JDK packages found; check the requested version and upstream directory format`.
- There is no loong64 job in the e2e suite. The hooks are tested offline against a saved copy of the archive listing, `tests/fixtures/loongnix` (see [development.md](development.md)).
