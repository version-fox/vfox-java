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

local test = require("vfox.test")
local plugin = test.load({
    os = "linux",
    arch = "amd64",
    env = { HOME = "/home/test" },
})
local detect = require("detect_jdk")

-- Fake filesystem: files maps a normalized file path to its content, dirs
-- maps a normalized directory path to its immediate child names.
local files = {}
local dirs = {}

local function norm(path)
    return (path or ""):gsub("\\", "/")
end

io.open = function(path, mode)
    mode = mode or "r"
    if mode == "r" then
        local content = files[norm(path)]
        if content == nil then
            return nil
        end
        return {
            read = function(_, pattern)
                if pattern == "*a" then
                    return content
                end
                return nil
            end,
            close = function()
                return true
            end,
        }
    end
    return nil
end

io.popen = function(cmd, mode)
    local dir = cmd:match("'([^']+)'") or cmd:match('"([^"]+)"')
    local children = (dir and dirs[norm(dir)]) or {}
    local index = 0
    return {
        lines = function()
            return function()
                index = index + 1
                return children[index]
            end
        end,
        close = function()
            return true
        end,
    }
end

local function release(fields)
    local lines = {}
    for key, value in pairs(fields) do
        table.insert(lines, key .. '="' .. value .. '"')
    end
    return table.concat(lines, "\n") .. "\n"
end

local function add_jdk(home, fields)
    files[norm(home .. "/release")] = release(fields)
    local parent = norm(home:match("^(.*)[/\\][^/\\]+$") or "")
    if parent ~= "" then
        dirs[parent] = dirs[parent] or {}
        local base = home:match("[/\\]([^/\\]+)$")
        local found = false
        for _, child in ipairs(dirs[parent]) do
            if child == base then
                found = true
                break
            end
        end
        if not found then
            table.insert(dirs[parent], base)
        end
    end
    dirs[norm(home .. "/lib")] = dirs[norm(home .. "/lib")] or {}
end

local function reset()
    files = {}
    dirs = {}
end

local cases = 0
local function check_version(fields, home, expected, message)
    local got = detect.version_for(detect.parse_release(release(fields)), home)
    assert(got == expected, (message or "") .. ": expected " .. tostring(expected) .. ", got " .. tostring(got))
    cases = cases + 1
end

