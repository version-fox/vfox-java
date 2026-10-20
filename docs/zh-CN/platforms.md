# 平台支持

[中文](platforms.md) | [English](../platforms.md)

插件向 Foojay 请求的是当前平台的包：操作系统、vfox 二进制所属的 CPU 架构，在 Linux 上还有 C 库（请求的具体内容见 [foojay.md](foojay.md)）。某个发行版在这个平台上没有包，`vfox search java bsg` 就会报 `no available version`，安装也会失败：

```
No JDK found for 21-bsg on darwin/arm64. Please check available versions with 'vfox search java'
```

下表列出各发行版有哪些平台的包，数据取自 2026-10-18 的 Foojay，从 AdoptOpenJDK 起的各行是 2026-10-20 补上的。✅ 表示 Foojay 在这个平台上至少列有一个插件能安装的包，❌ 表示一个也没有。未发布：0.6.2 只有到 Trava 为止的那些行。

| 发行版 | Linux x64 | Linux arm64 | Alpine x64 | Alpine arm64 | macOS Intel | macOS Apple Silicon | Windows x64 | Windows arm64 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OpenJDK（`open`） | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Temurin（`tem`） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Zulu（`zulu`） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Liberica（`librca`） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Corretto（`amzn`） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Microsoft（`ms`） | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Oracle JDK（`oracle`） | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Semeru（`sem`） | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| SapMachine（`sapmchn`） | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Kona（`kona`） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Dragonwell（`albba`） | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |
| 毕昇 JDK（`bsg`） | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Oracle GraalVM（`graal`） | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| GraalVM 社区版（`graalce`） | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Liberica NIK（`nik`） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Mandrel（`mandrel`） | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| JetBrains Runtime（`jb`） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Trava（`trava`） | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| AdoptOpenJDK（`adpt`） | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ |
| AdoptOpenJDK OpenJ9（`adptj9`） | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| Eliya（`eliya`） | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| OJDKBuild（`ojdkbld`） | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| OpenLogic（`opnlgc`） | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| Red Hat（`rdht`） | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Semeru 认证版（`semcrt`） | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Gluon GraalVM（`gln`） | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| GraalVM CE 8（`grl8`） | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| GraalVM CE 11（`grl11`） | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| GraalVM CE 16（`grl16`） | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| GraalVM CE 17（`grl17`） | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| GraalVM CE 19（`grl19`） | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |

“Alpine”指使用 musl C 库的 Linux。`ldd --version` 的输出里提到 musl，插件就当作 musl，否则当作 glibc。Loongnix 另有单独的页面：[loongnix.md](loongnix.md)。

