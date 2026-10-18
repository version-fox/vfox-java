# Development

[中文](zh-CN/development.md) | [English](development.md)

## Layout

```
metadata.lua                    plugin name, version, and .sdkmanrc as a legacy file
hooks/available.lua             vfox search
hooks/pre_install.lua           vfox install: choose the package and name the install
hooks/post_install.lua          macOS: move the Java home to the install root
hooks/env_keys.lua              JAVA_HOME and PATH
hooks/pre_use.lua               vfox use: map what was typed to an installed name
hooks/parse_legacy_file.lua     .sdkmanrc
lib/distribution_version.lua    distribution names, parsing of specs, GraalVM feature releases
lib/foojay.lua                  the Foojay request
lib/installed_version.lua       matching against installed names
lib/loongnix.lua                the Loongnix archive
tests/*_test.lua                offline hook tests
tests/fixtures/loongnix/        a saved copy of the Loongnix archive listing
tests/e2e/                      container tests, see e2e.md
Injection.lua                   type hints for what vfox injects, never loaded
```

vfox loads `metadata.lua`, calls a hook when a command needs it, and puts `PLUGIN` and `RUNTIME` (`osType`, `archType`, `version`) in scope. `osType` and `archType` are Go's `GOOS` and `GOARCH` of the vfox binary.

## What runs for a command

| You run | Hooks |
| --- | --- |
| `vfox search java tem` | `Available` |
| `vfox install java@21-tem` | `PreInstall` returns the URL and the name. vfox downloads and unpacks, then calls `PostInstall` |
| `vfox use java@21-tem` | `PreUse` returns the installed name to select. `EnvKeys` provides the variables |
| a shell hook, `cd` into a directory with `.sdkmanrc` | `ParseLegacyFile` |
| `vfox uninstall java@21.0.8+9-tem` | none, the name has to be exact |

A few contracts that cost time to find:

- `PreInstall` returns `url`, `version` and `note`. `version` becomes the name of the install, which is why it carries the build number. The package's checksum is not passed on yet (`TODO: checksum` in `hooks/pre_install.lua`), and vfox prints a warning for that.
- `PreUse` returns a table or `nil`. For a bare major it returns `nil` so that vfox matches it itself. vfox 1.0.13 and later reject a bare string such as `""`.
- `ParseLegacyFile` calls `ctx.getInstalledVersions()` with no argument. vfox 1.x binds it as a Go `func() []string` and rejects the extra argument that `ctx:getInstalledVersions()` adds. vfox ignores errors from this hook, so the failure is silent.
- vfox hands over the installed versions sorted as strings, descending: `21.0.8+9-tem`, `21.0.12+8-tem`, `21.0.1+12-tem`. The first one that starts with a release is not the right one, so `lib/installed_version.lua` compares numbers one by one.
- `EnvKeys` sets no `GRAALVM_HOME`. Users point it at a GraalVM of their own.

## Names

