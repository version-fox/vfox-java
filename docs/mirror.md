# GitHub mirror

[中文](zh-CN/mirror.md) | [English](mirror.md)

Foojay links the JDKs of most distributions to GitHub Releases, so `vfox install java@21-tem` downloads from `github.com`. If github.com is slow or unreachable where you are, set `VFOX_JAVA_GITHUB_MIRROR` and the plugin sends these downloads through a GitHub mirror.

The value is a URL prefix. The plugin puts it in front of the GitHub URL, and adds a `/` if the value does not end in one. For Temurin 21.0.8 on Linux x64:

| `VFOX_JAVA_GITHUB_MIRROR` | vfox downloads |
| --- | --- |
| not set | `https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.8%2B9/OpenJDK21U-jdk_x64_linux_hotspot_21.0.8_9.tar.gz` |
| `https://gh-proxy.org/` | `https://gh-proxy.org/https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.8%2B9/OpenJDK21U-jdk_x64_linux_hotspot_21.0.8_9.tar.gz` |

[gh-proxy](https://gh-proxy.org/) takes URLs in this form, and so does any service that takes the GitHub URL after its own address. The plugin does not run any of them and cannot vouch for them. The value must start with `http://` or `https://`. vfox takes any other address for a file on disk, so a download from GitHub stops with `VFOX_JAVA_GITHUB_MIRROR must start with http:// or https://` instead.

## Set it

In bash or zsh, for the current shell:

```bash
export VFOX_JAVA_GITHUB_MIRROR=https://gh-proxy.org/
```

Put the same line in `~/.bashrc` or `~/.zshrc` to keep it. In PowerShell:

```powershell
$env:VFOX_JAVA_GITHUB_MIRROR = "https://gh-proxy.org/"
```

To set it for every terminal opened afterwards:

```powershell
[Environment]::SetEnvironmentVariable('VFOX_JAVA_GITHUB_MIRROR', 'https://gh-proxy.org/', 'User')
```

Then install as usual, `vfox install java@21-tem`. To go back to github.com, unset the variable.

## What goes through the mirror

Only requests for `https://github.com/`: the downloads, and the checksum files on GitHub that the plugin reads for them (see [Notes](#notes)). A JDK on any other host downloads from there as before, and the requests to Foojay do not change.

Where Foojay links each distribution (2026-11-03):

| Short names | Download from |
| --- | --- |
| `tem`, `librca`, `sem`, `semcrt`, `sapmchn`, `kona`, `albba`, `mandrel`, `trava`, `adpt`, `adptj9`, `eliya`, `ojdkbld`, `gln`, `grl8`, `grl11`, `grl16`, `grl17`, `grl19` | GitHub |
| `graalce` | GitHub, except the monthly feature releases that `java@25-graalce` installs, which come from Oracle's GraalVM Download Service. `java@25.4.4.1-graalce` is the same file from GitHub |
| `nik` | GitHub for the newer releases, BellSoft's server for the older ones |
| `open` | jdk.java.net, except JDK 8 and most 11.x builds, which come from GitHub |
| `zulu`, `amzn`, `ms`, `oracle`, `graal`, `jb`, `bsg`, `opnlgc`, `rdht` | the vendor's server or a CDN, not GitHub |

Loongnix (`lnxabi1`, `lnxabi2`) downloads from ftp.loongnix.cn and is not mirrored.

To see where one release downloads from, ask Foojay for its package and read `direct_download_uri`. It is mirrored if it starts with `https://github.com/`. [foojay.md](foojay.md) has the queries for other platforms.

```bash
curl -s 'https://api.foojay.io/disco/v3.0/packages/jdks?distribution=temurin&version=21.0.8&architecture=amd64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz&directly_downloadable=true' \
  | jq -r '.result[0].links.pkg_info_uri' | xargs curl -s | jq -r '.result[0].direct_download_uri'
```

```
https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.8%2B9/OpenJDK21U-jdk_x64_linux_hotspot_21.0.8_9.tar.gz
```

## Notes

- vfox verifies a download against the checksum Foojay lists for it, see [foojay.md](foojay.md#checksums), so a mirror that serves a damaged or different file fails the install with `Checksum error`. Where the checksum is in Foojay's record (Temurin, Liberica, Zulu and others), the mirror has no say in it. Where it is in a file on GitHub (GraalVM Community's older releases, SAP Machine, Semeru, Tencent Kona and others), the file goes through the mirror like the archive, and a mirror that cannot be trusted could serve a matching pair. A package without a checksum (`WARNING: Checksum is not provided, skip verify...`) is not verified at all, so use a mirror you trust.
- The variable only changes where `vfox install` downloads a JDK from. `vfox add java` does not use it. For a proxy that covers all of vfox, see [Network](troubleshooting.md#network).
