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

local strings = require("vfox.strings")

local distribution_version_parser = require("distribution_version")
local installed_version = require("installed_version")

--- The distributions SDKMAN no longer offers, for which it wrote the VM or
--- the JDK into the version: AdoptOpenJDK with HotSpot or OpenJ9
--- (11.0.10.hs-adpt, 11.0.10.j9-adpt), GraalVM CE on JDK 8 to 19
--- (22.3.3.r17-grl) and Gluon GraalVM on JDK 17, the builds of it the plugin
--- installs (22.1.0.1.r17-gln). Each flavour maps to the plugin's short name.
local sdkman_flavours = {
    adpt = { hs = "adpt", j9 = "adptj9" },
    grl = { r8 = "grl8", r11 = "grl11", r16 = "grl16", r17 = "grl17", r19 = "grl19" },
    gln = { r17 = "gln" },
}

--- Mandrel and Liberica NIK, which SDKMAN still offers. The plugin names them
--- after the version of the GraalVM they are built from, and SDKMAN adds the
--- JDK to some of those versions: 25.0.4.r25-nik is the plugin's 25.0.4-nik.
local sdkman_jdks = {
    mandrel = true,
    nik = true,
}

--- Returns the JDK whose build of a Mandrel or Liberica NIK release the
--- plugin does not install, if any. Their releases from 21.3 to 23.0.1.2 come
--- for two JDKs, and the plugin installs the build for the newer one, so the
--- older one is 11 up to 22.3.5 (Mandrel 22.3 has no JDK 11 build at all)
--- and 17 from 23 to 23.0.1.2.
local function older_jdk(release)
    if installed_version.newer("21.3", release) then
        return nil
    elseif installed_version.newer("23", release) then
        return "11"
    elseif installed_version.newer("23.0.2", release) then
        return "17"
    end
    return nil
end

--- Rewrites an SDKMAN identifier in the plugin's spelling, which parse_version
--- reads. SDKMAN calls JetBrains jbr (the plugin's jb) and puts fx in the
--- version of JavaFX builds: 21.0.12.fx-zulu, or 21.0.12-fx+1.1-librca in its
--- semverish identifiers (the plugin's 21.0.12-zulu-fx, 21.0.12+1.1-librca-fx).
--- The semverish ones spell early-access builds 28.0.0+ea.19-open, padded or
--- not (28.0.0.0+ea.19-open), where SDKMAN used to write the plugin's
--- 28.ea.19-open (Foojay's 28-ea+19). The VM or JDK of the distributions in
--- sdkman_flavours becomes the short name (22.3.3.r17-grl is 22.3.3-grl17),
--- the JDK of those in sdkman_jdks is dropped (25.0.4.r25-nik is
--- 25.0.4-nik), and nil comes back for a build the plugin does not install
--- (11.0.9.open-adpt, 22.1.0.1.r11-gln, 22.1.r11-mandrel). Any other
--- spelling, the plugin's own included, is returned unchanged.
local function plugin_spelling(identifier)
    local version, distribution = identifier:match("^(.+)%-([^-]+)$")
    if not version then
        return identifier
    end
    if distribution == "jbr" then
        distribution = "jb"
    end
    local flavours = sdkman_flavours[distribution]
    local flavoured, flavour = version:match("^(%d[%d.]*)%.(%a%w*)$")
    if flavours and flavoured then
        distribution = flavours[flavour]
        if not distribution then
            return nil
        end
        version = flavoured
    end
    local own_number, jdk = version:match("^(%d[%d.]*)%.r(%d+)$")
    if sdkman_jdks[distribution] and own_number then
        if jdk == older_jdk(own_number) then
            return nil
        end
        version = own_number
    end
    local suffix = "-" .. distribution
    local release, build = version:match("^(%d[%d.]*)[.-]fx(.*)$")
    if release then
        version, suffix = release .. build, suffix .. "-fx"
    end
    local major, ea_build = version:match("^(%d+)[.0]*%+ea%.(%d+)$")
    if major then
        version = major .. ".ea." .. ea_build
    end
    return version .. suffix
end

function PLUGIN:ParseLegacyFile(ctx)
    local filepath = ctx.filepath

    --- 17.0.10-librca
    --- 17.0.10+20-librca
    local javaVersion

    for line in io.lines(filepath) do
        if strings.has_prefix(line, "java=") then
            javaVersion = strings.trim_prefix(line, "java=")
            break
        end
    end

    if not javaVersion then
        return {}
    end

    --- Get the list of versions of the current plugin installed
    --- (a plain call: vfox 1.x rejects the extra ctx argument of ctx:...).
    --- vfox sorts it as strings, descending (21.0.8+9-tem, 21.0.12+8-tem,
    --- 21.0.1+12-tem), so the first match is not the one to take.
    local installed = {}
    for _, v in ipairs(ctx.getInstalledVersions()) do
        installed[v] = true
    end

    --- An installed version written as vfox lists it selects itself, as in
    --- vfox use, even one that parse_version cannot read: an early-access
    --- build (28-ea+19, 28-ea+18-zulu).
    if installed[javaVersion] then
        return { version = javaVersion }
    end

    local spelling = plugin_spelling(javaVersion)
    local distributionVersion = spelling and distribution_version_parser.parse_version(spelling)
    if not distributionVersion then
        return {}
    end
    --- A distribution alone (java=tem) selects nothing, as vfox use rejects it.
    local fullVersion = distributionVersion.version
    if not fullVersion then
        return {}
    end
    local vendor = distributionVersion.distribution.short_name
    if not vendor then
        return {}
    end

    --- SDKMAN pads the release with zeros that Foojay, and so the installed
    --- name, leaves out: 27.0.0+36 is 27+36, 25.0.1.0+8 is 25.0.1+8.
    local version, build = installed_version.unpad(fullVersion):match("^([^+]*)(.*)$")
    local majorVersion = strings.split(version, ".")[1]

    --- Installed versions end in -<vendor> (OpenJDK's in nothing), then -fx for
    --- JavaFX builds: 21.0.8+9-tem, 21.0.12+7-zulu-fx, 25.0.2+10.
    local suffix = (vendor == "open" and "" or "-" .. vendor) .. (distributionVersion.javafx_bundled and "-fx" or "")

    --- The version itself (21.0.5+63130-jb), else the release itself or its
    --- newest build, as SDKMAN's build numbers count its own rebuilds
    --- (21.0.12+1.1-tem), else the newest installed release of the major
    --- (21.0.12+8-tem for 21.0.3-tem). A bare major (21-tem) skips the
    --- release, taking the newest one as vfox use java@21-tem does, while
    --- SDKMAN's 21.0.0 still names the release 21 (21+35-tem).
    local name = version .. build .. suffix
    return {
        version = installed[name] and name
            or not fullVersion:match("^%d+$") and installed_version.release(installed, version, suffix)
            or installed_version.major(installed, majorVersion, suffix),
    }
end
