# GitHub 镜像

[中文](mirror.md) | [English](../mirror.md)

Foojay 把大多数发行版的 JDK 链接到 GitHub Releases，所以 `vfox install java@21-tem` 是从 `github.com` 下载的。如果你那里访问 github.com 很慢，或者连不上，就设置 `VFOX_JAVA_GITHUB_MIRROR`，插件会让这些下载经过 GitHub 镜像。

值是一个 URL 前缀。插件把它放在 GitHub 地址前面，值不以 `/` 结尾时会补上一个。以 Linux x64 上的 Temurin 21.0.8 为例：

| `VFOX_JAVA_GITHUB_MIRROR` | vfox 下载的地址 |
| --- | --- |
| 没有设置 | `https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.8%2B9/OpenJDK21U-jdk_x64_linux_hotspot_21.0.8_9.tar.gz` |
| `https://gh-proxy.org/` | `https://gh-proxy.org/https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.8%2B9/OpenJDK21U-jdk_x64_linux_hotspot_21.0.8_9.tar.gz` |

[gh-proxy](https://gh-proxy.org/) 接受这种形式的地址，凡是把 GitHub 地址接在自己地址后面的服务都可以。插件不运营其中任何一个，也不为它们担保。值必须以 `http://` 或 `https://` 开头。别的写法 vfox 会当成磁盘上的文件，所以从 GitHub 下载时，插件会直接报错：`VFOX_JAVA_GITHUB_MIRROR must start with http:// or https://`。

## 设置

在 bash 或 zsh 里，对当前 shell 生效：

```bash
export VFOX_JAVA_GITHUB_MIRROR=https://gh-proxy.org/
```

把同一行加进 `~/.bashrc` 或 `~/.zshrc`，就一直生效。在 PowerShell 里：

```powershell
$env:VFOX_JAVA_GITHUB_MIRROR = "https://gh-proxy.org/"
```

要让之后打开的每个终端都生效，执行：

```powershell
[Environment]::SetEnvironmentVariable('VFOX_JAVA_GITHUB_MIRROR', 'https://gh-proxy.org/', 'User')
```

然后照常安装，`vfox install java@21-tem`。想回到 github.com，取消设置这个变量即可。

## 哪些下载会经过镜像

只有以 `https://github.com/` 开头的地址。其他主机上的 JDK 照旧从那里下载，向 Foojay 发的请求也不变。

Foojay 给各发行版的链接（2026-10-21）：

| 简称 | 下载来源 |
| --- | --- |
| `tem`、`librca`、`sem`、`semcrt`、`sapmchn`、`kona`、`albba`、`mandrel`、`trava`、`adpt`、`adptj9`、`eliya`、`ojdkbld`、`gln`、`grl8`、`grl11`、`grl16`、`grl17`、`grl19` | GitHub |
| `graalce` | GitHub，但 `java@25-graalce` 安装的每月特性版本除外，它来自 Oracle 的 GraalVM Download Service。`java@25.4.4.1-graalce` 是同一个文件在 GitHub 上的副本 |
| `nik` | 较新的版本在 GitHub，较旧的在 BellSoft 的服务器上 |
| `open` | jdk.java.net，只有 JDK 8 和大部分 11.x 的构建来自 GitHub |
| `zulu`、`amzn`、`ms`、`oracle`、`graal`、`jb`、`bsg`、`opnlgc`、`rdht` | 厂商的服务器或 CDN，不在 GitHub |

Loongnix（`lnxabi1`、`lnxabi2`）从 ftp.loongnix.cn 下载，不会经过镜像。

想看某个版本是从哪里下载的，向 Foojay 要它的包记录，看其中的 `direct_download_uri`。以 `https://github.com/` 开头的才会经过镜像。其他平台的查询见 [foojay.md](foojay.md)。

```bash
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?distribution=temurin&version=21.0.8&architecture=amd64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz&directly_downloadable=true' \
  | jq -r '.result[0].links.pkg_info_uri' | xargs curl -s | jq -r '.result[0].direct_download_uri'
```

```
https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.8%2B9/OpenJDK21U-jdk_x64_linux_hotspot_21.0.8_9.tar.gz
```

## 补充说明

- 插件没有把校验和交给 vfox，所以 vfox 不会校验下载的文件（`WARNING: Checksum is not provided, skip verify...`，见 [foojay.md](foojay.md#插件发出的请求)）。经过镜像时，拿到的压缩包就是镜像给的那个，请用你信得过的镜像。
- 这个变量只改变 `vfox install` 下载 JDK 的地址，`vfox add java` 不会用到它。想让 vfox 的所有请求都走代理，见[网络](troubleshooting.md#网络)。
