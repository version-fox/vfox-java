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
PLUGIN = {}
dofile("hooks/pre_use.lua")

-- Installed versions as PreInstall names them, keyed the way vfox passes them.
local installed = {}
for _, version in ipairs({
    "8.0.482+8-zulu-fx",
    "21.0.8+9-tem",
    "21.0.12+8-tem",
    "21.0.12.1+1-tem",
    "25.0.4+9-librca",
    "25.0.4+9-librca-fx",
    "21.0.5+63130-jb",
    "21.0.5+79248-jb",
    "17.0.12-graal",
    "26-ea+2-graal",
    "26-ea+13-graal",
    "25.0.2-graalce",
    "21.0.12+8-lnxabi2-fx",
}) do
    installed[version] = { name = "java", version = version, path = "/sdks/java-" .. version }
end

local cases = {
    { "8.0.482+8-zulu-fx", "8.0.482+8-zulu-fx" },
    { "zulu-8.0.482+8-fx", "8.0.482+8-zulu-fx" },
    { "17.0.17-liberica-fx", "17.0.17-librca-fx" },
    { "8.0.482+8-zulu", "8.0.482+8-zulu" },
    { "temurin-21.0.1", "21.0.1-tem" },
    { "21.0.1-fx", "21.0.1-fx" },
    { "21.0.1", "21.0.1" },
    -- A bare major returns no result, leaving vfox core to fuzzy match.
    { "21", nil },
    -- The input may leave out the build number of the installed name.
    { "21.0.8-tem", "21.0.8+9-tem" },
    { "temurin-21.0.8", "21.0.8+9-tem" },
    { "25.0.4-librca", "25.0.4+9-librca" },
    { "liberica-25.0.4-fx", "25.0.4+9-librca-fx" },
    { "21.0.5-jb", "21.0.5+79248-jb" },
    { "26.ea-graal", "26-ea+13-graal" },
    -- Not a patch release, which PreInstall would not install for 21.0.12-tem either.
    { "21.0.12-tem", "21.0.12+8-tem" },
    -- A bare major selects the newest release of that major.
    { "21-tem", "21.0.12.1+1-tem" },
    { "17-graal", "17.0.12-graal" },
    { "8-zulu-fx", "8.0.482+8-zulu-fx" },
    { "21-lnxabi2-fx", "21.0.12+8-lnxabi2-fx" },
    -- Never another build, distribution, JavaFX flavour or an EA build.
    { "21.0.8+7-tem", "21.0.8+7-tem" },
    { "21.0.8-zulu", "21.0.8-zulu" },
    { "25-graal", "25-graal" },
    { "8-zulu", "8-zulu" },
    { "26-graal", "26-graal" },
}
for _, case in ipairs(cases) do
    local result = PLUGIN:PreUse({ version = case[1], installedSdks = installed })
    -- vfox decodes the result as a table; releases after 1.0.12 reject a bare string.
    assert(result == nil or type(result) == "table", case[1] .. ": expected a table or nil, got " .. type(result))
    local version = result and result.version
    assert(version == case[2], case[1] .. ": expected " .. tostring(case[2]) .. ", got " .. tostring(version))
end
print("PASS: " .. #cases .. " PreUse regression cases")
