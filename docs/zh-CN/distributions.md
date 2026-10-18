# 来自 Foojay 的发行版

[中文](distributions.md) | [English](../distributions.md)

插件从 [Foojay](foojay.md) 获取下面 18 个发行版的版本列表和下载链接。凡是要写发行版的地方，简称和长名都可以：`21-tem`、`21-temurin`、`temurin-21`、`vfox search java tem`。

| 简称 | 长名 | 发行版 | 维护方 |
| --- | --- | --- | --- |
| `open` | `openjdk` | jdk.java.net 上的 OpenJDK 构建 | Oracle，代表 OpenJDK 项目 |
| `tem` | `temurin` | Temurin | Eclipse Adoptium |
| `zulu` | `zulu` | Zulu | Azul |
| `librca` | `liberica` | Liberica | BellSoft |
| `amzn` | `corretto` | Corretto | Amazon |
| `ms` | `microsoft` | Microsoft Build of OpenJDK | Microsoft |
| `oracle` | `oracle` | Oracle JDK | Oracle |
| `sem` | `semeru` | Semeru Runtimes 开放版 | IBM |
| `sapmchn` | `sap_machine` | SapMachine | SAP |
| `kona` | `kona` | 腾讯 Kona JDK | 腾讯 |
| `albba` | `dragonwell` | 阿里巴巴 Dragonwell | 阿里巴巴 |
| `bsg` | `bisheng` | 毕昇 JDK（BiSheng） | 华为 |
| `graal` | `graalvm` | Oracle GraalVM | Oracle |
| `graalce` | `graalvm_community` | GraalVM 社区版 | GraalVM 项目 |
| `nik` | `liberica_native` | Liberica Native Image Kit | BellSoft |
| `mandrel` | `mandrel` | Mandrel | Red Hat |
| `jb` | `jetbrains` | JetBrains Runtime | JetBrains |
| `trava` | `trava` | TravaOpenJDK | 社区 |

长名就是 Foojay 接受的发行版名，只有 `openjdk` 例外：Foojay 里它叫 Oracle OpenJDK，`openjdk` 只是它认的同义词。简称沿用 SDKMAN 的，只有 `jb` 不同（SDKMAN 里叫 `jbr`）；`.sdkmanrc` 里 `jbr` 和 `jb` 都认，见 [sdkmanrc.md](sdkmanrc.md)。`lnxabi1` 和 `lnxabi2` 不来自 Foojay，所以不在表里，见 [loongnix.md](loongnix.md)。

各发行版覆盖哪些操作系统和 CPU，见 [platforms.md](platforms.md)。`vfox search java <名字>` 列出的是你这台机器上能装的版本。安装后的版本名带简称，OpenJDK 例外，它没有后缀（见 [versions.md](versions.md)）。

## OpenJDK 构建

### OpenJDK（`open`）

