# 从源码安装

[中文](install-from-source.md) | [English](../install-from-source.md)

`vfox add java` 安装的是最新的发布版。想在下一个版本发布之前用上 `main`，或者试用你正在改的代码，就从源码构建插件。插件就是一个 `metadata.lua` 加上 `hooks` 和 `lib` 两个目录，vfox 可以从它们的 zip 包添加插件。

## Ubuntu 26.04

在 Bash 中执行：

```bash
sudo apt install --assume-yes git zip
git clone --depth 1 https://github.com/version-fox/vfox-java.git
cd ./vfox-java/
zip -qr ./java.zip metadata.lua hooks lib
vfox add java --source ./java.zip
rm ./java.zip
```

macOS 的步骤相同，系统自带 `git` 和 `zip`。

## Windows 11

这里默认已装好 PowerShell 7，在 PowerShell 7 中执行：

```powershell
winget install --id Git.Git --source winget --exact
git clone --depth 1 https://github.com/version-fox/vfox-java.git
cd ./vfox-java/
tar -a -cf ./java.zip metadata.lua hooks lib
vfox add java --source ./java.zip
Remove-Item ./java.zip
```

## 验证

```bash
vfox install java@21-tem
vfox use --global java@21-tem
java -version
```

`vfox install java@21-tem` 装的是最新的 Temurin 21，截至 2026-10-18 是 `21.0.12.1+1-tem`。

## 已经添加过 java 时

`vfox add` 会报错 `plugin named java already exists`。你可以替换原有的插件，也可以给源码构建的版本另起一个名字，与原插件并存。

替换要先执行 `vfox remove java`，它会连同通过这个插件装的 JDK 一起删掉，vfox 会在确认之前先告诉你这一点。之后需要重新安装这些 JDK。

想两个都留着，就给新的起个别名：

```bash
vfox add java --source ./java.zip --alias java-dev
vfox install java-dev@21-tem
vfox remove -y java-dev            # 只删除 java-dev 和它装的东西
```

别名有它自己的已安装列表，但两者的 `JAVA_HOME` 都是 `~/.vfox/sdks/java`。在每个作用域里，只从其中一个选版本：全局作用域下，先执行 `vfox unuse --global java`，再 `vfox use --global java-dev@...`，反过来也一样。两个都选了的话，vfox 在每个提示符都会重新建立两者的链接，`JAVA_HOME` 最后指向哪一个说不准。

## 更新

拉取代码，重新打 zip 包，再添加一次。以原名添加的插件必须先删除，这会连已安装的 JDK 一起删掉，所以经常更新时用别名更省事：

```bash
vfox remove -y java-dev
vfox add java --source ./java.zip --alias java-dev
```

`vfox update java` 会拿 `metadata.lua` 里的版本号和插件注册表里的比较，两者相同时只会打印 `java is already the latest version`，所以在发布出比它更新的版本之前，不会动源码构建的版本。

开发插件请看 [development.md](development.md)。
