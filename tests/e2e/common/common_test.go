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
	"strconv"
	"strings"
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

func TestVersionlessSpecs(t *testing.T) {
	for _, c := range []struct {
		dist string
		want []string
	}{
		{"open", []string{"open", "-open"}},
		{"tem", []string{"tem", "-tem"}},
		{"librca-fx", []string{"librca-fx", "-librca-fx"}},
	} {
		if got := VersionlessSpecs(c.dist); !slices.Equal(got, c.want) {
			t.Errorf("VersionlessSpecs(%s) = %q, want %q", c.dist, got, c.want)
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
	if !GraalVM("graal") || !GraalVM("graalce") || GraalVM("mandrel") || GraalVM("nik") {
		t.Error("GraalVM must hold for graal and graalce alone")
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

// lineEnding is how output ends its lines: LF, or CRLF as vfox and java write
// them in the Windows containers. A raw string cannot hold a carriage return,
// so the tests write their output with LF and check it with each lineEnding.
type lineEnding struct{ name, newline string }

var lineEndings = []lineEnding{{"LF", "\n"}, {"CRLF", "\r\n"}}

// apply returns output, written with LF, with this line ending.
func (e lineEnding) apply(output string) string {
	return strings.ReplaceAll(output, "\n", e.newline)
}

func TestJavaProperties(t *testing.T) {
	// Abridged `java -XshowSettings:properties -version` output, with a
	// multi-line value. java.class.path is empty, so its line ends in a space.
	output := `Property settings:
    java.class.path = 
    java.home = /root/.vfox/cache/java/v-21.0.8+9-tem/java-21.0.8+9-tem
    java.library.path = /usr/java/packages/lib
        /usr/lib64
    java.vendor = Eclipse Adoptium
    java.version = 21.0.8
    os.arch = amd64

openjdk version "21.0.8" 2025-07-15 LTS
`
	for _, ending := range lineEndings {
		t.Run(ending.name, func(t *testing.T) {
			props := JavaProperties(ending.apply(output))
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
		})
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
	tarball := `Preinstalling java@21.0.5+79248-jb...
Unpacking C:\Users\John Doe\.vfox\cache\java\v-21.0.5+79248-jb\jbrsdk_jcef-21.0.5-windows-x64-b792.48.tar.gz...
`
	zipped := `Unpacking C:\tmp\OpenJDK21U-jdk_x64_windows_hotspot_21.0.8_9.zip...
`
	for _, ending := range lineEndings {
		t.Run(ending.name, func(t *testing.T) {
			if !FromTarball(ending.apply(tarball)) {
				t.Error("FromTarball missed a .tar.gz unpack")
			}
			if FromTarball(ending.apply(zipped)) {
				t.Error("FromTarball matched a .zip unpack")
			}
		})
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

func TestFeatureReleaseEntries(t *testing.T) {
	output := `Available versions:
 - 25.4.4.1-graalce (LTS)
 - 25.1.3-graalce
 - 25.0.2-graalce (LTS) (installed)
 - 25-graalce (LTS)
 - 24.0.2-graalce
`
	want := []string{"25.4.4.1-graalce (LTS)", "25.1.3-graalce"}
	for _, ending := range lineEndings {
		t.Run(ending.name, func(t *testing.T) {
			if got := FeatureReleaseEntries(ending.apply(output)); !slices.Equal(got, want) {
				t.Errorf("FeatureReleaseEntries = %q, want %q", got, want)
			}
		})
	}
}

func TestMixedSupportEntries(t *testing.T) {
	// Abridged `vfox search` output, observed on 2026-10-20 with the plugin
	// before and after vfox-java#105: Foojay lists the feature releases
	// under the JDK's version, and the name of each stood for a feature
	// release first.
	before := map[string]string{
		"graal": `Available versions:
 - 25.0.4.1-graal
 - 25.0.4-graal
 - 25.0.3-graal
 - 25.0.2-graal (LTS)
 - 25-graal (LTS)
 - 24.0.2-graal
 - 24-graal
 - 21.0.12-graal (LTS)
`,
		"graalce": `Available versions:
 - 25.4.4.1-graalce
 - 25.1.3-graalce
 - 25.0.4.1-graalce
 - 25.0.3-graalce
 - 25.0.2-graalce (LTS) (installed)
 - 25-graalce (LTS)
 - 24.0.2-graalce
`,
	}
	after := `Available versions:
 - 25.4.4.1.1-graal
 - 25.1.3-graal
 - 25.0.4.1.1-graal (LTS)
 - 25.0.4.1-graal (LTS)
 - 25-graal (LTS)
 - 24.0.2-graal
 - 24-graal
 - 21.0.12-graal (LTS) (installed)
`
	for _, ending := range lineEndings {
		t.Run(ending.name, func(t *testing.T) {
			for distribution, want := range map[string][]string{
				"graal":   {"25.0.4.1-graal", "25.0.4-graal", "25.0.3-graal"},
				"graalce": {"25.0.4.1-graalce", "25.0.3-graalce"},
			} {
				if got := MixedSupportEntries(ending.apply(before[distribution])); !slices.Equal(got, want) {
					t.Errorf("MixedSupportEntries(%s before) = %q, want %q", distribution, got, want)
				}
			}
			if got := MixedSupportEntries(ending.apply(after)); len(got) != 0 {
				t.Errorf("MixedSupportEntries(after) = %q, want none", got)
			}
		})
	}
}

func TestSearchEntry(t *testing.T) {
	output := `Available versions:
 - 25.0.4+9-librca (LTS)
 - 25.0.4+9-librca-fx (LTS, JavaFX) (installed)
 - 25.0.2+10
`
	for _, ending := range lineEndings {
		t.Run(ending.name, func(t *testing.T) {
			out := ending.apply(output)
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
		})
	}
}

func TestBareMajorBuilds(t *testing.T) {
	// Abridged `vfox search java graal` output, observed on 2026-10-20.
	output := `Available versions:
 - 25.4.4.1.1-graal
 - 25.1.3-graal
 - 25.0.4.1.1-graal (LTS)
 - 25.0.4.1-graal (LTS) (installed)
 - 25-graal (LTS)
 - 24.0.2-graal
 - 21.0.12-graal (LTS)
`
	for _, ending := range lineEndings {
		t.Run(ending.name, func(t *testing.T) {
			searched := SearchedVersions(ending.apply(output))
			if want := []string{"25.4.4.1.1-graal", "25.1.3-graal", "25.0.4.1.1-graal", "25.0.4.1-graal", "25-graal", "24.0.2-graal", "21.0.12-graal"}; !slices.Equal(searched, want) {
				t.Fatalf("SearchedVersions = %q, want %q", searched, want)
			}
			builds, want := BareMajorBuilds(searched, OracleGraalVMSpec)
			// GA 25 is named like the spec, so vfox would find it installed
			// before asking PreInstall.
			if expected := []string{"25.4.4.1.1-graal", "25.1.3-graal", "25.0.4.1.1-graal", "25.0.4.1-graal"}; !slices.Equal(builds, expected) {
				t.Errorf("builds = %q, want %q", builds, expected)
			}
			if want != "25.0.4.1.1-graal" {
				t.Errorf("want = %q, want 25.0.4.1.1-graal", want)
			}
		})
	}
	// GraalVM Community's versions are not Oracle GraalVM's.
	if builds, want := BareMajorBuilds([]string{"25.4.4.1-graalce", "25.0.2-graalce"}, OracleGraalVMSpec); len(builds) != 0 || want != "" {
		t.Errorf("BareMajorBuilds(graalce versions) = %q, %q; want none", builds, want)
	}
	if !ChecksOracleGraalVM("graalce") || ChecksOracleGraalVM("tem") {
		t.Error("only the GraalVM Community combos check Oracle GraalVM's bare major")
	}
}

func TestNameOnlyDistributions(t *testing.T) {
	for platform, want := range map[string][]string{
		"linux/amd64":   {"adpt", "adptj9", "eliya", "gln", "grl11", "grl16", "grl17", "grl19", "grl8", "ojdkbld", "opnlgc", "rdht", "semcrt"},
		"linux/arm64":   {"adpt", "adptj9", "eliya", "grl11", "grl16", "grl17", "grl19", "rdht", "semcrt"},
		"windows/amd64": {"adpt", "adptj9", "gln", "grl11", "grl16", "grl17", "grl19", "grl8", "ojdkbld", "opnlgc", "rdht"},
		"windows/arm64": nil,
	} {
		if got := NameOnlyDistributions(platform); !slices.Equal(got, want) {
			t.Errorf("NameOnlyDistributions(%s) = %q, want %q", platform, got, want)
		}
	}
	// The suite installs these, so it knows their names already.
	for name := range nameOnly {
		if _, ok := distributions[name]; ok {
			t.Errorf("%s is checked by name only, but the suite installs it", name)
		}
	}
	// Temurin's combos run on every runner, arm64 included.
	for _, arch := range []string{"amd64", "arm64"} {
		if !slices.ContainsFunc(DefaultDistributions(arch), ChecksNameOnly) {
			t.Errorf("no %s default combo checks the distributions by name", arch)
		}
	}
	if ChecksNameOnly("librca-fx") {
		t.Error("only the Temurin combos check the distributions by name")
	}
}

func TestOwnNumbers(t *testing.T) {
	for platform, want := range map[string][]string{
		"linux/amd64":   {"mandrel", "nik"},
		"linux/arm64":   {"mandrel", "nik"},
		"windows/amd64": {"mandrel", "nik"},
		"windows/arm64": nil,
	} {
		if got := OwnNumberedDistributions(platform); !slices.Equal(got, want) {
			t.Errorf("OwnNumberedDistributions(%s) = %q, want %q", platform, got, want)
		}
	}
	for short, want := range map[string][3]string{
		"mandrel": {"mandrel-23.1.12", "23.1.12-mandrel", "23-mandrel"},
		"nik":     {"liberica_native-23.1.8", "23.1.8-nik", "23-nik"},
	} {
		if spec, installed, bare := OwnNumberSpecs(short); [3]string{spec, installed, bare} != want {
			t.Errorf("OwnNumberSpecs(%s) = %q, %q, %q; want %q", short, spec, installed, bare, want)
		}
	}
	// Temurin's combos run on every runner, arm64 included.
	for _, arch := range []string{"amd64", "arm64"} {
		if !slices.ContainsFunc(DefaultDistributions(arch), ChecksOwnNumbers) {
			t.Errorf("no %s default combo checks Mandrel and Liberica NIK", arch)
		}
	}
	if ChecksOwnNumbers("graalce") {
		t.Error("only the Temurin combos check Mandrel and Liberica NIK")
	}
}

func TestNewestOfMajor(t *testing.T) {
	// Abridged `vfox search` output, observed on 2026-10-20.
	mandrel := []string{"25.0.4.1-mandrel", "24.2.2-mandrel", "23.1.12.1-mandrel", "23.1.12-mandrel", "23-mandrel"}
	nik := []string{"25.0.4.1-nik-fx", "25.0.4.1-nik", "23.1.12.1-nik-fx", "23.1.12.1-nik", "23.1.8-nik"}
	for _, c := range []struct {
		searched     []string
		bare, newest string
		ok           bool
	}{
		{mandrel, "23-mandrel", "23.1.12.1-mandrel", true},
		{mandrel, "24-mandrel", "24.2.2-mandrel", true},
		{nik, "23-nik", "23.1.12.1-nik", true},
		// Before vfox-java#106 the search listed one name per JDK major.
		{[]string{"25-mandrel", "24-mandrel", "23-mandrel"}, "23-mandrel", "", false},
		{mandrel, "21-mandrel", "", false},
		{nik, "23-mandrel", "", false},
	} {
		if newest, ok := NewestOfMajor(c.searched, c.bare); newest != c.newest || ok != c.ok {
			t.Errorf("NewestOfMajor(%q, %s) = %q, %v; want %q, %v", c.searched, c.bare, newest, ok, c.newest, c.ok)
		}
	}
}

func TestNewestBareMajor(t *testing.T) {
	for _, c := range []struct {
		searched           []string
		short, spec, found string
		ok                 bool
	}{
		// Abridged `vfox search` output, observed on 2026-10-20.
		{[]string{"22.3.3-grl17", "22.3.2-grl17"}, "grl17", "22-grl17", "22.3.3-grl17", true},
		{[]string{"25.0.4+7-opnlgc", "25.0.3+9-opnlgc"}, "opnlgc", "25-opnlgc", "25.0.4+7-opnlgc", true},
		{[]string{"23+25-gln", "22.1.0.1-gln"}, "gln", "23-gln", "23+25-gln", true},
		{[]string{"8.0.345+1-rdht"}, "rdht", "8-rdht", "8.0.345+1-rdht", true},
		// vfox would find 16-adpt itself installed, without asking PreInstall.
		{[]string{"16-adpt", "15.0.2-adpt"}, "adpt", "16-adpt", "16-adpt", false},
		{[]string{"16.0.1-adptj9"}, "adpt", "", "16.0.1-adptj9", false},
		{nil, "eliya", "", "", false},
	} {
		spec, found, ok := NewestBareMajor(c.searched, c.short)
		if ok != c.ok || ok && (spec != c.spec || found != c.found) {
			t.Errorf("NewestBareMajor(%q, %s) = %q, %q, %v; want %q, %q, %v",
				c.searched, c.short, spec, found, ok, c.spec, c.found, c.ok)
		}
	}
}

// releaseNumbers returns the numbers of a release such as 25.0.4.1.
func releaseNumbers(release string) []int {
	var numbers []int
	for _, part := range strings.Split(release, ".") {
		n, _ := strconv.Atoi(part)
		numbers = append(numbers, n)
	}
	return numbers
}

func TestOwnNumberIdentifiers(t *testing.T) {
	cases, installs := OwnNumberIdentifiers()
	none := 0
	for _, c := range cases {
		release, rest, _ := strings.Cut(c.Identifier, ".r")
		jdk, short, _ := strings.Cut(rest, "-")
		if strings.Trim(release, "0123456789.") != "" || strings.Trim(jdk, "0123456789") != "" ||
			release == "" || jdk == "" {
			t.Errorf("%s does not carry the JDK after .r", c.Identifier)
			continue
		}
		major := Major(release)
		if _, ok := ownNumbers[short]; !ok {
			t.Errorf("%s is no identifier of Mandrel or Liberica NIK", c.Identifier)
		}
		// The plugin took the newest release of the major, so one newer than
		// the release named must be faked too (any one, for an identifier
		// that selects nothing), or the check passes by chance.
		if !slices.ContainsFunc(installs, func(name string) bool {
			core, ok := strings.CutSuffix(name, "-"+short)
			return ok && Major(core) == major &&
				(c.Selects == "" || slices.Compare(releaseNumbers(core), releaseNumbers(release)) > 0)
		}) {
			t.Errorf("no release of %s-%s that the plugin took for %s is faked", major, short, c.Identifier)
		}
		if c.Selects == "" {
			none++
			continue
		}
		if c.Selects != release+"-"+short || !slices.Contains(installs, c.Selects) {
			t.Errorf("%s selects %s, not the faked install of the release it names", c.Identifier, c.Selects)
		}
	}
	if none == 0 {
		t.Error("no identifier must select nothing")
	}
	// Each stand-in java prints its name, which must hold no other one.
	for _, a := range installs {
		for _, b := range installs {
			if a != b && strings.Contains(a, b) {
				t.Errorf("%s holds %s, so their output cannot tell them apart", a, b)
			}
		}
	}
}

func TestPrintedNames(t *testing.T) {
	_, installs := OwnNumberIdentifiers()
	// The stand-in java of a faked install prints its name, and nothing
	// prints when none is selected.
	for _, ending := range lineEndings {
		t.Run(ending.name, func(t *testing.T) {
			for output, want := range map[string]string{
				"25.0.4-nik\n":                 "25.0.4-nik",
				"25.0.4.1-mandrel\n":           "25.0.4.1-mandrel",
				"22.1-mandrel\n22.2-mandrel\n": "22.1-mandrel 22.2-mandrel",
				"":                             "",
			} {
				if got := printedNames(ending.apply(output), installs); got != want {
					t.Errorf("printedNames(%q) = %q, want %q", ending.apply(output), got, want)
				}
			}
		})
	}
}
