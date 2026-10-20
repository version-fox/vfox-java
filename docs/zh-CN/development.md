# 开发

[中文](development.md) | [English](../development.md)

## 目录结构

```
metadata.lua                    插件名、版本，以及把 .sdkmanrc 注册为兼容版本文件
hooks/available.lua             vfox search
hooks/pre_install.lua           vfox install：选择包并给安装后的版本命名
hooks/post_install.lua          macOS：把 Java home 移到安装根目录
hooks/env_keys.lua              JAVA_HOME 和 PATH
hooks/pre_use.lua               vfox use：把输入映射到已安装的版本名
hooks/parse_legacy_file.lua     .sdkmanrc
lib/distribution_version.lua    发行版名称、版本写法的解析、GraalVM 特性版本的识别
lib/foojay.lua                  向 Foojay 发出的请求，以及对返回结果的修正
lib/installed_version.lua       与已安装的版本名做匹配
lib/loongnix.lua                Loongnix 归档
tests/*_test.lua                离线的钩子测试
tests/fixtures/loongnix/        Loongnix 归档目录页的一份快照
tests/e2e/                      容器测试，见 e2e.md
Injection.lua                   vfox 注入对象的类型提示，不会被加载
```

vfox 加载 `metadata.lua`，命令需要时调用相应的钩子，并向钩子提供全局变量 `PLUGIN` 和 `RUNTIME`（`osType`、`archType`、`version`）。`osType` 和 `archType` 就是 vfox 二进制的 Go `GOOS` 和 `GOARCH`。

## 一条命令会执行什么

| 你执行 | 调用的钩子 |
| --- | --- |
| `vfox search java tem` | `Available` |
| `vfox install java@21-tem` | `PreInstall` 返回 URL 和版本名。vfox 下载并解压，然后调用 `PostInstall` |
| `vfox use java@21-tem` | `PreUse` 返回要选中的已安装版本名，`EnvKeys` 提供环境变量 |
| 已挂载到 Shell，`cd` 进有 `.sdkmanrc` 的目录 | `ParseLegacyFile` |
| `vfox uninstall java@21.0.8+9-tem` | 无，名字必须精确 |

几条容易踩坑的约定：

- `PreInstall` 返回 `url`、`version` 和 `note`。`version` 会成为安装后的版本名，所以它带着构建号。包的校验和目前没有传给 vfox（`hooks/pre_install.lua` 里的 `TODO: checksum`），vfox 为此会打印警告。
- `PreUse` 返回 Lua 表或 `nil`。只写大版本号时返回 `nil`，让 vfox 自己去匹配。vfox 1.0.13 及以后会拒绝裸字符串，比如 `""`。
- `ParseLegacyFile` 调用 `ctx.getInstalledVersions()` 时不能带参数。vfox 1.x 把它绑定成 Go 的 `func() []string`，会拒绝 `ctx:getInstalledVersions()` 多传的那个参数。vfox 会忽略这个钩子的错误，所以出错时没有任何提示。
- vfox 把已安装的版本按字符串降序传给钩子，例如 `21.0.8+9-tem`、`21.0.12+8-tem`、`21.0.1+12-tem`。按前缀匹配时，第一个命中的不一定是最新的，所以 `lib/installed_version.lua` 逐段比较数字。
- `EnvKeys` 不设置 `GRAALVM_HOME`，需要的话由用户自己把它指向某个 GraalVM。

## 命名

