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

// Package common holds the shared logic of the Linux and Windows container
// E2E suites.
//
// The two suites target different container systems (bash vs pwsh, different
// vfox installation and isolation), so the code interacting with containers
// stays in the linux / windows packages; the target-independent parts
// (matrix expansion, version defaults, distribution facts, output parsing,
// retry counts, name handling) live here and are reused by both platform
// packages, instead of being copied.
package common

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"os"
	"regexp"
	"runtime"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

// DefaultVersions pins the Java release each default distribution installs,
// maintained in one place for both packages. Every pin is published through
// Foojay for each platform its distribution runs on (see
// DefaultDistributions), so all runners install the same release.
var DefaultVersions = map[string]string{
	// OpenJDK (jdk.java.net), the plugin's default distribution: its
	// versions carry no distribution suffix.
	"open": "25.0.2",
	// Temurin: the common path (tar.gz on Linux, zip on Windows).
	"tem": "21.0.8",
	// Liberica with JavaFX: the -fx selection in PreInstall and PreUse.
	"librca-fx": "25.0.4",
	// JetBrains Runtime 21.0.5 ships no Windows zip, so on Windows it takes
	// the tar.gz fallback in lib/foojay.lua (vfox-java#58).
	"jb": "21.0.5",
	// GraalVM Community: the GRAALVM_HOME branch of hooks/env_keys.lua.
	"graalce": "25.0.2",
}

// distribution holds the facts the verifiers assert per distribution, keyed
// by the plugin's short name without the -fx suffix.
type distribution struct {
	// longName is the Foojay name the hooks accept in place of the short
	// one (lib/distribution_version.lua).
	longName string
	// vendor is the java.vendor property the distribution's builds report.
	vendor string
}

var distributions = map[string]distribution{
	"open":    {longName: "openjdk", vendor: "Oracle Corporation"},
	"tem":     {longName: "temurin", vendor: "Eclipse Adoptium"},
	"librca":  {longName: "liberica", vendor: "BellSoft"},
	"jb":      {longName: "jetbrains", vendor: "JetBrains s.r.o."},
	"graalce": {longName: "graalvm_community", vendor: "GraalVM Community"},
}

// PassThroughEnvs are host env knobs recorded in each target container's
// environment, so `docker inspect` shows what a combo ran with. Forwarded
// only when set, so unset stays default.
var PassThroughEnvs = []string{
	"JAVA_VERSION",
	"E2E_RETRY_ATTEMPTS",
}

// Combo is one matrix cell: a vfox version and a JDK distribution.
type Combo struct {
	Vfox         string
	Distribution string
}

// Prefix renders the log prefix: "vfox <vfox>, <distribution>, <platform>".
func (c Combo) Prefix(platform string) string {
	return fmt.Sprintf("vfox %s, %s, %s", c.Vfox, c.Distribution, platform)
}

// Slug renders a docker-safe container name fragment for the combo.
func (c Combo) Slug() string {
	return c.Vfox + "-" + Sanitize(c.Distribution)
}

// Sanitize replaces every non-ASCII-alphanumeric byte with '_' so arbitrary
// distribution names stay valid in container names.
func Sanitize(s string) string {
	var b strings.Builder
	b.Grow(len(s))
	for i := 0; i < len(s); i++ {
		ch := s[i]
		if ch >= 'A' && ch <= 'Z' || ch >= 'a' && ch <= 'z' || ch >= '0' && ch <= '9' {
			b.WriteByte(ch)
		} else {
			b.WriteByte('_')
		}
	}
	return b.String()
}

// NormalizeArch maps uname-style names, Windows PROCESSOR_ARCHITECTURE values
// and common aliases to docker arch names.
func NormalizeArch(s string) (string, error) {
	switch strings.ToLower(s) {
	case "x86_64", "x64", "amd64":
		return "amd64", nil
	case "aarch64", "arm64":
		return "arm64", nil
	default:
		return "", fmt.Errorf("unknown architecture %s", s)
	}
}