-- Version naming follows `vfox install`: <runtime>-<short name>, -fx for
-- JavaFX, no suffix for OpenJDK.
check_version({
    IMPLEMENTOR = "Eclipse Adoptium",
    IMPLEMENTOR_VERSION = "Temurin-21.0.8+9",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
    SEMANTIC_VERSION = "21.0.8+9",
}, "/jdks/temurin", "21.0.8+9-tem", "temurin")
check_version({
    IMPLEMENTOR = "Azul Systems, Inc.",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
    MODULES = "java.base javafx.base",
}, "/jdks/zulu", "21.0.8+9-zulu-fx", "zulu fx via MODULES")
check_version({
    IMPLEMENTOR = "Azul Systems, Inc.",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
    MODULES = "java.base",
}, "/jdks/zulu-plain", "21.0.8+9-zulu", "zulu plain")
check_version({
    IMPLEMENTOR = "BellSoft",
    JAVA_RUNTIME_VERSION = "21.0.8+12-LTS",
    JAVA_VERSION = "21.0.8",
}, "/jdks/liberica", "21.0.8+12-librca", "liberica")
check_version({
    IMPLEMENTOR = "Amazon.com Inc.",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
}, "/jdks/corretto", "21.0.8+9-amzn", "corretto keeps its build")
check_version({
    IMPLEMENTOR = "Microsoft",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
}, "/jdks/ms", "21.0.8+9-ms", "microsoft")
check_version({
    IMPLEMENTOR = "SAP SE",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
}, "/jdks/sap", "21.0.8+9-sapmchn", "sapmachine")
check_version({
    IMPLEMENTOR = "Tencent",
    JAVA_RUNTIME_VERSION = "21.0.8+1-LTS",
    JAVA_VERSION = "21.0.8",
}, "/jdks/kona", "21.0.8+1-kona", "kona")
check_version({
    IMPLEMENTOR = "JetBrains s.r.o.",
    JAVA_RUNTIME_VERSION = "17.0.11+1-b1207.24",
    JAVA_VERSION = "17.0.11",
}, "/jdks/jbr", "17.0.11+1-jb", "jetbrains keeps the JDK build")
check_version({
    IMPLEMENTOR = "GraalVM Community",
    JAVA_RUNTIME_VERSION = "25.0.2+10-jvmci-b01",
    JAVA_VERSION = "25.0.2",
    GRAALVM_VERSION = "25.0.2",
}, "/jdks/graalce", "25.0.2-graalce", "graalvm community goes by its own version")
check_version({
    IMPLEMENTOR = "Oracle Corporation",
    JAVA_RUNTIME_VERSION = "25.0.4+7-jvmci-25.2-b20",
    JAVA_VERSION = "25.0.4",
    GRAALVM_VERSION = "25.2.4",
}, "/jdks/graal", "25.2.4-graal", "oracle graalvm goes by its own version")
check_version({
    IMPLEMENTOR = "Oracle Corporation",
    JAVA_RUNTIME_VERSION = "21.0.8+9",
    JAVA_VERSION = "21.0.8",
}, "/jdks/openjdk", "21.0.8+9", "oracle corporation without oracle in the path stays open")
check_version({
    IMPLEMENTOR = "Oracle Corporation",
    IMPLEMENTOR_VERSION = "Oracle-21.0.8",
    JAVA_RUNTIME_VERSION = "21.0.8+9",
    JAVA_VERSION = "21.0.8",
}, "/opt/oracle-jdk-21", "21.0.8+9-oracle", "oracle in the path names oracle")
check_version({
    IMPLEMENTOR = "Ubuntu",
    JAVA_RUNTIME_VERSION = "17.0.21.0.3+1-1-26.04.1-Ubuntu",
    JAVA_VERSION = "17.0.21.0.3",
}, "/usr/lib/jvm/java-17", "17.0.21.0.3+1", "ubuntu maps to open and keeps a usable version")
check_version({
    IMPLEMENTOR = "N/A",
    JAVA_RUNTIME_VERSION = "25.0.2+9",
    JAVA_VERSION = "25.0.2",
}, "/jdks/open", "25.0.2+9", "N/A maps to open")
check_version({
    IMPLEMENTOR = "IBM Corporation",
    JAVA_RUNTIME_VERSION = "21.0.8+9",
    JAVA_VERSION = "21.0.8",
}, "/jdks/semeru", "21.0.8+9-sem", "semeru")
check_version({
    IMPLEMENTOR = "IBM Corporation",
    IMPLEMENTOR_VERSION = "Semeru-certified-21.0.8",
    JAVA_RUNTIME_VERSION = "21.0.8+9",
    JAVA_VERSION = "21.0.8",
}, "/jdks/semeru-certified", "21.0.8+9-semcrt", "semeru certified")
check_version({
    IMPLEMENTOR = "AdoptOpenJDK",
    JVM_VARIANT = "Hotspot",
    JAVA_RUNTIME_VERSION = "11.0.10+9",
    JAVA_VERSION = "11.0.10",
}, "/jdks/adpt", "11.0.10+9-adpt", "adoptopenjdk hotspot")
check_version({
    IMPLEMENTOR = "AdoptOpenJDK",
    JVM_VARIANT = "OpenJ9",
    JAVA_RUNTIME_VERSION = "11.0.10+9",
    JAVA_VERSION = "11.0.10",
}, "/jdks/adptj9", "11.0.10+9-adptj9", "adoptopenjdk openj9")
-- Java 8 legacy numbering.
check_version({
    JAVA_RUNTIME_VERSION = "1.8.0_422-b05",
    JAVA_VERSION = "1.8.0_422",
    IMPLEMENTOR = "Azul Systems, Inc.",
}, "/jdks/zulu8", "8.0.422+5-zulu", "java 8 converts 1.8.0_422-b05")
-- Early-access builds keep their -ea.
check_version({
    JAVA_RUNTIME_VERSION = "28-ea+19",
    JAVA_VERSION = "28",
    IMPLEMENTOR = "Eclipse Adoptium",
}, "/jdks/ea", "28-ea+19-tem", "early access")

