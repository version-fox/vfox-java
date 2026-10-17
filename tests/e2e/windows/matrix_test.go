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

import "testing"

func TestMaxJobsDefault(t *testing.T) {
	t.Setenv("E2E_MAX_JOBS", "")
	// empty means unset-equivalent for maxJobs (Atoi fails -> default 2)
	if got := maxJobs(); got != 2 {
		t.Errorf("maxJobs = %d, want 2", got)
	}
	t.Setenv("E2E_MAX_JOBS", "0")
	if got := maxJobs(); got != 2 {
		t.Errorf("maxJobs(0) = %d, want 2 (clamped to default)", got)
	}
}

func TestPwshQuote(t *testing.T) {
	if got := pwshQuote(`C:\a\b`); got != `'C:\a\b'` {
		t.Errorf("pwshQuote = %q", got)
	}
	if got := pwshQuote(`it's`); got != `'it''s'` {
		t.Errorf("pwshQuote escape = %q", got)
	}
}
