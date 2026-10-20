# 查询 Foojay

[中文](foojay.md) | [English](../foojay.md)

[Foojay](https://foojay.io/) 运营着 Disco API，一个汇总了多家厂商 JDK 构建的公开索引（源码：[foojayio/discoapi](https://github.com/foojayio/discoapi)）。除了 Linux loong64，插件所有的版本列表和下载链接都来自它。`vfox search` 显示的就是 Foojay 的数据，找不到预期的构建时，应该先去 Foojay 查。

你可以自己在浏览器里查。这套 API 的 [Swagger UI](https://api.foojay.io/swagger-ui) 列出了所有接口，规范文件是 [foojay-discoapi-3.0.yml](https://api.foojay.io/swagger/foojay-discoapi-3.0.yml)。打开 `GET /disco/v3.0/packages/jdks`，点“Try it out”，填好参数再点“Execute”，页面会给出实际执行的 `curl` 命令和返回的 JSON。

## 插件发出的请求

在 Linux x64 上执行 `vfox install java@21.0.8-tem`，发出的请求是：

```
https://api.foojay.io/disco/v3.0/packages/jdks
  ?version=21.0.8
  &distribution=temurin
  &architecture=amd64
  &archive_type=tar.gz
  &operating_system=linux
  &lib_c_type=glibc
  &directly_downloadable=true
```

| 参数 | 取值 |
| --- | --- |
| `distribution` | 发行版的长名，见 [distributions.md](distributions.md) |
| `version` | `vfox search` 时和只写大版本号（如 `21`）时为空，否则是你输入内容里的版本部分。`+` 会做百分号编码，因为 Foojay 会把没编码的 `+` 当成空格，进而丢掉构建号。`28.ea.19` 会变成 `28-ea+19`。查 Mandrel、Liberica NIK，以及 Oracle GraalVM 和 GraalVM 社区版的 GA 版本时始终为空 |
| `architecture` | arm64 用 `aarch64`，Windows x64 用 `x64`，其他系统的 x64 用 `amd64`，其他 CPU 用 vfox 报告的名字 |
| `operating_system` | `linux`、`macos` 或 `windows` |
| `archive_type` | `tar.gz`；Windows 上是 `zip` 加 `tar.gz`。其他系统上，Red Hat 还要 `tar.xz`，OJDKBuild、OpenLogic 和 Gluon GraalVM 还要 `zip` |
| `lib_c_type` | Linux 上是 `glibc` 或 `musl`，其他系统为空 |
| `directly_downloadable` | 始终是 `true` |

只写大版本号（如 `21`）时，返回结果里有全部版本，由插件自己挑出最新的 21.x，`java@21-tem` 装的就是它：`version=21` 只会匹配 21 的 GA 构建（`21+35`）。更具体的版本则按原样匹配。

只写大版本号时和搜索发同一个请求，这样安装时看到的构建和 `vfox search` 列出的才一致。Foojay 的结果按请求分别缓存，不同的请求拿到的结果可能新旧不一：2026-10-20 Oracle GraalVM 25.0.5 上了 Foojay 半小时后，GitHub 的 runner 用 `distribution_version=25` 查已经有它，搜索的结果里却还没有，`vfox install java@25-graal` 装上了 `vfox search java graal` 没有列出的构建（[#113](https://github.com/version-fox/vfox-java/issues/113)）。

返回的是一个包列表。插件用 `java_version` 给版本命名（Mandrel 和 Liberica NIK 用 `distribution_version`，Oracle GraalVM 和 GraalVM 社区版用 GraalVM 自己的版本号）；`javafx_bundled` 为真时加上 `-fx`；`term_of_support` 是 `lts` 时标注 LTS；在 Windows 上，同一版本既有 `zip` 又有 `tar.gz` 时优先用 `zip`。Foojay 混在 OJDKBuild 的 Windows JDK 里的 JRE、installer bundle 包和 RHEL 6 构建，以及 Gluon GraalVM 22.x 的 JDK 11 构建，插件都会略过，见 [distributions.md](distributions.md)。安装时，插件再取这个包的 `links.pkg_info_uri`，并从其中的 `direct_download_uri` 下载，那是厂商自己的服务器（Temurin 是 GitHub Releases）。这条记录里还有 `checksum`，但插件没有把它交给 vfox，所以 vfox 会打印 `WARNING: Checksum is not provided, skip verify...`，下载内容不做校验。从 GitHub 下载时可以经过镜像，见 [mirror.md](mirror.md)。

`vfox search` 与原始列表有几处不同：Foojay 里同一个名字有两条记录时，它只列一次；不给 GraalVM 的特性版本加 LTS 备注（见 [distributions.md](distributions.md#oracle-graalvm-与-graalvm-社区版的行为)）；只列 GA 版本。

### Mandrel 与 Liberica NIK

截至 2026-10-20，这两个发行版沿用的 GraalVM 版本号，Foojay 放在 `distribution_version` 里，Java 的版本号放在 `java_version` 里，其中 Mandrel 的 `java_version` 只有大版本号：

```bash
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?distribution=mandrel&distribution_version=23.1.12&architecture=amd64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz&directly_downloadable=true' \
  | jq -r '.result[] | [.java_version, .distribution_version, .filename] | @tsv'
```

```
21	23.1.12.1	mandrel-java21-linux-amd64-23.1.12.1-Final.tar.gz
21	23.1.12	mandrel-java21-linux-amd64-23.1.12.0-Final.tar.gz
```

所以插件像 `vfox search` 那样查出这两个发行版的全部包，再按 `distribution_version` 自己挑：写得具体时挑指定的那个版本，只写大版本号时挑这个大版本里最新的。Foojay 自己的匹配两样都做不到：如上所示，查 `distribution_version=23.1.12` 也会返回 23.1.12.1；查 `distribution_version=23` 并加上 `latest=available` 时，返回的是 23.1.8 和 23.0.1.2 的两个构建，而 23.1.12.1 已经发布。同一个版本有几个 Java 版本的构建时，插件取 Java 最新的那个；Liberica NIK 为同一个 Java 构建了两次时，取后一次的，两次构建只能从文件名里区分（`...-25.0.3+2-linux-amd64.tar.gz`）。搜索时按 `distribution_version` 从新到旧排列。

## 我的平台上有哪些发行版

`latest=per_distro` 为每个有包的发行版返回最新的一个包。不要和 `version` 一起用，`version` 会被忽略。

```bash
# Windows ARM64
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?architecture=aarch64&operating_system=windows&archive_type=zip&archive_type=tar.gz&directly_downloadable=true&latest=per_distro' \
  | jq -r '.result[].distribution' | sort -u
```

```
jetbrains
liberica
microsoft
temurin
zulu
```

换成别的平台，改动指明平台的那三个参数即可。Linux 还要加上 `lib_c_type=glibc` 或 `musl`：

| 平台 | 参数 |
| --- | --- |
| Linux arm64 | `architecture=aarch64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz` |
| Alpine x64 | `architecture=amd64&operating_system=linux&lib_c_type=musl&archive_type=tar.gz` |
| macOS Apple Silicon | `architecture=aarch64&operating_system=macos&archive_type=tar.gz` |
| macOS Intel | `architecture=amd64&operating_system=macos&archive_type=tar.gz` |
| Windows x64 | `architecture=x64&operating_system=windows&archive_type=zip&archive_type=tar.gz` |

返回结果里的名字就是 [distributions.md](distributions.md) 里的长名，只有 `oracle_open_jdk` 例外，插件里叫它 `openjdk`（`open`）。只写 `archive_type=tar.gz` 时，结果里会缺 Linux 上的 Red Hat 和 OJDKBuild、macOS 上的 OpenLogic，因为它们在那里提供的是 tar.xz 或 zip 包。插件会为它们额外请求这些格式，见上面的表。

## 我的平台上哪些发行版有某个版本

```bash
# Intel Mac 上的 Java 27
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?version=27&latest=available&architecture=amd64&operating_system=macos&archive_type=tar.gz&directly_downloadable=true' \
  | jq -r '.result[].distribution' | sort -u
```

2026-10-18 运行这条命令，打印的是 `corretto liberica oracle semeru zulu`。Temurin 和 OpenJDK 不在其中：它们在 Intel Mac 上停在了 26。只写大版本号时像插件一样加上 `latest=available`，写更具体的版本时就不要加。

## 某个发行版的所有版本

这就是 `vfox search java tem` 在你这台机器上显示的内容：

```bash
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?distribution=temurin&architecture=aarch64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz&directly_downloadable=true' \
  | jq -r '.result[].java_version'
```

```
27+35
26.0.2.1+1
26.0.2+10
...
```

加上 `version=21.0.8` 只看某个版本，加上 `javafx_bundled=true` 只看带 JavaFX 的构建。一条记录长这样：

```bash
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?distribution=temurin&version=21.0.8&architecture=amd64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz&directly_downloadable=true' \
  | jq -c '.result[] | {java_version, distribution_version, term_of_support, javafx_bundled, archive_type, filename}'
```

```
{"java_version":"21.0.8+9","distribution_version":"21.0.8","term_of_support":"lts","javafx_bundled":false,"archive_type":"tar.gz","filename":"OpenJDK21U-jdk_x64_linux_hotspot_21.0.8_9.tar.gz"}
```

`java_version` 是 Java 的版本号，插件用的就是它。`distribution_version` 是厂商自己的版本号（Java `27+35` 对应 Zulu 的 `27.28.101`），插件对 Mandrel 和 Liberica NIK 用它（见[上文](#mandrel-与-liberica-nik)），对 Oracle GraalVM 和 GraalVM 社区版也用它。

从 2026 年 10 月起，Oracle GraalVM 和 GraalVM 社区版的 `distribution_version` 是 GraalVM 自己的版本号，`java_version` 则是 JDK 的版本号，而每月的特性版本和 25.0 系列的某个构建会共用同一个 JDK 版本号：

```bash
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?distribution=graalvm&version=25.0.4.1&architecture=amd64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz&directly_downloadable=true' \
  | jq -r '.result[] | [.java_version, .distribution_version, .filename] | join(" ")'
```

```
25.0.4.1 25.4.4.1.1 graalvm-jdk-25i4-25.0.4.1.1_linux-x64_bin.tar.gz
25.0.4.1 25.3.4.1 graalvm-jdk-25i3-25.0.4.1_linux-x64_bin.tar.gz
25.0.4.1 25.0.4.1.1 graalvm-jdk-25.0.4.1.1_linux-x64_bin.tar.gz
25.0.4.1 25.0.4.1 graalvm-jdk-25.0.4.1_linux-x64_bin.tar.gz
```

用 `version` 分不开这几个包，而 `distribution_version` 按开头的完整几段来匹配（`25.0.4.1` 也会列出 `25.0.4.1.1`）。所以插件像 `vfox search` 那样查出全部的包，具体是哪个版本由它自己挑，并按 GraalVM 的版本号命名，也就是每个包的 `java_version` 和 `distribution_version` 中较新的那个：GraalVM 社区版的特性版本还有一份按老办法列的记录，GraalVM 的版本号放在 `java_version` 里。`vfox search` 按这个版本号从新到旧列出，Foojay 在两个版本号下各列一次的同一个文件，只列一次。

## 版本与支持期限

```bash
curl -s 'https://api.foojay.io/disco/v3.0/major_versions?ea=false&ga=true&maintained=true' \
  | jq -r '.result[] | [.major_version, .term_of_support] | @tsv'
```

列出仍在维护的各个大版本，以及每个是 LTS 还是 STS。EA 构建要用 `release_status=ea`，或者像 `version=28-ea` 这样明确写出版本。

## 补充说明

- 有些 HTTP 客户端用默认 User-Agent 访问 Foojay 会得到 `403`，比如 Python 的 `urllib`。`curl` 不会，vfox 也不会。
- 示例里用了 `jq`，你可能需要自己安装。任何 JSON 工具都可以。
- vfox 会缓存 `vfox search` 的结果 12 小时，所以 Foojay 上的变化最多要隔这么久才会出现。
- 数据本身的问题，比如缺少某个构建或标记有误，请向 [Foojay](https://github.com/foojayio/discoapi) 反馈。插件读取数据的方式有问题，请在本仓库提 issue。
