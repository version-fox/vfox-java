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
	"testing"

	tc "github.com/testcontainers/testcontainers-go"

	"github.com/version-fox/vfox-java/tests/e2e/common"
)

// installJava installs one JDK and returns the version vfox recorded for it
// (see common.CheckInstalled), logging whether it came from a zip or a
// tar.gz. Install runs plain: vfox.exe resolves through the slot PATH
// override.
func installJava(ctx context.Context, t *testing.T, ctr tc.Container, box slotBox, spec string) string {
	t.Helper()
	out := execRetry(ctx, t, ctr, "vfox install java@"+spec,
		"vfox install "+pwshQuote("java@"+spec), box.vars...)
	installed := common.CheckInstalled(t, out, spec)
	archive := "zip"
	if common.FromTarball(out) {
		archive = "tar.gz"
	}
	t.Logf("PASS java@%s installed as %s (%s)", spec, installed, archive)
	return installed
}

// useJava selects the installed JDK globally; `vfox use` needs the
// activation context captured by fetchActivation.
func useJava(ctx context.Context, t *testing.T, ctr tc.Container, box slotBox, activation, installed string) {
	t.Helper()
	execOK(ctx, t, ctr, activated(activation, "vfox use --global "+pwshQuote("java@"+installed)), box.vars...)
}
