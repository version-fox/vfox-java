# Install from source

[中文](zh-CN/install-from-source.md) | [English](install-from-source.md)

`vfox add java` installs the latest release. `main` has fixes that are not in it yet ([changes.md](changes.md)), and a change you are working on is not in any release. A plugin is a `metadata.lua` plus the `hooks` and `lib` directories, and vfox adds one from a zip of them.

## Ubuntu 26.04

Execute in Bash,

```bash
sudo apt install --assume-yes git zip
git clone --depth 1 https://github.com/version-fox/vfox-java.git
cd ./vfox-java/
zip -qr ./java.zip metadata.lua hooks lib
vfox add java --source ./java.zip
rm ./java.zip
```

macOS is the same, with `git` and `zip` that come with the system.

## Windows 11

Assume that PowerShell 7 is already installed. Execute in PowerShell 7,

```powershell
winget install --id Git.Git --source winget --exact
git clone --depth 1 https://github.com/version-fox/vfox-java.git
cd ./vfox-java/
tar -a -cf ./java.zip metadata.lua hooks lib
vfox add java --source ./java.zip
Remove-Item ./java.zip
```

## Check it

```bash
vfox install java@21-tem
vfox use --global java@21-tem
java -version
```

A build of `main` installs the newest Temurin 21 (`21.0.12.1+1-tem` on 2026-10-18). Release 0.6.1 installs `21+35-tem`, the first build of 21.

## When java is already added

`vfox add` refuses with `plugin named java already exists`. You can replace the plugin or add the source build next to it.

To replace it, `vfox remove java` comes first, and it removes the JDKs installed through the plugin as well: vfox says so before it asks. Reinstall them afterwards.

To keep both, give the new one another name:

```bash
vfox add java --source ./java.zip --alias java-dev
vfox install java-dev@21-tem
vfox remove -y java-dev            # removes only java-dev and what it installed
```

The alias has its own list of installed JDKs, but `JAVA_HOME` is `~/.vfox/sdks/java` for both. Select a version from only one of them per scope: for the global scope, `vfox unuse --global java` before you `vfox use --global java-dev@...`, or the other way round. With both selected, vfox relinks both on every prompt, and `JAVA_HOME` can end up at either.

## Updating

Pull, build the zip again and add it again. A plugin added under its own name has to be removed first, and that takes the installed JDKs with it, so the alias is the easier route when you update often:

```bash
vfox remove -y java-dev
vfox add java --source ./java.zip --alias java-dev
```

`vfox update java` compares the version in `metadata.lua` with the registry's and prints `java is already the latest version` while they are equal, so it leaves a source build alone until a release newer than that version is published.

To work on the plugin, see [development.md](development.md).
