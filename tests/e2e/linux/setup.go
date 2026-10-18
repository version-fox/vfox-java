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
