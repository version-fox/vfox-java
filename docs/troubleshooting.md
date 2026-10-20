# Troubleshooting

[中文](zh-CN/troubleshooting.md) | [English](troubleshooting.md)

## Messages from the plugin

### `No JDK found for 21-bsg on darwin/arm64. Please check available versions with 'vfox search java'`

Foojay has no package for that release, distribution and flavour on this platform. The platform in the message is the one the plugin asked for, `linux/amd64`, `darwin/arm64`, `windows/arm64` and so on. Check three things:

- Whether the distribution has anything for the platform at all: [platforms.md](platforms.md).
- Whether the release exists: `vfox search java <distribution>` lists what the platform can install.
- Whether a distribution is missing from the spec. `java@17.0.17` means OpenJDK from jdk.java.net, which stops at 17.0.2. `java@17.0.17-tem` works, see [versions.md](versions.md#without-a-distribution).

`with JavaFX` or `without JavaFX` in the message means the release exists, but not in that flavour. See [javafx.md](javafx.md).

### `No version in tem; add one, such as 21-tem. Please check available versions with 'vfox search java tem'`

The spec holds a distribution and no version. `java@-tem`, `java@temurin-` and `java@zulu-fx` are the same case.

### `Could not extract a valid distribution: 21-foo`

Neither part of the spec is the name of a distribution. Names are lower case and come from the table in [distributions.md](distributions.md). Unreleased: release 0.6.2 ends here for the 13 distributions added after it, such as `java@21-opnlgc` and `java@21-openlogic`.

### `Unsupported distribution: foo`

The same for `vfox search java foo`.

### `Failed to fetch jdk info from foojay: ...`

The request to Foojay failed. After `status_code =>` comes the HTTP status, otherwise the network error. See [Network](#network) below. `Failed to fetch jdk info: ...` is the same for the second request, the one for the download link.

### `source file not found`

The download answered 404. Vendors take old builds down while Foojay keeps their records. Early-access builds are the common case (see [versions.md](versions.md#early-access-builds)). Pick a newer build. Red Hat's builds for anything but Linux x64 all end here, see [distributions.md](distributions.md#red-hat-build-of-openjdk-rdht).

### `java@21-tem is not installed`

`vfox use` and `vfox uninstall` only know what is installed. `vfox list java` shows it, with names that carry the build number: `21.0.8+9-tem`. `vfox uninstall` needs the whole name.

### Messages about the Java home on macOS

`Checking Java home layout...` is printed during every macOS install. If it is followed by `Failed to normalize Java home`, the archive did not have the layout the plugin expects: `Multiple Java homes found in <dir>`, `No Java home containing bin/java found in <dir>`, or `Cannot normalize Java home: destination already exists: <path>`. Please report it with the distribution and version.

### Loongnix

`Loongnix JDKs require linux/loong64`, `Foojay does not support loong64; use vfox search java loongnix`, `Choose a Loongnix ABI explicitly`, `No Loongnix JDK found for ...` and `No Loongnix JDK packages found` are explained in [loongnix.md](loongnix.md).

## Network

The plugin talks to Foojay for the lists, and vfox downloads the archive from the vendor's server, often GitHub Releases. The plugin has no mirror setting.

vfox's own proxy setting covers both the Foojay requests and the download:

```bash
vfox config proxy.enable true
vfox config proxy.url http://127.0.0.1:7890
```

While `proxy.enable` is `false`, the usual `HTTP_PROXY`, `HTTPS_PROXY` and `NO_PROXY` environment variables apply. Only `http` and `https` proxies are supported.

## Things that look wrong and are not

- **A release you expect is missing from `vfox search`.** vfox keeps the result for 12 hours. `vfox config cache.availableHookDuration 0` turns the cache off. Foojay itself may not have the release yet either.
- **`WARNING: Checksum is not provided, skip verify...` on every install.** The plugin does not pass a checksum to vfox, so the download is not verified, see [foojay.md](foojay.md#what-the-plugin-asks).
- **The installed name has a build number you did not type.** `java@21.0.8-tem` installs `21.0.8+9-tem`. The build is part of the name, see [versions.md](versions.md#installed-names).
- **`vfox install java@21-tem` and `vfox install java tem` do different things.** The second one is two SDKs, `java` and `tem`.
- **A `GRAALVM_HOME` you set is left alone.** The plugin sets `JAVA_HOME` and `PATH` only.
- **`vfox use java@21` selects `21.3.1-grl11`, which runs Java 11.** GraalVM CE 8 to 19 and Gluon GraalVM before 23 carry GraalVM's version numbers, and vfox matches a bare major against those, see [distributions.md](distributions.md#versions-numbered-after-graalvm). Write `java@21-tem`.

## Where the JDK is

`JAVA_HOME` is a link that `vfox use` points at the JDK you chose. For `--global` it is `~/.vfox/sdks/java`, for `--project` it is `.vfox/sdks/java` in the project, and for a session it is a directory under `~/.vfox/tmp`. An IDE or a build tool that should follow your global choice can point at the first. For a fixed JDK, `vfox info java@21.0.8+9-tem` prints a directory, and the JDK is the `java-21.0.8+9-tem` directory inside it. `~/.vfox` is the default `$VFOX_HOME`. When `VFOX_HOME` is set, the JDKs (`cache/`) and the plugins live there, while the `sdks/java` link and the session directories stay in `~/.vfox`. `storage.sdkPath` moves the JDKs too, see vfox's [configuration](https://vfox.dev/guides/configuration.html).

## Reporting a problem

Open an issue at [version-fox/vfox-java](https://github.com/version-fox/vfox-java/issues) with the output of `vfox --version` and `vfox info java`, the operating system and CPU, the command, and everything it printed. `vfox --debug <command>` prints more. Data that Foojay gets wrong belongs with [Foojay](https://github.com/foojayio/discoapi).
