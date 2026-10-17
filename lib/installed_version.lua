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

--- Finds installed versions, which PreInstall names after the Java version,
--- then -<short name> (nothing for OpenJDK), then -fx for JavaFX builds:
--- 21.0.8+9-tem, 25.0.4+9-librca-fx, 25.0.2+10. installed is a table keyed by
--- those names.
local installed_version = {}

--- Compares the numbers in two version strings one by one, missing ones as 0.
local function compare(a, b)
    local x, y = {}, {}
    for number in a:gmatch("%d+") do
        table.insert(x, tonumber(number))
    end
    for number in b:gmatch("%d+") do
        table.insert(y, tonumber(number))
    end
    for i = 1, math.max(#x, #y) do
        if (x[i] or 0) ~= (y[i] or 0) then
            return (x[i] or 0) > (y[i] or 0) and 1 or -1
        end
    end
    return 0
end

--- Whether Java version a is newer than b: the release decides, then the
--- build (21.0.12.1+1 > 21.0.8+9 > 21.0.8+7 > 21+35).
local function newer(a, b)
    local a_release, a_build = a:match("^([^+]*)(.*)$")
    local b_release, b_build = b:match("^([^+]*)(.*)$")
    local order = compare(a_release, b_release)
    return order > 0 or order == 0 and compare(a_build, b_build) > 0
end

--- Returns the newest installed version ending in suffix whose Java version is
--- prefix followed by a rest that the pattern rest matches, or nil.
function installed_version.newest(installed, prefix, rest, suffix)
    local best, best_version
    for candidate in pairs(installed) do
        local java_version = candidate:sub(1, #candidate - #suffix)
        if
            java_version .. suffix == candidate
            and java_version:sub(1, #prefix) == prefix
            and java_version:sub(#prefix + 1):find(rest)
            and (not best or newer(java_version, best_version))
        then
            best, best_version = candidate, java_version
        end
    end
    return best
end

--- Returns the installed version that version .. suffix names, or nil. The
--- input may leave out the build number PreInstall found, so, like PreInstall,
--- take the newest build of a release (21.0.8-tem selects 21.0.8+9-tem) and
--- the newest release of a bare major (21-tem selects 21.0.12.1+1-tem), unless
--- the name itself is installed.
function installed_version.find(installed, version, suffix)
    local name = version .. suffix
    if installed[name] then
        return name
    end
    -- A bare major takes any release of it (21.0.12.1+1 for 21) but no EA build
    -- (26-ea+13 for 26); other versions take only a build number (not
    -- 21.0.12.1+1 for 21.0.12, nor 21.0.12+8 for 21.0.1).
    local rest = version:match("^%d+$") and "^[.+][%d.+]*$" or "^%+%d+$"
    return installed_version.newest(installed, version, rest, suffix)
end

return installed_version
