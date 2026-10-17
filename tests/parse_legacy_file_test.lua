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
    -- vfox lists the installed versions sorted as strings, descending.
    installed = { unpack(installed) }
    table.sort(installed, function(a, b)
        return a > b
    end)
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
    -- Neither the first version listed nor one whose release merely starts with
    -- the requested one (vfox-java#79): the version itself, else the newest
    -- build of the release, else the newest release of the major.
    { "java=21.0.1-tem\n", { "21.0.1+12-tem", "21.0.12+8-tem" }, "21.0.1+12-tem" },
    { "java=21.0.1+12-tem\n", { "21.0.1+12-tem", "21.0.12+8-tem" }, "21.0.1+12-tem" },
    { "java=21.0.5+63130-jb\n", { "21.0.5+63130-jb", "21.0.5+79248-jb" }, "21.0.5+63130-jb" },
    { "java=21.0.5-jb\n", { "21.0.5+63130-jb", "21.0.5+79248-jb" }, "21.0.5+79248-jb" },
    { "java=21-tem\n", { "21.0.8+9-tem", "21.0.12+8-tem" }, "21.0.12+8-tem" },
    { "java=21.0.3-tem\n", { "21.0.8+9-tem", "21.0.12+8-tem" }, "21.0.12+8-tem" },
    -- SDKMAN's build numbers count its own rebuilds, so they select the release.
    { "java=21.0.8+1.1-tem\n", { "21.0.8+9-tem", "21.0.12+8-tem" }, "21.0.8+9-tem" },
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
    -- SDKMAN pads releases with zeros that Foojay, and so the installed name,
    -- leaves out (vfox-java#80).
    { "java=27.0.0+36-librca\n", { "27+36-librca" }, "27+36-librca" },
    { "java=27.0.0-fx+36-librca\n", { "27+36-librca", "27+36-librca-fx" }, "27+36-librca-fx" },
    { "java=27.0.0+35-zulu\n", { "27+35-zulu" }, "27+35-zulu" },
    { "java=27.0.0.0+35-tem\n", { "27+35-tem" }, "27+35-tem" },
    { "java=27.0.0+35-open\n", { "27+35" }, "27+35" },
    { "java=26.0.0.0+35-open\n", { "26+35" }, "26+35" },
    { "java=25.0.1.0+8-open\n", { "25.0.1+8", "25.0.2+10" }, "25.0.1+8" },
    { "java=21.0.0.0-graal\n", { "21-graal", "21.0.12-graal" }, "21-graal" },
    { "java=21.0.12.0-sapmchn\n", { "21.0.12-sapmchn", "21.0.12.1-sapmchn" }, "21.0.12-sapmchn" },
    { "java=27.0.0.0+33-amzn\n", { "27-amzn" }, "27-amzn" },
    { "java=21.0.10-tem\n", { "21.0.1+12-tem", "21.0.10+7-tem" }, "21.0.10+7-tem" },
    -- A padded major names its first release, a bare major the newest one.
    { "java=26.0.0.0+35-open\n", { "26+34", "26.0.2+10" }, "26+34" },
    { "java=26-open\n", { "26+34", "26.0.2+10" }, "26.0.2+10" },
    -- Without the release, the first release of the major is the newest one too.
    { "java=25.0.1.0+8-open\n", { "25+36" }, "25+36" },
    { "java=26.0.1-oracle\n", { "26-oracle" }, "26-oracle" },
    { "java=26.0.2-oracle\n", { "26-oracle", "26.0.1-oracle" }, "26.0.1-oracle" },
    -- SDKMAN's semverish identifiers write early-access builds 28.0.0+ea.19,
    -- padded or not, where it used to write 28.ea.19 (vfox-java#86).
    { "java=28.ea.19-open\n", { "28-ea+19" }, "28-ea+19" },
    { "java=28.0.0+ea.19-open\n", { "28-ea+19" }, "28-ea+19" },
    { "java=28.0.0.0+ea.19-open\n", { "28-ea+18", "28-ea+19", "27+36" }, "28-ea+19" },
    { "java=26.0.0+ea.13-graal\n", { "26-ea+2-graal", "26-ea+13-graal" }, "26-ea+13-graal" },
    { "java=28.0.0.0+ea.19-jbr\n", { "28-ea+19-jb" }, "28-ea+19-jb" },
    { "java=28.0.0.0-fx+ea.19-zulu\n", { "28-ea+19-zulu", "28-ea+19-zulu-fx" }, "28-ea+19-zulu-fx" },
    -- A build not installed takes the newest one installed, as 28.ea.20 does.
    { "java=28.ea.20-open\n", { "28-ea+18", "28-ea+19" }, "28-ea+19" },
    { "java=28.0.0.0+ea.20-open\n", { "28-ea+18", "28-ea+19" }, "28-ea+19" },
    -- Never a release for an early-access build, nor the other way round.
    { "java=28.0.0.0+ea.19-open\n", { "28+36", "28.0.1+3" }, nil },
    { "java=28.0.0+36-open\n", { "28-ea+19" }, nil },
    -- No java line at all selects nothing.
    { "maven=3.9.9\n", { "21.0.8+9-tem" }, nil },
}
for _, case in ipairs(cases) do
    local version = parse(case[1], case[2])
    assert(version == case[3], string.format("%q: expected %s, got %s", case[1], tostring(case[3]), tostring(version)))
end
print("PASS: " .. #cases .. " ParseLegacyFile regression cases")
