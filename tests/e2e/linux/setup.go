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

// setupVfox installs vfox (release, or builds main with the in-image Go
// toolchain) and registers the local java plugin.
func setupVfox(ctx context.Context, t *testing.T, ctr tc.Container, vfoxVersion string) {
	t.Helper()
	work := strings.TrimSpace(execOK(ctx, t, ctr, "mktemp --directory"))
	// The container is removed after the test, but clean up anyway so
	// repeated local runs don't leak /tmp.
	defer func() {
		_, _ = execRun(ctx, t, ctr, fmt.Sprintf("rm --recursive --force %q", work))
	}()

	if vfoxVersion == "main" {
		execOK(ctx, t, ctr, fmt.Sprintf(
			"git clone --depth 1 https://github.com/version-fox/vfox %q/src && (cd %q/src && CGO_ENABLED=0 go build -trimpath -o /usr/local/bin/vfox .)",
			work, work))
	} else {
		execOK(ctx, t, ctr,
			"curl --fail --silent --show-error --location https://raw.githubusercontent.com/version-fox/vfox/main/install.sh | bash")
	}
	execOK(ctx, t, ctr, fmt.Sprintf(
		"(cd /e2e && zip -qr %q/java.zip metadata.lua hooks lib) && vfox add java --source %q/java.zip",
		work, work))
	t.Logf("PASS %s with the local java plugin", strings.TrimSpace(execOK(ctx, t, ctr, "vfox --version")))
}

// checkNotes proves the notes printed by `vfox info java` point to the
// README (see common.ReadmeURL).
func checkNotes(ctx context.Context, t *testing.T, ctr tc.Container) {
	t.Helper()
	out := execOK(ctx, t, ctr, "vfox info java")
	require.Containsf(t, common.StripANSI(out), common.ReadmeURL,
		"the notes of vfox info java must point to the README\n--- output ---\n%s", out)
	t.Logf("PASS the notes of vfox info java point to %s", common.ReadmeURL)
}

// checkVersionlessRejected proves a distribution without a version (e.g.
// java@tem, java@-tem, see common.VersionlessSpecs) fails both `vfox
// install` and `vfox use` with an error asking for one. The hooks raise it
// before any Foojay lookup, so nothing is retried.
func checkVersionlessRejected(ctx context.Context, t *testing.T, ctr tc.Container, distribution string) {
	t.Helper()
	for _, spec := range common.VersionlessSpecs(distribution) {
		want := "No version in " + spec + ";"
		for _, c := range []struct{ label, script string }{
			{"vfox install java@" + spec, "vfox install java@" + spec},
			{"vfox use --global java@" + spec, activated("vfox use --global java@" + spec)},
		} {
			code, out := execRun(ctx, t, ctr, c.script)
			require.NotZerof(t, code, "%s must fail\n--- output ---\n%s", c.label, out)
			require.Containsf(t, common.StripANSI(out), want, "%s must ask for a version", c.label)
		}
		t.Logf("PASS java@%s is rejected by vfox install and vfox use", spec)
	}
}

// checkMissingVersionRejected proves an unpublished release, and an
// unpublished build of the pinned one, fail loudly instead of installing
// something else: PreInstall finds no Foojay package and names the platform
// it searched, which must be the runner's (RUNTIME.osType/archType).
func checkMissingVersionRejected(ctx context.Context, t *testing.T, ctr tc.Container, distribution, version, arch string) {
	t.Helper()
	for _, spec := range []string{common.MissingSpec(distribution, version), common.MissingBuildSpec(distribution, version)} {
		want := "No JDK found for " + spec
		out := common.Retry(ctx, t, "vfox install java@"+spec+" (must fail)", func() (int, string) {
			code, out := execRun(ctx, t, ctr, "vfox install java@"+spec)
			if code == 0 {
				t.Fatalf("installing the unpublished %s unexpectedly succeeded\n--- output ---\n%s", spec, out)
			}
			// Any other failure (e.g. Foojay unreachable) is retried like the
			// other network-touching calls.
			if strings.Contains(out, want) {
				return 0, out
			}
			return code, out
		})
		require.Contains(t, out, " on linux/"+arch, "the lookup must target the runner platform")
		t.Logf("PASS java@%s is rejected on linux/%s", spec, arch)
	}
}

// checkGraalVMBareMajor proves Oracle GraalVM's bare major installs the
// newest build of its 25.0 line, not one of the monthly feature releases
// Foojay lists before it (see common.OracleGraalVMSpec). The builds of the
// major `vfox search java graal` lists are faked as installed first (see
// common.BareMajorBuilds), so `vfox install` names the one PreInstall picked
// and downloads nothing.
func checkGraalVMBareMajor(ctx context.Context, t *testing.T, ctr tc.Container) {
	t.Helper()
	spec := common.OracleGraalVMSpec
	out := execRetry(ctx, t, ctr, "vfox search java graal", "vfox search java graal")
	builds, want := common.BareMajorBuilds(common.SearchedVersions(out), spec)
	require.NotEmptyf(t, want, "vfox search java graal lists no %s build but feature releases\n--- output ---\n%s", spec, out)
	var dirs, javaDirs []string
	for _, build := range builds {
		dir := `"${VFOX_HOME:-$HOME/.vfox}"/cache/java/` + shQuote("v-"+build)
		dirs = append(dirs, dir)
		javaDirs = append(javaDirs, dir+"/"+shQuote("java-"+build))
	}
	execOK(ctx, t, ctr, "mkdir --parents "+strings.Join(javaDirs, " "))
	out = execRetry(ctx, t, ctr, "vfox install java@"+spec, "vfox install java@"+spec)
	require.Containsf(t, common.StripANSI(out), "java@"+want+" is already installed",
		"vfox install java@%s must take %s, the newest build that is no feature release", spec, want)
	execOK(ctx, t, ctr, "rm --recursive "+strings.Join(dirs, " "))
	t.Logf("PASS java@%s takes %s out of %s", spec, want, strings.Join(builds, ", "))
}

// checkNameOnly proves the distributions checked by name only go by their
// short names (see common.NameOnlyDistributions): `vfox search java
// <short>` lists each, and with the newest version it lists faked as
// installed, `vfox install java@<major>-<short>` finds that one installed,
// so nothing downloads (see common.NewestBareMajor).
func checkNameOnly(ctx context.Context, t *testing.T, ctr tc.Container, platform string) {
	t.Helper()
	names := common.NameOnlyDistributions(platform)
	var dirs []string
	for _, name := range names {
		search := "vfox search java " + name
		out := execRetry(ctx, t, ctr, search, search)
		spec, newest, ok := common.NewestBareMajor(common.SearchedVersions(out), name)
		require.Truef(t, ok, "%s lists no newest version that a bare major names\n--- output ---\n%s", search, out)
		dir := `"${VFOX_HOME:-$HOME/.vfox}"/cache/java/` + shQuote("v-"+newest)
		dirs = append(dirs, dir)
		execOK(ctx, t, ctr, "mkdir --parents "+dir+"/"+shQuote("java-"+newest))
		out = execRetry(ctx, t, ctr, "vfox install java@"+spec, "vfox install java@"+spec)
		require.Containsf(t, common.StripANSI(out), "java@"+newest+" is already installed",
			"vfox install java@%s must take %s, the newest version %s lists", spec, newest, search)
	}
	if len(dirs) > 0 {
		execOK(ctx, t, ctr, "rm --recursive "+strings.Join(dirs, " "))
	}
	t.Logf("PASS %d distributions go by name on %s: %s", len(names), platform, strings.Join(names, ", "))
}
