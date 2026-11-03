# vfox-java

[中文](README_CN.md) | [English](README.md)

[vfox](https://vfox.dev/) 的 Java 插件。

它通过 [Foojay](https://foojay.io/) 查找并安装 31 个发行版的 JDK，包括 Temurin、Zulu、Liberica、Corretto、Microsoft、GraalVM 等。在 Linux loong64 上，则改从 Loongnix 归档安装。

## 安装

先安装 [vfox](https://github.com/version-fox/vfox)，然后安装插件和 JDK，并选中这个 JDK：

```bash
vfox add java
vfox install java@21-tem
vfox use --global java@21-tem
java -version
```

`java -version` 会显示当前选中的 JDK。要让 `java` 出现在 `PATH` 里，需要先把 vfox 挂载到 Shell，见 vfox 的[快速入门](https://vfox.dev/zh-hans/guides/quick-start.html)。

`vfox search java tem` 会列出 Temurin 的各个版本，在交互式终端里还可以直接选一个并安装。

## 版本与命名

版本写成 `<版本>-<发行版>`，例如 `21.0.8-tem`，后面加 `-fx` 表示带 JavaFX：

```bash
vfox install java@21-tem          # Temurin 21 的最新版
vfox install java@21.0.8-tem      # Temurin 21.0.8
vfox install java@21-zulu-fx      # 带 JavaFX 的 Zulu 21
```

不写发行版时得到的是 jdk.java.net 上的 OpenJDK，它的 17 只到 17.0.2，21 只到 21.0.2，所以请指定发行版。安装、使用、搜索和 EA 构建的细节见 [docs/zh-CN/versions.md](docs/zh-CN/versions.md)。

## 发行版

| 简称 | 发行版 |
| --- | --- |
| `open` | jdk.java.net 上的 OpenJDK 构建，默认 |
| `tem` | Temurin（Eclipse Adoptium） |
| `zulu` | Zulu（Azul） |
| `librca` | Liberica（BellSoft） |
| `amzn` | Corretto（Amazon） |
| `ms` | Microsoft Build of OpenJDK |
| `oracle` | Oracle JDK |
| `sem` | Semeru（IBM） |
| `sapmchn` | SapMachine（SAP） |
| `kona` | Kona（腾讯） |
| `albba` | Dragonwell（阿里巴巴） |
| `bsg` | 毕昇 JDK（华为） |
| `graal` | Oracle GraalVM |
| `graalce` | GraalVM 社区版 |
| `nik` | Liberica Native Image Kit（BellSoft） |
| `mandrel` | Mandrel（Red Hat） |
| `jb` | JetBrains Runtime |
| `trava` | TravaOpenJDK |
| `adpt`、`adptj9` | AdoptOpenJDK，HotSpot 版和 OpenJ9 版 |
| `eliya` | Eliya JDK（Asymm Systems） |
| `ojdkbld` | OJDKBuild |
| `opnlgc` | OpenLogic OpenJDK |
| `rdht` | Red Hat build of OpenJDK |
| `semcrt` | Semeru 认证版（IBM） |
| `gln` | Gluon GraalVM |
| `grl8`、`grl11`、`grl16`、`grl17`、`grl19` | 基于 JDK 8 到 19 的 GraalVM CE |
| `lnxabi1`、`lnxabi2` | Loongnix，仅限 Linux loong64 |

简称沿用 [SDKMAN](https://sdkman.io/) 的标识符，有这几处不同：

- JetBrains Runtime 是 `jb`，毕昇是 `bsg`，它们在 SDKMAN 里叫 `jbr` 和 `bisheng`。
- AdoptOpenJDK 和 GraalVM CE 的虚拟机或 JDK 版本，SDKMAN 当时写在版本号里（`11.0.10.j9-adpt`、`22.3.3.r17-grl`），插件则给每种各起一个简称（`adptj9`、`grl17`）。
- Eliya、OJDKBuild、OpenLogic、Red Hat 和 Semeru 认证版在 SDKMAN 里没有标识符，简称是插件自己起的。

全部差别以及每个发行版是什么，见 [docs/zh-CN/distributions.md](docs/zh-CN/distributions.md)；最后一行见 [docs/zh-CN/loongnix.md](docs/zh-CN/loongnix.md)。

## 平台

并非每个发行版都有 arm64、Alpine 或 Windows ARM 的构建。只有 Temurin、Zulu、Liberica、Microsoft 和 JetBrains Runtime 有 Windows ARM64 的构建，31 个发行版里有 11 个有 Alpine x64 的构建，7 个有 Alpine arm64 的构建。GraalVM 既没有 Windows ARM64，也没有 Alpine。完整的表格见 [docs/zh-CN/platforms.md](docs/zh-CN/platforms.md)。

## JavaFX

Zulu、Liberica、Liberica NIK 和 Corretto（只有 Java 8）提供内置 JavaFX 的构建，在发行版后面加 `-fx` 即可，比如 `java@21-zulu-fx`。详见 [docs/zh-CN/javafx.md](docs/zh-CN/javafx.md)。

## Native Image

GraalVM 的安装和使用与别的 JDK 没有两样。只有用来构建原生可执行文件的 `native-image` 还需要 C 编译器和 zlib 的头文件，而最小化的 Ubuntu（比如它的容器镜像）两样都没有。第一次构建原生镜像之前装一次：

```bash
sudo apt install --assume-yes build-essential zlib1g-dev
```

GraalVM CE 8 到 19 不带 `native-image`，要先添加。没有这些包时 `native-image` 的报错、其他系统的做法以及怎样添加，见 [docs/zh-CN/native-image.md](docs/zh-CN/native-image.md)。

## `.sdkmanrc`

vfox 通过这个插件读取 SDKMAN 的 `.sdkmanrc` 里的 `java=` 一行，并选中已经安装的 JDK。详见 [docs/zh-CN/sdkmanrc.md](docs/zh-CN/sdkmanrc.md)。

## GitHub 镜像

大多数发行版从 GitHub 下载。如果你那里下载很慢，执行 `export VFOX_JAVA_GITHUB_MIRROR=https://gh-proxy.org/`，这些下载就会经过镜像。详见 [docs/zh-CN/mirror.md](docs/zh-CN/mirror.md)。

## SDKMAN 用户

[SDKMAN](https://sdkman.io/) 可以同时装好几个 JDK，并按单个 Shell、按项目，或为之后新开的所有 Shell 切换。这个插件也一样，沿用 SDKMAN 的简称，也读取 `.sdkmanrc`，所以 SDKMAN 用户和 vfox 用户可以共用同一个项目。

它还能用在 SDKMAN 用不了的地方。SDKMAN 是一组 bash 脚本，在 Windows 上要借助 WSL 或 Git Bash，不能在 PowerShell 里使用，Windows 自带的 Windows PowerShell 5.1 也不行。vfox 是原生的 Windows 程序，能挂载到 PowerShell，在那里这个插件就取代了 SDKMAN。两边的命令对照如下：

| | SDKMAN | vfox |
| --- | --- | --- |
| 安装 | `sdk install java 21.0.8-tem` | `vfox install java@21.0.8-tem` |
| 只在当前 Shell 里使用 | `sdk use java 21.0.8-tem` | `vfox use java@21.0.8-tem` |
| 在之后新开的所有 Shell 里使用 | `sdk default java 21.0.8-tem` | `vfox use --global java@21.0.8-tem` |

什么时候该用这个插件、其余的命令以及它们的差别，见 [docs/zh-CN/sdkman.md](docs/zh-CN/sdkman.md)。

## 文档

**使用插件**

- [版本与命名](docs/zh-CN/versions.md)：怎样写版本，以及安装、使用、搜索和 EA 构建
- [发行版](docs/zh-CN/distributions.md)：每个发行版是什么、它的长名，以及 GraalVM、Mandrel 和 Liberica NIK 怎样编号
- [平台](docs/zh-CN/platforms.md)：各发行版在哪些操作系统和 CPU 上有构建
- [查询 Foojay](docs/zh-CN/foojay.md)：自己去问 Foojay 你的平台上有哪些 JDK、插件向它问了什么，以及怎样校验下载的文件
- [JavaFX](docs/zh-CN/javafx.md)：`-fx` 构建以及哪些平台有
- [Native Image](docs/zh-CN/native-image.md)：`native-image` 需要的 C 编译器和 zlib
- [`.sdkmanrc`](docs/zh-CN/sdkmanrc.md)：SDKMAN 的项目文件会选中哪个 JDK
- [SDKMAN 与 vfox](docs/zh-CN/sdkman.md)：什么时候该用这个插件、命令对照以及差别
- [GitHub 镜像](docs/zh-CN/mirror.md)：github.com 很慢时让下载经过镜像
- [Loongnix](docs/zh-CN/loongnix.md)：Linux loong64 上的 JDK
- [问题排查](docs/zh-CN/troubleshooting.md)：插件和 `native-image` 的各种提示、代理设置和 JDK 的位置
- [变更记录](docs/zh-CN/changes.md)：每个版本改了什么

**参与开发**

- [从源码安装](docs/zh-CN/install-from-source.md)：在下一个版本发布之前用上 `main`
- [开发](docs/zh-CN/development.md)：插件的工作方式、修改方法和发布流程
- [E2E 测试](docs/zh-CN/e2e.md)：容器测试

## 致谢

- [SDKMAN](https://github.com/sdkman/)，简称和 `.sdkmanrc` 的支持都沿用了它的标识符
- [Foojay](https://github.com/foojayio/discoapi)，JDK 数据的来源
