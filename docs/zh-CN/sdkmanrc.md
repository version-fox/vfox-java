# `.sdkmanrc`

[中文](sdkmanrc.md) | [English](../sdkmanrc.md)

vfox 可以通过这个插件，把 [SDKMAN](https://sdkman.io/) 的项目文件 `.sdkmanrc` 当作兼容版本文件来读取（插件在 `PLUGIN.legacyFilenames` 里声明了它）。已经为 SDKMAN 固定了 JDK 版本的项目，不需要再为 vfox 另写一个文件：

```
# .sdkmanrc
java=21.0.8-tem
```

只读取 `java=` 这一行。其他行，例如 `maven=3.9.9`，与这个插件无关。

## 使用方法

```bash
eval "$(vfox activate bash)"       # 只需配置一次，写进 ~/.bashrc；其他 Shell 见 vfox 的快速入门

vfox install java@21.0.8-tem       # .sdkmanrc 不会帮你安装任何东西
cd my-project                      # 里面有上面那个 .sdkmanrc
java -version                      # Temurin 21.0.8
```

vfox 挂载到 Shell 之后，进入目录时会读取这个文件，并选中其中指定的 JDK，不需要 `vfox use`。zsh、fish、PowerShell 等其他 Shell 的挂载方式见 vfox 的[快速入门](https://vfox.dev/zh-hans/guides/quick-start.html)。

- 只读取当前目录下的文件。进入项目的子目录就找不到它了，SDKMAN 的 `sdk env` 也是这样。
- 同一目录里的 `.vfox.toml` 如果写了 `java`，优先于 `.sdkmanrc`。`vfox use --project` 会写出这个文件。
- 在这个目录里，这个文件还优先于不带 `--project` 的 `vfox use`：下一个提示符就会切回来，而 `vfox current java` 仍然显示会话里选的那个。
- vfox 会在这个目录里创建 `.vfox/sdks/java`，并且不会把 `.vfox/` 加进 `.gitignore`，所以 `git status` 会列出它，需要你自己忽略。
- JDK 必须已经安装。没有任何已安装的版本匹配时，这个文件会被忽略，也不会有任何提示。`vfox list java` 可以看到已有哪些。
- `vfox config legacyVersionFile.enable false` 会关闭所有兼容版本文件。`legacyVersionFile.strategy` 对这个插件没有作用：以文件里写的版本为准。

## 标识符会选中什么

插件把标识符与已安装的 JDK 按下面的顺序匹配：

1. 原样写出的已安装版本名：`java=21.0.8+9-tem`、`java=28-ea+19`。
2. 你写的那个版本，取它已安装的最新构建：`21.0.8-tem` 选中 `21.0.8+9-tem`。
3. 不行的话，取同一大版本里已安装的最新版本。`21-tem` 直接走这一步。

第 3 步不检查已装的版本是否低于你写的版本。只装了 `21.0.8+9-tem` 时，`java=21.0.12-tem` 会选中它，`java=21.0.3-tem` 也一样。写了没装的构建号，会退到这个版本已安装的最新构建（`21.0.8+7-tem` 选中 `21.0.8+9-tem`）。如果这个大版本根本没装，就什么也不选。

它不会跨发行版，不会在带 JavaFX 和不带 JavaFX 的构建之间串用，也不会在 EA 构建和 GA 版本之间串用。

## SDKMAN 的写法

`sdk list java` 里同时存在两代标识符。插件两种都认，也认自己的写法：

| `.sdkmanrc` 里写 | 选中 |
| --- | --- |
| `21.0.8-tem` | Temurin 21.0.8，安装后叫 `21.0.8+9-tem` |
| `21.0.5-jbr` | JetBrains Runtime（`jb`），SDKMAN 叫它 `jbr` |
| `21.0.12.fx-zulu` | 带 JavaFX 的 Zulu，`21.0.12+8-zulu-fx`（较旧的写法） |
| `21.0.12-fx+1.1-librca` | 带 JavaFX 的 Liberica（较新的写法） |
| `21.0.8+1.1-tem` | Temurin 21.0.8，见下文 |
| `27.0.0+36-librca`、`25.0.1.0+8-open` | `27+36-librca`、`25.0.1+8`：补的零会被去掉 |
| `28.ea.19-open`、`28.0.0+ea.19-open` | EA 构建 `28-ea+19` |
| `25.0.4.r25-nik`、`25.0.2.r25-mandrel` | `25.0.4-nik`、`25.0.2-mandrel`：`.r` 和后面的 JDK 版本会被去掉 |
| `11.0.10.hs-adpt`、`11.0.10.j9-adpt` | AdoptOpenJDK 的 HotSpot 版 `11.0.10-adpt` 和 OpenJ9 版 `11.0.10-adptj9` |
| `22.3.3.r17-grl` | 基于 JDK 17 的 GraalVM CE 22.3.3，`22.3.3-grl17` |
| `22.1.0.1.r17-gln` | Gluon GraalVM 22.1.0.1，`22.1.0.1-gln` |

最后三行是 SDKMAN 给它已经不再提供的发行版用过的标识符，虚拟机或 JDK 版本写在版本号里，见 [distributions.md](distributions.md#简称与-sdkman-的不同)。插件不安装 Gluon GraalVM 22 的 JDK 11 构建，也不安装 AdoptOpenJDK 的 upstream 构建，所以 `22.1.0.1.r11-gln` 和 `11.0.9.open-adpt` 什么都不会选中。未发布：0.6.2 对这三行都选不中任何 JDK。

SDKMAN 在一些 Mandrel 和 Liberica NIK 的版本号里也写了 JDK 版本，而插件只按 GraalVM 版本号给它们命名，见 [distributions.md](distributions.md#mandrel-与-liberica-nik-的行为)。一个版本同时为两个 JDK 发布时，插件只装较新 JDK 的构建，所以写了较旧 JDK 的标识符什么都不会选中：`22.1.r11-mandrel`、`23.0.1.r17-nik`。较旧的 JDK，在 21.3 到 22.3.5 是 JDK 11，在 23 到 23.0.1.2 是 JDK 17。`25.r25-mandrel` 只写了大版本号，会选中已安装的最新 Mandrel 25，和 `java=25-mandrel` 一样，而 SDKMAN 按这个标识符装的是 25.0.1.0。未发布：0.6.2 把 `25.0.4.r25` 当成版本号，找不到这个版本，就选中同一大版本里已安装的最新版本。

SDKMAN 新写法里 `+` 后面的数字（`21.0.8+1.1-tem`）是 SDKMAN 自己重新构建的次数，不是厂商的构建号，所以插件不会去找这个构建，而是按版本匹配。Foojay 和安装后的版本名都不补零，所以 `27.0.0` 指的就是 `27`。`sdk list java` 里补一个 `.0` 很常见（`25.0.1.0+8-open`、`21.0.9.0+116386-jbr`），插件同样能读。

## 没有生效怎么办

JDK 没有切换时，依次检查：

- vfox 没有挂载到当前的 Shell。`eval "$(vfox activate bash)"` 要在当前 Shell 里执行过，只在别处执行过不算。
- 当前目录是 `.sdkmanrc` 所在目录的子目录。
- JDK 没有安装，或者只装了另一种构建（带或不带 JavaFX）。`java=21.0.8-zulu` 不会选中带 JavaFX 的构建，`java=21.0.8.fx-zulu` 也不会选中不带的。请安装文件里指明的那种，比如 `vfox install java@21.0.8-zulu-fx`。
- 被 `.vfox.toml` 挡住了，或者 `legacyVersionFile.enable` 是 `false`。

`vfox --debug env -s bash` 会打印文件的解析过程。

## 与 SDKMAN 的区别

`sdk env install` 会安装 `.sdkmanrc` 里指明的 JDK。vfox 只在已安装的版本里选择，安装要用 `vfox install java@<版本>`。从文件里复制的标识符不一定能直接给 `vfox install` 用：`21.0.8-tem` 可以，`21.0.12.fx-zulu` 不行，`21.0.12-zulu-fx` 可以。
