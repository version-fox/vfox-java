# 使用本机已有的 JDK

[中文](link.md) | [English](../link.md)

如果本机已经有一个 JDK——系统包管理器、IDE、Gradle、别的版本管理工具、Homebrew 或 winget 装的——`vfox link --detect java` 会直接采用它，而不用再下载一份。需要 vfox 1.1.0 或更高版本（`vfox --version` 查看）。

```bash
vfox link --detect java
```

vfox 会列出插件找到的 JDK，选中哪个就链接哪个；`vfox link --detect -y java` 则全部链接，不再逐个确认。之后 `vfox use java@...` 和往常一样用：`vfox list java` 会把链接进来的版本标成 `(linked → <路径>)`，`vfox uninstall` 也只删除这个链接，不动原来位置的 JDK。

## 会找到哪些地方

- Gradle 的目录（`$GRADLE_USER_HOME/jdks`，默认是 `~/.gradle/jdks`）
- IntelliJ IDEA 的目录（`~/.jdks`，macOS 上是 `~/Library/Java/JavaVirtualMachines`）
- 系统目录（`/usr/lib/jvm`，macOS 上是 `/Library/Java/JavaVirtualMachines`，Windows 上是 `C:\Program Files\*`，winget、Chocolatey 和厂商安装包最终也都装在这里）
- 版本管理器 SDKMAN、asdf、mise 和 jabba 的目录
- Homebrew 的 keg（`/opt/homebrew/opt`、`/usr/local/opt`，还有 Linuxbrew）
- Scoop 的应用目录（`~/scoop/apps`）
- CI runner 的工具缓存
- `JAVA_HOME` 指向的目录

nvm 只管 Node.js，里面没有 Java 可找。

## 版本名

找到的 JDK 按 `vfox install` 的规则命名：取它的 `release` 文件里的运行时版本，再加 `-<简称>`，有 JavaFX 的再加 `-fx`，OpenJDK 不加后缀。比如 Gradle 下载的 Temurin 17 会报成 `17.0.21+9-tem`。已经安装过或链接过的版本会被跳过。

## 安装时自动建链接（可选）

`vfox link --detect` 是把 JDK 接进 vfox。反方向——让 Gradle 和 IntelliJ IDEA 找到 vfox 装好的每一个 JDK——要在安装时打开：先设置 `VFOX_JAVA_JDKS_LINKS=1`（`true`、`yes`、`on` 也一样），再安装：

```bash
export VFOX_JAVA_JDKS_LINKS=1
vfox install java@21-tem
```

之后每次安装都会在 IDEA 的目录里留一个以版本号命名的链接（`~/.jdks`，macOS 上是 `~/Library/Java/JavaVirtualMachines`，Windows 上是 `%USERPROFILE%\.jdks`），`vfox uninstall` 会把当初建的那个链接删掉。那里已经有同名的非链接东西（比如你自己的 JDK）时会被跳过，绝不会动；建链接失败只会打印一句警告，不会导致安装失败。不设这个变量时，安装和卸载都和原来一样，什么都不多做。

## 手动链接

`--detect` 没扫到的地方，可以手工指定目录。它就是 JDK 本体所在的目录，也就是装着 `bin` 的那一级（macOS 上 `.jdk` 包里的 `Contents/Home`）：

```bash
vfox link java@17-system /usr/lib/jvm/java-17-openjdk-amd64
vfox use java@17-system
```
