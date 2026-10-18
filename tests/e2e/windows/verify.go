// Copyright 2026 Han Li and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package windows

import (
	"context"
	"fmt"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
	tc "github.com/testcontainers/testcontainers-go"

	"github.com/version-fox/vfox-java/tests/e2e/common"
)

// NOTE: the markers asserted here are part of the plugin's or vfox's
// user-facing contract (see hooks/ lib/). If either side rewords them,
// update this file and tests/e2e/linux/verify.go together.

// showSettings prints the JVM properties plus the version banner. Both go to
// stderr, which pwsh passes straight through when it is not redirected;
// `2>&1` would instead wrap every line in an ErrorRecord.
const showSettings = "-XshowSettings:properties -version"

// userGraalVMHome is a GRAALVM_HOME set before activation: users point it at
// a GraalVM of their own, apart from JAVA_HOME.
const userGraalVMHome = `C:\graalvm-for-native-image`

// verifySearch checks `vfox search java` (the plugin's Available hook) lists
// the installed version under the name PreInstall gave it, marked
// installed, with the JavaFX note for -fx builds. That includes releases
// shipped only as tar.gz, such as JetBrains Runtime 21.0.5 (vfox-java#72).
func verifySearch(ctx context.Context, t *testing.T, ctr tc.Container, box slotBox, distribution, installed string) {
	t.Helper()
	cmd := "vfox search java" + common.SearchArgs(distribution)
	out := execRetry(ctx, t, ctr, cmd, cmd, box.vars...)
	entry, ok := common.SearchEntry(out, installed)
	require.Truef(t, ok, "%s does not list %s\n--- output ---\n%s", cmd, installed, out)
	require.Containsf(t, entry, "(installed)", "%s must mark %s installed", cmd, installed)
	if common.JavaFX(distribution) {
		require.Containsf(t, entry, "JavaFX", "%s must note JavaFX on %s", cmd, installed)
	}
	t.Logf("PASS %s lists %s", cmd, entry)
}

// verifyLegacyFile proves ParseLegacyFile selects the installed JDK from a
// .sdkmanrc (PLUGIN.legacyFilenames) holding the SDKMAN identifier without
// the build number (e.g. java=21.0.8-tem, java=21.0.5-jbr,
// java=25.0.4.fx-librca), the one with a zero padding the release (e.g.
// java=21.0.8.0+9-tem, see common.PaddedIdentifier) or the installed version
// itself (e.g. java=21.0.8+9-tem), written by Set-Content with Windows line
// endings, while vfox lists an empty install of another release first (see
// common.Decoy). SDKMAN's identifier of an early-access build (e.g.
// java=21.0.0.0+ea.1-tem) must then select a faked install of that build
// (see common.EarlyAccess), not the release, and so must its installed name
// (e.g. java=21-ea+1-tem). It runs before any `vfox use`, so java can only
// come from the legacy file.
func verifyLegacyFile(ctx context.Context, t *testing.T, ctr tc.Container, box slotBox, distribution, version, installed, arch string) {
	t.Helper()
	// vfox counts a version as installed once its directory holds
	// java-<version>; the decoy holds nothing more, so selecting it leaves
	// no java on PATH.
	decoy := common.Decoy(distribution, version)
	decoyDir := fmt.Sprintf("(Join-Path $env:VFOX_HOME %s)", pwshQuote(`cache\java\v-`+decoy))
	execOK(ctx, t, ctr, fmt.Sprintf("New-Item -ItemType Directory -Force -Path (Join-Path %s %s) | Out-Null",
		decoyDir, pwshQuote("java-"+decoy)), box.vars...)
	listed := common.ListedVersions(execOK(ctx, t, ctr, "vfox list java", box.vars...))
	require.Equalf(t, []string{decoy, installed}, listed, "vfox list java must list the decoy %s first", decoy)

	for _, identifier := range []string{
		common.LegacyIdentifier(distribution, version),
		common.PaddedIdentifier(distribution, version, installed),
		installed,
	} {
		out := legacyJava(ctx, t, ctr, box, identifier)
		common.CheckJava(t, out, distribution, version, arch, ".sdkmanrc java="+identifier)
		t.Logf("PASS .sdkmanrc java=%s selects java %s, not %s", identifier, version, decoy)
	}
	execOK(ctx, t, ctr, fmt.Sprintf("Remove-Item -LiteralPath %s -Recurse -Force", decoyDir), box.vars...)

	// The early-access build's java (a java.cmd) only prints its name, which
	// the release's java, selected instead, would not.
	ea := common.EarlyAccess(distribution, version)
	eaDir := fmt.Sprintf("(Join-Path $env:VFOX_HOME %s)", pwshQuote(`cache\java\v-`+ea))
	execOK(ctx, t, ctr, fmt.Sprintf(
		"$bin = Join-Path %s %s; New-Item -ItemType Directory -Force -Path $bin | Out-Null; "+
			"Set-Content -Path (Join-Path $bin 'java.cmd') -Value %s",
		eaDir, pwshQuote(`java-`+ea+`\bin`), pwshQuote("@echo "+ea)), box.vars...)
	// ParseLegacyFile could not parse the installed name, so it selected
	// nothing for it, while `vfox use` selects it (vfox-java#91).
	for _, identifier := range []string{common.EarlyAccessIdentifier(distribution, version), ea} {
		out := legacyJava(ctx, t, ctr, box, identifier)
		require.Containsf(t, out, ea, ".sdkmanrc java=%s must select %s, not %s", identifier, ea, installed)
		t.Logf("PASS .sdkmanrc java=%s selects %s, not %s", identifier, ea, installed)
	}
	execOK(ctx, t, ctr, fmt.Sprintf("Remove-Item -LiteralPath %s -Recurse -Force", eaDir), box.vars...)
}

