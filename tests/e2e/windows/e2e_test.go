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

// Package windows is the Windows container E2E suite, driven entirely from
// Go via testcontainers-go.
//
// TestE2E builds the image in tests/e2e/windows/Dockerfile once, then runs
// one long-lived container per (vfox version x distribution) combination and
// drives setup -> install -> verify through pwsh exec calls (setup.go,
// install.go, verify.go), asserting in Go. Target-independent logic (matrix
// expansion and friends) is reused from the common package.
package windows

import (
	"archive/tar"
	"bytes"
	"context"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/containerd/platforms"
	specs "github.com/opencontainers/image-spec/specs-go/v1"
	tc "github.com/testcontainers/testcontainers-go"

	client "github.com/moby/moby/client"

	"github.com/version-fox/vfox-java/tests/e2e/common"
)

// TestE2E builds the image once, then runs one container per matrix combo.
// Bounded parallelism via t.Parallel + semaphore (like E2E_MAX_JOBS).
//
// Full matrix runs in CI; locally scope it down, e.g.:
// VFOX_VERSION=latest DISTRIBUTION=tem E2E_MAX_JOBS=1 go test -v ./windows/
func TestE2E(t *testing.T) {
	if testing.Short() {
		t.Skip("skip container E2E in short mode")
	}
	// Ryuk has no Windows image, so the reaper can never start here.
	// Every container is terminated explicitly via t.Cleanup instead.
	t.Setenv("TESTCONTAINERS_RYUK_DISABLED", "true")

	arch, err := common.DetectArch()
	if err != nil {
		t.Fatal(err)
	}
	platform := "windows/" + arch
	image := "vfox-java-e2e:windows-" + arch
	baseImage := "mcr.microsoft.com/windows/servercore:ltsc2025-KB5122871-" + arch

	here, err := filepath.Abs(".")
	if err != nil {
		t.Fatal(err)
	}
	repoRoot := filepath.Join(here, "..", "..", "..")

	combos, err := common.Matrix()
	if err != nil {
		t.Fatal(err)
	}
	if len(combos) == 0 {
		t.Fatal("empty matrix: nothing to run")
	}

	ctx := context.Background()
	// The main combos' vfox compiles while the image builds.
	var vfoxMain *vfoxMainImage
	if slices.ContainsFunc(combos, func(c common.Combo) bool { return c.Vfox == "main" }) {
		vfoxMain = startVfoxMain(ctx, t, image, arch)
	}
	buildImage(t, ctx, repoRoot, image, platform, baseImage)

	sem := make(chan struct{}, maxJobs())
	for _, c := range combos {
		c := c
		t.Run(c.Slug(), func(t *testing.T) {
			t.Parallel()
			image := image
			if c.Vfox == "main" {
				// Before taking a slot, so the latest combos run meanwhile.
				image = vfoxMain.get(ctx, t)
			}
			sem <- struct{}{}
			defer func() { <-sem }()
			runOne(t, ctx, image, platform, arch, c)
		})
	}
}

// buildImage replicates `docker build --pull --platform $platform
// --build-arg BASE_IMAGE=$baseImage -f tests/e2e/windows/Dockerfile
// -t $image $repoRoot`.
func buildImage(t *testing.T, ctx context.Context, repoRoot, image, platform, baseImage string) {
	t.Helper()

	provider, err := tc.NewDockerProvider()
	if err != nil {
		t.Fatalf("new docker provider: %v", err)
	}
	t.Cleanup(func() { _ = provider.Close() })

	pf, err := platforms.Parse(platform)
	if err != nil {
		t.Fatalf("invalid platform %s: %v", platform, err)
	}

	tag, err := provider.BuildImage(ctx, &tc.ContainerRequest{
		FromDockerfile: tc.FromDockerfile{
			Context:        repoRoot,
			Dockerfile:     "tests/e2e/windows/Dockerfile",
			Repo:           "vfox-java-e2e",
			Tag:            image[strings.LastIndex(image, ":")+1:],
			BuildArgs:      map[string]*string{"BASE_IMAGE": &baseImage},
			KeepImage:      true,
			BuildLogWriter: os.Stdout,
			BuildOptionsModifier: func(opts *client.ImageBuildOptions) {
				opts.Platforms = []specs.Platform{pf}
				opts.PullParent = true
			},
		},
	})
	if err != nil {
		t.Fatalf("build image %s: %v", image, err)
	}
	if tag != image {
		t.Fatalf("built tag %s, want %s", tag, image)
	}
}

