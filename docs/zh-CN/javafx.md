# JavaFX 构建

[中文](javafx.md) | [English](../javafx.md)

有些厂商会把 JavaFX 打包进 JDK，作为单独的包发布。在发行版后面加 `-fx` 就能装上这种包：

```bash
vfox install java@21-zulu-fx
vfox install java@25.0.4-librca-fx
vfox use java@21-zulu-fx
```

`vfox search` 会同时列出两种构建，带 JavaFX 的名字以 `-fx` 结尾，并有 JavaFX 备注：

```
 - 25.0.4.1+1-zulu-fx (LTS, JavaFX)
 - 25.0.4.1+1-zulu (LTS)
```

安装后的版本名保留这个后缀（`25.0.4+9-librca-fx`），所以带 JavaFX 和不带的构建可以并存，两者不会串用：

- `java@21-zulu` 装不带 JavaFX 的构建，`java@21-zulu-fx` 装带的。如果发行版对某个版本只提供其中一种，另一种就会失败：`java@21-tem-fx` 会报 `No JDK found for 21-tem-fx with JavaFX on linux/amd64`，因为 Temurin 没有带 JavaFX 的构建。
- `vfox use java@21-zulu` 不会选中 `-fx` 构建，反过来也一样。
- `.sdkmanrc` 遵循同样的规则，见 [sdkmanrc.md](sdkmanrc.md)。

想确认装到的是哪种，看模块列表：

```bash
java --list-modules | grep javafx
```

带 JavaFX 的构建会列出 `javafx.base` 等模块，不带的什么也列不出。

## 哪些平台有 JavaFX 构建

截至 2026-10-18，提供 JavaFX 构建的发行版有四个，而且并非每个平台都有。下表列出有 JavaFX 构建的 LTS 版本，中间的非 LTS 版本也有一些，但有缺口。

| 发行版 | Linux x64 | Linux arm64 | Alpine x64 | macOS Intel | macOS Apple Silicon | Windows x64 | Windows arm64 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Zulu（`zulu`） | 8、11、17、21、25 | 8、11、17、21、25 | – | 8、11、17、21、25 | 8、11、17、21、25 | 8、11、17、21、25 | – |
| Liberica（`librca`） | 8、11、17、21、25 | 11、17、21、25 | 11 | 8、11、17、21、25 | 8、11、17、21、25 | 8、11、17、21、25 | 11、17、21、25 |
| Corretto（`amzn`） | 8 | 8 | – | 8 | – | 8 | – |
| Liberica NIK（`nik`） | 21、25 | – | – | 25 | 25 | 21、25 | – |

Alpine arm64 上没有任何发行版提供 JavaFX。Loongnix 为龙架构提供带 JavaFX 的构建，选择方式相同，见 [loongnix.md](loongnix.md)。想看某个平台当前的情况，在 [foojay.md](foojay.md) 的查询里加上 `javafx_bundled=true` 即可。
