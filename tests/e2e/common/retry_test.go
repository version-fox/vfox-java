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

package common

import (
	"context"
	"testing"
	"time"
)

// The linear schedule is the one behavior the suite pins down: 10s, 20s,
// ... . Everything else (loop, logging, cancellation) belongs to the
// backoff library.
func TestLinearAttemptBackOffSchedule(t *testing.T) {
	b := &linearAttemptBackOff{}
	for i, want := range []time.Duration{10 * time.Second, 20 * time.Second, 30 * time.Second} {
		if got := b.NextBackOff(); got != want {
			t.Fatalf("attempt %d backoff = %v, want %v", i+1, got, want)
		}
	}
	b.Reset()
	if got := b.NextBackOff(); got != 10*time.Second {
		t.Fatalf("after Reset backoff = %v, want 10s", got)
	}
}

// Immediate success passes the output through with a single run.
func TestRetryImmediateSuccess(t *testing.T) {
	t.Setenv("E2E_RETRY_ATTEMPTS", "")
	calls := 0
	out := Retry(context.Background(), t, "immediate", func() (int, string) {
		calls++
		return 0, "ok"
	})
	if out != "ok" || calls != 1 {
		t.Fatalf("out = %q after %d calls, want %q after 1", out, calls, "ok")
	}
}

// One failure then success exercises the library round trip (notify +
// backoff wait + second attempt) end to end; it takes ~10s of real wait.
func TestRetryRecoversAfterFailure(t *testing.T) {
	t.Setenv("E2E_RETRY_ATTEMPTS", "")
	calls := 0
	out := Retry(context.Background(), t, "recover", func() (int, string) {
		calls++
		if calls == 1 {
			return 1, "first failed"
		}
		return 0, "second ok"
	})
	if out != "second ok" || calls != 2 {
		t.Fatalf("out = %q after %d calls, want %q after 2", out, calls, "second ok")
	}
}
