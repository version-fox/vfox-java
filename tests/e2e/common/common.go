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
	"slices"
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
	// JetBrains Runtime 21.0.5 ships no Windows zip, so on Windows it
	// installs from a tar.gz (vfox-java#58), and searching must list it too
	// (vfox-java#72).
	"jb": "21.0.5",
	// GraalVM Community: vfox must leave GRAALVM_HOME alone even for
	// GraalVM (vfox-java#27), and searching must not mark its feature
	// releases LTS (vfox-java#95) nor list them under the JDK's version
	// (vfox-java#105).
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

// OracleGraalVMSpec is Oracle GraalVM's bare major 25. Since 25.1, Oracle
// GraalVM puts out a feature release every month on top of its 25.0 line
// (25.1.3 ... 25.4.4.1.1) and searching lists them first, but the bare major
// must install the newest build of the 25.0 line, the line Oracle's own
// 25/latest download follows (vfox-java#97). Since 2026-10 Foojay lists the
// feature releases under the JDK's version, which the 25.0 line has too, so
// that name took a feature release (vfox-java#105).
const OracleGraalVMSpec = "25-graal"

// ChecksOracleGraalVM reports whether a combo also checks Oracle GraalVM's
// bare major (see OracleGraalVMSpec), which downloads nothing. GraalVM
// Community's combos do: Foojay publishes both for the same platforms.
func ChecksOracleGraalVM(distribution string) bool {
	return Base(distribution) == "graalce"
}

// ReadmeURL is the README the plugin's notes point to, for the short names
// and how to search a distribution. The notes used to list five short names
// but not how to list their versions, while a bare `vfox search java` lists
// OpenJDK only (https://github.com/version-fox/vfox/issues/390).
const ReadmeURL = "https://github.com/version-fox/vfox-java/blob/main/README.md"

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

// MissingBuildSpec renders a build of the release that no distribution has
// published (<version>+99). Foojay answers it with an empty package list
// only when the + reaches it encoded: read as a space, it drops the build
// and lists every build of the release, so PreInstall installed the newest
// (vfox-java#73).
func MissingBuildSpec(distribution, version string) string {
	return Spec(distribution, version+"+99")
}

// VersionlessSpecs renders the distribution without a version, alone and
// after an empty one ("tem" and "-tem", "librca-fx" and "-librca-fx", "open"
// and "-open" for OpenJDK). PreInstall and PreUse must reject both, asking
// for a version: they failed with a Lua error on the first (vfox-java#98),
// while PreInstall sent the empty version to Foojay, which lists every
// release, and installed the newest one.
func VersionlessSpecs(distribution string) []string {
	return []string{distribution, "-" + distribution}
}

// Decoy renders the installed name of another release whose version starts
// with the pinned one (<version>0+1, e.g. 21.0.80+1-tem). vfox lists the
// installed versions sorted as strings, descending, so it comes before the
// pinned JDK (21.0.8+9-tem), and ParseLegacyFile, which took the first one
// starting with the release, selected it (vfox-java#79).
func Decoy(distribution, version string) string {
	return Spec(distribution, version+"0+1")
}

// Major returns the leading version component: "21.0.8" -> "21".
func Major(version string) string {
	return strings.SplitN(version, ".", 2)[0]
}

// sdkmanName returns SDKMAN's name for the distribution, which calls
// JetBrains "jbr".
func sdkmanName(distribution string) string {
	if name := Base(distribution); name != "jb" {
		return name
	}
	return "jbr"
}

// LegacyIdentifier renders the SDKMAN identifier a .sdkmanrc holds for a
// release: "<version>-<distribution>", without the build number, in SDKMAN's
// spelling: JetBrains is "jbr" and JavaFX builds are
// "<version>.fx-<distribution>" (21.0.5-jbr, 25.0.4.fx-librca).
func LegacyIdentifier(distribution, version string) string {
	if JavaFX(distribution) {
		version += ".fx"
	}
	return version + "-" + sdkmanName(distribution)
}

// PaddedIdentifier renders the SDKMAN identifier of an installed version
// with a zero padding the release, as `sdk list java` shows many
// (25.0.1.0+8-open, 21.0.9.0+116386-jbr):
// "<version>.0[-fx][+<build>]-<distribution>" with the installed build
// (21.0.8.0+9-tem, 25.0.4.0-fx+9-librca). Foojay, and so the installed
// name, leaves the zero out; ParseLegacyFile did not, so it found no such
// release and fell back to the newest one of the major (vfox-java#80).
func PaddedIdentifier(distribution, version, installed string) string {
	version += ".0"
	if JavaFX(distribution) {
		version += "-fx"
	}
	return version + buildNumber.FindString(installed) + "-" + sdkmanName(distribution)
}