// legacyJava writes java=<identifier> to a .sdkmanrc and returns what java
// prints next to it. The probe activates its own PowerShell process.
// Activation pins __VFOX_PID, which scopes the `vfox env` state cache, but
// Windows may reuse a just-exited PID and legacy files are not among the
// cache's tracked inputs, so the cache file is removed before the export.
func legacyJava(ctx context.Context, t *testing.T, ctr tc.Container, box slotBox, identifier string) string {
	t.Helper()
	const dir = `C:\e2e-legacy-sdkmanrc`
	execOK(ctx, t, ctr, fmt.Sprintf(
		"New-Item -ItemType Directory -Force -Path %s | Out-Null; Set-Content -Path %s -Value %s",
		pwshQuote(dir), pwshQuote(dir+`\.sdkmanrc`), pwshQuote("java="+identifier)), box.vars...)
	script := fmt.Sprintf(
		"Invoke-Expression -Command (vfox activate pwsh | Out-String); "+
			"Set-Location -LiteralPath %s; "+
			"if ($env:__VFOX_CURTMPPATH) { Remove-Item -LiteralPath (Join-Path $env:__VFOX_CURTMPPATH 'env-state.json') -Force -ErrorAction SilentlyContinue }; "+
			"$__vfoxExport = vfox env -s pwsh | Out-String; "+
			"if ($__vfoxExport.Trim()) { Invoke-Expression -Command $__vfoxExport }; "+
			"java %s", pwshQuote(dir), showSettings)
	return execRetry(ctx, t, ctr, ".sdkmanrc java="+identifier, script, box.vars...)
}

