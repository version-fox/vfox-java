# vfox-java

[中文](README_CN.md) | [English](README.md)

> Java plugin for [vfox](https://github.com/version-fox/vfox)

支持多种JDK发行版，如：Oracle、Graalvm、Eclipse等。

# 使用

**参数格式**:  x.y.z-distribution

```shell
# 添加插件
vfox add java

# 添加运行时
vfox install java@x.y.z  # 默认使用openjdk
vfox install java@x.y.z-graal # 使用graalvm

# 查看所有可用版本
vfox search java all # 查看所有sdk版本
vfox search java # 查看所有openjdk版本
vfox search java graal # 查看所有graalvm版本
```

# 支持的JDK发行版

> Thanks [SDKMAN](https://sdkman.io/jdks)!

## Bisheng (Huawei)

BiSheng JDK 是华为 JDK 的开源版本，源自 OpenJDK，受益于华为研发团队在解决服务相关挑战方面的丰富经验，已在 500 多款华为产品中使用。作为
OpenJDK 的下游产品，它是面向生产环境的高性能发行版，专门解决华为应用中的性能和稳定性问题。毕升JDK在优化ARM架构性能和稳定性方面表现出色，在大数据应用场景中效果更佳。其主要目标是为
Java 开发人员提供一个稳定、高性能的 JDK，尤其是在 ARM 架构上表现出色。

```shell
$ vfox install java x.y.z-bsg
$ vfox search java bsg
```

## Corretto (Amazon)

亚马逊 Corretto 是开放 Java 开发工具包（OpenJDK）的无成本、多平台、生产就绪发行版。Corretto
提供长期支持，包括性能增强和安全修复。亚马逊内部在数千个生产服务上运行 Corretto，Corretto 已通过认证，与 Java SE 标准兼容。使用
Corretto，您可以在 Linux、Windows 和 macOS 等流行的操作系统上开发和运行 Java 应用程序。

```shell
$ vfox install java x.y.z-amzn
$ vfox search java amzn
```

## Dragonwell (Alibaba)

作为 OpenJDK 的下游版本，Dragonwell 是阿里巴巴内部的 OpenJDK 实现。它针对在 10 万台以上服务器上运行的在线电子商务、金融和物流应用程序进行了优化。阿里巴巴
Dragonwell 是在极端扩展条件下运行这些分布式 Java 应用程序的引擎。

```shell
$ vfox install java x.y.z-albba
$ vfox search java albba
```

## GraalVM (Oracle)

Oracle GraalVM 是 Oracle 推出的免费 GraalVM 发行版，基于 Oracle JDK，包含高性能 Graal JIT 编译器。GraalVM 可将 Java
应用程序提前编译成独立的二进制文件，这些二进制文件可立即启动、快速扩展并使用更少的计算资源。Oracle GraalVM Native Image
提供的高级功能包括 G1 GC、SBOM 以及性能和大小优化。它还使在 Java 应用程序中嵌入 Python、JavaScript、Ruby 和其他语言成为可能。

```shell
$ vfox install java x.y.z-graal
$ vfox search java graal
```

## GraalVM (GraalVM Community)

GraalVM CE 是 GraalVM 的开源发行版，基于 OpenJDK，包含高性能 Graal JIT 编译器。GraalVM 可以将 Java
应用程序提前编译成独立的二进制文件，这些二进制文件可以立即启动、快速扩展并使用更少的计算资源。它还可以将
Python、JavaScript、Ruby 和其他语言嵌入 Java 应用程序。

```shell
$ vfox install java x.y.z-graalce
$ vfox search java graalce
```

## Java SE Development Kit (Oracle)

这个专有的 Java 开发工具包是 Oracle 公司以二进制产品形式发布的 Java 平台标准版的实现，面向 Linux、macOS 或 Windows 上的
Java 开发人员。JDK 包括一个私有 JVM 和其他一些资源，用于完成 Java 应用程序的开发。它根据 Oracle 免收费条款和条件许可证发布。

```shell
$ vfox install java x.y.z-oracle
$ vfox search java oracle
```

## Kona (Tencent)

Tencent Kona 是 OpenJDK 的免费、多平台和生产就绪发行版，提供长期支持（LTS）版本。它是腾讯内部默认的 JDK，用于云计算、大数据和其他众多
Java 应用程序。

```shell
$ vfox install java x.y.z-kona
$ vfox search java kona
```

## Liberica (Bellsoft)

Liberica 是 100% 的开源 Java 实现。它由 BellSoft 参与开发的 OpenJDK 构建，经过全面测试，并通过了 OpenJDK 许可提供的
JCK。Liberica 的所有支持版本还包含 JavaFX。

```shell
$ vfox install java x.y.z-librca
$ vfox search java librca
```

## Liberica NIK (Bellsoft)

Liberica Native Image Kit 是一款实用工具，可在封闭世界假设下将基于 JVM 的应用程序提前转换为完全编译的本地可执行文件，启动时间几乎为瞬间。该工具兼容各种平台，包括基于轻量级
musl 的 Alpine Linux，可优化资源消耗并最大限度地减少静态占用空间。

```shell
$ vfox install java x.y.z-nik
$ vfox search java nik
```

## Mandrel (Red Hat)

Mandrel 专注于 GraalVM 的本地镜像组件，目的是为 Quarkus 用户提供为其应用程序生成本地镜像的简便方法。使用 Quarkus
的开发人员应该能够从 Java 源代码一路开发到在 Linux 上运行的精益、原生、依赖平台的应用程序。这种能力对于在云原生应用程序开发模型中部署到容器中至关重要。

```shell
$ vfox install java x.y.z-mandrel
$ vfox search java mandrel
```

## OpenJDK (jdk.java.net)

OpenJDK（开放式 Java 开发工具包）是 Java 平台标准版（Java SE）的免费开源实现。它是 Sun Microsystems 于 2006 年开始努力的成果。该实现采用
GNU 通用公共许可证（GNU GPL）第 2 版许可，但有一个链接例外。如果没有 GPL 链接例外，链接到 Java 类库的组件将受 GPL
许可证条款的约束。OpenJDK 是 Java SE 自第 7 版起的官方参考实现。

```shell
$ vfox install java x.y.z-open
$ vfox search java open
```

## OpenJDK (Microsoft)

OpenJDK 的 Microsoft Build 是 OpenJDK 的免费发行版，它是开源的，任何人都可以免费在任何地方部署。它包括 MacOS、Linux 和
Windows x64 服务器和桌面环境上 Java 11 的长期支持 (LTS) 二进制文件，以及 Linux 和 Windows 上的
AArch64/ARM64。微软还发布了适用于所有三大操作系统以及 x64 和 AArch64 (M1/ARM64) 体系结构的 Java 16 二进制文件。

```shell
$ vfox install java x.y.z-ms
$ vfox search java ms
```

## SapMachine (SAP)

SapMachine 是 OpenJDK 项目的下游版本。它用于为希望使用 OpenJDK 运行其应用程序的 SAP 客户和合作伙伴构建和维护 SAP 支持版本的
OpenJDK。SAP 致力于确保 Java 平台的持续成功。

```shell
$ vfox install java x.y.z-sapmchn
$ vfox search java sapmchn
```

## Semeru (IBM)

Semeru Runtimes 使用 OpenJDK 的类库和 Eclipse OpenJ9 Java 虚拟机，使开发人员能够构建和部署 Java
应用程序，这些应用程序启动迅速，性能卓越，同时占用内存较少。

```shell
$ vfox install java x.y.z-sem
$ vfox search java sem
```

## Temurin (Eclipse)

Eclipse Adoptium Temurin™ 项目的前身是 AdoptOpenJDK，该项目提供代码和流程，支持构建运行时二进制文件和相关技术，这些二进制文件和技术具有高性能、企业级、跨平台、开源许可和经过
Java SE TCK 测试，可在整个 Java 生态系统中普遍使用。

```shell
$ vfox install java x.y.z-tem
$ vfox search java tem
```

## Trava (Trava)

TravaOpenJDK 是专为开发人员设计的 OpenJDK。它基于 dcevm 并使用集成的 HotswapAgent，因此允许在运行时通过方法和字段的添加或更新对类进行高级热交换。

```shell
$ vfox install java x.y.z-trava
$ vfox search java trava
```

## Zulu (Azul Systems)

Azul Zulu Builds of OpenJDK 是无成本、生产就绪的开源、经过 TCK 测试和认证的 OpenJDK 发行版。它们适用于各种硬件平台和操作系统，并与特殊要求兼容，如精简版
JRE 和构建，包括 OpenJFX 和 Coordinated Restore at Checkpoint (CRaC)。它们作为 Azul Platform Core 的一部分得到支持，Azul
Platform Core 可提供稳定的安全更新，以便快速、可靠地部署到生产中，并提供以解决方案为导向的工程协助。

```shell
$ vfox install java x.y.z-zulu
$ vfox search java zulu
```

## Jetbrains

```shell
$ vfox install java x.y.z-jb
$ vfox search java jb
```

# 感谢

- [SDKMAN](https://github.com/sdkman/)
- [foojayio](https://github.com/foojayio/discoapi)