// DetectArch reports the runner architecture: $PROCESSOR_ARCHITECTURE on
// Windows hosts (AMD64/ARM64/x86), else the test binary's own arch. There is
// deliberately no override knob: emulated runs (arm64 on an x64 host) are
// not supported, and CI covers each arch on native runners.
func DetectArch() (string, error) {
	if arch, ok := os.LookupEnv("PROCESSOR_ARCHITECTURE"); ok && strings.TrimSpace(arch) != "" {
		return NormalizeArch(strings.TrimSpace(arch))
	}
	return NormalizeArch(runtime.GOARCH)
}

// Fields splits space-separated env lists (e.g. DISTRIBUTION="tem jb").
func Fields(s string) []string {
	return strings.Fields(s)
}

// DefaultDistributions picks the distributions per runner architecture.
// arm64 runs the three Foojay publishes for both linux-aarch64 and
// windows-aarch64; OpenJDK and GraalVM Community ship no windows-aarch64
// build, so they only join on amd64.
func DefaultDistributions(arch string) []string {
	if arch == "arm64" {
		return []string{"tem", "librca-fx", "jb"}
	}
	return []string{"open", "tem", "librca-fx", "jb", "graalce"}
}

// Matrix expands the vfox x distribution combinations for the runner
// architecture. Env overrides: VFOX_VERSION (default "latest main") and
// DISTRIBUTION (default per DefaultDistributions).
func Matrix() ([]Combo, error) {
	arch, err := DetectArch()
	if err != nil {
		return nil, err
	}
	return MatrixForArch(arch)
}

// MatrixForArch expands the matrix for an explicit arch. Tests use it
// directly so each arch branch stays covered on any host.
func MatrixForArch(arch string) ([]Combo, error) {
	foxes := []string{"latest", "main"}
	if v, ok := os.LookupEnv("VFOX_VERSION"); ok && len(Fields(v)) > 0 {
		foxes = Fields(v)
	}
	dists := DefaultDistributions(arch)
	if v, ok := os.LookupEnv("DISTRIBUTION"); ok && len(Fields(v)) > 0 {
		dists = Fields(v)
	}

	var combos []Combo
	for _, vfox := range foxes {
		for _, dist := range dists {
			combos = append(combos, Combo{Vfox: vfox, Distribution: dist})
		}
	}
	return combos, nil
}

// MaxJobs bounds parallel containers; honours $E2E_MAX_JOBS and falls back
// to def when unset or invalid. Linux passes 3, Windows passes 2.
func MaxJobs(def int) int {
	if v, ok := os.LookupEnv("E2E_MAX_JOBS"); ok {
		if n, err := strconv.Atoi(strings.TrimSpace(v)); err == nil && n >= 1 {
			return n
		}
	}
	return def
}

// RetryAttempts caps exec retries; honours $E2E_RETRY_ATTEMPTS (default 3).
func RetryAttempts() int {
	if v, ok := os.LookupEnv("E2E_RETRY_ATTEMPTS"); ok && strings.TrimSpace(v) != "" {
		if n, err := strconv.Atoi(strings.TrimSpace(v)); err == nil {
			return n
		}
	}
	return 3
}

// ResolveJavaVersion honours $JAVA_VERSION (applied to every distribution
// of the run), else the distribution's pin in DefaultVersions.
func ResolveJavaVersion(t *testing.T, distribution string) string {
	t.Helper()
	if v := os.Getenv("JAVA_VERSION"); v != "" {
		return v
	}
	v, ok := DefaultVersions[distribution]
	if !ok {
		t.Fatalf("no pinned Java version for distribution %s; set JAVA_VERSION", distribution)
	}
	return v
}

// Base strips the -fx suffix: "librca-fx" -> "librca".
func Base(distribution string) string {
	return strings.TrimSuffix(distribution, "-fx")
}

// JavaFX reports whether the distribution asks for a JavaFX bundled build.
func JavaFX(distribution string) bool {
	return strings.HasSuffix(distribution, "-fx")
}

