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

package linux

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
// update this file and tests/e2e/windows/verify.go together.

// showSettings prints the JVM properties plus the version banner; both go
// to stderr.
const showSettings = "java -XshowSettings:properties -version 2>&1"

// userGraalVMHome is a GRAALVM_HOME set before activation: users point it at
// a GraalVM of their own, apart from JAVA_HOME.
const userGraalVMHome = "/opt/graalvm-for-native-image"

// verifySearch checks `vfox search java` (the plugin's Available hook) lists
// the installed version under the name PreInstall gave it, marked
// installed, with the JavaFX note for -fx builds. For GraalVM it must also
// list feature releases (e.g. 25.4.4.1-graalce), none of them marked LTS
// (see common.FeatureReleaseEntries).
func verifySearch(ctx context.Context, t *testing.T, ctr tc.Container, distribution, installed string) {
	t.Helper()
	cmd := "vfox search java" + common.SearchArgs(distribution)
	out := execRetry(ctx, t, ctr, cmd, cmd)
	entry, ok := common.SearchEntry(out, installed)
	require.Truef(t, ok, "%s does not list %s\n--- output ---\n%s", cmd, installed, out)
	require.Containsf(t, entry, "(installed)", "%s must mark %s installed", cmd, installed)
	if common.JavaFX(distribution) {
		require.Containsf(t, entry, "JavaFX", "%s must note JavaFX on %s", cmd, installed)
	}
	t.Logf("PASS %s lists %s", cmd, entry)
	if common.GraalVM(distribution) {
		// Foojay lists every feature release since 25.1.3 on each platform
		// the suite runs GraalVM on, so the check cannot pass vacuously.
		features := common.FeatureReleaseEntries(out)
		require.NotEmptyf(t, features, "%s lists no feature release\n--- output ---\n%s", cmd, out)
		for _, feature := range features {
			require.NotContainsf(t, feature, "LTS", "%s must not mark the feature release %s LTS", cmd, feature)
		}
		t.Logf("PASS %s marks no feature release LTS: %s", cmd, strings.Join(features, ", "))
	}
}

// verifyLegacyFile proves ParseLegacyFile selects the installed JDK from a
// .sdkmanrc (PLUGIN.legacyFilenames) holding the SDKMAN identifier without
// the build number (e.g. java=21.0.8-tem, java=21.0.5-jbr,
// java=25.0.4.fx-librca), the one with a zero padding the release (e.g.
// java=21.0.8.0+9-tem, see common.PaddedIdentifier) or the installed version
// itself (e.g. java=21.0.8+9-tem), while vfox lists an empty install of
// another release first (see common.Decoy). SDKMAN's identifier of an
// early-access build (e.g. java=21.0.0.0+ea.1-tem) must then select a faked
// install of that build (see common.EarlyAccess), not the release, and so
// must its installed name (e.g. java=21-ea+1-tem). It runs before any
// `vfox use`, so java can only come from the legacy file.
func verifyLegacyFile(ctx context.Context, t *testing.T, ctr tc.Container, distribution, version, installed, arch string) {
	t.Helper()
	// vfox counts a version as installed once its directory holds
	// java-<version>; the decoy holds nothing more, so selecting it leaves
	// no java on PATH.
	decoy := common.Decoy(distribution, version)
	decoyDir := `"${VFOX_HOME:-$HOME/.vfox}"/cache/java/` + shQuote("v-"+decoy)
	execOK(ctx, t, ctr, "mkdir --parents "+decoyDir+"/"+shQuote("java-"+decoy))
	listed := common.ListedVersions(execOK(ctx, t, ctr, "vfox list java"))
	require.Equalf(t, []string{decoy, installed}, listed, "vfox list java must list the decoy %s first", decoy)

	for _, identifier := range []string{
		common.LegacyIdentifier(distribution, version),
		common.PaddedIdentifier(distribution, version, installed),
		installed,
	} {
		out := legacyJava(ctx, t, ctr, identifier)
		common.CheckJava(t, out, distribution, version, arch, ".sdkmanrc java="+identifier)
		t.Logf("PASS .sdkmanrc java=%s selects java %s, not %s", identifier, version, decoy)
	}
	execOK(ctx, t, ctr, "rm --recursive "+decoyDir)

	// The early-access build's java only prints its name, which the
	// release's java, selected instead, would not.
	ea := common.EarlyAccess(distribution, version)
	eaDir := `"${VFOX_HOME:-$HOME/.vfox}"/cache/java/` + shQuote("v-"+ea)
	bin := eaDir + "/" + shQuote("java-"+ea) + "/bin"
	execOK(ctx, t, ctr, fmt.Sprintf("mkdir --parents %s && printf '%%s' %s > %s/java && chmod +x %s/java",
		bin, shQuote("#!/bin/sh\necho "+shQuote(ea)+"\n"), bin, bin))
	// ParseLegacyFile could not parse the installed name, so it selected
	// nothing for it, while `vfox use` selects it (vfox-java#91).
	for _, identifier := range []string{common.EarlyAccessIdentifier(distribution, version), ea} {
		out := legacyJava(ctx, t, ctr, identifier)
		require.Containsf(t, out, ea, ".sdkmanrc java=%s must select %s, not %s", identifier, ea, installed)
		t.Logf("PASS .sdkmanrc java=%s selects %s, not %s", identifier, ea, installed)
	}
	execOK(ctx, t, ctr, "rm --recursive "+eaDir)
}

