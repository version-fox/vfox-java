# Native Image and the C toolchain

[中文](zh-CN/native-image.md) | [English](native-image.md)

A GraalVM installs and runs like any other JDK. After `vfox install java@25.0.2-graalce` and `vfox use`, `java` and `javac` work on a system with no compiler and no zlib headers. Only `native-image` needs more. It is the tool that compiles a program into a native executable, and it links the executable with the system's `gcc` against the C library and zlib. So it needs them, and so does whatever calls it, such as the Maven and Gradle plugins for Native Image. The plugin installs the JDK and nothing else, and a minimal Ubuntu, such as its container image, has neither a compiler nor zlib's headers.

`native-image` is in the `bin` directory of Oracle GraalVM, GraalVM Community, Liberica NIK, Mandrel and Gluon GraalVM. GraalVM CE 8 to 19 are the exception, see [below](#graalvm-ce-8-to-19).

## Ubuntu

On Ubuntu 26.04, execute in Bash once, before the first native build,

```bash
sudo apt install --assume-yes build-essential zlib1g-dev
```

Without them:

- Without `gcc` the build stops within seconds with `Error: Default native-compiler executable 'gcc' not found via environment variable PATH`, and `zlib1g-dev` alone does not change that.
- With `gcc` but without `zlib1g-dev`, which is what `build-essential` alone gives, the build goes through the analysis and the compilation first, which took between 20 seconds and two minutes for a hello world, and fails when it links: `There was an error linking the native image: Linker command exited with 1`, GraalVM's hint `It appears as though libz:.a is missing. Please install it.`, and `cannot find -lz: No such file or directory`.

`gcc`, `libc6-dev` and `zlib1g-dev` were enough to build a hello world, without `g++` and `make`. `build-essential` brings both, and is what GraalVM's documentation lists.

## Other systems

Other systems need other packages. GraalVM's [prerequisites](https://www.graalvm.org/latest/reference-manual/native-image/#prerequisites) list `sudo dnf install gcc glibc-devel zlib-devel libstdc++-static` for Fedora and the other systems that use dnf, `xcode-select --install` for macOS, and the Visual Studio Build Tools with the Windows SDK for Windows. On Fedora 44, `gcc`, `glibc-devel` and `zlib-devel` built a hello world without `libstdc++-static`.

## GraalVM CE 8 to 19

GraalVM CE 8 to 19 (`grl8`, `grl11`, `grl16`, `grl17`, `grl19`) come without `native-image`. Their `bin` directory holds `gu`, the GraalVM Updater, and `native-image` is `command not found` until `gu install native-image` has added it from GitHub. That worked for `22.3.3-grl11`, `21.2-grl16`, `22.3.3-grl17` and `22.3.1-grl19` on 2026-11-03, and the packages above are needed after it as before. It failed for `21.3.1-grl8` with `Internal error occurred: A JSONObject text must begin with '{'`, because the release index that this `gu` downloads, `https://oca.opensource.oracle.com/gds/meta-data.json`, is a web page now. For that release, download `native-image-installable-svm-java8-linux-amd64-21.3.1.jar` from the [`vm-21.3.1` release](https://github.com/graalvm/graalvm-ce-builds/releases/tag/vm-21.3.1) and run `gu -L install` on the file.

## What was checked

Checked on 2026-11-03 with vfox 1.0.13 in Ubuntu 26.04 container images (x64) that had no compiler. GraalVM Community 25.0.2 and 25.4.4.1.1, Oracle GraalVM 25.0.5, Mandrel 25.0.5, Liberica NIK 25.0.4.1 and Gluon GraalVM 22.1.0.1 stopped as described without the packages, and with them built a hello world that ran. So did `22.3.3-grl11`, `21.2-grl16`, `22.3.3-grl17` and `22.3.1-grl19` after `gu install native-image`, `21.3.1-grl8` after `gu -L install` of the downloaded file, and GraalVM Community 25.0.2 in a Fedora 44 image.
