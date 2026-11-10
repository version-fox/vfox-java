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

-- macOS bundles report Contents/Home, and Homebrew kegs report their Home.
local test = require("vfox.test")
local plugin = test.load({
    os = "darwin",
    arch = "amd64",
    env = { HOME = "/home/test" },
})
require("detect_jdk")

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

local bundle_home = "/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home"
files[norm(bundle_home .. "/release")] = release({
    IMPLEMENTOR = "Eclipse Adoptium",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
    SEMANTIC_VERSION = "21.0.8+9",
})
dirs[norm("/Library/Java/JavaVirtualMachines")] = { "temurin-21.jdk" }
local brew_home = "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
files[norm(brew_home .. "/release")] = release({
    IMPLEMENTOR = "N/A",
    JAVA_RUNTIME_VERSION = "21.0.8+9",
    JAVA_VERSION = "21.0.8",
})
dirs[norm("/opt/homebrew/opt")] = { "openjdk@21" }
dirs[norm("/opt/homebrew/opt/openjdk@21")] = {}
dirs[norm("/home/test/Library/Java/JavaVirtualMachines")] = {}
dirs[norm("/home/test/.jdks")] = {}
dirs[norm("/home/test/.gradle/jdks")] = {}
dirs[norm("/home/test/.sdkman/candidates/java")] = {}
dirs[norm("/home/test/.asdf/installs/java")] = {}
dirs[norm("/home/test/.local/share/mise/installs/java")] = {}
dirs[norm("/home/test/.jabba/jdk")] = {}
dirs[norm("/usr/local/opt")] = {}
dirs[norm("/home/linuxbrew/.linuxbrew/opt")] = {}
dirs[norm("/home/test/.linuxbrew/opt")] = {}
dirs[norm("/opt")] = {}

local found = plugin:Detect({})
local versions = {}
for _, item in ipairs(found) do
    versions[item.path] = item.version
end
assert(versions[bundle_home] == "21.0.8+9-tem", "macOS bundle reports Contents/Home as tem")
assert(versions[brew_home] == "21.0.8+9", "homebrew keg reports its Home as open")
cases = cases + 1

print("PASS: " .. cases .. " Detect macOS cases")