// legacyJava writes java=<identifier> to a .sdkmanrc and returns what java
// prints next to it. The probe activates inside its own exec, a fresh shell
// session, so no `vfox env` state cached by an earlier call can answer for
// the file.
func legacyJava(ctx context.Context, t *testing.T, ctr tc.Container, identifier string) string {
	t.Helper()
	const dir = "/tmp/e2e-legacy-sdkmanrc"
	execOK(ctx, t, ctr, fmt.Sprintf("mkdir --parents %s && printf 'java=%%s\\n' %s > %s/.sdkmanrc",
		dir, shQuote(identifier), dir))
	return execRetry(ctx, t, ctr, ".sdkmanrc java="+identifier, fmt.Sprintf(
		`cd %s && eval "$(vfox activate bash)" && eval "$(vfox env -s bash)" && %s`, dir, showSettings))
}

// verifyToolchain runs java and javac through the activate hook and checks
// the JDK on PATH is the requested release, distribution, architecture and
// JavaFX flavour; that JAVA_HOME resolves to that same JDK, while a
// GRAALVM_HOME set beforehand keeps its value; that it compiles and runs a
// program; and that `vfox current` reports the installed version.
func verifyToolchain(ctx context.Context, t *testing.T, ctr tc.Container, distribution, version, installed, arch string) {
	t.Helper()
	out := execRetry(ctx, t, ctr, "java on PATH", activated(showSettings))
	props := common.CheckJava(t, out, distribution, version, arch, "java on PATH")

	// java.home is the canonical JDK root: the launcher resolves its own
	// symlinks, while JAVA_HOME names vfox's link (~/.vfox/sdks/java).
	viaHome := common.JavaProperties(execOK(ctx, t, ctr, activated(`"$JAVA_HOME"/bin/`+showSettings)))
	require.Equal(t, props["java.home"], viaHome["java.home"], "$JAVA_HOME/bin/java must be the java on PATH")
	home := strings.TrimSpace(execOK(ctx, t, ctr, activated(`test -n "$JAVA_HOME" && readlink --canonicalize "$JAVA_HOME"`)))
	require.Equal(t, props["java.home"], home, "JAVA_HOME must resolve to the JDK root")
	// The plugin set GRAALVM_HOME to JAVA_HOME for GraalVM, replacing the
	// user's (vfox-java#27).
	graalvmHome := strings.TrimSpace(execOK(ctx, t, ctr,
		"export GRAALVM_HOME="+shQuote(userGraalVMHome)+"; "+activated(`echo "$GRAALVM_HOME"`)))
	require.Equal(t, userGraalVMHome, graalvmHome, "a GRAALVM_HOME set beforehand must keep its value")

	javac := strings.TrimSpace(execOK(ctx, t, ctr, activated("javac -version 2>&1")))
	require.Equal(t, "javac "+version, javac, "javac -version")
	execOK(ctx, t, ctr, "mkdir --parents /tmp/e2e-hello && printf '%s' "+shQuote(common.HelloJava)+" > /tmp/e2e-hello/Hello.java")
	hello := execOK(ctx, t, ctr, activated(
		"javac -d /tmp/e2e-hello/classes /tmp/e2e-hello/Hello.java && java -cp /tmp/e2e-hello/classes Hello"))
	require.Equal(t, common.HelloOutput(version, arch), strings.TrimSpace(hello), "javac + java Hello")

	modules := execOK(ctx, t, ctr, activated("java --list-modules"))
	if common.JavaFX(distribution) {
		require.Contains(t, modules, "javafx.base@", "an -fx build must bundle JavaFX")
	} else {
		require.NotContains(t, modules, "javafx.", "a build without -fx must not bundle JavaFX")
	}

	current := execOK(ctx, t, ctr, activated("vfox current java"))
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
func verifyPreUse(ctx context.Context, t *testing.T, ctr tc.Container, distribution, version, installed string) {
	t.Helper()
	spellings := []string{common.Major(version), common.Spec(distribution, version)}
	if alias, ok := common.Alias(distribution, installed); ok {
		spellings = append(spellings, alias)
	}
	// Foojay leaves the zero out, so PreInstall names the installed JDK and
	// vfox downloads nothing.
	padded := common.PaddedSpecs(distribution, version, installed)
	for _, spec := range padded {
		out := execRetry(ctx, t, ctr, "vfox install java@"+spec, "vfox install java@"+spec)
		require.Containsf(t, common.StripANSI(out), "java@"+installed+" is already installed",
			"vfox install java@%s must find the installed %s", spec, installed)
	}
	t.Logf("PASS vfox install java@%s finds %s installed", strings.Join(padded, ", java@"), installed)
	spellings = append(spellings, padded...)
	for _, spelling := range spellings {
		out := execOK(ctx, t, ctr, activated("vfox use --global java@"+spelling))
		require.Containsf(t, common.StripANSI(out), "Now using java@"+installed+".",
			"java@%s must select the installed %s", spelling, installed)
		props := common.JavaProperties(execOK(ctx, t, ctr, activated(showSettings)))
		require.Equalf(t, version, props["java.version"], "java on PATH after java@%s", spelling)
	}
	t.Logf("PASS java@%s select %s", strings.Join(spellings, ", java@"), installed)
}