[jdk.java.net](https://jdk.java.net/) 上的构建，采用 GPLv2 加 Classpath 例外条款。不写发行版时指的就是它。这个站点只提供最新的几个版本，旧版本只留最后一个构建，所以 17、21 不适合用它，见 [versions.md](versions.md#不写发行版)。它也发布 EA 构建。

### Temurin（`tem`）

[Eclipse Adoptium](https://adoptium.net/temurin/releases) 项目的构建，前身是 AdoptOpenJDK。覆盖 Java 8、11，以及 16 起的所有版本，有 EA 构建。

### Zulu（`zulu`）

[Azul](https://www.azul.com/downloads/?package=jdk) 的 OpenJDK 构建。除了当前版本，还有 Java 6 和 7，并提供带 JavaFX 的构建（`-fx`）。

### Liberica（`librca`）

[BellSoft](https://bell-sw.com/) 的 OpenJDK 构建，提供带 JavaFX 的构建（`-fx`）。它是有 Windows ARM64 构建的 5 个发行版之一。

### Corretto（`amzn`）

[Amazon](https://aws.amazon.com/corretto/) 的 OpenJDK 构建。覆盖 Java 8、11，以及 15 起的所有版本。

### Microsoft Build of OpenJDK（`ms`）

[Microsoft](https://www.microsoft.com/openjdk) 的构建。覆盖 Java 11、16、17、21 和 25，支持 Linux、macOS、Windows 的 x64 和 arm64。

### Oracle JDK（`oracle`）

[Oracle](https://www.oracle.com/java/) 自己的 JDK，从 Java 17 起。许可证是 Oracle 的，不是开源许可证，而且各版本的条款不同，请阅读你要安装的那个版本的条款。

### Semeru（`sem`）

[IBM](https://developer.ibm.com/languages/java/semeru-runtimes/) 的运行时：OpenJDK 类库搭配 Eclipse OpenJ9 虚拟机，不是 HotSpot。只提供开放版，不提供 Foojay 里的 `semeru_certified`。

### SapMachine（`sapmchn`）

[SAP](https://sapmachine.io/) 的 OpenJDK 构建。Java 11 起。

### Kona（`kona`）

[腾讯](https://tencent.github.io/konajdk)的 OpenJDK 构建。覆盖 Java 8、11、17、21 和 25。

### Dragonwell（`albba`）

[阿里巴巴](https://dragonwell-jdk.io/)的 OpenJDK 构建。覆盖 Java 8、11、17、21 和 25，有 Linux 和 Windows 版本，没有 macOS 版本。

### 毕昇 JDK（`bsg`）

[华为](https://www.hikunpeng.com/developer/devkit/compilation_debugging?data=JDK)的 OpenJDK 构建，面向 ARM 服务器。覆盖 Java 8、11、17、21 和 25，只有 Linux 版本。

## GraalVM 系列

### Oracle GraalVM（`graal`）

Oracle 发行的 GraalVM，基于 Oracle JDK。版本号沿用 GraalVM 自己的编号：`17.0.12-graal`、`25.0.4.1-graal`。

### GraalVM 社区版（`graalce`）

GraalVM 的开源版本，基于 OpenJDK。

### Liberica Native Image Kit（`nik`）

[BellSoft](https://bell-sw.com/) 用来构建原生镜像的发行版，基于 GraalVM。覆盖 Java 21 到 25，部分平台有带 `-fx` 的构建。

### Mandrel（`mandrel`）

[Red Hat](https://github.com/graalvm/mandrel) 为构建 Quarkus 原生可执行文件提供的发行版，专注于 `native-image`。

Mandrel 和 Liberica NIK 在 24 及以前用自己的版本号体系（Mandrel 的 `23.1.12`），从 25 起沿用 JDK 的版本号（`25.0.4.1`）。

### Oracle GraalVM 与 GraalVM 社区版的行为

- 从 25.1（2026 年 6 月）起，GraalVM 在 25.0 系列之外每月发布一个特性版本（feature release）：`25.1.3`、`25.2.4`、`25.3.4.1`、`25.4.4.1`，每个大约一个月后就被下一个取代。它们基于的 JDK 是 LTS，所以 Foojay 也把它们标成了 LTS，而 `vfox search` 不给它们加 LTS 备注。
- `java@25-graal` 装的是 25.0 系列的最新构建（`25.0.4.1-graal`），Oracle 官方的 `25/latest` 下载链接跟的也是这个系列。特性版本要写全版本号：`java@25.4.4.1-graal`。
- GraalVM 社区版的 25.0 系列到 `25.0.2` 为止，现在只发布特性版本。`java@25-graalce` 装其中最新的一个，截至 2026-10-18 是 `25.4.4.1-graalce`。
- 插件只设置 `JAVA_HOME` 和 `PATH`，不设置 `GRAALVM_HOME`。你设置的、指向自己的 GraalVM 的 `GRAALVM_HOME` 保持原样；没有设置时，native-image 的构建插件会回退到 `JAVA_HOME`。
- 没有 Windows ARM64 和 Alpine 的构建，Intel Mac 上 25.0.1 之后的版本也没有。见 [platforms.md](platforms.md#graalvm)。

## 其他

### JetBrains Runtime（`jb`）

JetBrains 各 IDE 运行所用的 [OpenJDK 分支](https://github.com/JetBrains/JetBrainsRuntime)。覆盖 Java 11、17、21 和 25。在 Windows 上，有些版本只提供 tar.gz，插件可以安装，`vfox search` 也会列出。

### TravaOpenJDK（`trava`）

[带 DCEVM 的 OpenJDK](https://github.com/TravaOpenJDK)，附带 HotswapAgent，用于在运行中的程序里替换类。覆盖 Java 8 和 11。Foojay 把它标为不再维护。它没有 Apple Silicon 的构建，Linux arm64 上只有一个（`11.0.10+6`）。

## Foojay 有但插件没有提供的发行版

Foojay 列出的发行版比上面这 18 个多：`aoj` 和 `aoj_openj9`（AdoptOpenJDK，已由 Temurin 和 Semeru 接替）、`eliya`、`gluon_graalvm`、`graalvm_ce8`、`graalvm_ce11`、`graalvm_ce16`、`graalvm_ce17`、`graalvm_ce19`（GraalVM 社区版的旧版本）、`ojdk_build`、`openlogic`、`redhat` 和 `semeru_certified`。它们在这里没有简称，所以 `vfox install java@21-openlogic` 会报 `Could not extract a valid distribution`。添加新发行版的方法见 [development.md](development.md#添加发行版)。
