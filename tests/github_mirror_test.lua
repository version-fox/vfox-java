-- Copyright 2026 Han Li and contributors
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

dofile("tests/support.lua")
local github_mirror = require("github_mirror")

-- The mirror comes from the environment: os.getenv answers for it from this
-- table, whose field the cases set, and for everything else as it did.
local env = {}
local getenv = os.getenv
os.getenv = function(name)
    if name == "VFOX_JAVA_GITHUB_MIRROR" then
        return env.mirror
    end
    return getenv(name)
end

-- Download URLs as Foojay gives them (2026-10-21): Temurin's has a %2B in the
-- path and Liberica's a bare +.
local temurin =
    "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.8%2B9/OpenJDK21U-jdk_x64_linux_hotspot_21.0.8_9.tar.gz"
local liberica = "https://github.com/bell-sw/Liberica/releases/download/27+36/bellsoft-jdk27+36-linux-amd64.tar.gz"

local cases = 0
local function check(mirror, url, expected)
    env.mirror = mirror
    local got = github_mirror.url(url)
    assert(
        got == expected,
        ("mirror %q, %s: expected %s, got %s"):format(tostring(mirror), tostring(url), expected, got)
    )
    cases = cases + 1
end

-- Without a mirror, or with an empty one, nothing changes.
for _, mirror in ipairs({ "", " ", "\t\n" }) do
    check(mirror, temurin, temurin)
end
check(nil, temurin, temurin)

-- A mirror is a prefix of the whole URL, whether or not it ends in a slash.
check("https://gh-proxy.org/", temurin, "https://gh-proxy.org/" .. temurin)
check("https://gh-proxy.org", temurin, "https://gh-proxy.org/" .. temurin)
check("https://gh-proxy.org/", liberica, "https://gh-proxy.org/" .. liberica)
check("https://mirror.example:8443/github/", liberica, "https://mirror.example:8443/github/" .. liberica)
check("http://127.0.0.1:8080", liberica, "http://127.0.0.1:8080/" .. liberica)
-- Blanks around the value, as a shell or a profile can leave them, are dropped.
check(" https://gh-proxy.org/\n", temurin, "https://gh-proxy.org/" .. temurin)

-- Only github.com is mirrored: not the other hosts JDKs come from, nor
-- addresses that merely start like it.
for _, url in ipairs({
    "https://download.oracle.com/graalvm/25/latest/graalvm-jdk-25_linux-x64_bin.tar.gz",
    "https://cache-redirector.jetbrains.com/intellij-jbr/jbr-21.0.5-linux-x64-b631.28.tar.gz",
    "https://aka.ms/download-jdk/microsoft-jdk-21.0.8-linux-x64.tar.gz",
    "https://api.foojay.io/disco/v3.0/ids/0123456789abcdef",
    "http://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.8%2B9/file.tar.gz",
    "https://github.com.example.org/adoptium/file.tar.gz",
    "https://raw.githubusercontent.com/adoptium/file.tar.gz",
    "https://gist.github.com/adoptium/file.tar.gz",
    "https://github.com",
    "",
}) do
    check("https://gh-proxy.org/", url, url)
end
-- A missing URL is left to vfox to report.
env.mirror = "https://gh-proxy.org/"
assert(github_mirror.url(nil) == nil, "nil: expected nil")
cases = cases + 1

-- Something vfox would not download is refused with a message naming the
-- variable and the value, but only when a GitHub URL needs it. These cases come
-- last: once pcall has caught an error, gopher-lua's closures no longer see
-- later assignments to the locals around them.
for _, mirror in ipairs({ "gh-proxy.org", "gh-proxy.org/", "ftp://gh-proxy.org/", "HTTPS://gh-proxy.org/", "false" }) do
    env.mirror = mirror
    local ok, err = pcall(github_mirror.url, temurin)
    local want = "VFOX_JAVA_GITHUB_MIRROR must start with http:// or https://, such as https://gh-proxy.org/, but is "
    assert(not ok and tostring(err):find(want .. mirror, 1, true), mirror .. ": unexpected " .. tostring(err))
    assert(
        github_mirror.url("https://download.oracle.com/file.tar.gz") == "https://download.oracle.com/file.tar.gz",
        mirror .. ": a URL that is not on GitHub needs no mirror"
    )
    cases = cases + 2
end

print("PASS: " .. cases .. " GitHub mirror cases")