// EarlyAccess renders the installed name of an early-access build of the
// pinned major (<major>-ea+1, e.g. 21-ea+1-tem, 25-ea+1 for OpenJDK).
// jdk.java.net removes each early-access build within weeks, so the suite
// fakes the install: a java-<version> directory whose bin holds a stand-in
// java that only prints this name.
func EarlyAccess(distribution, version string) string {
	return Spec(distribution, Major(version)+"-ea+1")
}

// EarlyAccessIdentifier renders SDKMAN's identifier of that build, spelled
// as `sdk list java` shows OpenJDK's (28.0.0.0+ea.20-open):
// "<major>.0.0.0[-fx]+ea.1-<distribution>" (21.0.0.0+ea.1-tem,
// 25.0.0.0-fx+ea.1-librca). ParseLegacyFile matched only SDKMAN's older
// 21.ea.1-tem to it, so it took the newest release of the major instead
// (vfox-java#86).
func EarlyAccessIdentifier(distribution, version string) string {
	version = Major(version) + ".0.0.0"
	if JavaFX(distribution) {
		version += "-fx"
	}
	return version + "+ea.1-" + sdkmanName(distribution)
}

// Alias renders the asdf-style spelling "<long-name>-<version>[-fx]" of an
// installed version, which PreUse must rewrite back to installed
// (temurin-21.0.8+9 to 21.0.8+9-tem, openjdk-25.0.2+10 to 25.0.2+10).
func Alias(distribution, installed string) (string, bool) {
	d, ok := distributions[Base(distribution)]
	if !ok {
		return "", false
	}
	// Installed versions end the way specs do: "-tem", "-librca-fx", or
	// nothing for OpenJDK.
	core, found := strings.CutSuffix(installed, Spec(distribution, ""))
	if !found {
		return "", false
	}
	alias := d.longName + "-" + core
	if JavaFX(distribution) {
		alias += "-fx"
	}
	return alias, true
}

// PaddedSpecs renders the pinned release padded with a zero, as SDKMAN
// writes releases (27.0.0-librca, 25.0.1.0-open), in the plugin's spelling:
// "<version>.0[-<distribution>]" and, when the installed version has a
// build number, "<version>.0+<build>[-<distribution>]" (21.0.8.0-tem,
// 21.0.8.0+9-tem). PreInstall passes the zero on to Foojay, which leaves it
// out, so both install the pinned JDK, but PreUse looked for an installed
// version starting with the padded release and found none (vfox-java#87).
func PaddedSpecs(distribution, version, installed string) []string {
	specs := []string{Spec(distribution, version+".0")}
	if build := buildNumber.FindString(installed); build != "" {
		specs = append(specs, Spec(distribution, version+".0"+build))
	}
	return specs
}

// GraalVM reports whether the distribution is Oracle GraalVM or GraalVM
// Community, whose searches list GraalVM's feature releases.
func GraalVM(distribution string) bool {
	switch Base(distribution) {
	case "graal", "graalce":
		return true
	}
	return false
}

