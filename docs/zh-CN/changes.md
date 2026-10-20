# 变更记录

[中文](changes.md) | [English](../changes.md)

按发布版本列出用户能感受到的变化。GitHub 的 Release 页面列出了对应的 PR。写这篇文档时最新的发布版是 0.6.2，`main` 比它多出“未发布”下面的所有内容。想现在就用上这些变化，见 [install-from-source.md](install-from-source.md)。

## 未发布

- 新增 13 个发行版，Foojay 列出的发行版从此全都有了：AdoptOpenJDK（`adpt`、`adptj9`）、Eliya（`eliya`）、OJDKBuild（`ojdkbld`）、OpenLogic（`opnlgc`）、Red Hat（`rdht`）、Semeru 认证版（`semcrt`）、Gluon GraalVM（`gln`），以及基于 JDK 8 到 19 的 GraalVM CE（`grl8`、`grl11`、`grl16`、`grl17`、`grl19`）。Red Hat 从 tar.xz 包安装；Linux 上的 OJDKBuild、macOS 上的 OpenLogic 和 22.1 以前的 Gluon GraalVM 从 zip 包安装。`.sdkmanrc` 里写 SDKMAN 以前给它们的标识符也认，例如 `11.0.10.j9-adpt`、`22.3.3.r17-grl`。见 [distributions.md](distributions.md)。

## 0.6.2（2026-10-18）

- `.sdkmanrc` 在 vfox 1.x 下重新可用。0.6.1 在 vfox 1.x 下会报 `expected 0 arguments for func() []string, got 1`（测试过 1.0.12 和 1.0.13），但 vfox 不会把这个错误显示出来（[#65](https://github.com/version-fox/vfox-java/pull/65)）。
- 只写大版本号的 `vfox use java@21` 在 vfox 1.0.13 下可用。0.6.1 在那里会报 `cannot unmarshal string into plugin.PreUseHookResult`（[#65](https://github.com/version-fox/vfox-java/pull/65)）。
- `.sdkmanrc` 能匹配 SDKMAN 的 `jbr` 和 JavaFX 标识符（[#78](https://github.com/version-fox/vfox-java/pull/78)）、补零的版本（[#85](https://github.com/version-fox/vfox-java/pull/85)）和 EA 标识符（[#88](https://github.com/version-fox/vfox-java/pull/88)、[#96](https://github.com/version-fox/vfox-java/pull/96)）。同一大版本装了多个 JDK 时，会选中文件里指明的那个（[#84](https://github.com/version-fox/vfox-java/pull/84)）。见 [sdkmanrc.md](sdkmanrc.md)。
- 只写大版本号时，安装最新的版本。`java@21-tem` 装的是 `21.0.12.1+1-tem`，不再是 `21+35-tem`（[#74](https://github.com/version-fox/vfox-java/pull/74)）。`java@25-graal` 装的是 25.0 系列的最新构建 `25.0.4.1-graal`，0.6.1 装的是 `25-graal`（[#101](https://github.com/version-fox/vfox-java/pull/101)）。
- `vfox use java@21.0.8-tem` 能找到已安装的 `21.0.8+9-tem`（[#76](https://github.com/version-fox/vfox-java/pull/76)）。带 `-open` 或 `openjdk-` 的 OpenJDK 名字（[#77](https://github.com/version-fox/vfox-java/pull/77)）和补零的版本（[#92](https://github.com/version-fox/vfox-java/pull/92)）同样如此。
- `java@21.0.5+63130-jb` 和 `java@28.ea.15-open` 装的是它们指明的那个构建，不再是这个版本的最新构建（[#83](https://github.com/version-fox/vfox-java/pull/83)）。
- Windows 上的 `vfox search` 会列出只提供 tar.gz 的版本（[#81](https://github.com/version-fox/vfox-java/pull/81)）。
- 插件不再设置 `GRAALVM_HOME`（[#93](https://github.com/version-fox/vfox-java/pull/93)）。
- `java@tem`、`java@-tem` 这种只写发行版的写法会提示补上版本。0.6.1 对前者报 `attempt to index a non-table object(nil) with key 'match'`，对后者则装上最新版本（[#99](https://github.com/version-fox/vfox-java/pull/99)）。
- `vfox search` 不再把 GraalVM 每月发布的特性版本标成 LTS（[#100](https://github.com/version-fox/vfox-java/pull/100)）。
- 仓库有了覆盖 Linux 和 Windows 的容器 e2e 套件，见 [e2e.md](e2e.md)（[#65](https://github.com/version-fox/vfox-java/pull/65)、[#82](https://github.com/version-fox/vfox-java/pull/82)）。

## 0.6.1（2026-09-12）

- macOS 上通过 `bin/java` 的位置来确定 Java home，所以带厂商命名目录或 `Contents/Home` 的压缩包也能用（[#63](https://github.com/version-fox/vfox-java/pull/63)）。

## 0.6.0（2026-09-12）

- 支持在 Linux loong64 上从 Loongnix 归档安装 JDK，见 [loongnix.md](loongnix.md)（[#62](https://github.com/version-fox/vfox-java/pull/62)）。
- `vfox use` 切换 JavaFX 构建时保留 `-fx` 后缀（[#60](https://github.com/version-fox/vfox-java/pull/60)）。
- JetBrains Runtime 可以在 Windows 11 上安装（[#58](https://github.com/version-fox/vfox-java/pull/58)）。

## 0.5.4（2026-06-01）

- EA 构建可以这样安装：`java@26.ea.1-graal`（[#57](https://github.com/version-fox/vfox-java/pull/57)）。

## 0.5.3（2026-01-19）

- 支持用 `-fx` 后缀安装带 JavaFX 的构建（[#48](https://github.com/version-fox/vfox-java/pull/48)），见 [javafx.md](javafx.md)。
- Alpine 等 musl 系统现在装的是 musl 构建（[#50](https://github.com/version-fox/vfox-java/pull/50)）。
- Windows x64 上重新向 Foojay 请求 `x64`，0.5.2 在那里发的是 `amd64`（[#52](https://github.com/version-fox/vfox-java/pull/52)）。

## 0.5.2（2026-01-18）

- arm64 向 Foojay 请求 `aarch64`，这才是它认的名字（[#46](https://github.com/version-fox/vfox-java/pull/46)、[#47](https://github.com/version-fox/vfox-java/pull/47)）。

## 0.5.1（2026-01-02）

- `vfox use java@21` 交给 vfox 处理，由它在已安装的版本里匹配只写了大版本号的输入。

## 0.5.0（2025-09-29）

- 支持 asdf 风格的写法（发行版在前，版本在后），例如 `java@temurin-21`（[#17](https://github.com/version-fox/vfox-java/pull/17)）。

## 0.4.x（2024-04）

- 0.4.0 开始读取 `.sdkmanrc`。
- 0.4.3 在 Linux 上向 Foojay 请求 glibc 构建（[#14](https://github.com/version-fox/vfox-java/pull/14)）。

## 0.1.x 和 0.2.x（2024-04）

- 0.1.0 是第一个发布版，支持 17 个发行版。
- 0.1.2 增加了 `vfox search java all`（[#5](https://github.com/version-fox/vfox-java/pull/5)），并把 `open` 设为默认发行版（[#6](https://github.com/version-fox/vfox-java/pull/6)）。
- 0.2.1 增加了 Liberica Native Image Kit（[#10](https://github.com/version-fox/vfox-java/pull/10)）。
