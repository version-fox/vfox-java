# E2E

[中文](e2e.md) | [English](../e2e.md)

离线的 Lua 钩子测试（`tests/*_test.lua`）在 **Test Plugin** 工作流里运行。端到端套件在容器里针对真实的 vfox 运行，覆盖 Linux 和 Windows；每个 `vfox` x `distribution` 组合都有自己的一次性容器。CI 直接在标准 runner 上运行这套测试（Docker 加 `actions/setup-go` 提供的 Go）。本地则由仓库的开发容器在 Linux 上复现这一环境；Windows 上改用 Docker Compose runner 镜像，因为开发容器无法承载 Windows 容器镜像（见下文）。

## 开发容器

`.devcontainer/` 提供一个 Linux 开发环境，在四种宿主平台上都能用：

| 宿主 | 开发容器的运行方式 |
| --------------------- | ---------------------------------------------- |
| Linux amd64 / arm64 | 原生运行 |
| Windows amd64 / arm64 | Docker Desktop 的 Linux 容器模式（WSL 2） |

它带有 Go 1.27.1（CI 安装的版本）、Docker CLI、stylua、lua-language-server 和许可证工具，版本都与 `.github/workflows/lint.yml` 和 `license.yml` 里固定的一致，并挂载宿主的 Docker daemon socket。套件随后通过 testcontainers 连接这个 daemon（Docker-out-of-Docker），启动的目标容器和原生 CI runner 启动的完全相同；这里刻意不用 Docker-in-Docker，这样镜像缓存和网络都还是宿主的。镜像不需要工作区里的文件，所以构建上下文保持在 `.devcontainer/`；`postCreateCommand` 会预热 `tests/e2e` 的 Go 模块缓存，第一次运行测试时就不必停下来下载。

用任何支持 Dev Containers 规范的工具都可以打开它：在 VS Code/Cursor 里执行 **Dev Containers: Reopen in Container**，或者用 CLI：

```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . bash
```

`TESTCONTAINERS_RYUK_DISABLED=true` 是预先设好的：Ryuk 会在宿主 daemon 上发布一个端口，并等待套件回连，而 Docker-out-of-Docker 的容器做不到这一点。套件改为通过 `t.Cleanup` 显式终止每个容器；运行被强行中断后遗留的容器，名称都以 `vfox-java-e2e-` 开头，可以按这个前缀清理。使用 rootless Docker 的用户，请在打开容器之前先在宿主上 `export DOCKER_SOCK="$XDG_RUNTIME_DIR/docker.sock"`。在 Windows 宿主上，把检出的代码放在 WSL 2 里（例如 `\\wsl$` 下）能让文件和 bind mount 访问保持快速；放在 Windows 文件系统上也能用。

