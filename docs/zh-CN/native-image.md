# Native Image 与 C 工具链

[中文](native-image.md) | [English](../native-image.md)

GraalVM 的安装和使用与别的 JDK 没有两样：`vfox install java@25.0.2-graalce` 和 `vfox use` 之后，`java` 和 `javac` 在没有编译器、也没有 zlib 头文件的系统上照常工作。只有 `native-image` 还需要更多的东西。它是把程序编译成原生可执行文件的工具，会用系统的 `gcc` 把可执行文件与 C 库和 zlib 链接起来，所以需要它们；调用它的程序同样需要，比如 Native Image 的 Maven 和 Gradle 插件。插件只安装 JDK，不装别的，而最小化的 Ubuntu（比如它的容器镜像）既没有编译器，也没有 zlib 的头文件。

`native-image` 在 Oracle GraalVM、GraalVM 社区版、Liberica NIK、Mandrel 和 Gluon GraalVM 的 `bin` 目录里。GraalVM CE 8 到 19 是例外，见[下文](#graalvm-ce-8-到-19)。

## Ubuntu

在 Ubuntu 26.04 的 Bash 中执行，第一次构建原生镜像之前装一次即可：

```bash
sudo apt install --assume-yes build-essential zlib1g-dev
```

没有这些包时：

- 没有 `gcc` 时，构建几秒内就停下，报 `Error: Default native-compiler executable 'gcc' not found via environment variable PATH`，只装 `zlib1g-dev` 也没用。
- 有 `gcc` 却没有 `zlib1g-dev` 时（只装了 `build-essential` 也是这种情况），构建会先走完分析和编译（hello world 用了 20 秒到两分钟），到链接时才失败：`There was an error linking the native image: Linker command exited with 1`，GraalVM 自己的提示 `It appears as though libz:.a is missing. Please install it.`，以及 `cannot find -lz: No such file or directory`。

构建一个 hello world，`gcc`、`libc6-dev` 和 `zlib1g-dev` 就够了，用不着 `g++` 和 `make`。`build-essential` 把这两个也装上，GraalVM 的文档列出的正是它。

## 其他系统

其他系统需要的包不一样。GraalVM 的[前置条件](https://www.graalvm.org/latest/reference-manual/native-image/#prerequisites)里，Fedora 和其他使用 dnf 的系统是 `sudo dnf install gcc glibc-devel zlib-devel libstdc++-static`，macOS 是 `xcode-select --install`，Windows 是带 Windows SDK 的 Visual Studio Build Tools。在 Fedora 44 上，只装 `gcc`、`glibc-devel` 和 `zlib-devel`、不装 `libstdc++-static`，也构建出了 hello world。

## GraalVM CE 8 到 19

GraalVM CE 8 到 19（`grl8`、`grl11`、`grl16`、`grl17`、`grl19`）不带 `native-image`。它们的 `bin` 目录里只有 GraalVM 更新器 `gu`，`native-image` 会报 `command not found`，要先用 `gu install native-image` 从 GitHub 添加。2026-11-02 这在 `22.3.3-grl11`、`21.2-grl16`、`22.3.3-grl17` 和 `22.3.1-grl19` 上成功了，添加之后仍然需要上面的包。`21.3.1-grl8` 上失败了，报 `Internal error occurred: A JSONObject text must begin with '{'`：这个 `gu` 下载的版本索引 `https://oca.opensource.oracle.com/gds/meta-data.json` 现在返回的是一个网页。对这个版本，请从 [`vm-21.3.1` 发布页](https://github.com/graalvm/graalvm-ce-builds/releases/tag/vm-21.3.1)下载 `native-image-installable-svm-java8-linux-amd64-21.3.1.jar`，再对这个文件执行 `gu -L install`。

## 检查过的环境

2026-11-02 用 vfox 1.0.13 在没有编译器的 Ubuntu 26.04 容器镜像（x64）里检查过：GraalVM 社区版 25.0.2 和 25.4.4.1.1、Oracle GraalVM 25.0.5、Mandrel 25.0.5、Liberica NIK 25.0.4.1 和 Gluon GraalVM 22.1.0.1，没有这些包时都如上所述停下，装上之后都构建出了能运行的 hello world。`22.3.3-grl17` 在执行 `gu install native-image` 之后也是如此，GraalVM 社区版 25.0.2 在 Fedora 44 的镜像里也一样。
