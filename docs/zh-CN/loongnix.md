# Loongnix JDK

[中文](loongnix.md) | [English](../loongnix.md)

Foojay 没有龙架构（LoongArch）的包，并且会拒绝这个架构名。所以在 Linux loong64 上，插件改从龙芯的 [Loongnix 归档](https://ftp.loongnix.cn/Java/)读取 JDK，完全不访问 Foojay。这是插件在 Foojay 之外唯一的 JDK 来源。在其他平台上，`lnxabi1` 和 `lnxabi2` 会报 `Loongnix JDKs require linux/loong64`；在 loong64 上，[distributions.md](distributions.md) 里的发行版都用不了：

```
$ vfox search java tem
Foojay does not support loong64; use vfox search java loongnix
```

## 选择 ABI

归档里有两种构建，插件不会替你猜该用哪一种：

| 简称 | 长名 | 构建 | 适用于 |
| --- | --- | --- | --- |
| `lnxabi1` | `loongnix_abi1` | Linux 4.19 UAPI | Loongnix 20、Loongnix Server 8.4 |
| `lnxabi2` | `loongnix_abi2` | Linux 5.10 UAPI，上游文件名里是 `glibc2.34` | Debian 12、openEuler |

请对照[龙芯的兼容性说明](https://www.loongnix.cn/zh/api/java/)，按你的系统来选，不要只看内核版本。

## 使用

```bash
vfox search java lnxabi2                   # ABI2 的构建
vfox install java@21-lnxabi2-fx            # Java 21 的最新版，带 JavaFX，ABI2
vfox install java@21.0.12+8-lnxabi2-fx     # 指定构建
vfox use java@21.0.12+8-lnxabi2-fx
```

不带名字的 `vfox search java` 会列出两种 ABI 的构建，`vfox search java loongnix` 和 `vfox search java all` 也一样。一条结果长这样：

```
 - 26+35-lnxabi2-fx (JDK 26+35; ABI2 (Linux 5.10 UAPI, glibc 2.34); JavaFX)
 - 25.0.4+7-lnxabi2-fx (JDK 25.0.4+7; ABI2 (Linux 5.10 UAPI, glibc 2.34); JavaFX)
```

安装时名字里必须带 ABI。`vfox install java@21` 和 `java@21-tem` 都会报 `Choose a Loongnix ABI explicitly: run vfox search java and select lnxabi1 or lnxabi2`。在交互式终端里从 `vfox search` 的结果中选择，会自动带上 ABI。

版本号是 Java 的版本和构建号，即 `21.0.12+8`，不是龙芯自己的发行号（文件名里的 `loongson21.12.26`）。同一个版本龙芯发布过多次的，取最新的一次。`21` 和 `21.0.12` 按前缀匹配，取最新的构建，`21.0.1` 不会匹配 `21.0.12`。`vfox use` 会保留你输入的 ABI 和 `-fx`，所以 `21-lnxabi2-fx` 选中的是已安装的最新版本，不会选到 `lnxabi1` 的构建。

## JavaFX

龙芯的包大多是带 JavaFX 的构建，上游文件名里有 `fx-`，在插件里写作 `-fx`。Java 21 及以后的全部带 JavaFX，8、11、17 的大部分也带，只有少数早期构建不带。不写 `-fx` 就只会得到不带 JavaFX 的构建，所以 `java@21-lnxabi2` 会失败，报 `No Loongnix JDK found for 21-lnxabi2`，而 `java@21-lnxabi2-fx` 可以装上。

## 限制

- 只提供归档里 GA 版本的龙架构 tar 包。EA 构建、安装程序、校验文件以及 MIPS 包都会跳过。
- 归档里只有 glibc 构建，没有 musl 构建。
- 插件不校验下载内容。
- 插件读取的是归档的 HTML 目录页。龙芯如果改了目录格式，插件会报错 `No Loongnix JDK packages found; check the requested version and upstream directory format` 并停止。
- e2e 套件里没有 loong64 作业。钩子的离线测试用的是 `tests/fixtures/loongnix` 里保存的一份归档目录页（见 [development.md](development.md)）。
