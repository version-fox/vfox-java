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

local foojay = require("foojay")
local loongnix = require("loongnix")
local distribution_version_parser = require("distribution_version")

-- is_feature_release reads GraalVM's numbering since 25 only. Liberica NIK and
-- Mandrel carry GraalVM's older numbers up to 24, whose minor is no feature
-- release (Mandrel 23.1.12, on JDK 21, is LTS), and the JDK's from 25 on, so
-- they stay out of it, and so do GraalVM CE 8 to 19 and Gluon GraalVM, which
-- ended before the monthly feature releases began.
local graalvm = { graal = true, graalce = true }

--- Return all available versions provided by this plugin
--- @param ctx table Empty table used as context, for future extension
--- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
    local query = ctx.args[1] or (loongnix.supported() and "loongnix" or "open")
    if query == "loongnix" or loongnix.is_distribution(query) or (loongnix.supported() and query == "all") then
        return loongnix.available(query)
    end
    if loongnix.supported() then
        error("Foojay does not support loong64; use vfox search java loongnix")
    end
    local jdks = {}
    local short_name = nil

    if query == "all" then
        for _, dist in ipairs(distribution_version_parser.distributions) do
            local tempJdks = {}
            if not loongnix.is_distribution(dist.name) then
                tempJdks = foojay.fetchtJdkList(dist.name, "")
            end
            for _, jdk in ipairs(tempJdks) do
                jdk.short = dist.short_name
                table.insert(jdks, jdk)
            end
        end
    else
        local distribution = distribution_version_parser.parse_distribution(query)
        if not distribution then
            error("Unsupported distribution: " .. query)
        end
        short_name = distribution.short_name
        jdks = foojay.fetchtJdkList(distribution.name, "")
    end

    local result = {}
    local seen = {}
    for _, jdk in ipairs(jdks) do
        local v = jdk.java_version
        local short = jdk.short or short_name

        -- Add -fx suffix for JavaFX bundled versions (after distribution name)
        local fx_suffix = ""
        if jdk.javafx_bundled == true then
            fx_suffix = "-fx"
        end

        -- OpenJDK versions carry no distribution suffix, as PreInstall names
        -- them, whether the query is open, openjdk or all.
        if short == "open" then
            v = v .. fx_suffix
        else
            v = v .. "-" .. short .. fx_suffix
        end

        if not seen[v] then
            seen[v] = true
            -- check if version exists
            -- Foojay marks GraalVM's feature releases LTS, as the JDK they build on is.
            local lts = jdk.term_of_support == "lts"
                and not (graalvm[short] and distribution_version_parser.is_feature_release(jdk.java_version))
            local note = lts and "LTS" or ""
            if jdk.javafx_bundled == true then
                note = note == "" and "JavaFX" or note .. ", JavaFX"
            end
            table.insert(result, {
                version = v,
                note = note,
            })
        end
    end
    return result
end