安装后的版本名是 `<java_version>[-<简称>][-fx]`，OpenJDK 没有简称（[versions.md](versions.md#安装后的版本名)）。`lib/distribution_version.lua` 把一个写法解析成版本、发行版和 JavaFX 标志，两种顺序都接受（`21-tem`、`tem-21`）。`lib/installed_version.lua` 把用户输入的版本变成已安装的版本名：先看这个名字本身。只写大版本号时，取这个大版本里已安装的最新版本；其他写法则取这个版本本身，或它的最新构建。`PreUse` 到此为止。`ParseLegacyFile` 还会再退一步，取同一大版本里已安装的最新版本。

SDKMAN 有些写法不同（`jbr`、`21.0.12.fx-zulu`、`21.0.12-fx+1.1-librca`、`28.0.0+ea.19-open`），`hooks/parse_legacy_file.lua` 里的 `plugin_spelling` 会在解析之前把它们改写成插件自己的写法。对 SDKMAN 已经不再提供的发行版，同一文件里的 `sdkman_flavours` 把 SDKMAN 写在版本号里的虚拟机或 JDK 版本换成简称（`22.3.3.r17-grl` 就是 `22.3.3-grl17`）。SDKMAN 给版本补的零由 `installed_version.unpad` 去掉（`27.0.0+36` 就是 `27+36`）。简称与 SDKMAN 不同的地方见 [distributions.md](distributions.md#简称与-sdkman-的不同)。

## Foojay

- 查询里的 `+` 必须做百分号编码。Foojay 会把没编码的 `+` 当成空格并丢掉构建号，`21.0.5+63130` 就会匹配 21.0.5 的所有构建。
- `version=21` 只是 GA 构建 `21+35`。只写大版本号时会加上 `latest=available`，才能拿到最新的 21.x。
- Windows 在同一次请求里同时要 `zip` 和 `tar.gz`。JetBrains Runtime 只为较新的构建提供 Windows 的 zip。同一版本两种都有时，`PreInstall` 取 zip。
- 在其他系统上，有几个发行版的部分或全部版本没有 tar.gz，`lib/foojay.lua` 里的 `other_archive_type` 会为它们多要一种格式：Red Hat 要 `tar.xz`，OJDKBuild、OpenLogic 和 Gluon GraalVM 要 `zip`。这两种 vfox 都能解压，这些 zip 包也带着 Unix 权限，所以 `bin/java` 仍然可以执行。
- `lib/foojay.lua` 里的 `fixes` 会在钩子拿到结果之前去掉一些包：Foojay 列在 OJDKBuild 的 Windows JDK 里的 JRE、installer bundle 包和 RHEL 6 构建，以及 Gluon GraalVM 22.x 的 JDK 11 构建，它们和 JDK 17 构建共用一个版本号。只写大版本号时，`latest=available` 每种格式只返回一个包，这个包可能正好是要去掉的，所以对这两个发行版，插件会再按那个版本完整地查一次。
- Foojay 里同一个名字有两条记录时，`Available` 只列一次。
- Foojay 把 GraalVM 每月发布的特性版本（`25.1.3` 起）标成 LTS。`lib/distribution_version.lua` 里的 `is_feature_release` 按次版本号识别它们，`Available` 去掉它们的备注。它只适用于 `graal` 和 `graalce`：Mandrel 和 Liberica NIK 在 24 及以前按自己的版本号编号（`mandrel` 的 `23.1.12` 就是 LTS），从 25 起沿用 JDK 的编号。
- 只有 Oracle GraalVM（`graal`）在只写大版本号时，`PreInstall` 才会跳过特性版本，所以装的是 25.0 系列。一个大版本里只有特性版本时，则保留它们。GraalVM 社区版不做这个过滤，因为特性版本就是它现在发布的全部。
- CPU 名字：`arm64` 改成 `aarch64`，Windows 上 `amd64` 改成 `x64`；`darwin` 改成 `macos`。在 Linux 上，由 `ldd --version` 决定是 glibc 还是 musl。

## 测试

钩子测试在离线状态下用 `gopher-lua` 运行，它就是 vfox 内嵌的 Lua 解释器：

```bash
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/pre_install_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/pre_use_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/parse_legacy_file_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/loongnix_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/post_install_test.lua
```

请在仓库根目录运行。五个文件都会加载 `tests/support.lua`，它模拟 `vfox.strings`；`tests/pre_install_test.lua` 和 `tests/loongnix_test.lua` 还自己模拟了 `http` 和 `json`。`tests/pre_install_test.lua` 把 Foojay 的返回结果放在文件开头的一张表里，键是 `<发行版> [<版本>] [<latest>]`，Windows 和 macOS 的前面再分别加 `windows` 和 `macos`。新增用例需要的返回结果就加在那里，并注明观察到的日期。Lint、许可证头和容器测试见 [e2e.md](e2e.md#本地检查)。

想对着真实的 Foojay 调用单个钩子，可以用 vfox 1.0.13 及以后版本的 `vfox plugin run`。它不会注册插件，`--os` 和 `--arch` 可以模拟其他平台：

```bash
vfox plugin run . Available --input '{"args":["tem"]}' --json
vfox plugin run . PreInstall --input '{"version":"21-tem"}' --os windows --arch arm64 --json
vfox plugin run . ParseLegacyFile --input '{"filename":".sdkmanrc","filepath":"/tmp/p/.sdkmanrc","installedVersions":["21.0.8+9-tem"]}' --json
```

`vfox --debug <命令>` 会显示 vfox 对钩子做了什么，vfox 吞掉的错误可以靠它找出来。

## 添加发行版

1. 在 Foojay 里找到它的 id（见 [foojay.md](foojay.md)），并确认它在你关心的平台上有包。
2. 在 `lib/distribution_version.lua` 的 `short_name` 里加一行 `["<简称>"] = "<foojay id>"`。SDKMAN 现在或以前有这个发行版的话，用 SDKMAN 的标识符；没有的话，照 SDKMAN 的习惯起一个：短的厂商名保持原样，长的要缩短，多半是去掉元音（`opnlgc`）。SDKMAN 写法不同的话，在 `hooks/parse_legacy_file.lua` 的 `plugin_spelling` 里做映射，并把这个差别补进 [distributions.md](distributions.md#简称与-sdkman-的不同)。
3. 如果它的版本号或 LTS 标记需要特殊处理，像 GraalVM 那样，就在 `hooks/available.lua` 和 `hooks/pre_install.lua` 里处理。如果它在 Windows 以外的系统上没有 tar.gz，就把它的格式加进 `lib/foojay.lua` 的 `other_archive_type`；如果 Foojay 给它列的包有的不能照原样安装，就在同一文件的 `fixes` 里加一条修正。
4. 在 `tests/pre_install_test.lua` 里加一个用例。
5. 更新 `README.md`、[distributions.md](distributions.md) 和 [platforms.md](platforms.md) 里的表，以及对应的中文版（`README_CN.md` 和 `docs/zh-CN/` 下的同名页面）。
6. 如果引入了新的代码路径，也要加进 e2e 矩阵（[e2e.md](e2e.md)）。矩阵之外的发行版仍会运行所有检查，只是跳过 `java.vendor` 断言和 asdf 风格的 `PreUse` 写法。只新增名字、没有新代码路径的发行版，则改加进 `tests/e2e/common/common.go` 的 `nameOnly`，并写上 Foojay 有它的那些 runner 平台。

## 更新平台表

[platforms.md](platforms.md) 的数据取自 Foojay。下面的命令用 14 次请求，按平台打印有构建的发行版。在 Windows 以外的平台上，每个平台的第二次请求和插件一样，查 Red Hat、OJDKBuild、OpenLogic 和 Gluon GraalVM 在那里除 tar.gz 以外提供的格式：

```bash
base='https://api.foojay.io/disco/v3.0/packages/jdks?directly_downloadable=true&latest=per_distro'
while read -r name query; do
  printf '%-14s ' "$name"
  {
    curl -s "$base&$query&archive_type=tar.gz" | jq -r '.result[].distribution'
    case $name in windows-*) ;; *)
      curl -s "$base&$query&archive_type=tar.xz&archive_type=zip" | jq -r '.result[].distribution
        | select(. == "redhat" or . == "ojdk_build" or . == "openlogic" or . == "gluon_graalvm")' ;;
    esac
  } | sort -u | tr '\n' ' '; echo
done <<'EOF'
linux-x64 architecture=amd64&operating_system=linux&lib_c_type=glibc
linux-arm64 architecture=aarch64&operating_system=linux&lib_c_type=glibc
alpine-x64 architecture=amd64&operating_system=linux&lib_c_type=musl
alpine-arm64 architecture=aarch64&operating_system=linux&lib_c_type=musl
macos-intel architecture=amd64&operating_system=macos
macos-arm64 architecture=aarch64&operating_system=macos
windows-x64 architecture=x64&operating_system=windows&archive_type=zip
windows-arm64 architecture=aarch64&operating_system=windows&archive_type=zip
EOF
```

id 是 Foojay 的（`oracle_open_jdk` 对应 `open`）。这段命令在 Linux arm64 和 Windows x64 上也会打印 `redhat`，但这些下载都返回 404，所以表里没有算进去。“只有部分版本”一节里的说明，需要对每个发行版、每个平台单独查询，不带 `latest`，再按 `major_version` 分组。

## 已知限制

- 下载内容没有校验，见上文。
- `vfox search` 只列 GA 版本。EA 构建要自己写出名字来安装。
- 插件不提供 JRE 包，也不提供 Gluon GraalVM 22.x 的 JDK 11 构建。
- 只有 Linux loong64 有 Foojay 以外的来源。

## 发布

维护者在默认分支上执行 **Actions → Plugin → Run workflow**，填入不带 `v` 的版本号。共享工作流具体做什么，README 里有说明。发布之后，[vfox-plugins](https://github.com/version-fox/vfox-plugins) 里的 `plugins/java.json` 会显示 `vfox add java` 提供的是哪个版本。

文档里用“未发布”（英文是“Unreleased”）标记比最新发布版更新的内容。发布之后，把 [changes.md](changes.md) 里的这些条目移到新版本下面，并去掉这些标注，两种语言都要处理：`grep -rn -i -e unreleased -e 未发布 docs README*`。上一个发布版的版本号也要搜一遍：有几句话是拿它做对比的，没有写“未发布”。

## 编写文档

英文页面在 `docs/`，中文页面在 `docs/zh-CN/`，文件名相同；README 的中文版是根目录的 `README_CN.md`。每页开头有指向另一种语言的链接。引用 Foojay 数据的页面会写明数据取自哪一天。CI 不检查这些文档，所以你加的命令请自己跑一遍。
