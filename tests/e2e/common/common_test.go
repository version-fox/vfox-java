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
	"slices"
	"testing"
)

func setEnv(t *testing.T, kv map[string]string) {
	t.Helper()
	for k, v := range kv {
		t.Setenv(k, v)
	}
}

func comboKeys(combos []Combo) []string {
	keys := make([]string, 0, len(combos))
	for _, c := range combos {
		keys = append(keys, c.Vfox+"/"+c.Distribution)
	}
	return keys
}

// Default amd64 matrix: every distribution against both vfox channels.
func TestMatrixDefaultAmd64(t *testing.T) {
	t.Setenv("VFOX_VERSION", "")
	t.Setenv("DISTRIBUTION", "")

	// t.Setenv sets the var to "" which LookupEnv reports as set; the empty
	// values above exercise the real defaults via Fields dropping empties.
	combos, err := MatrixForArch("amd64")
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("combos: %v", comboKeys(combos))
	if want := 2 * len(DefaultDistributions("amd64")); len(combos) != want {
		t.Fatalf("combos = %v, want %d", comboKeys(combos), want)
	}
}

// arm64 defaults: only distributions published for windows-aarch64 too.
func TestMatrixDefaultArm64(t *testing.T) {
	setEnv(t, map[string]string{
		"VFOX_VERSION": "latest main",
		"DISTRIBUTION": "",
	})

	combos, err := MatrixForArch("arm64")
	if err != nil {
		t.Fatal(err)
	}
	if len(combos) == 0 {
		t.Fatal("empty matrix")
	}
	for _, c := range combos {
		switch c.Distribution {
		case "open", "graalce":
			t.Errorf("arm64 runs %s, which has no windows-aarch64 build", c.Distribution)
		}
	}
}

// Every default distribution has a pinned version.
func TestDefaultVersionsCoverDefaults(t *testing.T) {
	for _, arch := range []string{"amd64", "arm64"} {
		for _, d := range DefaultDistributions(arch) {
			if _, ok := DefaultVersions[d]; !ok {
				t.Errorf("%s default distribution %s has no pinned version", arch, d)
			}
		}
	}
}

// Explicit VFOX_VERSION and DISTRIBUTION narrow the matrix.
func TestMatrixExplicit(t *testing.T) {
	setEnv(t, map[string]string{
		"VFOX_VERSION": "main",
		"DISTRIBUTION": "tem zulu-fx",
	})

	combos, err := MatrixForArch("amd64")
	if err != nil {
		t.Fatal(err)
	}
	if got := comboKeys(combos); len(got) != 2 || got[0] != "main/tem" || got[1] != "main/zulu-fx" {
		t.Fatalf("combos = %v, want [main/tem main/zulu-fx]", got)
	}
}

// PROCESSOR_ARCHITECTURE values from real Windows hosts resolve correctly.
func TestMatrixProcessorArchitecture(t *testing.T) {
	t.Setenv("PROCESSOR_ARCHITECTURE", "ARM64")
	t.Setenv("VFOX_VERSION", "latest")
	t.Setenv("DISTRIBUTION", "")
	combos, err := Matrix()
	if err != nil {
		t.Fatal(err)
	}
	if want := len(DefaultDistributions("arm64")); len(combos) != want {
		t.Fatalf("combos = %v, want %d", comboKeys(combos), want)
	}
}

// Unknown architectures fail fast instead of running a wrong matrix.
func TestMatrixUnknownArch(t *testing.T) {
	t.Setenv("PROCESSOR_ARCHITECTURE", "bogus64")
	if _, err := Matrix(); err == nil {
		t.Error("Matrix() with bogus PROCESSOR_ARCHITECTURE succeeded, want error")
	}
}

func TestNormalizeArch(t *testing.T) {
	for in, want := range map[string]string{
		"AMD64": "amd64", "x86_64": "amd64", "x64": "amd64", "amd64": "amd64",
		"ARM64": "arm64", "aarch64": "arm64", "arm64": "arm64",
	} {
		got, err := NormalizeArch(in)
		if err != nil || got != want {
			t.Errorf("NormalizeArch(%q) = %q, %v; want %q", in, got, err, want)
		}
	}
	for _, bad := range []string{"riscv64", "x86"} {
		if _, err := NormalizeArch(bad); err == nil {
			t.Errorf("NormalizeArch(%q) succeeded, want error", bad)
		}
	}
}

func TestSlug(t *testing.T) {
	got := Combo{Vfox: "latest", Distribution: "librca-fx"}.Slug()
	if want := "latest-librca_fx"; got != want {
		t.Errorf("slug = %q, want %q", got, want)
	}
}