-- clean_runtime strips the distro suffixes but keeps the build.
assert(detect.clean_runtime("21.0.8+9-LTS") == "21.0.8+9", "strips -LTS")
assert(detect.clean_runtime("22.0.2+9-70") == "22.0.2+9", "strips oracle build suffix")
assert(detect.clean_runtime("17.0.21.0.3+1-1-26.04.1-Ubuntu") == "17.0.21.0.3+1", "strips ubuntu suffix")
cases = cases + 3

-- The prototype from vfox-java#127: Gradle's Temurin 17 is adopted as
-- 17.0.21+9-tem with a Gradle note.
reset()
add_jdk("/home/test/.gradle/jdks/eclipse_adoptium-17-amd64-linux.2", {
    IMPLEMENTOR = "Eclipse Adoptium",
    JAVA_RUNTIME_VERSION = "17.0.21+9",
    JAVA_VERSION = "17.0.21",
    SEMANTIC_VERSION = "17.0.21+9",
})
dirs[norm("/home/test/.gradle/jdks")] = { "eclipse_adoptium-17-amd64-linux.2" }
dirs[norm("/home/test/.jdks")] = {}
dirs[norm("/home/test/.sdkman/candidates/java")] = {}
dirs[norm("/usr/lib/jvm")] = {}
dirs[norm("/opt")] = {}
dirs[norm("/usr/java")] = {}
dirs[norm("/usr/local")] = {}
dirs[norm("/opt/hostedtoolcache")] = {}
local found = plugin:Detect({})
assert(#found == 1, "gradle prototype: expected 1, got " .. #found)
assert(found[1].version == "17.0.21+9-tem", "gradle prototype version: " .. found[1].version)
assert(found[1].path == "/home/test/.gradle/jdks/eclipse_adoptium-17-amd64-linux.2", "gradle prototype path")
assert(found[1].note == "provisioned by Gradle", "gradle prototype note: " .. tostring(found[1].note))
cases = cases + 1

-- Several roots and duplicates: the same Temurin 21.0.8+9-tem shows up
-- through SDKMAN and /opt, and the first path wins. A vfox-managed copy
-- would never be reached through these roots.
reset()
add_jdk("/home/test/.jdks/temurin-21", {
    IMPLEMENTOR = "Eclipse Adoptium",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
    SEMANTIC_VERSION = "21.0.8+9",
})
add_jdk("/usr/lib/jvm/java-17-openjdk-amd64", {
    IMPLEMENTOR = "Ubuntu",
    JAVA_RUNTIME_VERSION = "17.0.21.0.3+1-1-26.04.1-Ubuntu",
    JAVA_VERSION = "17.0.21.0.3",
})
add_jdk("/home/test/.sdkman/candidates/java/21.0.8-tem", {
    IMPLEMENTOR = "Eclipse Adoptium",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
    SEMANTIC_VERSION = "21.0.8+9",
})
add_jdk("/opt/jdk-21-temurin", {
    IMPLEMENTOR = "Eclipse Adoptium",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
    SEMANTIC_VERSION = "21.0.8+9",
})
dirs[norm("/home/test/.gradle/jdks")] = {}
dirs[norm("/home/test/.jdks")] = { "temurin-21" }
dirs[norm("/home/test/.sdkman/candidates/java")] = { "21.0.8-tem" }
dirs[norm("/usr/lib/jvm")] = { "java-17-openjdk-amd64" }
dirs[norm("/opt")] = { "jdk-21-temurin" }
dirs[norm("/usr/java")] = {}
dirs[norm("/usr/local")] = {}
dirs[norm("/opt/hostedtoolcache")] = {}
dirs[norm("/home/test/.asdf/installs/java")] = {}
dirs[norm("/home/test/.local/share/mise/installs/java")] = {}
dirs[norm("/home/test/.jabba/jdk")] = {}
found = plugin:Detect({})
local versions = {}
for _, item in ipairs(found) do
    versions[item.version] = item.path
end
assert(versions["17.0.21.0.3+1"] == "/usr/lib/jvm/java-17-openjdk-amd64", "system ubuntu jdk")
assert(versions["21.0.8+9-tem"] ~= nil, "temurin 21 is found")
assert(#found == 2, "expected 2 versions (ubuntu 17, temurin 21), got " .. #found)
for _, item in ipairs(found) do
    assert(not item.path:find(".vfox", 1, true), "vfox-managed path leaked: " .. item.path)
end
cases = cases + 1

-- Version managers and Linuxbrew: asdf, mise and jabba hold JDKs the same
-- way SDKMAN does, and a Linuxbrew keg reports its Home.
reset()
add_jdk("/home/test/.asdf/installs/java/temurin-21.0.8+9", {
    IMPLEMENTOR = "Eclipse Adoptium",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
    SEMANTIC_VERSION = "21.0.8+9",
})
add_jdk("/home/test/.local/share/mise/installs/java/corretto-21.0.8", {
    IMPLEMENTOR = "Amazon.com Inc.",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
})
add_jdk("/home/test/.jabba/jdk/jbr-21.0.5", {
    IMPLEMENTOR = "JetBrains s.r.o.",
    JAVA_RUNTIME_VERSION = "21.0.5+11-b895.86",
    JAVA_VERSION = "21.0.5",
})
local linuxbrew_home = "/home/linuxbrew/.linuxbrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
files[norm(linuxbrew_home .. "/release")] = release({
    IMPLEMENTOR = "N/A",
    JAVA_RUNTIME_VERSION = "17.0.21+9",
    JAVA_VERSION = "17.0.21",
})
dirs[norm("/home/test/.gradle/jdks")] = {}
dirs[norm("/home/test/.jdks")] = {}
dirs[norm("/home/test/.sdkman/candidates/java")] = {}
dirs[norm("/home/test/.asdf/installs/java")] = { "temurin-21.0.8+9" }
dirs[norm("/home/test/.local/share/mise/installs/java")] = { "corretto-21.0.8" }
dirs[norm("/home/test/.jabba/jdk")] = { "jbr-21.0.5" }
dirs[norm("/home/linuxbrew/.linuxbrew/opt")] = { "openjdk@17" }
dirs[norm("/home/linuxbrew/.linuxbrew/opt/openjdk@17")] = {}
dirs[norm("/usr/lib/jvm")] = {}
dirs[norm("/opt")] = {}
dirs[norm("/usr/java")] = {}
dirs[norm("/usr/local")] = {}
dirs[norm("/opt/hostedtoolcache")] = {}
found = plugin:Detect({})
local notes = {}
for _, item in ipairs(found) do
    notes[item.path] = item.note
end
assert(notes["/home/test/.asdf/installs/java/temurin-21.0.8+9"] == "installed by asdf", "asdf note")
assert(notes["/home/test/.local/share/mise/installs/java/corretto-21.0.8"] == "installed by mise", "mise note")
assert(notes["/home/test/.jabba/jdk/jbr-21.0.5"] == "installed by jabba", "jabba note")
assert(notes[linuxbrew_home] == "installed by Homebrew", "linuxbrew note")
cases = cases + 1

-- The CI runner tool cache nests JDKs two levels down.
reset()
local cached_home = "/opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/21.0.8-9/x64"
files[norm(cached_home .. "/release")] = release({
    IMPLEMENTOR = "Eclipse Adoptium",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
    SEMANTIC_VERSION = "21.0.8+9",
})
dirs[norm("/home/test/.gradle/jdks")] = {}
dirs[norm("/home/test/.jdks")] = {}
dirs[norm("/home/test/.sdkman/candidates/java")] = {}
dirs[norm("/home/test/.asdf/installs/java")] = {}
dirs[norm("/home/test/.local/share/mise/installs/java")] = {}
dirs[norm("/home/test/.jabba/jdk")] = {}
dirs[norm("/usr/lib/jvm")] = {}
dirs[norm("/opt")] = {}
dirs[norm("/usr/java")] = {}
dirs[norm("/usr/local")] = {}
dirs[norm("/home/linuxbrew/.linuxbrew/opt")] = {}
dirs[norm("/opt/hostedtoolcache")] = { "Java_Temurin-Hotspot_jdk" }
dirs[norm("/opt/hostedtoolcache/Java_Temurin-Hotspot_jdk")] = { "21.0.8-9" }
dirs[norm("/opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/21.0.8-9")] = { "x64" }
found = plugin:Detect({})
assert(#found == 1, "toolcache: expected 1, got " .. #found)
assert(found[1].version == "21.0.8+9-tem", "toolcache version: " .. found[1].version)
assert(found[1].path == cached_home, "toolcache path")
assert(found[1].note == "CI runner tool cache", "toolcache note: " .. tostring(found[1].note))
cases = cases + 1

print("PASS: " .. cases .. " Detect version and layout cases")
