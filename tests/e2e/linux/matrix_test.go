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
	"testing"
)

func TestMaxJobsDefault(t *testing.T) {
	t.Setenv("E2E_MAX_JOBS", "")
	// empty means unset-equivalent for maxJobs (Atoi fails -> default 3)
	if got := maxJobs(); got != 3 {
		t.Errorf("maxJobs = %d, want 3", got)
	}
	t.Setenv("E2E_MAX_JOBS", "0")
	if got := maxJobs(); got != 3 {
		t.Errorf("maxJobs(0) = %d, want 3 (clamped to default)", got)
	}
}

func TestShQuote(t *testing.T) {
	if got := shQuote(`a "b" c`); got != `'a "b" c'` {
		t.Errorf("shQuote = %q", got)
	}
	if got := shQuote(`it's`); got != `'it'\''s'` {
		t.Errorf("shQuote escape = %q", got)
	}
}