func TestMaxJobs(t *testing.T) {
	t.Setenv("E2E_MAX_JOBS", "")
	// empty means unset-equivalent for MaxJobs (Atoi fails -> default)
	if got := MaxJobs(3); got != 3 {
		t.Errorf("MaxJobs = %d, want 3", got)
	}
	t.Setenv("E2E_MAX_JOBS", "0")
	if got := MaxJobs(3); got != 3 {
		t.Errorf("MaxJobs(0) = %d, want 3 (clamped to default)", got)
	}
	t.Setenv("E2E_MAX_JOBS", "2")
	if got := MaxJobs(3); got != 2 {
		t.Errorf("MaxJobs(2) = %d, want 2", got)
	}
}

func TestResolveJavaVersion(t *testing.T) {
	t.Setenv("JAVA_VERSION", "")
	if got := ResolveJavaVersion(t, "tem"); got != DefaultVersions["tem"] {
		t.Errorf("tem default = %q, want %q", got, DefaultVersions["tem"])
	}
	t.Setenv("JAVA_VERSION", "17.0.12")
	if got := ResolveJavaVersion(t, "zulu"); got != "17.0.12" {
		t.Errorf("override = %q, want 17.0.12", got)
	}
}

func TestRetryAttemptsDefault(t *testing.T) {
	t.Setenv("E2E_RETRY_ATTEMPTS", "")
	if got := RetryAttempts(); got != 3 {
		t.Errorf("retryAttempts = %d, want 3", got)
	}
	t.Setenv("E2E_RETRY_ATTEMPTS", "5")
	if got := RetryAttempts(); got != 5 {
		t.Errorf("retryAttempts = %d, want 5", got)
	}
}

func TestSpecs(t *testing.T) {
	for _, c := range []struct{ dist, version, spec, missing, missingBuild, legacy, decoy string }{
		{"open", "25.0.2", "25.0.2", "25.0.99", "25.0.2+99", "25.0.2-open", "25.0.20+1"},
		{"tem", "21.0.8", "21.0.8-tem", "21.0.99-tem", "21.0.8+99-tem", "21.0.8-tem", "21.0.80+1-tem"},
		{"librca-fx", "25.0.4", "25.0.4-librca-fx", "25.0.99-librca-fx", "25.0.4+99-librca-fx", "25.0.4.fx-librca", "25.0.40+1-librca-fx"},
		{"jb", "21.0.5", "21.0.5-jb", "21.0.99-jb", "21.0.5+99-jb", "21.0.5-jbr", "21.0.50+1-jb"},
	} {
		if got := Spec(c.dist, c.version); got != c.spec {
			t.Errorf("Spec(%s, %s) = %q, want %q", c.dist, c.version, got, c.spec)
		}
		if got := MissingSpec(c.dist, c.version); got != c.missing {
			t.Errorf("MissingSpec(%s, %s) = %q, want %q", c.dist, c.version, got, c.missing)
		}
		if got := MissingBuildSpec(c.dist, c.version); got != c.missingBuild {
			t.Errorf("MissingBuildSpec(%s, %s) = %q, want %q", c.dist, c.version, got, c.missingBuild)
		}
		if got := LegacyIdentifier(c.dist, c.version); got != c.legacy {
			t.Errorf("LegacyIdentifier(%s, %s) = %q, want %q", c.dist, c.version, got, c.legacy)
		}
		if got := Decoy(c.dist, c.version); got != c.decoy {
			t.Errorf("Decoy(%s, %s) = %q, want %q", c.dist, c.version, got, c.decoy)
		}
	}
}

func TestPaddedIdentifier(t *testing.T) {
	for _, c := range []struct{ dist, version, installed, want string }{
		{"open", "25.0.2", "25.0.2+10", "25.0.2.0+10-open"},
		{"tem", "21.0.8", "21.0.8+9-tem", "21.0.8.0+9-tem"},
		{"librca-fx", "25.0.4", "25.0.4+9-librca-fx", "25.0.4.0-fx+9-librca"},
		{"jb", "21.0.5", "21.0.5+79248-jb", "21.0.5.0+79248-jbr"},
		{"graalce", "25.0.2", "25.0.2-graalce", "25.0.2.0-graalce"},
	} {
		if got := PaddedIdentifier(c.dist, c.version, c.installed); got != c.want {
			t.Errorf("PaddedIdentifier(%s, %s, %s) = %q, want %q", c.dist, c.version, c.installed, got, c.want)
		}
	}
}

