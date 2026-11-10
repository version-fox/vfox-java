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

-- Windows roots: Program Files vendors (where winget, Chocolatey and the
-- vendor installers land), the Gradle cache, mise, and Scoop's nested apps.
local test = require("vfox.test")
local plugin = test.load({
    os = "windows",
    arch = "amd64",
    env = {
        HOME = "C:\\Users\\test",
        USERPROFILE = "C:\\Users\\test",
        ProgramFiles = "C:\\Program Files",
    },
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

local win_jdk = "C:\\Program Files\\Eclipse Adoptium\\jdk-21.0.8.9-hotspot"
files[norm(win_jdk .. "/release")] = release({
    IMPLEMENTOR = "Eclipse Adoptium",
    JAVA_RUNTIME_VERSION = "21.0.8+9-LTS",
    JAVA_VERSION = "21.0.8",
    SEMANTIC_VERSION = "21.0.8+9",
})
dirs[norm("C:\\Program Files\\Eclipse Adoptium")] = { "jdk-21.0.8.9-hotspot" }
dirs[norm("C:\\Program Files\\Java")] = {}
dirs[norm("C:\\Program Files\\Microsoft")] = {}
dirs[norm("C:\\Program Files\\Amazon Corretto")] = {}
dirs[norm("C:\\Program Files\\Zulu")] = {}
dirs[norm("C:\\Program Files\\BellSoft")] = {}
dirs[norm("C:\\Program Files\\OpenJDK")] = {}
dirs[norm("C:\\Program Files\\GraalVM")] = {}
dirs[norm("C:\\Program Files\\SapMachine")] = {}
dirs[norm("C:\\Program Files\\JetBrains")] = {}
dirs[norm("C:\\Program Files\\Oracle")] = {}
dirs[norm("C:\\Users\\test\\.gradle\\jdks")] = {}
dirs[norm("C:\\Users\\test\\.jdks")] = {}
dirs[norm("C:\\Users\\test\\.sdkman\\candidates\\java")] = {}
dirs[norm("C:\\Users\\test\\.asdf\\installs\\java")] = {}
dirs[norm("C:\\Users\\test\\.local\\share\\mise\\installs\\java")] = { "temurin-21.0.12" }
dirs[norm("C:\\Users\\test\\.jabba\\jdk")] = {}
local gradle_win = "C:\\Users\\test\\.gradle\\jdks\\eclipse_adoptium-17-amd64-windows.2"
files[norm(gradle_win .. "/release")] = release({
    IMPLEMENTOR = "Eclipse Adoptium",
    JAVA_RUNTIME_VERSION = "17.0.21+9",
    JAVA_VERSION = "17.0.21",
    SEMANTIC_VERSION = "17.0.21+9",
})
dirs[norm("C:\\Users\\test\\.gradle\\jdks")] = { "eclipse_adoptium-17-amd64-windows.2" }
-- mise on Windows keeps the same layout as elsewhere.
local mise_win = "C:\\Users\\test\\.local\\share\\mise\\installs\\java\\temurin-21.0.12"
files[norm(mise_win .. "/release")] = release({
    IMPLEMENTOR = "Eclipse Adoptium",
    JAVA_RUNTIME_VERSION = "21.0.12+7-LTS",
    JAVA_VERSION = "21.0.12",
    SEMANTIC_VERSION = "21.0.12+7",
})
-- Scoop nests builds under apps/<app>/<version> with a current link.
local scoop_current = "C:\\Users\\test\\scoop\\apps\\temurin-lts-jdk\\current"
files[norm(scoop_current .. "/release")] = release({
    IMPLEMENTOR = "Eclipse Adoptium",
    JAVA_RUNTIME_VERSION = "17.0.22+7",
    JAVA_VERSION = "17.0.22",
    SEMANTIC_VERSION = "17.0.22+7",
})
dirs[norm("C:\\Users\\test\\scoop\\apps")] = { "temurin-lts-jdk" }
dirs[norm("C:\\Users\\test\\scoop\\apps\\temurin-lts-jdk")] = { "current", "21.0.8.9" }
dirs[norm("C:\\Users\\test\\scoop\\apps\\temurin-lts-jdk\\21.0.8.9")] = {}

local found = plugin:Detect({})
local versions = {}
local found_notes = {}
for _, item in ipairs(found) do
    versions[item.version] = item.path
    found_notes[item.path] = item.note
end
assert(versions["21.0.8+9-tem"] == win_jdk, "windows program files jdk")
assert(versions["17.0.21+9-tem"] == gradle_win, "windows gradle jdk")
assert(versions["21.0.12+7-tem"] == mise_win, "windows mise jdk")
assert(versions["17.0.22+7-tem"] == scoop_current, "windows scoop jdk via deep scan")
assert(found_notes[mise_win] == "installed by mise", "windows mise note")
assert(found_notes[scoop_current] == "installed by Scoop", "windows scoop note")
cases = cases + 1

print("PASS: " .. cases .. " Detect Windows cases")
