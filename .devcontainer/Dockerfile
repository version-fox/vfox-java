# Copyright 2026 Han Li and contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The repository dev container (see docs/e2e.md): a Linux userland that is
# identical on every host platform — Linux amd64/arm64 natively, Windows
# amd64/arm64 through Docker Desktop's Linux-container mode. It carries the
# pinned Go toolchain the E2E suites and the local checks need, matching the
# setup-go version CI uses, plus the Lua and license tooling pinned in the
# lint and license workflows.
#
# The suites themselves run testcontainers against the host daemon through
# the socket mounted by devcontainer.json (Docker-out-of-Docker), so the
# target containers are spawned exactly as a native CI runner spawns them.
#
# The image is multi-arch (linux/amd64 and linux/arm64); the Lua downloads
# below select their asset per target arch.

FROM golang:1.27.1

# Docker CLI (client only): drives the host daemon from the shell, the same
# daemon the suites drive through the Docker Go API. Engine 29 is the line
# tests/e2e/windows/install-docker-arm64.ps1 builds for Windows arm64.
COPY --from=docker:29-cli /usr/local/bin/docker /usr/local/bin/docker

# Keep the tool versions below in step with .github/workflows/lint.yml
# (stylua-action's version and the `mise x aqua:...` line).
ARG STYLUA_VERSION=2.5.2
ARG LUA_LANGUAGE_SERVER_VERSION=3.19.1

# Heredocs need BuildKit, which the dev container tooling uses by default. The
# E2E target Dockerfiles stay on the chained-`;` form: testcontainers-go's
# build path cannot use BuildKit (see tests/e2e/linux/Dockerfile).

RUN <<EOF
set -o errexit -o nounset -o xtrace
apt-get update
apt-get install --assume-yes --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    zip
rm --recursive --force /var/lib/apt/lists/*
case "$(dpkg --print-architecture)" in
    amd64) stylua_asset=stylua-linux-x86_64.zip; luals_asset="lua-language-server-${LUA_LANGUAGE_SERVER_VERSION}-linux-x64.tar.gz" ;;
    arm64) stylua_asset=stylua-linux-aarch64.zip; luals_asset="lua-language-server-${LUA_LANGUAGE_SERVER_VERSION}-linux-arm64.tar.gz" ;;
    *) echo "FAIL unsupported architecture $(dpkg --print-architecture)" >&2; exit 1 ;;
esac
curl --fail --silent --show-error --location --output /tmp/stylua.zip \
    "https://github.com/JohnnyMorganz/StyLua/releases/download/v${STYLUA_VERSION}/${stylua_asset}"
unzip -q /tmp/stylua.zip -d /usr/local/bin
rm --force /tmp/stylua.zip
curl --fail --silent --show-error --location --output /tmp/luals.tar.gz \
    "https://github.com/LuaLS/lua-language-server/releases/download/${LUA_LANGUAGE_SERVER_VERSION}/${luals_asset}"
mkdir --parents /opt/lua-language-server
tar --extract --gzip --file /tmp/luals.tar.gz --directory /opt/lua-language-server
rm --force /tmp/luals.tar.gz
ln --symbolic /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server
stylua --version
lua-language-server --version
EOF

# License-header tooling at the versions pinned by .github/workflows/license.yml
# (SkyWalking Eyes v0.9.0 for the header check, addlicense v1.2.0 for the
# PowerShell files).
RUN <<EOF
set -o errexit -o nounset -o xtrace
GOBIN=/usr/local/bin go install github.com/apache/skywalking-eyes/cmd/license-eye@v0.9.0
GOBIN=/usr/local/bin go install github.com/google/addlicense@v1.2.0
command -v license-eye addlicense
EOF
