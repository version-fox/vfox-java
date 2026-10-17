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
dofile("hooks/parse_legacy_file.lua")

local function parse(content, installed)
    local path = os.tmpname()
    local file = assert(io.open(path, "wb"))
    assert(file:write(content))
    assert(file:close())
    local ok, result = pcall(function()
        return PLUGIN:ParseLegacyFile({
            filepath = path,
            filename = ".sdkmanrc",
            -- vfox 1.x binds this as a Go func() []string and rejects any
            -- argument, including the ctx a ctx:getInstalledVersions() call adds.
            getInstalledVersions = function(...)
                assert(select("#", ...) == 0, "getInstalledVersions takes no arguments")
                return installed
            end,
        })
    end)
    os.remove(path)
    assert(ok, result)
    return result.version
end

-- The JDKs installed in vfox-java#71.
local jb_and_zulu_fx = { "21.0.5+79248-jb", "21.0.12+7-zulu-fx" }

local cases = {
    -- SDKMAN identifiers carry no build number.
    { "java=21.0.8-tem\n", { "21.0.8+9-zulu", "21.0.8+9-tem" }, "21.0.8+9-tem" },
    { "java=25.0.2-open\n", { "25.0.2+10-tem", "25.0.2+10" }, "25.0.2+10" },
    { "java=21.0.5+79248-jb\n", { "21.0.5+79248-jb" }, "21.0.5+79248-jb" },
    -- Without the exact release, the newest installed one of the major.
    { "java=21.0.1-tem\n", { "21.0.8+9-tem" }, "21.0.8+9-tem" },
    -- Windows line endings, as Set-Content writes them.
    { "java=21.0.8-tem\r\nmaven=3.9.9\r\n", { "21.0.8+9-tem" }, "21.0.8+9-tem" },
    -- SDKMAN's JetBrains is jbr and its JavaFX builds are 21.0.12.fx-zulu or,
    -- semverish, 21.0.12-fx+1.1-librca; the plugin's own spellings work too.
    { "java=21.0.5-jb\n", jb_and_zulu_fx, "21.0.5+79248-jb" },
    { "java=21.0.5-jbr\n", jb_and_zulu_fx, "21.0.5+79248-jb" },
    { "java=21.0.12.fx-zulu\n", jb_and_zulu_fx, "21.0.12+7-zulu-fx" },
    { "java=21.0.12-zulu-fx\n", jb_and_zulu_fx, "21.0.12+7-zulu-fx" },
    { "java=21.0.12-fx+1.1-librca\n", { "21.0.12+10-librca", "21.0.12+10-librca-fx" }, "21.0.12+10-librca-fx" },
    -- Never a JavaFX build for one without JavaFX, nor the other way round.
    { "java=21.0.12-zulu\n", { "21.0.12+7-zulu-fx", "21.0.12+7-zulu" }, "21.0.12+7-zulu" },
    { "java=21.0.12-zulu\n", jb_and_zulu_fx, nil },
    { "java=21.0.12.fx-zulu\n", { "21.0.12+7-zulu" }, nil },
    { "java=21.0.8.fx-zulu\n", { "21.0.12+7-zulu", "21.0.12+7-zulu-fx" }, "21.0.12+7-zulu-fx" },
    -- No java line at all selects nothing.
    { "maven=3.9.9\n", { "21.0.8+9-tem" }, nil },
}
for _, case in ipairs(cases) do
    local version = parse(case[1], case[2])
    assert(version == case[3], string.format("%q: expected %s, got %s", case[1], tostring(case[3]), tostring(version)))
end
print("PASS: " .. #cases .. " ParseLegacyFile regression cases")
