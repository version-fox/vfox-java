# 问题排查

[中文](troubleshooting.md) | [English](../troubleshooting.md)

## 插件给出的提示

### `No JDK found for 21-bsg on darwin/arm64. Please check available versions with 'vfox search java'`

Foojay 在这个平台上没有对应的包：版本、发行版、带不带 JavaFX，三者要同时对上。提示里的平台是插件实际请求的平台，比如 `linux/amd64`、`darwin/arm64`、`windows/arm64`。检查这三点：

- 这个发行版在这个平台上有没有包，见 [platforms.md](platforms.md)。
- 这个版本是否存在：`vfox search java <发行版>` 列出的是这个平台能装的版本。
- 是不是漏写了发行版。`java@17.0.17` 指的是 jdk.java.net 上的 OpenJDK，它停在 17.0.2。`java@17.0.17-tem` 可以装，见 [versions.md](versions.md#不写发行版)。

提示里出现 `with JavaFX` 或 `without JavaFX`，说明这个版本是有的，只是没有对应的构建（带或不带 JavaFX），见 [javafx.md](javafx.md)。

### `No version in tem; add one, such as 21-tem. Please check available versions with 'vfox search java tem'`

`java@` 后面只有发行版，没有版本。`java@-tem`、`java@temurin-` 和 `java@zulu-fx` 都属于这种情况。

### `Could not extract a valid distribution: 21-foo`

`-` 前后两部分都不是发行版名。名字都是小写，取自 [distributions.md](distributions.md) 里的表。未发布：0.6.2 之后新增的 13 个发行版，在 0.6.2 上都会报这个错，比如 `java@21-opnlgc` 和 `java@21-openlogic`。

### `Unsupported distribution: foo`

`vfox search java foo` 报的是这一条。

### `Failed to fetch jdk info from foojay: ...`

向 Foojay 的请求失败了。`status_code =>` 后面是 HTTP 状态码；没有这一段时，后面是网络错误。见下面的[网络](#网络)。第二次请求（取下载链接）失败时，报的是 `Failed to fetch jdk info: ...`。

### `source file not found`

下载时服务器返回 404。厂商会下线旧的构建，而 Foojay 仍保留它们的记录。最常见的是 EA 构建（见 [versions.md](versions.md#早期访问ea构建)）。换一个较新的构建。Red Hat 除了 Linux x64 以外的构建都会报这个错，见 [distributions.md](distributions.md#red-hat-build-of-openjdkrdht)。

### `java@21-tem is not installed`

`vfox use` 和 `vfox uninstall` 只认已安装的版本。`vfox list java` 能看到它们，名字里带构建号：`21.0.8+9-tem`。`vfox uninstall` 需要写完整的名字。

### macOS 上关于 Java home 的提示

每次在 macOS 上安装都会打印 `Checking Java home layout...`。如果后面跟着 `Failed to normalize Java home`，说明压缩包的目录结构不是插件预期的：`Multiple Java homes found in <dir>`、`No Java home containing bin/java found in <dir>`，或者 `Cannot normalize Java home: destination already exists: <path>`。请带上发行版和版本号来报告。

### Loongnix

`Loongnix JDKs require linux/loong64`、`Foojay does not support loong64; use vfox search java loongnix`、`Choose a Loongnix ABI explicitly`、`No Loongnix JDK found for ...` 和 `No Loongnix JDK packages found` 的含义见 [loongnix.md](loongnix.md)。

## 网络

插件向 Foojay 取版本列表，压缩包则由 vfox 从厂商的服务器下载，常常是 GitHub Releases。插件没有镜像设置。

vfox 自己的代理设置对 Foojay 请求和下载都有效：

```bash
vfox config proxy.enable true
vfox config proxy.url http://127.0.0.1:7890
```

`proxy.enable` 为 `false` 时，通常的 `HTTP_PROXY`、`HTTPS_PROXY` 和 `NO_PROXY` 环境变量依然有效。只支持 `http` 和 `https` 代理。

## 看起来不对，其实没问题

- **`vfox search` 里没有你预期的版本。** vfox 会缓存搜索结果 12 小时。`vfox config cache.availableHookDuration 0` 可以关闭缓存。也可能是 Foojay 那边还没有这个版本。
- **每次安装都有 `WARNING: Checksum is not provided, skip verify...`。** 插件没有把校验和交给 vfox，所以下载内容没有校验，见 [foojay.md](foojay.md#插件发出的请求)。
- **安装后的版本名里多了一个你没写的构建号。** `java@21.0.8-tem` 装出来是 `21.0.8+9-tem`。构建号是版本名的一部分，见 [versions.md](versions.md#安装后的版本名)。
- **`vfox install java@21-tem` 和 `vfox install java tem` 做的是不同的事。** 后者是两个 SDK，`java` 和 `tem`。
- **你设置的 `GRAALVM_HOME` 不会被改动。** 插件只设置 `JAVA_HOME` 和 `PATH`。
- **`vfox use java@21` 选中了 `21.3.1-grl11`，而它运行的是 Java 11。** GraalVM CE 8 到 19 和 23 以前的 Gluon GraalVM 用的是 GraalVM 的版本号，对只写大版本号的写法，vfox 只按版本号匹配，不分发行版，见 [distributions.md](distributions.md#按-graalvm-编号的版本)。请写成 `java@21-tem`。

## JDK 在哪里

`JAVA_HOME` 是一个链接，由 `vfox use` 指向你选的 JDK：`--global` 时是 `~/.vfox/sdks/java`，`--project` 时是项目里的 `.vfox/sdks/java`，会话作用域下是 `~/.vfox/tmp` 下的一个目录。想让 IDE 或构建工具跟随全局选择，可以直接指向 `~/.vfox/sdks/java`。要固定指向某个 JDK，`vfox info java@21.0.8+9-tem` 会打印一个目录，JDK 就在其中的 `java-21.0.8+9-tem` 目录里。`~/.vfox` 是 `$VFOX_HOME` 的默认值。设置了 `VFOX_HOME` 之后，JDK（`cache/`）和插件放在那里，`sdks/java` 链接和会话目录仍留在 `~/.vfox`。`storage.sdkPath` 同样可以改变 JDK 的存放位置，见 vfox 的[配置文档](https://vfox.dev/zh-hans/guides/configuration.html)。

## 报告问题

请到 [version-fox/vfox-java](https://github.com/version-fox/vfox-java/issues) 提 issue，附上 `vfox --version` 和 `vfox info java` 的输出、操作系统和 CPU、你执行的命令以及它打印的全部内容。`vfox --debug <命令>` 会打印更多信息。Foojay 数据本身的错误请向 [Foojay](https://github.com/foojayio/discoapi) 反馈。
