# Using JDKs that are already on the machine

[中文](zh-CN/link.md) | [English](link.md)

If a JDK is already on the machine — from the system package manager, an IDE, Gradle, another version manager, Homebrew, or winget — `vfox link --detect java` adopts it instead of downloading another copy. It needs vfox 1.1.0 or later (`vfox --version`).

```bash
vfox link --detect java
```

vfox lists what the plugin found and links what you pick. `vfox link --detect -y java` links everything without asking. Afterwards `vfox use java@...` works as usual: `vfox list java` marks linked versions `(linked → <path>)`, and `vfox uninstall` removes only the link, leaving the JDK where it is.

## What it finds

- Gradle's provisioning folder (`$GRADLE_USER_HOME/jdks`, `~/.gradle/jdks` by default)
- IntelliJ IDEA's folder (`~/.jdks`, `~/Library/Java/JavaVirtualMachines` on macOS)
- The system directories (`/usr/lib/jvm`, `/Library/Java/JavaVirtualMachines` on macOS, `C:\Program Files\*` on Windows, where winget, Chocolatey and the vendor installers land too)
- The version managers SDKMAN, asdf, mise and jabba
- Homebrew kegs (`/opt/homebrew/opt`, `/usr/local/opt`, Linuxbrew)
- Scoop apps (`~/scoop/apps`)
- The CI runner tool cache
- `JAVA_HOME`

nvm manages Node.js only, so there is nothing Java-related to find in it.

## Version names

A found JDK is named the way `vfox install` names it: the runtime version from its `release` file, then `-<short name>`, then `-fx` for JavaFX builds and nothing for OpenJDK. Gradle's Temurin 17, for example, becomes `17.0.21+9-tem`. Entries that are already installed or linked are skipped.

## Automatic links on install (opt-in)

`vfox link --detect` adopts JDKs into vfox. The other direction — letting Gradle and IntelliJ IDEA find every JDK vfox installed — is opt-in per install: set `VFOX_JAVA_JDKS_LINKS` to `1` (also `true`, `yes` or `on`) before installing:

```bash
export VFOX_JAVA_JDKS_LINKS=1
vfox install java@21-tem
```

Each install then leaves a link named after the version in IDEA's folder (`~/.jdks`, `~/Library/Java/JavaVirtualMachines` on macOS, `%USERPROFILE%\.jdks` on Windows), and `vfox uninstall` removes the link it created. Where something that is not a link already has the name, it is left alone, so a JDK of your own is never touched; a link that fails prints a warning and never fails the install. Without the variable, installs behave as before and uninstalling removes nothing extra.

## Linking by hand

Where `--detect` does not look, point at the directory by hand. It is the JDK home itself, the directory that holds `bin` (on macOS a `.jdk` bundle, `Contents/Home` inside it):

```bash
vfox link java@17-system /usr/lib/jvm/java-17-openjdk-amd64
vfox use java@17-system
```
