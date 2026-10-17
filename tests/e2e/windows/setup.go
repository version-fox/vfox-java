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
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"testing"

	"github.com/stretchr/testify/require"
	tc "github.com/testcontainers/testcontainers-go"

	"github.com/version-fox/vfox-java/tests/e2e/common"
)

// Java defaults live in the common package; only Windows-specific values
// stay here.
const (
	// spacedVfoxHome is the default vfox home of a Windows account whose
	// name contains a space, the layout reported in
	// https://github.com/version-fox/vfox-flutter/issues/33 .
	spacedVfoxHome = `C:\Users\John Doe\.vfox`

	// vfoxMainSource is vfox's main branch, built once per run for every
	// main combo (see vfoxMainImage).
	vfoxMainSource = "https://github.com/version-fox/vfox/archive/refs/heads/main.tar.gz"

	// mainVfoxExe is where the main combos' image carries that build.
	mainVfoxExe = "C:/vfox-main/vfox.exe"
)

// pwshQuote renders a single-quoted PowerShell string literal.
func pwshQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", "''") + "'"
}

// slotBox carries the per-combo isolated profile locations plus the exec env
// overrides that apply them (each exec starts a fresh process, so the
// $env: assignments cannot persist and must ride along).
type slotBox struct {
	slot     string
	slotRoot string
	tmp      string
	workDir  string
	vfoxExe  string
	pluginZw string
	vars     []string
}

// setupSlotEnv isolates the combo: USERPROFILE/TEMP/TMP point under
// vfox-e2e-runs\<slot>, while VFOX_HOME is spacedVfoxHome. Each combo runs in
// its own container, so the shared VFOX_HOME never leaks between combos. Both
// vfox main and releases since v1.0.13 handle a home containing a space
// (https://github.com/version-fox/vfox/pull/712).
func setupSlotEnv(ctx context.Context, t *testing.T, ctr tc.Container, slot string) slotBox {
	t.Helper()
	userProfile := strings.TrimSpace(execOK(ctx, t, ctr, "$env:USERPROFILE"))
	containerPath := strings.TrimSpace(execOK(ctx, t, ctr, "$env:PATH"))
	procArch := strings.TrimSpace(execOK(ctx, t, ctr, "$env:PROCESSOR_ARCHITECTURE"))

	home := spacedVfoxHome
	box := slotBox{slot: slot}
	box.slotRoot = userProfile + `\vfox-e2e-runs\` + slot
	box.tmp = box.slotRoot + `\tmp`
	box.workDir = box.tmp + `\vfox-java-e2e`
	box.vfoxExe = box.workDir + `\vfox.exe`
	box.pluginZw = box.workDir + `\java.zip`
	box.vars = []string{
		"USERPROFILE=" + box.slotRoot,
		"VFOX_HOME=" + home,
		"TEMP=" + box.tmp,
		"TMP=" + box.tmp,
		"PATH=" + box.workDir + ";" + containerPath,
	}

	execOK(ctx, t, ctr, fmt.Sprintf(
		"New-Item -ItemType Directory -Force -Path %s | Out-Null; "+
			"New-Item -ItemType Directory -Force -Path %s | Out-Null; "+
			"New-Item -ItemType Directory -Force -Path %s | Out-Null",
		pwshQuote(box.tmp), pwshQuote(box.workDir), pwshQuote(home)))
	t.Logf("PASS slot %s isolated at %s (vfox home %s, arch %s)", slot, box.slotRoot, home, procArch)
	return box
}

// procArchOfContainer reports $env:PROCESSOR_ARCHITECTURE (AMD64/ARM64/x86).
func procArchOfContainer(ctx context.Context, t *testing.T, ctr tc.Container) string {
	t.Helper()
	return strings.TrimSpace(execOK(ctx, t, ctr, "$env:PROCESSOR_ARCHITECTURE"))
}

// curlRetry flags shared by every curl.exe download.
const curlRetry = "--retry 3 --retry-delay 5 --retry-all-errors"

// installVfoxRelease resolves the latest vfox tag, downloads the windows
// zip, extracts it, and stages vfox.exe into the work dir.
func installVfoxRelease(ctx context.Context, t *testing.T, ctr tc.Container, box slotBox, procArch string) {
	t.Helper()
	effective := strings.TrimSpace(execOK(ctx, t, ctr,
		`curl.exe `+curlRetry+` -fsSLI -o NUL -w '%{url_effective}' https://github.com/version-fox/vfox/releases/latest`,
		box.vars...))
	parts := strings.Split(effective, "/tag/")
	tag := strings.TrimSpace(parts[len(parts)-1])
	if tag == "" {
		t.Fatalf("could not resolve the latest vfox tag from %q", effective)
	}
	vfoxArch := "x86_64"
	if procArch == "ARM64" {
		vfoxArch = "aarch64"
	}
	zipPath := box.workDir + `\vfox.zip`
	url := fmt.Sprintf("https://github.com/version-fox/vfox/releases/download/%s/vfox_%s_windows_%s.zip",
		tag, strings.TrimPrefix(tag, "v"), vfoxArch)
	execOK(ctx, t, ctr, fmt.Sprintf(
		"curl.exe %s -fsSL -o %s %s",
		curlRetry, pwshQuote(zipPath), pwshQuote(url)), box.vars...)
	execOK(ctx, t, ctr, fmt.Sprintf(
		"tar -xf %s -C %s; Remove-Item %s; "+
			"Copy-Item -Path (Get-ChildItem -Path %s -Recurse -Filter 'vfox.exe') -Destination %s",
		pwshQuote(zipPath), pwshQuote(box.workDir), pwshQuote(zipPath),
		pwshQuote(box.workDir), pwshQuote(box.vfoxExe)), box.vars...)
	t.Logf("PASS installed vfox %s (%s)", tag, vfoxArch)
}

