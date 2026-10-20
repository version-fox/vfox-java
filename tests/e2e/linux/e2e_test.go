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

// Package linux is the Linux container E2E suite, driven entirely from Go via
// testcontainers-go.
//
// TestE2E builds the image in tests/e2e/linux/Dockerfile once, then runs one
// long-lived container per (vfox version x distribution) combination and
// drives setup -> install -> verify through exec calls (setup.go,
// install.go, verify.go), asserting in Go. Target-independent logic (matrix
// expansion and friends) is reused from the common package.
package linux

import (
	"context"
	"os"
	"path/filepath"
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
// VFOX_VERSION=latest DISTRIBUTION=tem E2E_MAX_JOBS=1 go test -v ./linux/
func TestE2E(t *testing.T) {
	if testing.Short() {
		t.Skip("skip container E2E in short mode")
	}

	arch, err := common.DetectArch()
	if err != nil {
		t.Fatal(err)
	}
	platform := "linux/" + arch
	image := "vfox-java-e2e:linux-" + arch

	here, err := filepath.Abs(".")
	if err != nil {
		t.Fatal(err)
	}
	repoRoot := filepath.Join(here, "..", "..", "..")

	ctx := context.Background()
	buildImage(t, ctx, repoRoot, image, platform)

	combos, err := common.Matrix()
	if err != nil {
		t.Fatal(err)
	}
	if len(combos) == 0 {
		t.Fatal("empty matrix: nothing to run")
	}

	sem := make(chan struct{}, maxJobs())
	for _, c := range combos {
		c := c
		t.Run(c.Slug(), func(t *testing.T) {
			t.Parallel()
			sem <- struct{}{}
			defer func() { <-sem }()
			runOne(t, ctx, image, platform, arch, c)
		})
	}
}

// buildImage replicates `docker build --pull --platform $platform
// --file tests/e2e/linux/Dockerfile --tag $image $repoRoot`.
func buildImage(t *testing.T, ctx context.Context, repoRoot, image, platform string) {
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
			Dockerfile:     "tests/e2e/linux/Dockerfile",
			Repo:           "vfox-java-e2e",
			Tag:            image[strings.LastIndex(image, ":")+1:],
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

// runOne starts one long-lived container per combo and drives the whole
// E2E flow (setup -> install -> verify) through exec calls, asserting in Go.
// A combo passes when every phase exits 0 and the outputs carry the expected
// markers.
func runOne(t *testing.T, ctx context.Context, image, platform, arch string, c common.Combo) {
	t.Helper()
	prefix := c.Prefix(platform)

	env := map[string]string{
		"VFOX_VERSION": c.Vfox,
		"DISTRIBUTION": c.Distribution,
	}
	for _, name := range common.PassThroughEnvs {
		if v, ok := os.LookupEnv(name); ok && v != "" {
			env[name] = v
		}
	}

	ctr, err := tc.GenericContainer(ctx, tc.GenericContainerRequest{
		ContainerRequest: tc.ContainerRequest{
			Image:         image,
			ImagePlatform: platform,
			Name:          common.ContainerName(c.Slug()),
			Env:           env,
		},
		Started: true,
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
	machine := strings.TrimSpace(execOK(ctx, t, ctr, "uname --machine"))
	t.Logf("=== vfox %s, java@%s, %s (%s) ===", c.Vfox, common.Spec(c.Distribution, version), platform, machine)

	setupVfox(ctx, t, ctr, c.Vfox)
	checkNotes(ctx, t, ctr)
	checkVersionlessRejected(ctx, t, ctr, c.Distribution)
	checkMissingVersionRejected(ctx, t, ctr, c.Distribution, version, arch)
	if common.ChecksOracleGraalVM(c.Distribution) {
		checkGraalVMBareMajor(ctx, t, ctr)
	}
	if common.ChecksNameOnly(c.Distribution) {
		checkNameOnly(ctx, t, ctr, platform)
	}
	if common.ChecksOwnNumbers(c.Distribution) {
		checkOwnNumbers(ctx, t, ctr, platform)
	}

	installed := installJava(ctx, t, ctr, common.Spec(c.Distribution, version))
	verifySearch(ctx, t, ctr, c.Distribution, installed)
	// Before any `vfox use`, so java can only come from the legacy file.
	verifyLegacyFile(ctx, t, ctr, c.Distribution, version, installed, arch)

	useJava(ctx, t, ctr, installed)
	verifyToolchain(ctx, t, ctr, c.Distribution, version, installed, arch)
	verifyPreUse(ctx, t, ctr, c.Distribution, version, installed)
}