func TestEarlyAccess(t *testing.T) {
	for _, c := range []struct{ dist, version, installed, identifier string }{
		{"open", "25.0.2", "25-ea+1", "25.0.0.0+ea.1-open"},
		{"tem", "21.0.8", "21-ea+1-tem", "21.0.0.0+ea.1-tem"},
		{"librca-fx", "25.0.4", "25-ea+1-librca-fx", "25.0.0.0-fx+ea.1-librca"},
		{"jb", "21.0.5", "21-ea+1-jb", "21.0.0.0+ea.1-jbr"},
		{"graalce", "25.0.2", "25-ea+1-graalce", "25.0.0.0+ea.1-graalce"},
	} {
		if got := EarlyAccess(c.dist, c.version); got != c.installed {
			t.Errorf("EarlyAccess(%s, %s) = %q, want %q", c.dist, c.version, got, c.installed)
		}
		if got := EarlyAccessIdentifier(c.dist, c.version); got != c.identifier {
			t.Errorf("EarlyAccessIdentifier(%s, %s) = %q, want %q", c.dist, c.version, got, c.identifier)
		}
	}
}

func TestAlias(t *testing.T) {
	for _, c := range []struct{ dist, installed, want string }{
		{"open", "25.0.2+10", "openjdk-25.0.2+10"},
		{"tem", "21.0.8+9-tem", "temurin-21.0.8+9"},
		{"librca-fx", "25.0.4+9-librca-fx", "liberica-25.0.4+9-fx"},
		{"jb", "21.0.5+79248-jb", "jetbrains-21.0.5+79248"},
		{"graalce", "25.0.2-graalce", "graalvm_community-25.0.2"},
	} {
		if got, ok := Alias(c.dist, c.installed); !ok || got != c.want {
			t.Errorf("Alias(%s, %s) = %q, %v; want %q", c.dist, c.installed, got, ok, c.want)
		}
	}
	for _, c := range []struct{ dist, installed string }{
		{"zulu", "21.0.8+9-zulu"},  // long name unknown to the suite
		{"tem", "21.0.8+9-librca"}, // not this distribution's version
	} {
		if got, ok := Alias(c.dist, c.installed); ok {
			t.Errorf("Alias(%s, %s) = %q, want none", c.dist, c.installed, got)
		}
	}
}

func TestPaddedSpecs(t *testing.T) {
	for _, c := range []struct {
		dist, version, installed string
		want                     []string
	}{
		{"open", "25.0.2", "25.0.2+10", []string{"25.0.2.0", "25.0.2.0+10"}},
		{"tem", "21.0.8", "21.0.8+9-tem", []string{"21.0.8.0-tem", "21.0.8.0+9-tem"}},
		{"librca-fx", "25.0.4", "25.0.4+9-librca-fx", []string{"25.0.4.0-librca-fx", "25.0.4.0+9-librca-fx"}},
		{"jb", "21.0.5", "21.0.5+79248-jb", []string{"21.0.5.0-jb", "21.0.5.0+79248-jb"}},
		// GraalVM's versions carry no build number.
		{"graalce", "25.0.2", "25.0.2-graalce", []string{"25.0.2.0-graalce"}},
	} {
		if got := PaddedSpecs(c.dist, c.version, c.installed); !slices.Equal(got, c.want) {
			t.Errorf("PaddedSpecs(%s, %s, %s) = %q, want %q", c.dist, c.version, c.installed, got, c.want)
		}
	}
}

func TestDistributionFacts(t *testing.T) {
	if v, ok := Vendor("librca-fx"); !ok || v != "BellSoft" {
		t.Errorf("Vendor(librca-fx) = %q, %v", v, ok)
	}
	if _, ok := Vendor("zulu"); ok {
		t.Error("Vendor(zulu) is known, want unknown")
	}
	if !JavaFX("librca-fx") || JavaFX("tem") || Base("librca-fx") != "librca" {
		t.Error("JavaFX/Base mishandle the -fx suffix")
	}
	if SearchArgs("open") != "" || SearchArgs("librca-fx") != " librca" {
		t.Errorf("SearchArgs = %q, %q", SearchArgs("open"), SearchArgs("librca-fx"))
	}
	if JavaArch("amd64") != "amd64" || JavaArch("arm64") != "aarch64" {
		t.Error("JavaArch must report the JVM os.arch names")
	}
	if got := HelloOutput("21.0.8", "arm64"); got != "hello 21.0.8 aarch64" {
		t.Errorf("HelloOutput = %q", got)
	}
}