// vfoxMainImage is the e2e image plus vfox.exe built from main, which every
// main combo starts from. The runner compiles vfox once, with its own Go,
// while the image builds; building it in each main combo's container meant
// installing the Go MSI there, then cloning and building, over two minutes a
// combo on arm64.
type vfoxMainImage struct {
	base, arch string

	built chan struct{} // closed once exe and err are set
	exe   string
	once  sync.Once
	image string
	err   error
}

// startVfoxMain starts compiling vfox from main in the background, for the
// image that layers it onto base.
func startVfoxMain(ctx context.Context, t *testing.T, base, arch string) *vfoxMainImage {
	t.Helper()
	m := &vfoxMainImage{base: base, arch: arch, built: make(chan struct{})}
	dir := t.TempDir()
	ctx, cancel := context.WithCancel(ctx)
	go func() {
		defer close(m.built)
		m.exe, m.err = buildVfoxMain(ctx, dir, arch)
	}()
	// Before dir is removed: a run that fails early stops the build.
	t.Cleanup(func() {
		cancel()
		<-m.built
	})
	return m
}

// get returns the image, layering the compiled vfox.exe onto base on first
// use; the other main combos wait for it. A failed build fails every main
// combo.
func (m *vfoxMainImage) get(ctx context.Context, t *testing.T) string {
	t.Helper()
	m.once.Do(func() {
		<-m.built
		if m.err == nil {
			m.image, m.err = buildMainImage(ctx, m.base, m.exe)
		}
		if m.err == nil {
			t.Logf("PASS built vfox from main with %s (%s)", runtime.Version(), m.arch)
		}
	})
	if m.err != nil {
		t.Fatalf("build vfox from main: %v", m.err)
	}
	return m.image
}

// buildVfoxMain downloads vfox's main branch into dir and builds vfox.exe
// there for arch with the runner's Go, returning its path. It runs
// Windows' own curl and tar: CI runners also put Git's GNU tar on the PATH,
// which reads the colon of a drive letter as a remote host.
func buildVfoxMain(ctx context.Context, dir, arch string) (string, error) {
	tarball := filepath.Join(dir, "vfox-main.tar.gz")
	exe := filepath.Join(dir, "vfox.exe")
	system32 := filepath.Join(os.Getenv("SystemRoot"), "System32")
	download := exec.CommandContext(ctx, filepath.Join(system32, "curl.exe"),
		append(strings.Fields(curlRetry), "-fsSL", "-o", tarball, vfoxMainSource)...)
	extract := exec.CommandContext(ctx, filepath.Join(system32, "tar.exe"), "-xzf", tarball, "-C", dir)
	build := exec.CommandContext(ctx, "go", "build", "-trimpath", "-o", exe, ".")
	build.Dir = filepath.Join(dir, "vfox-main")
	build.Env = append(os.Environ(), "CGO_ENABLED=0", "GOOS=windows", "GOARCH="+arch)
	for _, cmd := range []*exec.Cmd{download, extract, build} {
		if out, err := cmd.CombinedOutput(); err != nil {
			return "", fmt.Errorf("%s: %w\n%s", strings.Join(cmd.Args, " "), err, out)
		}
	}
	return exe, nil
}