Installed names are `<java_version>[-<short name>][-fx]`, with no short name for OpenJDK ([versions.md](versions.md#installed-names)). `lib/distribution_version.lua` reads a spec into a version, a distribution and the JavaFX flag, in either order (`21-tem`, `tem-21`). `lib/installed_version.lua` turns a version the user typed into an installed name: the name itself first. A bare major then takes the newest installed release of it, and any other version takes the release itself or its newest build. `PreUse` stops there. `ParseLegacyFile` goes one step further and falls back to the newest installed release of the major.

SDKMAN spells some things differently (`jbr`, `21.0.12.fx-zulu`, `21.0.12-fx+1.1-librca`, `28.0.0+ea.19-open`), and `plugin_spelling` in `hooks/parse_legacy_file.lua` rewrites them into the plugin's before parsing. `installed_version.unpad` drops the zeros SDKMAN pads releases with (`27.0.0+36` is `27+36`). The plugin's short names are SDKMAN's, except `jb`.

## Foojay

- A `+` in a query has to be percent-encoded. Foojay reads a bare one as a space and drops the build, so `21.0.5+63130` would match every 21.0.5 build.
- `version=21` is the GA build `21+35`. A bare major adds `latest=available` to get the newest 21.x.
- Windows asks for `zip` and `tar.gz` in one request. JetBrains Runtime ships Windows zips for its newer builds only. `PreInstall` takes the zip when a version has both.
- `Available` lists a name once where Foojay has two records for it.
- Foojay marks GraalVM's monthly feature releases (`25.1.3` and on) as LTS. `is_feature_release` in `lib/distribution_version.lua` recognises them, by the minor number, and `Available` drops the note. It is for `graal` and `graalce` only: Mandrel and Liberica NIK numbered their releases after themselves up to 24 (`mandrel` `23.1.12` is LTS) and follow the JDK from 25 on.
- For a bare major of Oracle GraalVM (`graal`) only, `PreInstall` skips the feature releases, so the 25.0 line is installed. A major that has nothing but feature releases keeps them. GraalVM Community is not filtered, because its feature releases are what it still ships.
- The CPU names are `arm64` to `aarch64`, and on Windows `amd64` to `x64`. `darwin` becomes `macos`. On Linux `ldd --version` decides between glibc and musl.

## Tests

The hook tests run offline under `gopher-lua`, the Lua interpreter vfox embeds:

```bash
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/pre_install_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/pre_use_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/parse_legacy_file_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/loongnix_test.lua
go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/post_install_test.lua
```

Run them from the repository root. All five load `tests/support.lua`, which stubs `vfox.strings`, and `tests/pre_install_test.lua` and `tests/loongnix_test.lua` stub `http` and `json` themselves. `tests/pre_install_test.lua` keeps Foojay's answers in a table at the top, keyed by `<distribution> [<version>] [<latest>]`, with `windows` in front for Windows. Add the answer a new case needs there, and note the day you observed it. Lint, license headers and the container tests are in [e2e.md](e2e.md#local-checks).

To call a single hook against the real Foojay, vfox 1.0.13 and later has `vfox plugin run`. It does not register the plugin, and `--os` and `--arch` answer for another platform:

```bash
vfox plugin run . Available --input '{"args":["tem"]}' --json
vfox plugin run . PreInstall --input '{"version":"21-tem"}' --os windows --arch arm64 --json
vfox plugin run . ParseLegacyFile --input '{"filename":".sdkmanrc","filepath":"/tmp/p/.sdkmanrc","installedVersions":["21.0.8+9-tem"]}' --json
```

`vfox --debug <command>` shows what vfox does with a hook, which is how to find an error it swallows.

## Adding a distribution

1. Find its id in Foojay ([foojay.md](foojay.md)), and check that it has packages for the platforms you care about.
2. Add `["<short name>"] = "<foojay id>"` to `short_name` in `lib/distribution_version.lua`. Use SDKMAN's identifier when SDKMAN has the distribution. If SDKMAN spells it differently, map it in `plugin_spelling` in `hooks/parse_legacy_file.lua`.
3. If its version numbers or its LTS marks need special care, as GraalVM's do, handle that in `hooks/available.lua` and `hooks/pre_install.lua`.
4. Add a case to `tests/pre_install_test.lua`.
5. Update the tables in `README.md`, [distributions.md](distributions.md) and [platforms.md](platforms.md), and their translations in `README_CN.md` and `docs/zh-CN`.
6. For a new code path, also add it to the e2e matrix ([e2e.md](e2e.md)). Distributions outside the matrix still run every check except the `java.vendor` assertion and the asdf-style `PreUse` spelling.

## Refreshing the platform table

[platforms.md](platforms.md) was taken from Foojay. This prints, for each platform, which distributions have a build there, in 8 requests:

```bash
base='https://api.foojay.io/disco/v3.0/packages/jdks?directly_downloadable=true&latest=per_distro'
while read -r name query; do
  printf '%-14s ' "$name"
  curl -s "$base&$query" | jq -r '.result[].distribution' | sort -u | tr '\n' ' '; echo
done <<'EOF'
linux-x64 architecture=amd64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz
linux-arm64 architecture=aarch64&operating_system=linux&lib_c_type=glibc&archive_type=tar.gz
alpine-x64 architecture=amd64&operating_system=linux&lib_c_type=musl&archive_type=tar.gz
alpine-arm64 architecture=aarch64&operating_system=linux&lib_c_type=musl&archive_type=tar.gz
macos-intel architecture=amd64&operating_system=macos&archive_type=tar.gz
macos-arm64 architecture=aarch64&operating_system=macos&archive_type=tar.gz
windows-x64 architecture=x64&operating_system=windows&archive_type=zip&archive_type=tar.gz
windows-arm64 architecture=aarch64&operating_system=windows&archive_type=zip&archive_type=tar.gz
EOF
```

The ids are Foojay's (`oracle_open_jdk` is `open`). The notes under "Only some releases" need one query per distribution and platform without `latest`, grouped by `major_version`.

## Known gaps

- Downloads are not verified, see above.
- `vfox search` lists GA releases only. Early-access builds install by name.
- Foojay distributions without a short name ([distributions.md](distributions.md#foojay-distributions-the-plugin-does-not-offer)), and JRE packages, are not offered.
- Only Linux loong64 has a source besides Foojay.

## Releasing

A maintainer runs **Actions → Plugin → Run workflow** on the default branch with the version, without `v`. The README describes what the shared workflow does. Afterwards `plugins/java.json` in [vfox-plugins](https://github.com/version-fox/vfox-plugins) shows the version that `vfox add java` serves.

The documentation marks what is newer than the last release with "Unreleased" ("未发布" in Chinese). After a release, move those entries in [changes.md](changes.md) under the new version and take the remarks out, in both languages: `grep -rn -i -e unreleased -e 未发布 docs README*`. Also search for the number of the previous release: a few sentences compare against it without saying "Unreleased".

## Writing the docs

English pages are in `docs/`, the Chinese ones in `docs/zh-CN/` under the same names (the Chinese README is `README_CN.md`), and each page starts with a link to the other language. Pages that quote Foojay give the day the data was taken. Nothing in CI checks them, so run the commands you add.