func TestJavaProperties(t *testing.T) {
	// Abridged `java -XshowSettings:properties -version` output, with a
	// multi-line value and Windows line endings.
	out := "Property settings:\r\n" +
		"    java.class.path = \r\n" +
		"    java.home = /root/.vfox/cache/java/v-21.0.8+9-tem/java-21.0.8+9-tem\r\n" +
		"    java.library.path = /usr/java/packages/lib\r\n" +
		"        /usr/lib64\r\n" +
		"    java.vendor = Eclipse Adoptium\r\n" +
		"    java.version = 21.0.8\r\n" +
		"    os.arch = amd64\r\n" +
		"\r\n" +
		"openjdk version \"21.0.8\" 2025-07-15 LTS\r\n"
	props := JavaProperties(out)
	for k, want := range map[string]string{
		"java.class.path":   "",
		"java.home":         "/root/.vfox/cache/java/v-21.0.8+9-tem/java-21.0.8+9-tem",
		"java.library.path": "/usr/java/packages/lib",
		"java.vendor":       "Eclipse Adoptium",
		"java.version":      "21.0.8",
		"os.arch":           "amd64",
	} {
		if got, ok := props[k]; !ok || got != want {
			t.Errorf("%s = %q, %v; want %q", k, got, ok, want)
		}
	}
	if len(props) != 6 {
		t.Errorf("props = %v, want 6 entries", props)
	}
}

func TestInstalledVersion(t *testing.T) {
	out := "Preinstalling java@21.0.8+9-tem...\n" +
		"Install \x1b[92mjava@21.0.8+9-tem\x1b[0m success! \n" +
		"Please use `vfox use java@21.0.8+9-tem` to use it.\n"
	if got := InstalledVersion(out); got != "21.0.8+9-tem" {
		t.Errorf("InstalledVersion = %q, want 21.0.8+9-tem", got)
	}
	if got := InstalledVersion("java@21.0.8+9-tem is already installed"); got != "" {
		t.Errorf("InstalledVersion = %q, want empty", got)
	}
}

func TestListedVersions(t *testing.T) {
	out := "-> 21.0.80+1-tem\r\n" +
		"-> 21.0.8+9-tem \x1b[92m<— current\x1b[0m\r\n"
	if got := ListedVersions(out); len(got) != 2 || got[0] != "21.0.80+1-tem" || got[1] != "21.0.8+9-tem" {
		t.Errorf("ListedVersions = %q, want [21.0.80+1-tem 21.0.8+9-tem]", got)
	}
	if got := ListedVersions("no available version\n"); len(got) != 0 {
		t.Errorf("ListedVersions = %q, want none", got)
	}
}

func TestFromTarball(t *testing.T) {
	tarball := "Preinstalling java@21.0.5+79248-jb...\r\n" +
		"Unpacking C:\\Users\\John Doe\\.vfox\\cache\\java\\v-21.0.5+79248-jb\\jbrsdk_jcef-21.0.5-windows-x64-b792.48.tar.gz...\r\n"
	if !FromTarball(tarball) {
		t.Error("FromTarball missed a .tar.gz unpack")
	}
	if FromTarball("Unpacking C:\\tmp\\OpenJDK21U-jdk_x64_windows_hotspot_21.0.8_9.zip...\n") {
		t.Error("FromTarball matched a .zip unpack")
	}
}

func TestCheckInstalled(t *testing.T) {
	for spec, installed := range map[string]string{
		"21.0.8-tem":       "21.0.8+9-tem",
		"25.0.2":           "25.0.2+10",
		"25.0.4-librca-fx": "25.0.4+9-librca-fx",
		"25.0.2-graalce":   "25.0.2-graalce",
	} {
		if got := CheckInstalled(t, "Install java@"+installed+" success! \n", spec); got != installed {
			t.Errorf("CheckInstalled(%s) = %q, want %q", spec, got, installed)
		}
	}
}

func TestSearchEntry(t *testing.T) {
	out := "Available versions:\n" +
		" - 25.0.4+9-librca (LTS)\n" +
		" - 25.0.4+9-librca-fx (LTS, JavaFX) (installed)\n" +
		" - 25.0.2+10\n"
	if got, ok := SearchEntry(out, "25.0.4+9-librca-fx"); !ok || got != "25.0.4+9-librca-fx (LTS, JavaFX) (installed)" {
		t.Errorf("SearchEntry(fx) = %q, %v", got, ok)
	}
	// The non-FX build must not match the FX entry, nor vice versa.
	if got, ok := SearchEntry(out, "25.0.4+9-librca"); !ok || got != "25.0.4+9-librca (LTS)" {
		t.Errorf("SearchEntry(non-fx) = %q, %v", got, ok)
	}
	if got, ok := SearchEntry(out, "25.0.2+10"); !ok || got != "25.0.2+10" {
		t.Errorf("SearchEntry(bare) = %q, %v", got, ok)
	}
	if _, ok := SearchEntry(out, "25.0.4"); ok {
		t.Error("SearchEntry matched a version prefix")
	}
}