// installVfoxMain stages the vfox.exe built from main that the main combos'
// image carries (see vfoxMainImage).
func installVfoxMain(ctx context.Context, t *testing.T, ctr tc.Container, box slotBox) {
	t.Helper()
	execOK(ctx, t, ctr, fmt.Sprintf("Copy-Item -Path %s -Destination %s",
		pwshQuote(mainVfoxExe), pwshQuote(box.vfoxExe)), box.vars...)
	t.Logf("PASS staged vfox built from main")
}

// setupVfox installs vfox (release, or the build from main) and registers
// the local java plugin.
func setupVfox(ctx context.Context, t *testing.T, ctr tc.Container, box slotBox, vfoxVersion string) {
	t.Helper()
	if vfoxVersion == "main" {
		installVfoxMain(ctx, t, ctr, box)
	} else {
		installVfoxRelease(ctx, t, ctr, box, procArchOfContainer(ctx, t, ctr))
	}
	execOK(ctx, t, ctr, fmt.Sprintf(
		"tar -a -cf %s -C 'C:\\e2e' metadata.lua hooks lib",
		pwshQuote(box.pluginZw)), box.vars...)
	execOK(ctx, t, ctr,
		fmt.Sprintf("vfox add java --source %s", pwshQuote(box.pluginZw)), box.vars...)
}

// fetchActivation captures `vfox activate pwsh` once per container; the
// output is prepended to later scripts via activated()/activatedEnv(), since
// each exec starts a fresh process and the $env: assignments cannot persist.
func fetchActivation(ctx context.Context, t *testing.T, ctr tc.Container, box slotBox) string {
	t.Helper()
	out := execOK(ctx, t, ctr, "vfox activate pwsh", box.vars...)
	if strings.TrimSpace(out) == "" {
		t.Fatal("vfox activate pwsh produced no output")
	}
	return out
}

// activated prepends captured activation code to a script. `vfox use` needs
// the activation context ("vfox requires hook support" otherwise).
func activated(activation, script string) string {
	return activation + "\r\n" + script
}

// activatedEnv is activated plus a fresh `vfox env` export. vfox's pwsh
// activation refreshes the toolchain env lazily through a prompt hook, which
// never runs in non-interactive `pwsh -Command` execs, so each call must pull
// the export explicitly (mirrors what the prompt hook itself runs).
// Only valid after a version is selected via `vfox use`.
func activatedEnv(activation, script string) string {
	return activation + "\r\n$__vfoxExport = vfox env -s pwsh | Out-String; " +
		"if ($__vfoxExport.Trim()) { Invoke-Expression -Command $__vfoxExport }\r\n" + script
}

// checkMissingVersionRejected proves an unpublished release, and an
// unpublished build of the pinned one, fail loudly instead of installing
// something else: PreInstall finds no Foojay package (zip or tar.gz) and
// names the platform it searched, which must be the runner's
// (RUNTIME.osType/archType).
func checkMissingVersionRejected(ctx context.Context, t *testing.T, ctr tc.Container, box slotBox, distribution, version, arch string) {
	t.Helper()
	for _, spec := range []string{common.MissingSpec(distribution, version), common.MissingBuildSpec(distribution, version)} {
		want := "No JDK found for " + spec
		out := common.Retry(ctx, t, "vfox install java@"+spec+" (must fail)", func() (int, string) {
			code, out := execRun(ctx, t, ctr, "vfox install "+pwshQuote("java@"+spec), box.vars...)
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
		require.Contains(t, out, " on windows/"+arch, "the lookup must target the runner platform")
		t.Logf("PASS java@%s is rejected on windows/%s", spec, arch)
	}
}
