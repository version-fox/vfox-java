# vfox-java

[中文](README_CN.md) | [English](README.md)

[vfox](https://vfox.dev/) 的 Java 插件。

它通过 [Foojay](https://foojay.io/) 查找并安装 31 个发行版的 JDK，包括 Temurin、Zulu、Liberica、Corretto、Microsoft、GraalVM 等。在 Linux loong64 上，则改从 Loongnix 归档安装。

## 安装

先安装 [vfox](https://github.com/version-fox/vfox)，然后执行下面的命令安装插件：

```bash
vfox add java
```

要让 `java` 出现在 `PATH` 里，需要先把 vfox 挂载到 Shell，见 vfox 的[快速入门](https://vfox.dev/zh-hans/guides/quick-start.html)。

### 示例

```bash
vfox add java
vfox install java@21-tem
vfox use --global java@21-tem
```

可以用下面的命令验证：

```bash
java -version
```

`vfox search java tem` 会列出 Temurin 的各个版本，在交互式终端里还可以直接选一个并安装。

只存在于 `main`、还没进入最新发布版的行为，在下面各页里标有“未发布”。完整列表见 [docs/zh-CN/changes.md](docs/zh-CN/changes.md)，想直接用上 `main`，见 [docs/zh-CN/install-from-source.md](docs/zh-CN/install-from-source.md)。

## 版本与命名

版本写成 `<版本>-<发行版>`，例如 `21.0.8-tem`，后面加 `-fx` 表示带 JavaFX。不写发行版时得到的是 jdk.java.net 上的 OpenJDK，它的 17 只到 17.0.2，21 只到 21.0.2。详见 [docs/zh-CN/versions.md](docs/zh-CN/versions.md)。

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

未发布：0.6.2 只有到 `trava` 为止的那些行，以及 Loongnix 那一行。

简称沿用 SDKMAN 的标识符，有几处不同：JetBrains Runtime 在 SDKMAN 里叫 `jbr`；AdoptOpenJDK 和 GraalVM CE 的虚拟机或 JDK 版本，SDKMAN 当时写在版本号里（`11.0.10.j9-adpt`、`22.3.3.r17-grl`），插件则给每种各起一个简称（`adptj9`、`grl17`）。Eliya、OJDKBuild、OpenLogic、Red Hat 和 Semeru 认证版在 SDKMAN 里没有标识符，简称是插件自己起的。全部差别以及每个发行版是什么，见 [docs/zh-CN/distributions.md](docs/zh-CN/distributions.md)；最后一行见 [docs/zh-CN/loongnix.md](docs/zh-CN/loongnix.md)。

## 平台

并非每个发行版都有 arm64、Alpine 或 Windows ARM 的构建。只有 Temurin、Zulu、Liberica、Microsoft 和 JetBrains Runtime 有 Windows ARM64 的构建，31 个发行版里有 11 个有 Alpine x64 的构建，7 个有 Alpine arm64 的构建。GraalVM 既没有 Windows ARM64，也没有 Alpine。完整的表格见 [docs/zh-CN/platforms.md](docs/zh-CN/platforms.md)。

## JavaFX

Zulu、Liberica、Liberica NIK 和 Corretto（只有 Java 8）提供内置 JavaFX 的构建，在发行版后面加 `-fx` 即可，比如 `java@21-zulu-fx`。详见 [docs/zh-CN/javafx.md](docs/zh-CN/javafx.md)。

## `.sdkmanrc`

vfox 通过这个插件读取 SDKMAN 的 `.sdkmanrc` 里的 `java=` 一行，并选中已经安装的 JDK。详见 [docs/zh-CN/sdkmanrc.md](docs/zh-CN/sdkmanrc.md)。

## GitHub 镜像

大多数发行版从 GitHub 下载。如果你那里下载很慢，执行 `export VFOX_JAVA_GITHUB_MIRROR=https://gh-proxy.org/`，这些下载就会经过镜像。详见 [docs/zh-CN/mirror.md](docs/zh-CN/mirror.md)。

未发布：0.6.2 没有镜像设置。

## 查询 Foojay

想知道你的平台上有哪些 JDK，可以自己去问 Foojay。[docs/zh-CN/foojay.md](docs/zh-CN/foojay.md) 里有 Swagger UI 和查询命令。

## 问题排查

插件的各种提示、代理设置和 JDK 的位置，见 [docs/zh-CN/troubleshooting.md](docs/zh-CN/troubleshooting.md)。

## 从源码安装

详见 [docs/zh-CN/install-from-source.md](docs/zh-CN/install-from-source.md)。

## 开发

插件的工作方式和修改方法见 [docs/zh-CN/development.md](docs/zh-CN/development.md)，容器测试见 [docs/zh-CN/e2e.md](docs/zh-CN/e2e.md)。

## 发布这个插件

维护者在默认分支上执行 **Actions → Plugin → Run workflow**，填入不带 `v` 前缀的稳定版插件版本号即可发布。共享工作流会更新 `metadata.lua`，创建版本提交和标签，并把 ZIP 包和 manifest 发布到本仓库；不需要在本地打标签，也不需要额外的发布令牌。PR 只运行检查，PR 标题不再触发发布。

直接推送版本标签也可以发布，前提是 `PLUGIN.version` 已经与标签一致。发布失败时，重新运行失败的那个作业即可接着发布。

工作流引用的是共享的 `@v1` 发布工具，升级这个工具不会发布本插件。包的约定和首次接入的要求，见[共享工作流的文档](https://github.com/version-fox/plugin-manifest-action)。

## 致谢

- [SDKMAN](https://github.com/sdkman/)，简称和 `.sdkmanrc` 的支持都沿用了它的标识符
- [Foojay](https://github.com/foojayio/discoapi)，JDK 数据的来源
