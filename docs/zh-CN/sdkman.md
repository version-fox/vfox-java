# SDKMAN 与 vfox

[中文](sdkman.md) | [English](../sdkman.md)

[SDKMAN](https://sdkman.io/) 用 `sdk install java` 和 `sdk use java` 安装并切换 JDK。有了这个插件，vfox 也能做同样的事。插件沿用 SDKMAN 的简称，也能读取它的 `.sdkmanrc`，所以你在 SDKMAN 上积累的经验大多可以直接用。本页说明什么时候该用这个插件，把两边的命令并列出来，并列出它们的差别。

## 什么时候用

- **你在 Windows PowerShell 里工作。** SDKMAN 是一组 bash 脚本。它的[安装页面](https://sdkman.io/install)写明它需要 bash 环境，在 Windows 上不能原生安装：只能在 WSL 里，或者在带 MinGW 的 Git Bash 里运行。所以 PowerShell（包括 Windows 自带的 Windows PowerShell 5.1）和 cmd 都用不了它。vfox 是原生的 Windows 程序，能挂载到 PowerShell，所以 `vfox install java@21-tem` 和 `vfox use` 在那里直接可用，不需要 WSL 或 Git Bash。在这里，这个插件取代了 SDKMAN。
- **你用的不是 Bash 或 Zsh。** SDKMAN 只支持这两种。vfox 可以挂载到 Bash、Zsh、Fish、PowerShell、Nushell 和 Clink，见它的[快速入门](https://vfox.dev/zh-hans/guides/quick-start.html)。
- **团队或脚本要跨系统。** Linux、macOS 和 Windows 上的命令一样。项目里的 `.sdkmanrc` 会通过插件读取，所以用 SDKMAN 的开发者和用 vfox 的开发者可以共用它，见 [sdkmanrc.md](sdkmanrc.md)。
- **你管理的不只是 JDK。** vfox 有 Maven、Gradle、Groovy、Kotlin、Scala、Node.js、Go 等许多工具的插件，用的是同一套命令（`vfox available`）。

如果你在 Linux 或 macOS 上用 Bash 或 Zsh，而 SDKMAN 已经满足需要，就没有换的理由。

## 命令对照

示例用 Temurin 21.0.8。两个工具都要先挂载到 Shell：SDKMAN 是 source `sdkman-init.sh`，vfox 是 `vfox activate`，见 vfox 的[快速入门](https://vfox.dev/zh-hans/guides/quick-start.html)。vfox 的命令在它能挂载的所有 Shell 里都一样。

| | SDKMAN | vfox |
| --- | --- | --- |
| 安装 | `sdk install java 21.0.8-tem` | `vfox install java@21.0.8-tem` |
| 列出可安装的版本 | `sdk list java` | `vfox search java tem`；`vfox search java all` 列出所有发行版 |
| 列出已安装的版本 | `sdk list java` 会标出已安装的 | `vfox list java` |
| 只在当前 Shell 里使用 | `sdk use java 21.0.8-tem` | `vfox use java@21.0.8-tem` |
| 在之后新开的所有 Shell 里使用 | `sdk default java 21.0.8-tem` | `vfox use --global java@21.0.8-tem` |
| 为项目固定版本 | `sdk env init` 写出带有当前 JDK 的 `.sdkmanrc` | `vfox use --project java@21.0.8-tem` 写出 `.vfox.toml` |
| 切换到项目的 JDK | `sdk env`，或设置 `sdkman_auto_env=true` 后每次 `cd` 自动切换 | 挂载之后，进入目录时自动切换 |
| 安装项目要的 JDK | `sdk env install` | `.vfox.toml` 用 `vfox install --all`，`.sdkmanrc` 没有对应的命令 |
| 查看正在使用的 JDK | `sdk current java` | `vfox current java` |
| 查看 JDK 在哪里 | `sdk home java 21.0.8-tem` | `vfox info java@21.0.8+9-tem` |
| 卸载 | `sdk uninstall java 21.0.8-tem` | `vfox uninstall java@21.0.8+9-tem` |
| 查看哪些 JDK 过时了 | `sdk upgrade java` | 没有，自己对比 `vfox list java` 和 `vfox search java tem` |
| 升级工具本身 | `sdk selfupdate` | `vfox upgrade`；插件用 `vfox update java` |
| 查看工具的版本 | `sdk version` | `vfox --version` |

`vfox use` 的作用域与 SDKMAN 的命令对应：默认的 `--session` 对应 `sdk use`，`--global` 对应 `sdk default`，`--project` 对应 `.sdkmanrc`。没有挂载 vfox 时，`vfox use` 在 Linux 和 macOS 上会报错退出，在 Windows 上则退到全局作用域，见 [versions.md](versions.md#使用)。

## 差别

- **标识符。** SDKMAN 的 `21.0.8-tem` 原样写在 `java@` 后面，简称也沿用 SDKMAN 的，只有少数例外，比如 JetBrains Runtime 在 SDKMAN 里叫 `jbr`，这里是 `jb`，见 [distributions.md](distributions.md#简称与-sdkman-的不同)。SDKMAN 现在的标识符会给版本补一个零（`25.0.5.0+8-tem`），这样的写法也能识别。JavaFX 是放在最后的 `-fx`，即 `21.0.12-zulu-fx`。SDKMAN 的 `21.0.12.fx-zulu` 不是 `vfox install` 接受的写法，不过 `.sdkmanrc` 里可以写，见 [sdkmanrc.md](sdkmanrc.md#sdkman-的写法)。
- **只写大版本号。** `vfox install java@21-tem` 装的是最新的 Temurin 21，2026-11-03 是 `21.0.13+9-tem`。SDKMAN 的 `21-tem` 只是一个版本，即 GA 构建 `21+35`。
- **没有默认 JDK。** `sdk install java` 装的是 SDKMAN 的默认版本，一个 Temurin 的 LTS 版本（2026-11-03 是 `25.0.5.0+8-tem`）。`vfox install java` 没有默认值：在终端里它会让你选一个版本，在脚本里则直接失败。只写版本不写发行版（`java@21`）指的是 jdk.java.net 上的 OpenJDK，它的 21 只到 21.0.2。请写 `java@21-tem`，见 [versions.md](versions.md#不写发行版)。
- **安装不等于选中。** `sdk install` 之后，SDKMAN 会问要不要把这个 JDK 设为默认。`vfox install` 只负责安装，选中要用 `vfox use`。
- **两份列表。** `sdk list java` 列出所有厂商的 JDK。`vfox search java` 只列 OpenJDK，所以要写上发行版（`vfox search java tem`）或 `all`。已安装的看 `vfox list java`。版本数据来自 [Foojay](foojay.md)。
- **安装后的版本名带构建号。** `vfox list java` 显示 `21.0.8+9-tem`，`vfox uninstall` 和 `vfox info` 都要写全，而 `vfox use java@21.0.8-tem` 不写构建号也能找到它，见 [versions.md](versions.md#安装后的版本名)。
- **`.sdkmanrc` 只负责选中。** `sdk env install` 会安装它里面写的 JDK。插件只在已安装的 JDK 里选，见 [sdkmanrc.md](sdkmanrc.md#与-sdkman-的区别)。
- **JDK 在哪里。** SDKMAN 把 JDK 放在 `~/.sdkman/candidates/java/<标识符>`。vfox 放在 `~/.vfox/cache/java/v-<版本名>/java-<版本名>`，`JAVA_HOME` 是指向你所选 JDK 的链接。`vfox info` 打印的是包含 `java-<版本名>` 的那个目录。IntelliJ IDEA 能自己找到 SDKMAN 的 JDK，但对 vfox 只会列出正在使用的那个，见 [troubleshooting.md](troubleshooting.md#jdk-在哪里)。