// buildMainImage layers vfox.exe onto base as <base>-main, for the main
// combos. Its build context is that file and the Dockerfile alone,
// assembled in memory.
func buildMainImage(ctx context.Context, base, exe string) (string, error) {
	vfox, err := os.ReadFile(exe)
	if err != nil {
		return "", err
	}
	var buildContext bytes.Buffer
	tw := tar.NewWriter(&buildContext)
	for _, f := range []struct {
		name string
		data []byte
	}{
		{"Dockerfile", []byte("FROM " + base + "\nCOPY vfox.exe " + mainVfoxExe + "\n")},
		{"vfox.exe", vfox},
	} {
		if err := tw.WriteHeader(&tar.Header{Name: f.name, Mode: 0o644, Size: int64(len(f.data))}); err != nil {
			return "", err
		}
		if _, err := tw.Write(f.data); err != nil {
			return "", err
		}
	}
	if err := tw.Close(); err != nil {
		return "", err
	}

	provider, err := tc.NewDockerProvider()
	if err != nil {
		return "", fmt.Errorf("new docker provider: %w", err)
	}
	defer provider.Close()
	// No PullParent: base exists only on this daemon.
	return provider.BuildImage(ctx, &tc.ContainerRequest{
		FromDockerfile: tc.FromDockerfile{
			ContextArchive: bytes.NewReader(buildContext.Bytes()),
			Repo:           "vfox-java-e2e",
			Tag:            base[strings.LastIndex(base, ":")+1:] + "-main",
			KeepImage:      true,
			BuildLogWriter: os.Stdout,
		},
	})
}

// runOne starts one long-lived container per combo and drives the whole
// E2E flow (setup -> install -> verify) through pwsh exec calls, asserting
// in Go. A combo passes when every phase exits 0 and the outputs carry the
// expected markers. Every combo runs against a VFOX_HOME containing a
// space (see spacedVfoxHome).
func runOne(t *testing.T, ctx context.Context, image, platform, arch string, c common.Combo) {
	t.Helper()
	prefix := c.Prefix(platform)

	env := map[string]string{
		"VFOX_VERSION":  c.Vfox,
		"DISTRIBUTION":  c.Distribution,
		"VFOX_E2E_SLOT": c.Slug(),
	}
	for _, name := range common.PassThroughEnvs {
		if v, ok := os.LookupEnv(name); ok && v != "" {
			env[name] = v
		}
	}

	// Stock Windows daemons have no "bridge" network (only "nat"), and
	// CreateContainer unconditionally ensures the provider's default bridge
	// network, creating it when missing. Point it at "nat" — the daemon
	// default that plain `docker run` also uses — or every start fails with
	// "could not find plugin bridge".
	provider, err := tc.NewDockerProvider(tc.WithDefaultBridgeNetwork("nat"))
	if err != nil {
		t.Fatalf("[%s] new docker provider: %v", prefix, err)
	}
	// NB: no provider.Close here: the container below terminates through
	// this very provider in t.Cleanup.
	ctr, err := provider.RunContainer(ctx, tc.ContainerRequest{
		Image:         image,
		ImagePlatform: platform,
		Name:          common.ContainerName(c.Slug()),
		Env:           env,
	})
	if err != nil {
		t.Fatalf("[%s] start container: %v", prefix, err)
	}
	t.Cleanup(func() {
		_ = ctr.Terminate(context.Background())
	})

	// One overall budget per combo; the CI job timeout stays the outer bound.
	ctx, cancel := context.WithTimeout(ctx, 45*time.Minute)
	defer cancel()

	version := common.ResolveJavaVersion(t, c.Distribution)
	procArch := procArchOfContainer(ctx, t, ctr)
	t.Logf("=== vfox %s, java@%s, %s (%s) ===", c.Vfox, common.Spec(c.Distribution, version), platform, procArch)

	box := setupSlotEnv(ctx, t, ctr, c.Slug())
	setupVfox(ctx, t, ctr, box, c.Vfox)
	checkNotes(ctx, t, ctr, box)
	activation := fetchActivation(ctx, t, ctr, box)
	checkVersionlessRejected(ctx, t, ctr, box, activation, c.Distribution)
	checkMissingVersionRejected(ctx, t, ctr, box, c.Distribution, version, arch)
	if common.ChecksOracleGraalVM(c.Distribution) {
		checkGraalVMBareMajor(ctx, t, ctr, box)
	}
	if common.ChecksNameOnly(c.Distribution) {
		checkNameOnly(ctx, t, ctr, box, platform)
	}

	installed := installJava(ctx, t, ctr, box, common.Spec(c.Distribution, version))
	verifySearch(ctx, t, ctr, box, c.Distribution, installed)
	// Before any `vfox use`, so java can only come from the legacy file.
	verifyLegacyFile(ctx, t, ctr, box, c.Distribution, version, installed, arch)

	useJava(ctx, t, ctr, box, activation, installed)
	verifyToolchain(ctx, t, ctr, box, activation, c.Distribution, version, installed, arch)
	verifyPreUse(ctx, t, ctr, box, activation, c.Distribution, version, installed)
}