// Vendor returns the java.vendor property the distribution's builds report,
// when the suite knows it.
func Vendor(distribution string) (string, bool) {
	d, ok := distributions[Base(distribution)]
	return d.vendor, ok
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

// listedVersion matches one `vfox list java` entry: "-> <version>", followed
// by "<— current" for the version in use.
var listedVersion = regexp.MustCompile(`^-> (\S+)`)

// ListedVersions extracts the installed versions from `vfox list java`
// output, in the order vfox lists them.
func ListedVersions(output string) []string {
	var versions []string
	for _, line := range strings.Split(StripANSI(output), "\n") {
		if m := listedVersion.FindStringSubmatch(strings.TrimRight(line, "\r")); m != nil {
			versions = append(versions, m[1])
		}
	}
	return versions
}

// unpackedTarball matches the "Unpacking <archive>..." line vfox prints
// before extracting a .tar.gz.
var unpackedTarball = regexp.MustCompile(`(?m)^Unpacking .*\.tar\.gz\.\.\.\r?$`)

// FromTarball reports whether `vfox install` output unpacked a .tar.gz, i.e.
// on Windows the JDK came from a release Foojay lists with no zip.
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

// featureReleaseEntry matches the `vfox search` entry of a GraalVM feature
// release. GraalVM ships one every month since 25.1, numbered with the
// feature release train as the minor version (25.4.4.1.1-graalce), which its
// other releases keep at zero (25.0.2-graalce).
var featureReleaseEntry = regexp.MustCompile(`^\d+\.[1-9]`)

// FeatureReleaseEntries returns the entries of GraalVM feature releases in
// a GraalVM `vfox search`, without the leading " - ". Foojay marked them LTS,
// as the JDK they build on is, and still does where it lists GraalVM
// Community's the old way round; the Available hook passed that on, though
// each is superseded within a month (vfox-java#95).
func FeatureReleaseEntries(output string) []string {
	var entries []string
	for _, line := range strings.Split(StripANSI(output), "\n") {
		entry, ok := strings.CutPrefix(strings.TrimRight(line, "\r"), " - ")
		if ok && featureReleaseEntry.MatchString(entry) {
			entries = append(entries, entry)
		}
	}
	return entries
}

// MixedSupportEntries returns the entries of a GraalVM `vfox search`,
// without the leading " - ", that are no feature release but lack the LTS
// note another release of their major carries (25.0.4.1-graal next to
// 25.0.2-graal (LTS)). Foojay marks the 25.0 line LTS and, since 2026-10,
// lists the feature releases under the JDK's version as STS, so a 25.0.x
// entry without the note next to one with it stands for a feature release:
// the plugin named them after that version (vfox-java#105).
func MixedSupportEntries(output string) []string {
	var entries []string
	lts := map[string]bool{}
	for _, line := range strings.Split(StripANSI(output), "\n") {
		entry, ok := strings.CutPrefix(strings.TrimRight(line, "\r"), " - ")
		if ok && !featureReleaseEntry.MatchString(entry) {
			entries = append(entries, entry)
			if strings.Contains(entry, "LTS") {
				lts[leadingNumber.FindString(entry)] = true
			}
		}
	}
	var mixed []string
	for _, entry := range entries {
		if lts[leadingNumber.FindString(entry)] && !strings.Contains(entry, "LTS") {
			mixed = append(mixed, entry)
		}
	}
	return mixed
}

// CheckGraalVMSearch asserts that a GraalVM `vfox search` lists feature
// releases, none of them noted LTS (see FeatureReleaseEntries), and notes the
// other releases of each major alike (see MixedSupportEntries). Foojay lists
// every feature release since 25.1.3 on each platform the suite runs GraalVM
// on, so the checks cannot pass vacuously.
func CheckGraalVMSearch(t *testing.T, cmd, output string) {
	t.Helper()
	features := FeatureReleaseEntries(output)
	require.NotEmptyf(t, features, "%s lists no feature release\n--- output ---\n%s", cmd, output)
	for _, feature := range features {
		require.NotContainsf(t, feature, "LTS", "%s must not mark the feature release %s LTS", cmd, feature)
	}
	require.Emptyf(t, MixedSupportEntries(output),
		"%s must note the releases of a major alike, feature releases aside\n--- output ---\n%s", cmd, output)
	t.Logf("PASS %s marks no feature release LTS and the other releases of each major alike: %s",
		cmd, strings.Join(features, ", "))
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

// SearchedVersions extracts the versions `vfox search` lists, in its order.
func SearchedVersions(output string) []string {
	var versions []string
	for _, line := range strings.Split(StripANSI(output), "\n") {
		if entry, ok := strings.CutPrefix(strings.TrimRight(line, "\r"), " - "); ok {
			version, _, _ := strings.Cut(entry, " ")
			versions = append(versions, version)
		}
	}
	return versions
}

// featureRelease matches a GraalVM feature release, numbered in the second
// component (25.4.4.1), which the 25.0 line keeps at 0 or leaves out
// (25.0.4.1, 25).
var featureRelease = regexp.MustCompile(`^\d+\.[1-9]`)

// BareMajorBuilds picks out of the versions `vfox search` lists, newest
// first, the builds of a bare major spec's major and distribution
// (25.4.4.1.1-graal ... 25.0.1-graal for 25-graal), and the one the spec must
// install: the newest that is no feature release (25.0.4.1.1-graal). The
// build named like the spec (25-graal, GA 25) is left out: vfox reports a
// spec naming an installed version as installed without calling PreInstall.
func BareMajorBuilds(searched []string, spec string) (builds []string, want string) {
	major, distribution, _ := strings.Cut(spec, "-")
	for _, version := range searched {
		core, ok := strings.CutSuffix(version, "-"+distribution)
		if !ok || Major(core) != major || version == spec {
			continue
		}
		builds = append(builds, version)
		if want == "" && !featureRelease.MatchString(core) {
			want = version
		}
	}
	return builds, want
}

// nameOnly maps the distributions the suite checks by name only, by short
// name, to the runner platforms Foojay lists packages of them for
// (2026-10-20). Only Red Hat's Linux x64 builds still download, which the
// check needs not.
var nameOnly = map[string][]string{
	"adpt":    {"linux/amd64", "linux/arm64", "windows/amd64"},
	"adptj9":  {"linux/amd64", "linux/arm64", "windows/amd64"},
	"eliya":   {"linux/amd64", "linux/arm64"},
	"gln":     {"linux/amd64", "windows/amd64"},
	"grl8":    {"linux/amd64", "windows/amd64"},
	"grl11":   {"linux/amd64", "linux/arm64", "windows/amd64"},
	"grl16":   {"linux/amd64", "linux/arm64", "windows/amd64"},
	"grl17":   {"linux/amd64", "linux/arm64", "windows/amd64"},
	"grl19":   {"linux/amd64", "linux/arm64", "windows/amd64"},
	"ojdkbld": {"linux/amd64", "windows/amd64"},
	"opnlgc":  {"linux/amd64", "windows/amd64"},
	"rdht":    {"linux/amd64", "linux/arm64", "windows/amd64"},
	"semcrt":  {"linux/amd64", "linux/arm64"},
}

// NameOnlyDistributions returns, sorted, the distributions in nameOnly that
// Foojay has packages of for platform ("linux/amd64", "windows/arm64"). The
// suite checks them by name only, installing no JDK. The plugin had no name
// for them, so `vfox search java adpt` failed with "Unsupported
// distribution" and `vfox install java@16-adpt` with "Could not extract a
// valid distribution".
func NameOnlyDistributions(platform string) []string {
	var names []string
	for name, platforms := range nameOnly {
		if slices.Contains(platforms, platform) {
			names = append(names, name)
		}
	}
	slices.Sort(names)
	return names
}

// ChecksNameOnly reports whether a combo also checks the distributions in
// NameOnlyDistributions, which downloads nothing. Temurin's combos do: they
// run on every runner.
func ChecksNameOnly(distribution string) bool {
	return Base(distribution) == "tem"
}

// leadingNumber matches the major of a Foojay java_version, which a dot
// or a build follows (22.3.3, 23+25).
var leadingNumber = regexp.MustCompile(`^\d+`)

// NewestBareMajor picks the newest version `vfox search java <short>`
// lists (22.3.3-grl17) and the bare major spec that must install it
// (22-grl17). ok is false when there is none, or when the spec names the
// version itself: vfox reports a spec naming an installed version as
// installed without calling PreInstall.
func NewestBareMajor(searched []string, short string) (spec, newest string, ok bool) {
	if len(searched) == 0 {
		return "", "", false
	}
	newest = searched[0]
	core, found := strings.CutSuffix(newest, "-"+short)
	major := leadingNumber.FindString(core)
	spec = major + "-" + short
	return spec, newest, found && major != "" && spec != newest
}

// ownNumbered describes a distribution that goes by the numbers of the
// GraalVM it is built from (Mandrel 23.1.12 runs on JDK 21): its long name, a
// release it has under such a number for every platform in platforms, and
// those runner platforms (2026-10-20).
type ownNumbered struct {
	longName, release string
	platforms         []string
}

// ownNumbers maps Mandrel and Liberica NIK, by short name, to what the suite
// checks of them. Foojay gives their numbers as distribution_version and the
// JDK as java_version, after which the plugin named them, so `vfox install
// java@23.1.12-mandrel` found no package, `vfox search java mandrel` listed
// one name per JDK major, and `java@23-mandrel` installed Mandrel 24.1.2,
// built for JDK 23 (vfox-java#106).
var ownNumbers = map[string]ownNumbered{
	"mandrel": {longName: "mandrel", release: "23.1.12", platforms: []string{"linux/amd64", "linux/arm64", "windows/amd64"}},
	"nik":     {longName: "liberica_native", release: "23.1.8", platforms: []string{"linux/amd64", "linux/arm64", "windows/amd64"}},
}

// OwnNumberedDistributions returns, sorted, the distributions in ownNumbers
// that Foojay has packages of for platform ("linux/amd64", "windows/arm64").
func OwnNumberedDistributions(platform string) []string {
	var names []string
	for name, d := range ownNumbers {
		if slices.Contains(d.platforms, platform) {
			names = append(names, name)
		}
	}
	slices.Sort(names)
	return names
}

// OwnNumberSpecs renders, for a distribution in ownNumbers, its release in
// asdf's order ("mandrel-23.1.12"), which vfox does not find installed under
// that spelling and so passes to PreInstall, the installed name it must
// resolve to ("23.1.12-mandrel"), and the bare major of that release
// ("23-mandrel").
func OwnNumberSpecs(short string) (spec, installed, bare string) {
	d := ownNumbers[short]
	return d.longName + "-" + d.release, d.release + "-" + short, Major(d.release) + "-" + short
}

// NewestOfMajor picks out of the versions `vfox search` lists, newest first,
// the one a bare major spec ("23-mandrel") must install: the first release of
// that major and distribution without JavaFX ("23.1.12.1-mandrel"). The
// release named like the spec (Mandrel 23.0.0.0, "23-mandrel") does not
// count, as vfox would find it installed without asking PreInstall.
func NewestOfMajor(searched []string, bare string) (newest string, ok bool) {
	major, short, _ := strings.Cut(bare, "-")
	for _, version := range searched {
		core, found := strings.CutSuffix(version, "-"+short)
		if found && strings.HasPrefix(core, major+".") {
			return version, true
		}
	}
	return "", false
}

// ChecksOwnNumbers reports whether a combo also checks the distributions in
// OwnNumberedDistributions and SDKMAN's identifiers of them
// (OwnNumberIdentifiers), which downloads nothing. Temurin's combos do: they
// run on every runner.
func ChecksOwnNumbers(distribution string) bool {
	return Base(distribution) == "tem"
}

// LegacyCase is a java= value of a .sdkmanrc and the installed version it
// must select, "" for none.
type LegacyCase struct {
	Identifier, Selects string
}

// ownNumberIdentifiers lists identifiers of Mandrel and Liberica NIK in
// SDKMAN's spelling, with the JDK after .r, and what each selects out of
// ownNumberInstalls: three that `sdk list java` shows (2026-10-20), and
// 22.1.r17-mandrel for the JDK 17 build of the release 22.1.r11-mandrel
// names.
var ownNumberIdentifiers = []LegacyCase{
	{"25.0.4.r25-nik", "25.0.4-nik"},
	{"25.0.2.r25-mandrel", "25.0.2-mandrel"},
	{"22.1.r17-mandrel", "22.1-mandrel"},
	{"22.1.r11-mandrel", ""},
}

// ownNumberInstalls holds the release each of ownNumberIdentifiers names and a
// newer release of its major.
var ownNumberInstalls = []string{
	"25.0.4-nik", "25.0.4.1-nik", "25.0.2-mandrel", "25.0.4.1-mandrel", "22.1-mandrel", "22.2-mandrel",
}

// OwnNumberIdentifiers returns identifiers of Mandrel and Liberica NIK in
// SDKMAN's spelling, with the JDK after .r (25.0.4.r25-nik), each with what a
// .sdkmanrc holding it must select, and the installs to fake for them: the
// releases they name, each next to a newer release of its major
// (25.0.4.1-nik). ParseLegacyFile read 25.0.4.r25 as the release, found no
// such install and took that newer one (vfox-java#109). Mandrel 22.1 comes for
// JDK 11 and 17, and the plugin installs the build for 17 only, so
// 22.1.r11-mandrel must select nothing.
func OwnNumberIdentifiers() (cases []LegacyCase, installs []string) {
	return ownNumberIdentifiers, ownNumberInstalls
}

// printedNames returns those of names that output holds, in the order of
// names, joined by spaces.
func printedNames(output string, names []string) string {
	var printed []string
	for _, name := range names {
		if strings.Contains(output, name) {
			printed = append(printed, name)
		}
	}
	return strings.Join(printed, " ")
}

// CheckSelects fails t unless a .sdkmanrc holding c.Identifier selected what
// c.Selects names among installs, whose stand-in java prints its name: out is
// what java printed next to the file, nothing when none was selected.
func CheckSelects(t *testing.T, out string, c LegacyCase, installs []string) {
	t.Helper()
	selected := printedNames(out, installs)
	if c.Selects == "" {
		require.Emptyf(t, selected, ".sdkmanrc java=%s must select nothing\n--- output ---\n%s", c.Identifier, out)
		t.Logf("PASS .sdkmanrc java=%s selects nothing", c.Identifier)
		return
	}
	require.Equalf(t, c.Selects, selected, ".sdkmanrc java=%s must select %s\n--- output ---\n%s", c.Identifier, c.Selects, out)
	t.Logf("PASS .sdkmanrc java=%s selects %s", c.Identifier, c.Selects)
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
