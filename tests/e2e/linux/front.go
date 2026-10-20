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
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"math/big"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	tc "github.com/testcontainers/testcontainers-go"

	"github.com/version-fox/vfox-java/tests/e2e/common"
)

// frontDir holds, in a container, the stand-in for api.foojay.io built from
// ./front, its certificate and key, and the log of what it was asked.
const frontDir = "/opt/foojay-front"

// frontFiles is what every container's front is made of: its binary on the
// host, built once per run, and a certificate for api.foojay.io that signs
// itself, with its key.
type frontFiles struct {
	binary    string
	cert, key []byte
}

// buildFront builds ./front for the containers' architecture and makes its
// certificate.
func buildFront(t *testing.T, here, arch string) frontFiles {
	t.Helper()
	binary := filepath.Join(t.TempDir(), "front")
	cmd := exec.Command("go", "build", "-trimpath", "-o", binary, "./front")
	cmd.Dir = here
	cmd.Env = append(os.Environ(), "GOOS=linux", "GOARCH="+arch, "CGO_ENABLED=0")
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("build the stand-in for api.foojay.io: %v\n%s", err, out)
	}
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	template := &x509.Certificate{
		SerialNumber:          big.NewInt(1),
		Subject:               pkix.Name{CommonName: "api.foojay.io"},
		DNSNames:              []string{"api.foojay.io"},
		NotBefore:             time.Now().Add(-time.Hour),
		NotAfter:              time.Now().Add(24 * time.Hour),
		KeyUsage:              x509.KeyUsageDigitalSignature | x509.KeyUsageCertSign,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
		IsCA:                  true,
	}
	der, err := x509.CreateCertificate(rand.Reader, template, template, &key.PublicKey, key)
	if err != nil {
		t.Fatal(err)
	}
	keyDER, err := x509.MarshalECPrivateKey(key)
	if err != nil {
		t.Fatal(err)
	}
	return frontFiles{
		binary: binary,
		cert:   pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der}),
		key:    pem.EncodeToMemory(&pem.Block{Type: "EC PRIVATE KEY", Bytes: keyDER}),
	}
}

// startFront puts the front between vfox and Foojay in ctr: api.foojay.io
// resolves to it, its certificate is trusted, and vfox runs the Available
// hook for every search, where it would answer a repeated one from its
// cache. stopFront takes it out again.
func startFront(ctx context.Context, t *testing.T, ctr tc.Container, files frontFiles) {
	t.Helper()
	execOK(ctx, t, ctr, "mkdir --parents "+frontDir)
	if err := ctr.CopyFileToContainer(ctx, files.binary, frontDir+"/front", 0o755); err != nil {
		t.Fatalf("copy the stand-in for api.foojay.io: %v", err)
	}
	for name, content := range map[string][]byte{"cert.pem": files.cert, "key.pem": files.key} {
		if err := ctr.CopyToContainer(ctx, content, frontDir+"/"+name, 0o600); err != nil {
			t.Fatalf("copy %s: %v", name, err)
		}
	}
	execOK(ctx, t, ctr, `set -e
# Foojay's own address, taken before api.foojay.io resolves to the front.
upstream=$(getent ahostsv4 api.foojay.io | awk 'NR == 1 { print $1 }')
[ -n "$upstream" ] || upstream=$(getent ahosts api.foojay.io | awk 'NR == 1 { print $1 }')
[ -n "$upstream" ]
cp `+frontDir+`/cert.pem /usr/local/share/ca-certificates/foojay-front.crt
update-ca-certificates > /dev/null
echo '127.0.0.1 api.foojay.io' >> /etc/hosts
cd `+frontDir+`
nohup ./front -cert cert.pem -key key.pem -upstream "$upstream" -log asked.log < /dev/null > front.out 2>&1 &
echo $! > front.pid
# Up once curl gets an answer through it.
for i in $(seq 50); do curl --silent --output /dev/null https://api.foojay.io/disco/v3.0/distributions && break; sleep 0.2; done
curl --silent --show-error --output /dev/null https://api.foojay.io/disco/v3.0/distributions
vfox config cache.availableHookDuration 0 > /dev/null`)
}

// stopFront takes the front out of ctr again, so that the checks after it
// talk to Foojay directly.
func stopFront(ctx context.Context, t *testing.T, ctr tc.Container) {
	t.Helper()
	execOK(ctx, t, ctr, `set -e
kill "$(cat `+frontDir+`/front.pid)"
grep --invert-match ' api.foojay.io$' /etc/hosts > `+frontDir+`/hosts
# /etc/hosts is mounted by Docker, so it is written over, not replaced.
cat `+frontDir+`/hosts > /etc/hosts
vfox config --unset cache.availableHookDuration > /dev/null`)
}

// asked runs script, retried as execRetry does, and returns its output with
// the lookups of packages the front logged meanwhile (see
// common.JdkLookups).
func asked(ctx context.Context, t *testing.T, ctr tc.Container, script string) (string, []string) {
	t.Helper()
	before := len(common.JdkLookups(execOK(ctx, t, ctr, "cat "+frontDir+"/asked.log")))
	out := execRetry(ctx, t, ctr, script, script)
	return out, common.JdkLookups(execOK(ctx, t, ctr, "cat "+frontDir+"/asked.log"))[before:]
}