// Spec renders the version argument the plugin documents for a release:
// "<version>[-fx]" for OpenJDK, the default distribution, and
// "<version>-<distribution>" otherwise (e.g. "25.0.4-librca-fx").
func Spec(distribution, version string) string {
	if Base(distribution) == "open" {
		return version + strings.TrimPrefix(distribution, "open")
	}
	return version + "-" + distribution
}

// MissingSpec renders a release in the version's line that no distribution
// has published (<major>.0.99): Foojay answers it with an empty package
// list, so PreInstall must fail naming the platform it searched.
func MissingSpec(distribution, version string) string {
	return Spec(distribution, Major(version)+".0.99")
}

// Major returns the leading version component: "21.0.8" -> "21".
func Major(version string) string {
	return strings.SplitN(version, ".", 2)[0]
}

// LegacyIdentifier renders the SDKMAN-style identifier a .sdkmanrc holds for
// a release: "<version>-<distribution>", without the build number.
func LegacyIdentifier(distribution, version string) string {
	return version + "-" + Base(distribution)
}

// Alias renders the asdf-style spelling "<long-name>-<version>[-fx]" of an
// installed version, which PreUse must rewrite back to installed. OpenJDK
// has none: its versions carry no suffix for PreUse to rewrite.
func Alias(distribution, installed string) (string, bool) {
	d, ok := distributions[Base(distribution)]
	if !ok || Base(distribution) == "open" {
		return "", false
	}
	core, found := strings.CutSuffix(installed, "-"+distribution)
	if !found {
		return "", false
	}
	alias := d.longName + "-" + core
	if JavaFX(distribution) {
		alias += "-fx"
	}
	return alias, true
}

// Vendor returns the java.vendor property the distribution's builds report,
// when the suite knows it.
func Vendor(distribution string) (string, bool) {
	d, ok := distributions[Base(distribution)]
	return d.vendor, ok
}

// SetsGraalVMHome mirrors hooks/env_keys.lua: GraalVM distributions also
// export GRAALVM_HOME.
func SetsGraalVMHome(distribution string) bool {
	switch Base(distribution) {
	case "graal", "graalce":
		return true
	}
	return false
}

// SearchArgs renders the `vfox search java` arguments listing the
// distribution: none for OpenJDK (Available's default query), else the
// short name, which lists the JavaFX builds too.
func SearchArgs(distribution string) string {
	if Base(distribution) == "open" {
		return ""
	}
	return " " + Base(distribution)
}

// JavaArch maps the docker architecture to the os.arch property a JVM built
// for it reports. An x64 JDK emulated on Windows ARM64 reports amd64, so the
// check also catches the wrong package being installed.
func JavaArch(arch string) string {
	if arch == "arm64" {
		return "aarch64"
	}
	return arch
}

// javaProperty matches one `java -XshowSettings:properties` entry. Values
// spanning several lines (java.library.path and friends) continue on deeper
// indented lines, which the pattern skips.
var javaProperty = regexp.MustCompile(`^ {4}(\S+) = (.*)$`)

// JavaProperties parses `java -XshowSettings:properties -version` output
// into a map; multi-line values keep their first line.
func JavaProperties(output string) map[string]string {
	props := map[string]string{}
	for _, line := range strings.Split(StripANSI(output), "\n") {
		if m := javaProperty.FindStringSubmatch(strings.TrimRight(line, "\r")); m != nil {
			props[m[1]] = m[2]
		}
	}
	return props
}

// CheckJava parses `java -XshowSettings:properties -version` output and
// asserts the JVM is the requested release (java.version), built for the
// runner (os.arch), by the distribution's vendor (java.vendor, when known).
// It returns the properties for further checks.
func CheckJava(t *testing.T, output, distribution, version, arch, what string) map[string]string {
	t.Helper()
	props := JavaProperties(output)
	require.Equalf(t, version, props["java.version"], "%s: java.version\n--- output ---\n%s", what, output)
	require.Equalf(t, JavaArch(arch), props["os.arch"],
		"%s: os.arch (the %s package must be installed)\n--- output ---\n%s", what, arch, output)
	if vendor, ok := Vendor(distribution); ok {
		require.Equalf(t, vendor, props["java.vendor"], "%s: java.vendor\n--- output ---\n%s", what, output)
	}
	return props
}

