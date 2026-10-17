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
	"testing"

	tc "github.com/testcontainers/testcontainers-go"

	"github.com/version-fox/vfox-java/tests/e2e/common"
)

// installJava installs one JDK and returns the version vfox recorded for it
// (see common.CheckInstalled).
func installJava(ctx context.Context, t *testing.T, ctr tc.Container, spec string) string {
	t.Helper()
	out := execRetry(ctx, t, ctr, "vfox install java@"+spec, "vfox install java@"+spec)
	installed := common.CheckInstalled(t, out, spec)
	t.Logf("PASS java@%s installed as %s", spec, installed)
	return installed
}

// useJava selects the installed JDK globally; `vfox use` needs the activate
// context (see exec.go).
func useJava(ctx context.Context, t *testing.T, ctr tc.Container, installed string) {
	t.Helper()
	execOK(ctx, t, ctr, activated("vfox use --global java@"+installed))
}
