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

// Retry helpers shared by the Linux and Windows container suites.
//
// Both suites shell out into throwaway containers where downloads and
// daemon calls flake, so every network-touching exec goes through Retry:
// linear 10s*attempt backoff with per-attempt logging, driven by
// github.com/cenkalti/backoff/v7 instead of a hand-rolled loop. Only the
// backoff schedule itself stays local (linearAttemptBackOff): no third-party
// policy reproduces the exact 10s/20s/... cadence the suite's timeouts were
// tuned against.
package common

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/cenkalti/backoff/v7"
)

// linearAttemptBackOff waits 10s after the first failure, 20s after the
// second, and so on. It exists only to preserve the suite's historical
// cadence; the retry loop, logging fan-out and context handling come from
// the backoff library.
type linearAttemptBackOff struct {
	attempt int
}

func (b *linearAttemptBackOff) NextBackOff() time.Duration {
	b.attempt++
	return time.Duration(10*b.attempt) * time.Second
}

func (b *linearAttemptBackOff) Reset() {
	b.attempt = 0
}

// Retry runs run until it reports exit code 0, giving up after
// RetryAttempts() attempts. It returns the successful run's output and
// fatals (with the last output attached) once the budget is exhausted.
func Retry(ctx context.Context, t *testing.T, label string, run func() (code int, output string)) string {
	t.Helper()
	max := RetryAttempts()
	if max < 1 {
		max = 1
	}
	var out string
	var code, attempts int
	notify := func(_ error, _ time.Duration) {
		t.Logf("retrying %s, attempt %d exited %d", label, attempts, code)
		t.Logf("--- output ---\n%s", out)
	}
	result, err := backoff.Retry(ctx, func() (string, error) {
		attempts++
		code, out = run()
		if code == 0 {
			return out, nil
		}
		return "", fmt.Errorf("%s: attempt %d exited %d", label, attempts, code)
	},
		backoff.WithBackOff(&linearAttemptBackOff{}),
		backoff.WithMaxTries(uint(max)),
		// Bound retries by attempt count and the caller's context only;
		// the library's default 15-minute elapsed budget must not cut
		// long downloads short.
		backoff.WithMaxElapsedTime(0),
		backoff.WithNotify(notify),
	)
	if err != nil {
		if ctx.Err() != nil {
			t.Fatalf("%s: %v", label, ctx.Err())
		}
		t.Fatalf("%s failed after %d attempt(s) (exit %d)\n--- output ---\n%s", label, attempts, code, out)
	}
	return result
}
