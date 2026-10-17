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

// Package e2e is the single Go module root of the container E2E suites.
//
// This directory holds no test logic, only the module definition
// (go.mod/go.sum) and the orchestration files; the code is split by
// subpackage:
//
//   - common: target-independent shared logic (matrix expansion, version
//     defaults, distribution facts, output parsing, retry counts, name
//     handling);
//   - linux: the Linux container suite (bash-driven), run in CI and locally
//     through the repository dev container (.devcontainer/, see docs/e2e.md);
//   - windows: the Windows container suite (pwsh-driven), run via
//     tests/e2e/windows/compose.amd64.yaml (amd64) or
//     tests/e2e/windows/compose.arm64.yaml (arm64) as `go test ./windows/`.
//
// Pure unit tests without containers (matrix expansion and friends) run from
// the module root:
//
//	go test -short ./...
package e2e
