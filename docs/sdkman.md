# SDKMAN and vfox

[中文](zh-CN/sdkman.md) | [English](sdkman.md)

[SDKMAN](https://sdkman.io/) installs JDKs and switches between them with `sdk install java` and `sdk use java`. With this plugin vfox does the same. It follows SDKMAN's short names and reads its `.sdkmanrc`, so much of what you know from SDKMAN carries over. This page says when to use the plugin, puts the commands side by side and lists what differs.

## When to use it

- **You work in Windows PowerShell.** SDKMAN is a set of bash scripts. Its [installation page](https://sdkman.io/install) says that it requires a bash environment and cannot be installed natively on Windows: it runs in WSL, or in Git Bash with MinGW. That leaves out PowerShell, including the Windows PowerShell 5.1 that comes with Windows, and cmd. vfox is a native Windows program with a hook for PowerShell, so `vfox install java@21-tem` and `vfox use` work there without WSL or Git Bash. This is where the plugin takes SDKMAN's place.
- **Your shell is not Bash or Zsh.** SDKMAN supports those two. vfox hooks into Bash, Zsh, Fish, PowerShell, Nushell and Clink, see its [quick start](https://vfox.dev/guides/quick-start.html).
- **A team or a set of scripts spans systems.** The commands are the same on Linux, macOS and Windows. A project's `.sdkmanrc` is read through the plugin, so developers on SDKMAN and developers on vfox can share it, see [sdkmanrc.md](sdkmanrc.md).
- **You manage more than JDKs.** vfox has plugins for Maven, Gradle, Groovy, Kotlin, Scala, Node.js, Go and many other tools behind the same commands (`vfox available`).

If you work in Bash or Zsh on Linux or macOS and SDKMAN does what you need, there is no reason to change.

## Commands side by side

The examples use Temurin 21.0.8. Both tools have to be hooked into the shell first: SDKMAN by sourcing `sdkman-init.sh`, vfox by `vfox activate`, see its [quick start](https://vfox.dev/guides/quick-start.html). The vfox commands are the same in every shell it hooks into.

| | SDKMAN | vfox |
| --- | --- | --- |
| Install | `sdk install java 21.0.8-tem` | `vfox install java@21.0.8-tem` |
| List what can be installed | `sdk list java` | `vfox search java tem`, `vfox search java all` for every distribution |
| List what is installed | `sdk list java` marks them | `vfox list java` |
| Use in the current shell only | `sdk use java 21.0.8-tem` | `vfox use java@21.0.8-tem` |
| Use in every new shell | `sdk default java 21.0.8-tem` | `vfox use --global java@21.0.8-tem` |
| Pin a project | `sdk env init` writes a `.sdkmanrc` with the JDK in use | `vfox use --project java@21.0.8-tem` writes a `.vfox.toml` |
| Switch to the project's JDK | `sdk env`, or on every `cd` with `sdkman_auto_env=true` | automatic, by the hook, on entering the directory |
| Install the project's JDKs | `sdk env install` | `vfox install --all` for a `.vfox.toml`, nothing for a `.sdkmanrc` |
| Show the JDK in use | `sdk current java` | `vfox current java` |
| Show where a JDK is | `sdk home java 21.0.8-tem` | `vfox info java@21.0.8+9-tem` |
| Uninstall | `sdk uninstall java 21.0.8-tem` | `vfox uninstall java@21.0.8+9-tem` |
| See which JDKs are outdated | `sdk upgrade java` | none, compare `vfox list java` with `vfox search java tem` |
| Update the tool | `sdk selfupdate` | `vfox upgrade`, and `vfox update java` for this plugin |
| Show the version of the tool | `sdk version` | `vfox --version` |

The scopes of `vfox use` correspond to SDKMAN's: `--session`, the default, to `sdk use`, `--global` to `sdk default` and `--project` to a `.sdkmanrc`. Without vfox's hook, `vfox use` stops on Linux and macOS and falls back to the global scope on Windows, see [versions.md](versions.md#using).

## What differs

- **Identifiers.** SDKMAN's `21.0.8-tem` goes after `java@` as it is, and the short names are SDKMAN's, with a few exceptions such as `jb`, which SDKMAN calls `jbr`, see [distributions.md](distributions.md#short-names-and-sdkman). A release padded with a zero, as in SDKMAN's current identifiers (`25.0.5.0+8-tem`), is accepted. JavaFX is `-fx` at the end, `21.0.12-zulu-fx`. SDKMAN's `21.0.12.fx-zulu` is not a spec that `vfox install` takes, though a `.sdkmanrc` can hold it, see [sdkmanrc.md](sdkmanrc.md#sdkmans-spellings).
- **A bare major.** `vfox install java@21-tem` installs the newest Temurin 21, `21.0.13+9-tem` on 2026-11-10. SDKMAN's `21-tem` is one release, the GA build `21+35`.
- **No default JDK.** `sdk install java` installs SDKMAN's default, a Temurin LTS release (`25.0.5.0+8-tem` on 2026-11-10). `vfox install java` has none: in a terminal it asks you to pick a version, in a script it fails. A version without a distribution (`java@21`) is OpenJDK from jdk.java.net, which has nothing newer than 21.0.2 for 21. Write `java@21-tem`, see [versions.md](versions.md#without-a-distribution).
- **Installing does not select.** After `sdk install`, SDKMAN asks whether the JDK becomes the default. `vfox install` only installs, and `vfox use` selects.
- **Two lists.** `sdk list java` shows every vendor's JDKs. `vfox search java` lists OpenJDK only, so name a distribution (`vfox search java tem`) or write `all`. `vfox list java` shows what is installed. The versions come from [Foojay](foojay.md).
- **Installed names carry the build number.** `vfox list java` shows `21.0.8+9-tem`, which `vfox uninstall` and `vfox info` need in full, while `vfox use java@21.0.8-tem` finds it without the build, see [versions.md](versions.md#installed-names).
- **A `.sdkmanrc` only selects.** `sdk env install` installs the JDKs it names. The plugin selects among the installed ones, see [sdkmanrc.md](sdkmanrc.md#differences-from-sdkman).
- **Where the JDKs are.** SDKMAN keeps them in `~/.sdkman/candidates/java/<identifier>`. vfox keeps them in `~/.vfox/cache/java/v-<name>/java-<name>` and makes `JAVA_HOME` a link to the one you chose. `vfox info` prints the directory that holds `java-<name>`. IntelliJ IDEA finds the JDKs of SDKMAN by itself but lists only the JDK in use of vfox, see [troubleshooting.md](troubleshooting.md#where-the-jdk-is).
