# 来自 Foojay 的发行版

[中文](distributions.md) | [English](../distributions.md)

插件从 [Foojay](foojay.md) 获取下面 31 个发行版的版本列表和下载链接，2026-10-20 时 Foojay 列出的发行版全在这里。凡是要写发行版的地方，简称和长名都可以：`21-tem`、`21-temurin`、`temurin-21`、`vfox search java tem`。

未发布：0.6.2 没有 `adpt`、`adptj9`、`eliya`、`gln`、`grl8`、`grl11`、`grl16`、`grl17`、`grl19`、`ojdkbld`、`opnlgc`、`rdht` 和 `semcrt`。对这些发行版，0.6.2 的 `vfox install` 会报 `Could not extract a valid distribution`，`vfox search` 会报 `Unsupported distribution`。

| 简称 | 长名 | 发行版 | 维护方 |
| --- | --- | --- | --- |
| `adpt` | `aoj` | AdoptOpenJDK（HotSpot） | AdoptOpenJDK |
| `adptj9` | `aoj_openj9` | AdoptOpenJDK（OpenJ9） | AdoptOpenJDK |
| `albba` | `dragonwell` | 阿里巴巴 Dragonwell | 阿里巴巴 |
| `amzn` | `corretto` | Corretto | Amazon |
| `bsg` | `bisheng` | 毕昇 JDK（BiSheng） | 华为 |
| `eliya` | `eliya` | Eliya JDK | Asymm Systems |
| `gln` | `gluon_graalvm` | Gluon GraalVM | Gluon |
| `graal` | `graalvm` | Oracle GraalVM | Oracle |
| `graalce` | `graalvm_community` | GraalVM 社区版 | GraalVM 项目 |
| `grl8` | `graalvm_ce8` | 基于 JDK 8 的 GraalVM CE | GraalVM 项目 |
| `grl11` | `graalvm_ce11` | 基于 JDK 11 的 GraalVM CE | GraalVM 项目 |
| `grl16` | `graalvm_ce16` | 基于 JDK 16 的 GraalVM CE | GraalVM 项目 |
| `grl17` | `graalvm_ce17` | 基于 JDK 17 的 GraalVM CE | GraalVM 项目 |
| `grl19` | `graalvm_ce19` | 基于 JDK 19 的 GraalVM CE | GraalVM 项目 |
| `jb` | `jetbrains` | JetBrains Runtime | JetBrains |
| `kona` | `kona` | 腾讯 Kona JDK | 腾讯 |
| `librca` | `liberica` | Liberica | BellSoft |
| `mandrel` | `mandrel` | Mandrel | Red Hat |
| `ms` | `microsoft` | Microsoft Build of OpenJDK | Microsoft |
| `nik` | `liberica_native` | Liberica Native Image Kit | BellSoft |
| `ojdkbld` | `ojdk_build` | OJDKBuild | 社区 |
| `open` | `openjdk` | jdk.java.net 上的 OpenJDK 构建 | Oracle，代表 OpenJDK 项目 |
| `opnlgc` | `openlogic` | OpenLogic OpenJDK | OpenLogic |
| `oracle` | `oracle` | Oracle JDK | Oracle |
| `rdht` | `redhat` | Red Hat build of OpenJDK | Red Hat |
| `sapmchn` | `sap_machine` | SapMachine | SAP |
| `sem` | `semeru` | Semeru Runtimes 开放版 | IBM |
| `semcrt` | `semeru_certified` | Semeru Runtimes 认证版 | IBM |
| `tem` | `temurin` | Temurin | Eclipse Adoptium |
| `trava` | `trava` | TravaOpenJDK | 社区 |
| `zulu` | `zulu` | Zulu | Azul |

长名就是 Foojay 接受的发行版名，只有 `openjdk` 例外：Foojay 里它叫 Oracle OpenJDK，`openjdk` 只是它认的同义词。`lnxabi1` 和 `lnxabi2` 不来自 Foojay，所以不在表里，见 [loongnix.md](loongnix.md)。

