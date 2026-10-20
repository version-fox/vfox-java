# 版本与命名

[中文](versions.md) | [English](../versions.md)

`vfox install` 和 `vfox use` 在 `java@` 后面写版本和发行版，用 `-` 连接：

```bash
vfox install java@21-tem            # Temurin 21 的最新版
vfox install java@21.0.8-tem        # Temurin 21.0.8
vfox install java@21.0.8+9-tem      # 精确到某个构建
vfox install java@21-zulu-fx        # 带 JavaFX 的 Zulu 21
vfox install java@temurin-21        # 等同于 21-tem，发行版写在前面
vfox install java@21                # 不写发行版：jdk.java.net 上的 OpenJDK
```

发行版可以写简称（`tem`）或长名（`temurin`），两份名单都在 [distributions.md](distributions.md)。`-fx` 放在最后，表示要带 JavaFX 的构建，见 [javafx.md](javafx.md)。

## 不写发行版

`java@21` 指 [jdk.java.net](https://jdk.java.net/) 上发布的 OpenJDK，安装后的版本名不带后缀（`21.0.2+13`）。这个站点只提供最新的几个版本，旧版本只留最后一个构建：17 停在 `17.0.2`，21 停在 `21.0.2`。所以 `vfox install java@17.0.17` 会失败，`java@17.0.17-tem` 才能装上。要用仍在维护的版本，请指定发行版。

## 安装

`vfox install` 先问插件该装哪个包，再由 vfox 下载并解压。

- 只写大版本号（`21`、`21-tem`）时，安装这个发行版列出的、这个大版本下最新的版本，例如截至 2026-10-18 是 `21.0.12.1+1-tem`。
- 写得更具体时，必须是这个发行版列出的版本。`21.0.8-tem` 装的是 21.0.8 的最新构建 `21.0.8+9-tem`。根本不存在的版本会失败，报 `No JDK found for 21.0.99-tem on linux/amd64`。
- 写了构建号就装那个构建：`21.0.5+63130-jb`。
- SDKMAN 写法里补了零的版本也能识别：`27.0.0-librca` 装的是 `27+36-librca`。
- Oracle GraalVM 只写大版本号时，装 25.0 系列的最新构建，不装每月发布的特性版本（feature release）。特性版本要写全版本号（`25.4.4.1.1-graal`）。未发布：0.6.2 只写大版本号时可能装上特性版本。见 [GraalVM](distributions.md#graalvm-系列)。
- 写了 `-fx` 就只考虑带 JavaFX 的构建，没写就只考虑不带的，两者不会混用。
- Mandrel 和 Liberica NIK 按它们沿用的 GraalVM 版本号来，只写大版本号时也一样：`java@23-mandrel` 装的是 `23.1.12.1-mandrel`，运行的是 Java 21。见 [Mandrel 与 Liberica NIK](distributions.md#mandrel-与-liberica-nik-的行为)。
- 在 Windows 上，同一版本既有 zip 又有 tar.gz 时，装 zip。
- 只写发行版不写版本（`java@tem`、`java@-tem`、`java@zulu-fx`）会被拒绝，并提示补上版本。

如果这个版本名已经装过，会提示 `java@21.0.12.1+1-tem is already installed`，不会重新下载。

## 安装后的版本名

安装后的版本名取自 Foojay 返回的 `java_version`，Mandrel 和 Liberica NIK 取的是 `distribution_version`，Oracle GraalVM 和 GraalVM 社区版取的是 GraalVM 自己的版本号。`vfox search` 里显示的也是这些名字：

```
<java_version>[-<简称>][-fx]
```

| 安装后的版本名 | 含义 |
| --- | --- |
| `21.0.12.1+1-tem` | Temurin |
| `25.0.4+9-librca-fx` | 带 JavaFX 的 Liberica |
| `25.0.2+10` | OpenJDK，没有后缀 |
| `17.0.12-graal` | GraalVM，没有构建号 |
| `25.4.4.1.1-graal` | Oracle GraalVM 和 GraalVM 社区版用的是 GraalVM 自己的版本号，不是 `java_version`，这里是一个每月发布的特性版本，见 [GraalVM](distributions.md#oracle-graalvm-与-graalvm-社区版的行为) |
| `8.0.482+8-zulu` | Java 8 写成 `8.0.<更新号>+<构建号>` |
| `23.1.12.1-mandrel` | Mandrel，按 GraalVM 编号，运行的是 Java 21 |
| `28-ea+19` | EA 构建，见下文 |

`vfox list java` 显示的、`vfox uninstall` 需要的都是这种名字：

```bash
vfox uninstall java@21.0.8+9-tem
```

`vfox uninstall java@21.0.8-tem` 会提示 `is not installed`。卸载当前正在使用的版本时，vfox 会切到 `vfox list java` 里剩下的第一项，那可能是另一个大版本。

## 使用

`vfox use` 会把你输入的内容映射到已安装的版本名，不会下载任何东西，所以构建号和小版本都可以省略：

| 输入 | 选中 |
| --- | --- |
| `21.0.8-tem` | 这个版本已安装的最新构建 `21.0.8+9-tem` |
| `21-tem` | 已安装的最新 Temurin 21 |
| `temurin-21.0.8` | `21.0.8+9-tem` |
| `25.0.2-open`、`openjdk-25.0.2` | `25.0.2+10`，OpenJDK 没有后缀 |
| `21` | 由 vfox 自己匹配：已安装的最高 21.x，不限发行版 |

写明了构建或版本时，不会跳到别的构建或版本（`21.0.12-tem` 不会选中 `21.0.12.1+1-tem`）。也不会跨发行版，不会在带 JavaFX 和不带 JavaFX 的构建之间串用，不会在 EA 和 GA 之间串用。什么都匹配不上时，报 `java@99-tem is not installed`。

vfox 自己匹配 `21` 时只看版本号，所以 GraalVM CE 8 到 19、Gluon GraalVM、Mandrel 和 Liberica NIK 也会被它选中，它们的版本号是 GraalVM 的：`21.3.1-grl11` 运行的是 Java 11，`vfox use java@21` 却会选中它，而不是 `21.0.12.1+1-tem`。见 [distributions.md](distributions.md#按-graalvm-编号的版本)。

作用域用 `vfox use` 的参数选择：`--global`、`--project` 或 `--session`，默认是会话作用域。如果 Shell 没有挂载 vfox，Windows 会警告并切到全局作用域，Linux 和 macOS 则报 `vfox requires hook support` 后退出。`--project` 会写出 `.vfox.toml`，里面记录的是安装后的版本名（`java = "17.0.10+7-tem"`）。`.sdkmanrc` 也会被读取，见 [sdkmanrc.md](sdkmanrc.md)。

## 早期访问（EA）构建

写成 `<大版本>.ea[.<构建号>]`：

```bash
vfox install java@28.ea-open       # 最新的 EA 构建，截至 2026-10-18 是 28-ea+19
vfox install java@28.ea.15-open    # 28-ea+15
```

安装后的版本名沿用 Foojay 的写法 `28-ea+19`，`vfox use java@28-ea+19` 按原样识别。`vfox search` 只列 GA 版本。Foojay 列有 EA 构建的发行版包括 OpenJDK、Temurin、Zulu、SapMachine、GraalVM 和 GraalVM 社区版等。厂商会把旧的 EA 构建从服务器上撤掉，而 Foojay 仍保留记录，所以较旧的构建可能下载失败。

## 搜索

```bash
vfox search java            # 默认的 OpenJDK
vfox search java tem        # 指定一个发行版，简称或长名都行
vfox search java all        # 所有发行版，在 Linux x64 上约 2500 行
```

每一行都是可以接在 `java@` 后面的名字，新的在前，带 LTS、JavaFX（见 [javafx.md](javafx.md)）备注，已安装的会有标记：

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

列表是按你运行命令的这台机器来的，只含它能装的版本，见 [platforms.md](platforms.md)。在交互式终端里，`vfox search java tem` 可以直接选一个版本安装；在其他环境下只打印列表。vfox 会缓存搜索结果 12 小时（`vfox config cache.availableHookDuration`），所以刚发布的版本可能暂时看不到。

`vfox install java tem` 选的不是 Temurin：用空格分隔的参数表示多个 SDK。请写 `java@21-tem`。

LTS 备注来自 Foojay，唯独 GraalVM 每月发布的特性版本（`25.4.4.1.1-graal`）不带这个备注，尽管 Foojay 把其中一些标成了 LTS。