Windows 容器的覆盖（`tests/e2e/windows`）无法在开发容器里运行：Dev Containers 规范不支持 Windows 容器镜像（[vscode-remote-release#445](https://github.com/microsoft/vscode-remote-release/issues/445)），而且 Windows 容器只能跑在 Windows daemon 上。这套测试仍然使用 Windows 宿主上的 Docker Compose runner，见下面的 [Windows 11](#windows-11)。

## 套件验证什么

每个组合都运行同样的流程（每个组合一个长期存活的容器，由 Go 通过类似 `docker exec` 的调用来驱动）；目标镜像里没有 JDK，所以 `java` 只能来自 vfox 安装的东西：

1. 从指定的渠道安装 vfox，要么是最新发布版（`latest`），要么从源码构建（`main`），然后从当前检出的代码注册本地的 `java` 插件。在 Windows 上，runner 会在 `latest` 组合运行期间把 `main` 构建一次，`main` 的容器由 e2e 镜像加上这个 `vfox.exe` 启动。接着，`vfox info java` 打印的 Notes 要链接到 README，README 里列了各个简称，也写了怎样搜索某个发行版。以前的 Notes 只给了五个简称，没说怎样列出它们的版本（[vfox#390](https://github.com/version-fox/vfox/issues/390)）。
2. 只写发行版不写版本，无论单独写还是跟在空版本后面（`java@tem`、`java@-tem`），`vfox install` 和 `vfox use` 都应失败，并提示补上版本。以前，`java@tem` 会让钩子报 Lua 错误；`java@-tem` 则让 `PreInstall` 把空版本发给 Foojay，Foojay 列出所有版本，结果装上了最新的。没有任何发行版发布过的版本（`<大版本>.0.99`）应该安装失败，并且 `PreInstall` 要指出它搜索的平台（`linux/amd64`、`windows/arm64` 等），以此确认向 Foojay 查询的就是 runner 所在的平台。已固定版本里从未发布过的构建（`<版本>+99`，例如 `21.0.8+99-tem`）也一样，这证明查询保留了构建号：Foojay 会把没编码的 `+` 当成空格并丢掉构建号，于是会装上这个版本的最新构建。

   在 `tem` 这几行里，经过一个不存在的镜像安装也必须失败。设成 `VFOX_JAVA_GITHUB_MIRROR=https://invalid.example.invalid` 后，镜像会加在 Temurin 的 GitHub 地址前面，所以 `vfox install` 在下载时失败，错误信息里必须出现 vfox 请求的那个地址：镜像、一个斜杠，再加 GitHub 地址。以前插件不读这个变量，会从 github.com 下载 JDK，安装成功。这一步不下载任何东西，也不运行能正常工作的镜像。
3. 在 `graalce` 这一行里，Oracle GraalVM 只写大版本号的 `25-graal` 应该装 25.0 系列的最新构建（2026-10-20 是 `25.0.5-graal`），也就是 Oracle 官方 `25/latest` 下载跟的那个系列，而不是列在它前面的某个每月特性版本（比如 `25.4.4.1.1-graal`）。`vfox search java graal` 必须按 GraalVM 自己的版本号列出这些特性版本，25 的其他版本备注要一致，同第 5 条。从 2026 年 10 月起，Foojay 给特性版本标的是 JDK 的版本号，和 25.0 系列共用。插件以前按这个版本号命名，结果搜索里一个特性版本都没有，`25.0.4.1-graal` 也没有 LTS 备注，装上的却是 25.4.4.1.1。搜索列出的 25 的各构建会先被模拟成已安装，这样 `vfox install` 报出的就是 `PreInstall` 选中的那个，而且不会下载任何东西。GA 版本 25 不放进去，因为那样 vfox 会发现 `25-graal` 已安装，根本不会去问 `PreInstall`。在 Linux 上，安装向 Foojay 发的请求还必须和搜索的相同，同第 4 条末尾。

   装着这些构建时，`vfox use java@25-graal` 和写着 `java=25-graal` 的 `.sdkmanrc` 必须选中 `vfox install` 报出的那个构建。`PreUse` 和 `ParseLegacyFile` 以前选的是 25 里已安装的最新版本，所以一旦装了特性版本，选中的就是它（[#110](https://github.com/version-fox/vfox-java/issues/110)）。模拟出的每个构建里都放着一个只打印名字的替身 `java`，同第 6 条。把 25.0 系列的构建删掉之后，`vfox use` 和 `.sdkmanrc` 都必须选中最新的特性版本。
4. 在 `tem` 这几行里（这几行在每个 runner 上都会运行），只按名字检查的发行版（`adpt` 到 `semcrt`，即 `tests/e2e/common` 里的 `nameOnly`），只要 Foojay 在这个 runner 上有它的包，都要能用简称找到：`vfox search java <简称>` 能列出它；把它列出的最新版本模拟成已安装后，`vfox install java@<大版本>-<简称>`（`22-grl17`）要报告这个版本已经安装，所以不会下载任何东西。以前没有这些简称时，这两条命令分别报 `Unsupported distribution` 和 `Could not extract a valid distribution`。

   同样在这几行里，Mandrel 和 Liberica NIK 要按它们沿用的 GraalVM 版本号来（`tests/e2e/common` 里的 `ownNumbers`；Windows arm64 上两者都没有）：`vfox search java mandrel` 要列出 `23.1.12-mandrel`（Liberica NIK 是 `23.1.8-nik`）；把它和搜索结果里最新的 23.x 模拟成已安装后，`vfox install java@mandrel-23.1.12` 和 `vfox install java@23-mandrel` 要报告这两个版本已经安装。2026 年 10 月 Foojay 把这个版本号挪到了 `distribution_version`，插件改读它之前，搜索结果每个 Java 大版本只列一个名字，找不到 `23.1.12-mandrel`，`java@23-mandrel` 装上的是为 Java 23 构建的 Mandrel 24.1.2。

   在 Linux 上，这几行和第 3 条的 `graalce` 行经由一个冒充 api.foojay.io 的替身访问 Foojay（由 `tests/e2e/linux/front` 构建），替身记下插件发出的每个请求。上面每次安装发的请求都必须和它前面那次搜索的相同（`tests/e2e/common` 里的 `AsksAsSearch`）。Foojay 的结果按请求分别缓存，新版本发布后的半小时里，换一个请求就可能装上搜索还没列出的构建，于是真的下载，检查失败（见 [foojay.md](foojay.md#插件发出的请求)）。[#113](https://github.com/version-fox/vfox-java/issues/113) 之前，只写大版本号时查的是 `latest=available`，Mandrel 和 Liberica NIK 则按 `distribution_version` 查。
5. 固定的版本按 `PreInstall` 给它起的名字安装：请求的版本加上构建号（`21.0.8-tem` 安装为 `21.0.8+9-tem`）。`vfox search java <发行版>`（`Available` 钩子）把同一个名字列为已安装，带 JavaFX 的构建会标注 JavaFX。对 GraalVM，它还必须列出自 25.1 起每月发布的特性版本（`25.4.4.1.1-graalce`），这些版本都不标 LTS（Foojay 给其中一些标了，因为它们基于的 JDK 是 LTS）；每个版本大约只存在一个月。同一个大版本里的其他版本，备注必须一致。插件以前把特性版本 25.4.4.1.1 列成 `25.0.4.1-graalce`，没有 `25.0.2-graalce` 那样的 LTS 备注。在 Windows 上，列表里要包含 JetBrains Runtime 21.0.5，它在 Windows 上只有 tar.gz。
6. 在执行任何 `vfox use` 之前，`.sdkmanrc` 要能通过 `ParseLegacyFile` 选中 JDK。测试时，`vfox list java` 里排在最前面的是另一个版本的空安装（`21.0.80+1-tem`，它的版本号以固定的版本开头；vfox 按字符串降序给已安装版本排序）。以前 `ParseLegacyFile` 会把它当成第一个以该版本开头的版本，对补零的版本（见下面第二条），则当成该大版本里最新的版本。要覆盖的写法有：
   - 不含构建号的 SDKMAN 标识符：`java=21.0.8-tem`、`java=21.0.5-jbr`（SDKMAN 对 JetBrains 的叫法）、`java=25.0.4.fx-librca`（它对 JavaFX 构建的写法）。
   - 补零的标识符，`sdk list java` 里有很多这样的：`java=21.0.8.0+9-tem`、`java=25.0.4.0-fx+9-librca`（Foojay 以及安装后的版本名里没有这个零）。
   - 安装后的版本名：`java=21.0.8+9-tem`。
   - EA 构建的标识符。固定大版本的 EA 构建，如果按 `sdk list java` 里 OpenJDK 的写法来写（`28.0.0.0+ea.20-open`），必须选中那个 EA 构建：`java=21.0.0.0+ea.1-tem` 要选中 `21-ea+1-tem`，不能选中 GA 版本。`ParseLegacyFile` 只认 SDKMAN 较旧的 `21.ea.1-tem` 写法时，选中的正是 GA 版本。安装后的版本名本身（`java=21-ea+1-tem`）也要能选中：`ParseLegacyFile` 以前解析不了它，什么也没选中，而 `vfox use` 是能选中的。

   jdk.java.net 会在几周内撤掉每个 EA 构建，所以这个安装是模拟出来的：它的 `bin` 里放着一个只打印名字的替身 `java`。在 Windows 上，文件用 CRLF 换行写入。

   接着，在 `tem` 这几行里，`.sdkmanrc` 里写的是 SDKMAN 给 Mandrel 和 Liberica NIK 的、`.r` 后面带 JDK 版本的标识符时，要选中标识符指明的版本：`java=25.0.4.r25-nik` 选中 `25.0.4-nik`，而不是 `25.0.4.1-nik`。`ParseLegacyFile` 以前把 `25.0.4.r25` 当成版本号，选中的正是后者。`java=22.1.r11-mandrel` 则什么都不能选中，因为插件只装 Mandrel 22.1 的 JDK 17 构建（`tests/e2e/common` 里的 `OwnNumberIdentifiers`）。标识符指明的版本，以及同一大版本里更新的一个版本，也是这样模拟安装的。
7. `vfox use --global` 之后，`PATH` 上的 JDK 要报告请求的 `java.version`、runner 的 `os.arch`（`amd64` / `aarch64`，这也能抓出在 Windows ARM64 上模拟运行的 x64 JDK）和这个发行版的 `java.vendor`。`JAVA_HOME` 指向同一个 JDK，`javac` 能编译一个程序，`java` 能运行它，模块列表恰好在 `-fx` 构建里含有 JavaFX，`vfox current java` 报告已安装的版本。事先设置的 `GRAALVM_HOME` 保持原值，因为用户会把它指向自己的 GraalVM；对 GraalVM，插件以前会把它替换成正在使用的 JDK。
8. `PreUse` 把用户输入的各种写法映射到已安装的版本，不需要再次下载：只写大版本号（`java@21`，交给 vfox 核心做模糊匹配）、安装时用的写法（`java@21.0.8-tem`，`PreUse` 会在已安装的版本里找到它的构建号），以及 asdf 风格的 `<长名>-<版本>[-fx]`（`java@temurin-21.0.8+9` 改写成 `21.0.8+9-tem`；`java@openjdk-25.0.2+10` 改写成 `25.0.2+10`）。SDKMAN 那样补零的版本也一样（`java@21.0.8.0-tem`、`java@21.0.8.0+9-tem`），`vfox install` 必须先发现它们已经安装：`PreInstall` 把零原样交给了 Foojay，Foojay 会去掉它，而 `PreUse` 以前去找以补零版本开头的已安装版本，报告说没有安装。

默认矩阵对每个发行版都跑两个 vfox 渠道（`latest`、`main`）：

| 发行版 | 版本 | 覆盖内容 | amd64 | arm64 |
| ------------ | ------- | ---------------------------------------------------------------------------- | ----- | ----- |
| `open` | 25.0.2 | 默认发行版，版本不带后缀 | ✓ | |
| `tem` | 21.0.8 | 常规路径（Linux 上是 tar.gz，Windows 上是 zip）；第 2、4、6 条里的镜像检查、按名字和按版本号的检查 | ✓ | ✓ |
| `librca-fx` | 25.0.4 | 带 JavaFX 的构建（`-fx`） | ✓ | ✓ |
| `jb` | 21.0.5 | Windows 上走 tar.gz 的路径，那里没有 zip | ✓ | ✓ |
| `graalce` | 25.0.2 | 事先设置的 `GRAALVM_HOME` 保持原值；Oracle GraalVM 的 `25-graal` | ✓ | |

表里每一行固定的版本，在这一行要跑的每个平台上，Foojay 都有对应的包。OpenJDK 和 GraalVM 社区版没有 `windows-aarch64` 构建，所以 arm64 不管在 Linux 还是 Windows 上，都只跑另外三个。

## 环境变量

| 变量 | 默认值 | 含义 |
| -------------------- | -------------------------- | ----------------------------------------------------------------------- |
| `VFOX_VERSION` | `latest main` | 用空格分隔的 vfox 渠道（`latest`、`main`） |
| `DISTRIBUTION` | 见上面的矩阵 | 用空格分隔的插件发行版，JavaFX 加 `-fx`（`tem zulu-fx`） |
| `JAVA_VERSION` | 按发行版而定 | 为每个选中的发行版安装的版本（Java 9+ 的编号方式） |
| `E2E_MAX_JOBS` | `3`（Linux），`2`（Windows） | 每台宿主并行的容器数 |
| `E2E_RETRY_ATTEMPTS` | `3` | 每个涉及网络的 exec 的尝试次数（线性退避 10 秒） |

`JAVA_VERSION` 必须是 `java.version` 原样报告的版本（例如 `21.0.8`，而不是 Java 8 的 `1.8.0_462` 写法）。默认矩阵之外的发行版仍会运行所有检查，只是跳过 `java.vendor` 断言和 asdf 风格的 `PreUse` 写法，这两项要用到的数据只为默认的几个发行版保存（`tests/e2e/common`）。

## Linux（Ubuntu 26.04）

在开发容器里，从仓库根目录执行：

```bash
cd tests/e2e
go test -v -timeout 55m -run TestE2E ./linux
```

迭代时可以用环境变量缩小范围：

```bash
VFOX_VERSION=latest DISTRIBUTION=tem E2E_MAX_JOBS=1 go test -v -timeout 55m -run TestE2E ./linux
```

在原生宿主上，同一条命令也能用，只需要两个前提：Docker Engine（rootful 或 rootless）和 Go 1.27.1，CI 里装的就是这两样。使用 rootless Docker 的用户要把 Docker 客户端指向自己的 socket（`export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"`）；开发容器挂载的 socket 已经替你处理了这种情况。

## Windows 11

Windows 容器无法跨架构模拟，所以 ARM64 套件需要 ARM64 宿主（Copilot+ PC 或 `windows-11-arm` CI runner）。

这套测试没有开发容器，因为 Dev Containers 规范拒绝 Windows 容器镜像（见[开发容器](#开发容器)），所以它仍使用 Docker Compose runner。runner 镜像（`Dockerfile-runner`：标准的 servercore 加固定版本的 Go，它同时用来构建 vfox `main`）通过挂载的命名管道驱动宿主 daemon；对宿主的要求是 Windows 容器模式的 Docker，加上 Compose v5 插件（每台机器安装一次，见下文）。Go 从不接触宿主，所以不会与 vfox 管理的工具链冲突。

`windows-11-arm` runner 没有 Windows Hypervisor Platform 功能，所以无法使用 Hyper-V 隔离；进程隔离只需要 Containers 功能。

CI 跳过了 runner 镜像：在 `windows-11-arm` 上解压它里面的 Go 就花了两分半，而 `actions/setup-go` 已经提供了同样的 Go。CI 直接在 runner 上运行 `go test ./windows`，设置 `E2E_MAX_JOBS=3`。运行之前，`use-local-disk.ps1` 先把 Docker 的数据根目录、Go 的缓存和临时目录，从 runner 上网络挂载的 C: 盘挪到本地磁盘：`windows-latest` 用 D:，`windows-11-arm` 用未格式化的 NVMe 磁盘（脚本会先把它格式化）。镜像层和容器文件是一个个文件写入的，所以在 C: 上，光拉取 servercore 就花了五分钟。这个脚本只允许在 GitHub Actions 里运行。

每个组合运行时，`VFOX_HOME` 都设为带空格的路径（`C:\Users\John Doe\.vfox`），以复现 [vfox-flutter#33](https://github.com/version-fox/vfox-flutter/issues/33)。vfox 从 1.0.13 起支持这样的路径（[vfox#712](https://github.com/version-fox/vfox/pull/712)），所以 `latest` 发布版和 `main` 都在这个路径下运行。

### x64

下面所有命令都在 PowerShell 7 中运行。如果还没有安装，请先装上（这一条引导命令可以在自带的 Windows PowerShell 里运行）：

```powershell
winget install --id Microsoft.PowerShell --source winget --exact
```

1. 在 PowerShell 7 中执行：

```powershell
winget install --id Git.Git --source winget --exact
# 按需配置 Git。

curl.exe -fsSL `
    "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1" `
    -o ./install-docker-ce.ps1
```

2. 以管理员身份在 PowerShell 7 中执行：

```powershell
./install-docker-ce.ps1
```

3. 在 PowerShell 7 中执行：

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.docker\cli-plugins" | Out-Null

curl.exe -fsSL `
    "https://github.com/docker/compose/releases/download/v5.5.1/docker-compose-windows-x86_64.exe" `
    -o "$env:USERPROFILE\.docker\cli-plugins\docker-compose.exe"

git clone git@github.com:version-fox/vfox-java.git
cd ./vfox-java/
docker compose -f tests/e2e/windows/compose.amd64.yaml run --rm --build e2e
```

### arm64

下面所有命令都在 PowerShell 7 中运行。如果还没有安装，请先装上（这一条引导命令可以在自带的 Windows PowerShell 里运行）：

```powershell
winget install --id Microsoft.PowerShell --source winget --exact
```

1. 在 PowerShell 7 中执行：

```powershell
winget install --id Git.Git --source winget --exact
# 按需配置 Git。
winget install --id GoLang.Go --source winget --exact
git clone git@github.com:version-fox/vfox-java.git
cd ./vfox-java/
pwsh -NoProfile -File .\tests\e2e\windows\install-docker-arm64.ps1
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.docker\cli-plugins" | Out-Null

curl.exe -fsSL `
    "https://github.com/docker/compose/releases/download/v5.5.1/docker-compose-windows-aarch64.exe" `
    -o "$env:USERPROFILE\.docker\cli-plugins\docker-compose.exe"

docker compose -f tests/e2e/windows/compose.arm64.yaml run --rm --build e2e
```

在 arm64 上，构建 Docker 引擎也要用 Go，所以 `install-docker-arm64.ps1` 要在套件之前运行；之后 compose runner 镜像自带固定版本的 Go 来跑测试，宿主上的 Go 不会再被用到。这个脚本会复用它之前构建过的、版本符合的引擎；CI 从以这个脚本为键的缓存里恢复一个。想缩小运行范围，在 compose 命令前加上 `$env:VFOX_VERSION = 'latest'; $env:DISTRIBUTION = 'tem'`，和其他平台一样。

## 本地检查

在开发容器里执行，下面所有工具都已预装，版本和工作流使用的一致；也可以在宿主上装好同样的工具。

```bash
# Lua 和 Go 检查（.github/workflows/lint.yml）。
cd tests/e2e
go test -short ./...
test -z "$(gofmt -l .)"
go vet ./...
cd ../..

stylua --check .
lua-language-server --check . --checklevel=Warning
```

```bash
# 离线的钩子测试（.github/workflows/test.yml）。
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/pre_install_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/pre_use_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/parse_legacy_file_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/loongnix_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/github_mirror_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/post_install_test.lua
```

```bash
# 许可证头（.github/workflows/license.yml）。
license-eye header check
license-eye header fix
addlicense -check -f .license.tpl tests/e2e/windows/*.ps1
addlicense -f .license.tpl tests/e2e/windows/*.ps1
```

在只有 Docker 的宿主上，许可证检查改用容器运行（和 CI 用的镜像相同）：

```bash
docker run --rm -v "$PWD:/work" -w /work apache/skywalking-eyes:0.9.0 header check
docker run --rm -v "$PWD:/work" -w /work apache/skywalking-eyes:0.9.0 header fix
docker run --rm -v "$PWD:/src" ghcr.io/google/addlicense:v1.2.0 -check -f .license.tpl tests/e2e/windows/*.ps1
docker run --rm -v "$PWD:/src" ghcr.io/google/addlicense:v1.2.0 -f .license.tpl tests/e2e/windows/*.ps1
```