各发行版覆盖哪些操作系统和 CPU，见 [platforms.md](platforms.md)。`vfox search java <名字>` 列出的是你这台机器上能装的版本。安装后的版本名带简称，OpenJDK 例外，它没有后缀（见 [versions.md](versions.md)）。

## 简称与 SDKMAN 的不同

简称沿用 [SDKMAN](https://sdkman.io/) 的标识符，Temurin 21.0.8 在两边都写作 `21.0.8-tem`。下面是与 SDKMAN 不同的地方，对照的是 2026-10-20 的 SDKMAN 列表：

- JetBrains Runtime 叫 `jb`，SDKMAN 里叫 `jbr`；毕昇 JDK 叫 `bsg`，SDKMAN 里叫 `bisheng`，也就是插件给它的长名。`.sdkmanrc` 里写 SDKMAN 的叫法也认，见 [sdkmanrc.md](sdkmanrc.md)。
- Dragonwell、TravaOpenJDK、AdoptOpenJDK、Gluon GraalVM 和按 GraalVM 自身编号的 GraalVM CE，SDKMAN 都已经不再提供。后三个在 SDKMAN 里曾叫 `adpt`、`gln` 和 `grl`，当时把虚拟机或 JDK 版本写进版本号：HotSpot 版是 `11.0.10.hs-adpt`，OpenJ9 版是 `11.0.10.j9-adpt`，基于 JDK 17 的是 `22.3.3.r17-grl`。插件给 Foojay 的每个发行版各起一个名字，所以这部分挪进了简称：`11.0.10-adpt`、`11.0.10-adptj9`、`22.3.3-grl17`。`.sdkmanrc` 里用 SDKMAN 的旧写法也能选中它们。
- Eliya、OJDKBuild、OpenLogic、Red Hat 和 Semeru 认证版在 SDKMAN 里没有标识符，简称是插件按 SDKMAN 的习惯起的：短的厂商名保持原样（`eliya`，类似 `zulu`），长的要缩短，多半是去掉元音（`ojdkbld`、`opnlgc`、`rdht`，类似 `librca`、`sapmchn`）。`semcrt` 是 SDKMAN 的 `sem` 加上 certified。Eliya 自己的安装说明里写着 `sdk install java 25.0.3-eliya`，它的网站也说正在向 SDKMAN 申请，但 SDKMAN 的列表里并没有它。

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

[IBM](https://developer.ibm.com/languages/java/semeru-runtimes/) 的运行时：OpenJDK 类库搭配 Eclipse OpenJ9 虚拟机，不是 HotSpot。这是开放版，认证版是 `semcrt`，见[下文](#semeru-认证版semcrt)。

### SapMachine（`sapmchn`）

[SAP](https://sapmachine.io/) 的 OpenJDK 构建。Java 11 起。

### Kona（`kona`）

[腾讯](https://tencent.github.io/konajdk)的 OpenJDK 构建。覆盖 Java 8、11、17、21 和 25。

### Dragonwell（`albba`）

[阿里巴巴](https://dragonwell-jdk.io/)的 OpenJDK 构建。覆盖 Java 8、11、17、21 和 25，有 Linux 和 Windows 版本，没有 macOS 版本。

### 毕昇 JDK（`bsg`）

[华为](https://www.hikunpeng.com/developer/devkit/compilation_debugging?data=JDK)的 OpenJDK 构建，面向 ARM 服务器。覆盖 Java 8、11、17、21 和 25，只有 Linux 版本。

### AdoptOpenJDK（`adpt`、`adptj9`）

[AdoptOpenJDK](https://adoptopenjdk.net/) 项目并入 Eclipse 基金会之前的构建，虚拟机用 HotSpot（`adpt`）或 Eclipse OpenJ9（`adptj9`）。覆盖 Java 8 到 16，到 2021 年为止。Foojay 把两者都标为不再维护。HotSpot 构建由 Temurin（`tem`）接替，OpenJ9 构建由 Semeru（`sem`）接替。

### Eliya（`eliya`）

[Asymm Systems](https://asymm.systems/product/eliya) 的 OpenJDK 25 构建，加上 `-XX:EliyaProfile=Production` 会打开一组面向生产环境的设置，例如 `OutOfMemoryError` 时导出堆转储。Foojay 只列了一个版本 25.0.3，平台是 Linux x64 和 arm64。

### OJDKBuild（`ojdkbld`）

[ojdkbuild](https://github.com/ojdkbuild/ojdkbuild) 项目的构建：Windows x64 上有 Java 8 到 15 和 17，Linux x64 上有 8 和 11，都是 zip 包。这个项目 2022 年发布 17.0.3 后就停止了。Foojay 在它的 Windows JDK 里还混着 JRE、installer bundle 包和给 Linux 的 RHEL 6 构建，插件会把这些排除掉。

### OpenLogic（`opnlgc`）

[OpenLogic](https://www.openlogic.com/openjdk-downloads) 的 OpenJDK 构建。覆盖 Java 8、11、17、21、22 和 25，有 Linux x64、Intel Mac 和 Windows x64 的版本。macOS 版是 zip 包。

### Red Hat build of OpenJDK（`rdht`）

[Red Hat](https://developers.redhat.com/products/openjdk/overview) 的便携版构建。Linux x64 上有 Java 8、11、17 和 21，是 tar.xz 包。Foojay 里最新的是 21.0.8（2025 年 7 月）。它也列了几个 Linux arm64 的构建和一个 Windows 的，但下载都返回 404（`source file not found`），Linux x64 的 11.0.15 和 11.0.16 也一样。

### Semeru 认证版（`semcrt`）

IBM Semeru Runtime Certified Edition：Semeru 的 OpenJ9 运行时，通过了 Java 兼容性测试套件（JCK）认证，采用 IBM 的许可证，不是开源许可证。覆盖 Java 11、17、21 和 25。Foojay 里没有它的 macOS 和 Windows 版本。

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

### GraalVM CE 8 到 19（`grl8`、`grl11`、`grl16`、`grl17`、`grl19`）

22.3 及以前的 GraalVM 社区版，那时它还没有改用 JDK 的版本号。Foojay 按 JDK 分成了几个发行版：`grl8`（GraalVM 19.3 到 21.3.1）、`grl11`（19.3 到 22.3.3）、`grl16`（21.1 和 21.2）、`grl17`（21.3 到 22.3.3）和 `grl19`（22.3 和 22.3.1）。之后接替它们的是 GraalVM 社区版（`graalce`）。

### Gluon GraalVM（`gln`）

[Gluon](https://docs.gluonhq.com/#_graalvm) 的 GraalVM 构建，用来把 JavaFX 应用编译成原生镜像。21.1 和 21.2 基于 JDK 11。22.x（22 到 22.1.0.1）同一个版本号下有 JDK 11 和 JDK 17 两个构建，插件装的是 JDK 17 的。23+25 是基于 JDK 23 的开发构建。有 Linux x64、macOS 和 Windows x64 的版本，Apple Silicon 从 22.1.0.1 起才有。

### 按 GraalVM 编号的版本

GraalVM CE 8 到 19，以及 23 以前的 Gluon GraalVM，版本号是 GraalVM 自己的，不是 Java 的：`22.3.3-grl17` 是 GraalVM 22.3.3，运行的是 Java 17.0.8；`21.3.1-grl11` 运行的是 Java 11。对只写大版本号的写法，vfox 只按版本号匹配，不分发行版，取以它开头的最高已安装版本，所以同时装了 `21.3.1-grl11` 和 `21.0.12.1+1-tem` 时，`vfox use java@21` 选中的是 `21.3.1-grl11`。请写上发行版，比如 `java@21-tem`。

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
