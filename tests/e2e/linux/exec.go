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
	"io"
	"strings"
	"testing"

	tc "github.com/testcontainers/testcontainers-go"
	tcexec "github.com/testcontainers/testcontainers-go/exec"

	"github.com/version-fox/vfox-java/tests/e2e/common"
)

// execRun runs script via `bash -c` in the container and returns its exit
// code with the combined stdout+stderr output. extraEnv entries ("K=V")
// override single variables; the rest of the container env is inherited.
func execRun(ctx context.Context, t *testing.T, ctr tc.Container, script string, extraEnv ...string) (int, string) {
	t.Helper()
	opts := []tcexec.ProcessOption{tcexec.Multiplexed()}
	if len(extraEnv) > 0 {
		opts = append(opts, tcexec.WithEnv(extraEnv))
	}
	code, r, err := ctr.Exec(ctx, []string{"bash", "-c", script}, opts...)
	if err != nil {
		t.Fatalf("exec: %v\n--- script ---\n%s", err, script)
	}
	out, err := io.ReadAll(r)
	if err != nil {
		t.Fatalf("exec read output: %v\n--- script ---\n%s", err, script)
	}
	return code, string(out)
}

// execOK runs script and fatals unless it exits 0, returning the output.
func execOK(ctx context.Context, t *testing.T, ctr tc.Container, script string, extraEnv ...string) string {
	t.Helper()
	code, out := execRun(ctx, t, ctr, script, extraEnv...)
	if code != 0 {
		t.Fatalf("exec exited with code %d\n--- script ---\n%s\n--- output ---\n%s", code, script, out)
	}
	return out
}

// execRetry runs script through the shared common.Retry helper (linear
// 10s*attempt backoff, per-attempt logging).
func execRetry(ctx context.Context, t *testing.T, ctr tc.Container, label, script string, extraEnv ...string) string {
	t.Helper()
	return common.Retry(ctx, t, label, func() (int, string) {
		return execRun(ctx, t, ctr, script, extraEnv...)
	})
}

// activated prefixes script with the vfox env setup (`eval "$(vfox activate
// bash)"`). Every exec starts a fresh shell, so activation cannot persist
// and must wrap each call; `vfox use` in particular fails without it
// ("vfox requires hook support").
func activated(script string) string {
	return `eval "$(vfox activate bash)"; ` + script
}

// shQuote renders a single-quoted POSIX shell string literal.
func shQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}