Foojay 的数据会变，这张表也会过时。想看当前的情况，按 [foojay.md](foojay.md#我的平台上有哪些发行版) 里的方法去问 Foojay。

## 只有部分版本

标了 ✅ 也不代表所有版本都有。以下同样截至 2026-10-18：

- Windows ARM64 上，没有任何发行版提供 Java 8。Temurin 有 21 和 23，Zulu 有 16 到 19、21 和 25，Liberica 有 11 和 16 到 27，Microsoft 有 11、16、17、21 和 25，JetBrains Runtime 有 17、21 和 25。
- Apple Silicon 上，Java 8 来自 Zulu、Liberica、Corretto 和 Kona。Temurin 和 Semeru 在那里有 11 和 17 到 27，OpenJDK 有 17 到 27。Mandrel 有 23.1 到 25 的版本，运行 Java 21 到 25；Liberica NIK 有 22.2 到 25 的版本，运行 Java 11、17 和 20 到 25（见[它们的版本号](distributions.md#mandrel-与-liberica-nik-的行为)）。
- Intel Mac 上的新版本来得更晚，有的干脆没有。OpenJDK 和 Temurin 停在 26，而 Linux 上已有 27；SapMachine 停在 24；Oracle GraalVM 和 GraalVM 社区版停在 25.0.1。Mandrel 没有 Intel Mac 的构建。
- 在 Alpine 上，Temurin 的 arm64 构建只有 21 及以后。x64 方面，Microsoft 只有 11 和 17，SapMachine 有 17 和 20 到 27，Kona 有 8 和 21，Dragonwell 有 11、17、21 和 25，JetBrains Runtime 只有 17。arm64 方面，Kona 有 Java 8，JetBrains Runtime 有 17（x64 也有）。
- Trava 在 Linux arm64 上只有一个构建，11.0.10+6。
- 带 JavaFX 的构建覆盖的平台比不带的少，见 [javafx.md](javafx.md#哪些平台有-javafx-构建)。

2026-10-20 补上的那些行，截至当天：

- AdoptOpenJDK 的 Alpine x64 构建只有 HotSpot 版的 Java 16，OpenJ9 版在 Linux arm64 上只有 8、11、15 和 16。
- OJDKBuild 在 Linux 上只有 Java 8 和 11。
- Red Hat 的构建只有 Linux x64 能下载，也就是表里它唯一的 ✅。Foojay 还列了几个 Linux arm64 的和一个 Windows 的，`vfox search` 也会列出来，但下载都返回 404。
- Apple Silicon 上，Gluon GraalVM 有 22.1.0.1 和 23+25，GraalVM CE 11 和 17 有 GraalVM 22.1 到 22.3.1，GraalVM CE 19 有 22.3 和 22.3.1。

## 哪些只有 x64

除了 OJDKBuild、OpenLogic、Red Hat、Gluon GraalVM 和 GraalVM CE 8，每个发行版在 Linux 上都有 arm64 构建，Trava 只有一个（11.0.10+6）。macOS 上，Dragonwell、毕昇、Eliya、OJDKBuild、Red Hat 和 Semeru 认证版两种架构都没有；Trava、AdoptOpenJDK、OpenLogic、GraalVM CE 8 和 GraalVM CE 16 只有 Intel；Mandrel 只有 Apple Silicon。

Windows 上几乎都只有 x64。另外有 arm64 构建的是 Temurin、Zulu、Liberica、Microsoft 和 JetBrains Runtime。其余都只有 x64，其中毕昇、Eliya、Red Hat 和 Semeru 认证版在 Windows 上根本没有。

## GraalVM

Oracle GraalVM 和 GraalVM 社区版在 Linux 和 macOS 上有 x64 和 arm64 构建，在 Windows 上只有 x64。它们没有 Alpine 的构建。Intel Mac 上最新的是 25.0.1，25.1 之后每月发布的特性版本在 macOS 上只有 Apple Silicon 版本。e2e 套件在 arm64 上不测 GraalVM 社区版，只是因为它的 Windows arm64 作业没有可装的包。Linux arm64 是有构建的。

GraalVM CE 8 到 19 和 Gluon GraalVM 同样没有 Alpine 和 Windows ARM64 的构建。GraalVM CE 从 JDK 11 起才有 Linux arm64 的构建，Gluon GraalVM 则没有。

## 其他 CPU

vfox 除了 x64、arm64 和 loong64，还发布 32 位 x86 和 32 位 ARM 的二进制。插件会把 vfox 二进制的架构名传给 Foojay（`arm64` 改成 `aarch64`，Windows 上 `amd64` 改成 `x64`），所以能装到什么，取决于 Foojay 列出什么。e2e 套件没有覆盖这些情况。

- 32 位 ARM Linux：Corretto、Liberica、Temurin 和 Zulu，以及 HotSpot 版的 AdoptOpenJDK。
- 32 位 x86 Linux：Corretto、Liberica、Zulu 和 JetBrains Runtime，以及 OpenLogic 的 Java 8。
- Foojay 不认识 loong64，Linux loong64 改用 Loongnix，见 [loongnix.md](loongnix.md)。

如果你自己为 riscv64、ppc64le 或 s390x 编译 vfox：Foojay 列有 riscv64 包的是 Dragonwell、Liberica 和 Temurin，ppc64le 的是 Liberica、SapMachine、Semeru 和 Temurin，s390x 的是 Semeru 和 Temurin。2026-10-20 补上的发行版里，AdoptOpenJDK（HotSpot 版和 OpenJ9 版都有）和 Semeru 认证版有 ppc64le 和 s390x 的包，Red Hat 的 ppc64le 记录下载返回 404。

## macOS 上的 Java home

有些 macOS 压缩包把 JDK 放在 `Contents/Home` 里，或放在以厂商命名的目录中。安装之后插件会把内容上移一层，这样 `JAVA_HOME` 总是指向含有 `bin/java` 的目录。安装时会打印 `Checking Java home layout...`。压缩包里有两个候选的 Java home，或者移动时文件会互相覆盖，插件会在移动任何文件之前报错并中止。
