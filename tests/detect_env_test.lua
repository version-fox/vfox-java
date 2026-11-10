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

-- GRADLE_USER_HOME moves Gradle's provisioning folder, and a JAVA_HOME that
-- points into vfox's own directory must never be reported.
local test = require("vfox.test")
local plugin = test.load({
    os = "linux",
    arch = "amd64",
    env = {
        HOME = "/home/test",
        GRADLE_USER_HOME = "/custom/gradle",
        JAVA_HOME = "/home/test/.vfox/sdks/java",
    },
})
local detect = require("detect_jdk")

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

local cases = 0

-- $GRADLE_USER_HOME/jdks replaces ~/.gradle/jdks. The vfox-managed JAVA_HOME
-- below does hold a JDK, so only the .vfox filter keeps it out.
local custom_jdk = "/custom/gradle/jdks/eclipse_adoptium-21-amd64-linux.2"
files[norm(custom_jdk .. "/release")] = release({
    IMPLEMENTOR = "Eclipse Adoptium",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
    SEMANTIC_VERSION = "21.0.8+9",
})
files[norm("/home/test/.vfox/sdks/java/release")] = release({
    IMPLEMENTOR = "Eclipse Adoptium",
    JAVA_RUNTIME_VERSION = "25.0.4+7-LTS",
    JAVA_VERSION = "25.0.4",
    SEMANTIC_VERSION = "25.0.4+7",
})
dirs[norm("/custom/gradle/jdks")] = { "eclipse_adoptium-21-amd64-linux.2" }
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
dirs[norm("/home/test/.linuxbrew/opt")] = {}
dirs[norm("/opt/hostedtoolcache")] = {}

local found = plugin:Detect({})
assert(#found == 1, "expected the gradle override only, got " .. #found)
assert(found[1].version == "21.0.8+9-tem", "gradle override version: " .. found[1].version)
assert(found[1].path == custom_jdk, "gradle override path")
assert(found[1].note == "provisioned by Gradle", "gradle override note: " .. tostring(found[1].note))
-- The vfox-managed JAVA_HOME contributes nothing.
for _, item in ipairs(found) do
    assert(not item.path:find(".vfox", 1, true), "vfox-managed path leaked: " .. item.path)
end
cases = cases + 1

-- A JAVA_HOME outside vfox is adopted with its note.
assert(detect.version_for(
    detect.parse_release(release({
        IMPLEMENTOR = "Microsoft",
        JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
        JAVA_VERSION = "21.0.8",
    })),
    "/opt/java"
) == "21.0.8+9-ms", "unit check for the JAVA_HOME naming")
cases = cases + 1

print("PASS: " .. cases .. " Detect environment cases")