// HelloJava is the program both suites compile with javac and run with
// java; it prints HelloOutput for the running JVM.
const HelloJava = `public class Hello {
    public static void main(String[] args) {
        System.out.println("hello " + System.getProperty("java.version") + " " + System.getProperty("os.arch"));
    }
}
`

// HelloOutput is what HelloJava prints on the requested release and arch.
func HelloOutput(version, arch string) string {
	return "hello " + version + " " + JavaArch(arch)
}

// ansiEscape matches the SGR colour sequences pterm emits even when it
// writes to a pipe.
var ansiEscape = regexp.MustCompile(`\x1b\[[0-9;]*m`)

// StripANSI removes SGR colour sequences from command output.
func StripANSI(s string) string {
	return ansiEscape.ReplaceAllString(s, "")
}

// installSuccess matches the "Install java@<version> success!" line vfox
// prints with the final version PreInstall returned.
var installSuccess = regexp.MustCompile(`Install java@(\S+) success!`)

// InstalledVersion extracts the version vfox recorded from `vfox install`
// output (e.g. 21.0.8+9-tem for 21.0.8-tem), or "" when the line is absent.
func InstalledVersion(output string) string {
	if m := installSuccess.FindStringSubmatch(StripANSI(output)); m != nil {
		return m[1]
	}
	return ""
}

// unpackedTarball matches the "Unpacking <archive>..." line vfox prints
// before extracting a .tar.gz.
var unpackedTarball = regexp.MustCompile(`(?m)^Unpacking .*\.tar\.gz\.\.\.\r?$`)

// FromTarball reports whether `vfox install` output unpacked a .tar.gz, i.e.
// on Windows the JDK came from lib/foojay.lua's tar.gz fallback.
func FromTarball(output string) bool {
	return unpackedTarball.MatchString(StripANSI(output))
}

// buildNumber matches the "+<build>" part of a Foojay java_version.
var buildNumber = regexp.MustCompile(`\+[^-]*`)

// CheckInstalled extracts the version vfox recorded from `vfox install`
// output and asserts PreInstall named it after the requested spec plus at
// most a build number (21.0.8-tem -> 21.0.8+9-tem, 25.0.2 -> 25.0.2+10),
// the same name `vfox search` lists.
func CheckInstalled(t *testing.T, output, spec string) string {
	t.Helper()
	installed := InstalledVersion(output)
	require.NotEmptyf(t, installed, "vfox install java@%s did not report the installed version\n--- output ---\n%s", spec, output)
	require.Equalf(t, spec, buildNumber.ReplaceAllString(installed, ""),
		"java@%s was installed as %s, not as the requested release plus a build number", spec, installed)
	return installed
}

// SearchEntry finds the `vfox search` entry listing exactly version
// (" - <version>[ (<note>)][ (installed)]") and returns it without the
// leading " - ".
func SearchEntry(output, version string) (string, bool) {
	for _, line := range strings.Split(StripANSI(output), "\n") {
		entry, ok := strings.CutPrefix(strings.TrimRight(line, "\r"), " - ")
		if ok && (entry == version || strings.HasPrefix(entry, version+" ")) {
			return entry, true
		}
	}
	return "", false
}

// ContainerName returns a unique container name per run: the combo slug stays
// greppable in `docker ps`, the random suffix avoids clashes with leftovers
// from killed runs.
func ContainerName(slug string) string {
	var b [4]byte
	if _, err := rand.Read(b[:]); err != nil {
		return fmt.Sprintf("vfox-java-e2e-%s-%d", slug, time.Now().UnixNano())
	}
	return "vfox-java-e2e-" + slug + "-" + hex.EncodeToString(b[:])
}
