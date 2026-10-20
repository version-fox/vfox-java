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

// Command front stands in for api.foojay.io in an E2E container, so that a
// check can read what the plugin asked Foojay. It serves TLS with the
// certificate it is given, appends the path and query of every request to
// the log, one per line, and passes the request on to Foojay at the address
// it is given, as api.foojay.io itself resolves to the front.
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"sync"
)

func main() {
	listen := flag.String("listen", "127.0.0.1:443", "address to serve on")
	cert := flag.String("cert", "", "certificate file for api.foojay.io")
	key := flag.String("key", "", "key file of the certificate")
	upstream := flag.String("upstream", "", "IP address that api.foojay.io resolved to")
	logPath := flag.String("log", "", "file to append the path and query of each request to")
	flag.Parse()

	out, err := os.OpenFile(*logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		log.Fatal(err)
	}
	proxy := httputil.NewSingleHostReverseProxy(&url.URL{Scheme: "https", Host: "api.foojay.io"})
	address := net.JoinHostPort(*upstream, "443")
	var dialer net.Dialer
	proxy.Transport = &http.Transport{
		DialContext: func(ctx context.Context, network, _ string) (net.Conn, error) {
			return dialer.DialContext(ctx, network, address)
		},
		ForceAttemptHTTP2: true,
	}
	var mu sync.Mutex
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		_, err := fmt.Fprintln(out, r.URL.RequestURI())
		mu.Unlock()
		if err != nil {
			log.Print(err)
		}
		proxy.ServeHTTP(w, r)
	})
	log.Fatal(http.ListenAndServeTLS(*listen, *cert, *key, handler))
}
