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
    -- The installed name of an early-access build selects it, as in vfox use,
    -- although parse_version cannot read it (vfox-java#91). Not installed, it
    -- selects nothing, as vfox use reports it not installed.
    { "java=28-ea+19\n", { "21.0.8+9-tem", "28-ea+19", "28-ea+18-zulu" }, "28-ea+19" },
    { "java=28-ea+18-zulu\n", { "21.0.8+9-tem", "28-ea+19", "28-ea+18-zulu" }, "28-ea+18-zulu" },
    { "java=28-ea+19-zulu-fx\n", { "28-ea+19-zulu", "28-ea+19-zulu-fx" }, "28-ea+19-zulu-fx" },
    { "java=26-ea+13-graal\n", { "26-ea+2-graal", "26-ea+13-graal" }, "26-ea+13-graal" },
    { "java=28-ea+20\n", { "28-ea+18", "28-ea+19" }, nil },
    -- A distribution without a version selects nothing, as vfox use rejects it
    -- (vfox-java#98), where parse_version failed with a Lua error.
    { "java=tem\n", { "21.0.8+9-tem", "21.0.12+8-tem" }, nil },
    { "java=temurin-\n", { "21.0.8+9-tem" }, nil },
    { "java=-tem\n", { "21.0.8+9-tem" }, nil },
    { "java=zulu-fx\n", { "21.0.12+7-zulu-fx" }, nil },
    { "java=open\n", { "25.0.2+10" }, nil },
    -- SDKMAN wrote the VM or the JDK of the distributions it no longer offers
    -- into the version, which is the plugin's short name (adpt, adptj9,
    -- grl17, gln). SDKMAN's AdoptOpenJDK upstream builds and Gluon's JDK 11
    -- builds are not the plugin's, so they select nothing.
    { "java=11.0.10.hs-adpt\n", { "11.0.10-adpt", "11.0.10-adptj9" }, "11.0.10-adpt" },
    { "java=11.0.10.j9-adpt\n", { "11.0.10-adpt", "11.0.10-adptj9" }, "11.0.10-adptj9" },
    { "java=8.0.282.j9-adpt\n", { "8.0.282-adpt", "8.0.282-adptj9" }, "8.0.282-adptj9" },
    { "java=11.0.9.open-adpt\n", { "11.0.9-adpt", "11.0.11-adpt" }, nil },
    { "java=22.3.3.r17-grl\n", { "22.3.3-grl11", "22.3.3-grl17" }, "22.3.3-grl17" },
    { "java=22.3.3.r11-grl\n", { "22.3.3-grl11", "22.3.3-grl17" }, "22.3.3-grl11" },
    { "java=21.3.1.r8-grl\n", { "21.3.1-grl8", "21.3.1-grl11" }, "21.3.1-grl8" },
    { "java=22.3.r19-grl\n", { "22.3-grl19", "22.3.1-grl19" }, "22.3-grl19" },
    { "java=21.2.0.r16-grl\n", { "21.2-grl16" }, "21.2-grl16" },
    { "java=22.3.3.r20-grl\n", { "22.3.3-grl17" }, nil },
    { "java=22.1.0.1.r17-gln\n", { "22.1.0.1-gln" }, "22.1.0.1-gln" },
    { "java=22.1.0.1.r11-gln\n", { "22.1.0.1-gln" }, nil },
    -- The plugin's own spellings of them.
    { "java=22.3.3-grl17\n", { "22.3.3-grl11", "22.3.3-grl17" }, "22.3.3-grl17" },
    { "java=21.0.8-rdht\n", { "21.0.8+9-rdht" }, "21.0.8+9-rdht" },
    { "java=25.0.4-semcrt\n", { "25.0.4-semcrt", "25.0.2+10-sem" }, "25.0.4-semcrt" },
    { "java=25.0.2-sem\n", { "25.0.4-semcrt", "25.0.2+10-sem" }, "25.0.2+10-sem" },
    -- SDKMAN writes the JDK into some versions of Mandrel and Liberica NIK as
    -- well, which their installed names leave out (vfox-java#109).
    -- ParseLegacyFile took 25.0.4.r25 for a release, found none and fell back
    -- to the newest one of the major. A release from 21.3 to 23.0.1.2 comes
    -- for two JDKs, of which the plugin installs the newer one's build, so the
    -- older JDK selects nothing, as Gluon's JDK 11 does.
    { "java=25.0.4.r25-nik\n", { "25.0.4-nik", "25.0.4.1-nik" }, "25.0.4-nik" },
    { "java=25.0.2.r25-mandrel\n", { "25.0.2-mandrel", "25.0.4.1-mandrel" }, "25.0.2-mandrel" },
    { "java=22.1.r17-mandrel\n", { "22.1-mandrel", "22.2-mandrel" }, "22.1-mandrel" },
    { "java=22.1.r11-mandrel\n", { "22.1-mandrel", "22.2-mandrel" }, nil },
    { "java=21.2.r11-nik\n", { "21.2-nik" }, "21.2-nik" },
    { "java=21.3.r11-nik\n", { "21.3-nik" }, nil },
    { "java=22.3.5.r11-nik\n", { "22.3.5-nik" }, nil },
    { "java=22.3.5.r17-nik\n", { "22.3.5-nik" }, "22.3.5-nik" },
    { "java=23.r17-nik\n", { "23-nik" }, nil },
    { "java=23.r20-nik\n", { "23-nik", "23.1.12.1-nik" }, "23-nik" },
    { "java=23.0.1.2.r17-mandrel\n", { "23.0.1.2-mandrel" }, nil },
    { "java=23.0.1.2.r20-mandrel\n", { "23.0.1.2-mandrel", "23.0.6-mandrel" }, "23.0.1.2-mandrel" },
    { "java=23.0.2.r17-nik\n", { "23.0.2-nik" }, "23.0.2-nik" },
    -- SDKMAN's 25.r25-mandrel (Mandrel 25.0.1.0) names a bare major, which
    -- selects the newest release of it, as java@25-mandrel does.
    { "java=25.r25-mandrel\n", { "25.0.1-mandrel", "25.0.4.1-mandrel" }, "25.0.4.1-mandrel" },
    -- Until Foojay's change in October 2026, release 0.6.2 named Liberica NIK
    -- with BellSoft's build.
    { "java=23.1.8.r21-nik\n", { "23.1.8+1-nik", "23.1.12.1-nik" }, "23.1.8+1-nik" },
    -- A bare major, or a release that is not installed, takes the newest
    -- release of the major, and Oracle GraalVM's monthly feature releases come
    -- after the 25.0 line there, as in vfox install java@25-graal and vfox use
    -- java@25-graal (vfox-java#110).
    { "java=25-graal\n", { "25.4.4.1.1-graal", "25.0.4.1-graal" }, "25.0.4.1-graal" },
    {
        "java=25-graal\n",
        { "25.3.4.1-graal", "25.0.4.1.1-graal", "25.4.4.1.1-graal", "25.0.4.1-graal" },
        "25.0.4.1.1-graal",
    },
    { "java=25.0.3-graal\n", { "25.4.4.1.1-graal", "25.0.4.1-graal" }, "25.0.4.1-graal" },
    { "java=25.0.4.1-graal\n", { "25.4.4.1.1-graal", "25.0.4.1.1-graal", "25.0.5-graal" }, "25.0.5-graal" },
    -- The first release of the major belongs to the 25.0 line as well.
    { "java=25.0.3-graal\n", { "25.4.4.1.1-graal", "25-graal" }, "25-graal" },
    -- Nothing else of the major installed.
    { "java=25-graal\n", { "25.4.4.1.1-graal", "25.3.4.1-graal" }, "25.4.4.1.1-graal" },
    { "java=25.0.3-graal\n", { "25.4.4.1.1-graal" }, "25.4.4.1.1-graal" },
    -- A file that names a feature release (SDKMAN's identifier is 25.4.4+1-graal)
    -- takes the newest release of the major, as it did.
    { "java=25.4.4+1-graal\n", { "25.4.4.1.1-graal", "25.0.4.1-graal" }, "25.4.4.1.1-graal" },
    { "java=25.5.5-graal\n", { "25.4.4.1.1-graal", "25.0.4.1-graal" }, "25.4.4.1.1-graal" },
    { "java=25.4.4.1.1-graal\n", { "25.4.4.1.1-graal", "25.0.4.1-graal" }, "25.4.4.1.1-graal" },
    -- Other majors and distributions: GraalVM Community's feature releases are
    -- what it still ships, and a minor above 0 means nothing for Mandrel.
    { "java=21-graal\n", { "21.0.8-graal", "25.4.4.1.1-graal" }, "21.0.8-graal" },
    { "java=25-graalce\n", { "25.4.4.1.1-graalce", "25.0.2-graalce" }, "25.4.4.1.1-graalce" },
    { "java=25.0.1-graalce\n", { "25.4.4.1.1-graalce", "25.0.2-graalce" }, "25.4.4.1.1-graalce" },
    { "java=23-mandrel\n", { "23.1.12.1-mandrel", "23.0.1.2-mandrel" }, "23.1.12.1-mandrel" },
    -- No java line at all selects nothing.
    { "maven=3.9.9\n", { "21.0.8+9-tem" }, nil },
}
for _, case in ipairs(cases) do
    local version = parse(case[1], case[2])
    assert(version == case[3], string.format("%q: expected %s, got %s", case[1], tostring(case[3]), tostring(version)))
end
print("PASS: " .. #cases .. " ParseLegacyFile regression cases")