// verifyToolchain runs java and javac through the activate + env hooks and
// checks the JDK on PATH is the requested release, distribution,
// architecture and JavaFX flavour; that JAVA_HOME holds that same JDK,
// while a GRAALVM_HOME set beforehand keeps its value; that it compiles and
// runs a program; and that `vfox current` reports the installed version.
func verifyToolchain(ctx context.Context, t *testing.T, ctr tc.Container, box slotBox, activation, distribution, version, installed, arch string) {
	t.Helper()
	out := execRetry(ctx, t, ctr, "java on PATH", activatedEnv(activation, "java "+showSettings), box.vars...)
	props := common.CheckJava(t, out, distribution, version, arch, "java on PATH")
	require.NotEmpty(t, props["java.home"], "java on PATH: java.home")

	viaHome := common.JavaProperties(execOK(ctx, t, ctr, activatedEnv(activation,
		`& (Join-Path $env:JAVA_HOME 'bin\java.exe') `+showSettings), box.vars...))
	require.Equal(t, props["java.home"], viaHome["java.home"], `JAVA_HOME\bin\java.exe must be the java on PATH`)
	// The plugin set GRAALVM_HOME to JAVA_HOME for GraalVM, replacing the
	// user's (vfox-java#27).
	graalvmHome := strings.TrimSpace(execOK(ctx, t, ctr,
		"$env:GRAALVM_HOME = "+pwshQuote(userGraalVMHome)+"\r\n"+activatedEnv(activation, "$env:GRAALVM_HOME"), box.vars...))
	require.Equal(t, userGraalVMHome, graalvmHome, "a GRAALVM_HOME set beforehand must keep its value")

	javac := strings.TrimSpace(execOK(ctx, t, ctr, activatedEnv(activation, "javac -version"), box.vars...))
	require.Equal(t, "javac "+version, javac, "javac -version")
	dir := box.tmp + `\e2e-hello`
	execOK(ctx, t, ctr, fmt.Sprintf(
		"New-Item -ItemType Directory -Force -Path %s | Out-Null; Set-Content -Path %s -Value %s",
		pwshQuote(dir), pwshQuote(dir+`\Hello.java`), pwshQuote(common.HelloJava)), box.vars...)
	hello := execOK(ctx, t, ctr, activatedEnv(activation, fmt.Sprintf("javac -d %s %s; java -cp %s Hello",
		pwshQuote(dir+`\classes`), pwshQuote(dir+`\Hello.java`), pwshQuote(dir+`\classes`))), box.vars...)
	require.Equal(t, common.HelloOutput(version, arch), strings.TrimSpace(hello), "javac + java Hello")

	modules := execOK(ctx, t, ctr, activatedEnv(activation, "java --list-modules"), box.vars...)
	if common.JavaFX(distribution) {
		require.Contains(t, modules, "javafx.base@", "an -fx build must bundle JavaFX")
	} else {
		require.NotContains(t, modules, "javafx.", "a build without -fx must not bundle JavaFX")
	}

	current := execOK(ctx, t, ctr, "vfox current java", box.vars...)
	require.Contains(t, current, installed, "vfox current java")
	t.Logf("PASS java %s (%s, %s) runs from %s", version, props["java.vendor"], props["os.arch"], props["java.home"])
}

// verifyPreUse proves PreUse turns the spellings users type into the
// installed version, without another download:
//
//  1. the bare major (e.g. java@21), for which PreUse returns no result and
//     vfox core fuzzy-matches the installed versions;
//  2. the spec the JDK was installed with (e.g. java@21.0.8-tem), whose
//     build number PreUse finds among the installed versions;
//  3. the asdf-style <long-name>-<version>[-fx] spelling (e.g.
//     java@temurin-21.0.8+9), which PreUse rewrites to <version>-<short>
//     (<version> for OpenJDK, installed without a suffix);
//  4. the release padded with a zero, as SDKMAN writes releases (e.g.
//     java@21.0.8.0-tem, java@21.0.8.0+9-tem, see common.PaddedSpecs),
//     which `vfox install` must first find already installed.
//
// After each `vfox use`, java on PATH must still be the installed JDK.
func verifyPreUse(ctx context.Context, t *testing.T, ctr tc.Container, box slotBox, activation, distribution, version, installed string) {
	t.Helper()
	spellings := []string{common.Major(version), common.Spec(distribution, version)}
	if alias, ok := common.Alias(distribution, installed); ok {
		spellings = append(spellings, alias)
	}
	// Foojay leaves the zero out, so PreInstall names the installed JDK and
	// vfox downloads nothing.
	padded := common.PaddedSpecs(distribution, version, installed)
	for _, spec := range padded {
		out := execRetry(ctx, t, ctr, "vfox install java@"+spec, "vfox install "+pwshQuote("java@"+spec), box.vars...)
		require.Containsf(t, common.StripANSI(out), "java@"+installed+" is already installed",
			"vfox install java@%s must find the installed %s", spec, installed)
	}
	t.Logf("PASS vfox install java@%s finds %s installed", strings.Join(padded, ", java@"), installed)
	spellings = append(spellings, padded...)
	for _, spelling := range spellings {
		out := execOK(ctx, t, ctr, activated(activation, "vfox use --global "+pwshQuote("java@"+spelling)), box.vars...)
		require.Containsf(t, common.StripANSI(out), "Now using java@"+installed+".",
			"java@%s must select the installed %s", spelling, installed)
		props := common.JavaProperties(execOK(ctx, t, ctr, activatedEnv(activation, "java "+showSettings), box.vars...))
		require.Equalf(t, version, props["java.version"], "java on PATH after java@%s", spelling)
	}
	t.Logf("PASS java@%s select %s", strings.Join(spellings, ", java@"), installed)
}
