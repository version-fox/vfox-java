# `.sdkmanrc`

[中文](zh-CN/sdkmanrc.md) | [English](sdkmanrc.md)

vfox can read `.sdkmanrc`, the project file of [SDKMAN](https://sdkman.io/), through this plugin (the plugin lists it in `PLUGIN.legacyFilenames`). A project that already pins its JDK for SDKMAN needs no second file for vfox:

```
# .sdkmanrc
java=21.0.8-tem
```

Only the `java=` line is read. Other lines, such as `maven=3.9.9`, are not this plugin's business.

## Using it

```bash
eval "$(vfox activate bash)"       # once, in ~/.bashrc; other shells: see vfox's quick start

vfox install java@21.0.8-tem       # .sdkmanrc never installs anything
cd my-project                      # holds the .sdkmanrc above
java -version                      # Temurin 21.0.8
```

vfox's shell hook reads the file when you enter the directory and selects the JDK it names. `vfox use` is not needed. The hook is vfox's own, see its [quick start](https://vfox.dev/guides/quick-start.html) for zsh, fish, PowerShell and the others.

- The file is read from the current directory only. In a subdirectory of the project it is not found, as with SDKMAN's `sdk env`.
- A `.vfox.toml` in the same directory that names `java` wins over `.sdkmanrc`. `vfox use --project` writes one.
- In that directory the file also outranks a `vfox use` without `--project`: the next prompt switches back, while `vfox current java` still names the session's choice.
- vfox creates `.vfox/sdks/java` in that directory and does not add `.vfox/` to `.gitignore`, so `git status` lists it. Ignore it yourself.
- The JDK has to be installed already. When nothing installed matches, the file is ignored and no message is printed. `vfox list java` shows what there is.
- `vfox config legacyVersionFile.enable false` turns all legacy files off. `legacyVersionFile.strategy` has no effect on this plugin: the version in the file is what counts.

## What an identifier selects

The plugin matches the identifier against the JDKs that are installed, in this order:

1. An installed name written as it is: `java=21.0.8+9-tem`, `java=28-ea+19`.
2. The release you named, with its newest installed build: `21.0.8-tem` selects `21.0.8+9-tem`.
3. Failing that, the newest installed release of the same major. `21-tem` goes straight to this step.

Step 3 does not check that the release is at least the one named. With only `21.0.8+9-tem` installed, `java=21.0.12-tem` selects it, and so does `java=21.0.3-tem`. A build number that is not installed falls back to the newest installed build of the release (`21.0.8+7-tem` selects `21.0.8+9-tem`). If the major is not installed at all, nothing is selected.

It never crosses to another distribution, between a JavaFX build and a plain one, or between an early-access build and a release.

## SDKMAN's spellings

`sdk list java` shows two generations of identifiers side by side. The plugin reads both, and its own names:

| In `.sdkmanrc` | Selects |
| --- | --- |
| `21.0.8-tem` | Temurin 21.0.8, installed as `21.0.8+9-tem` |
| `21.0.5-jbr` | JetBrains Runtime (`jb`), which SDKMAN calls `jbr` |
| `21.0.12.fx-zulu` | Zulu with JavaFX, `21.0.12+8-zulu-fx` (older spelling) |
| `21.0.12-fx+1.1-librca` | Liberica with JavaFX (newer spelling) |
| `21.0.8+1.1-tem` | Temurin 21.0.8, see below |
| `27.0.0+36-librca`, `25.0.1.0+8-open` | `27+36-librca`, `25.0.1+8`: the zeros are dropped |
| `28.ea.19-open`, `28.0.0+ea.19-open` | the early-access build `28-ea+19` |

The number after `+` in SDKMAN's newer identifiers (`21.0.8+1.1-tem`) counts SDKMAN's own rebuilds. It is not a build number of the vendor, so the plugin does not look for one and takes the release. Foojay, and so the installed name, has no zero padding, which is why `27.0.0` means the release `27`. A `.0` padding in `sdk list java` is common (`25.0.1.0+8-open`, `21.0.9.0+116386-jbr`), and the plugin reads it as well.

## Not finding it

If the JDK does not switch:

- The shell hook is not active. `eval "$(vfox activate bash)"` has to run in the shell, not only once somewhere else.
- The shell is in a subdirectory of the one with the file.
- The JDK is not installed, or only another flavour of it is. `java=21.0.8-zulu` does not select a JavaFX build, and `java=21.0.8.fx-zulu` does not select a plain one. Install the one the file names, for example `vfox install java@21.0.8-zulu-fx`.
- A `.vfox.toml` is in the way, or `legacyVersionFile.enable` is `false`.

`vfox --debug env -s bash` prints how the file was parsed.

## Differences from SDKMAN

`sdk env install` installs the JDKs a `.sdkmanrc` names. vfox only selects among what is installed, and you install with `vfox install java@<version>`. An identifier copied from the file is not always a spec that `vfox install` takes: `21.0.8-tem` is, `21.0.12.fx-zulu` is not, and `21.0.12-zulu-fx` is.
