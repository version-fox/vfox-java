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

local distribution_version_parser = require("distribution_version")
local installed_version = require("installed_version")

function PLUGIN:PreUse(ctx)
    local input_version = ctx.version
    local distribution_version = distribution_version_parser.parse_version(input_version)

    -- If it is a pure numeric major version (such as "8"), let the core perform
    -- fuzzy matching, which takes any distribution. Spelled as OpenJDK (8-open,
    -- openjdk-8), it selects the newest OpenJDK release below instead.
    if input_version:match("^%d+$") then
        -- Return no result, let vfox core perform fuzzy matching. Not "": vfox
        -- after 1.0.12 rejects a bare string ("cannot unmarshal string").
        return nil
    end

    if distribution_version then
        if not distribution_version.version then
            error(distribution_version_parser.missing_version_error(input_version, distribution_version))
        end
        -- OpenJDK versions are installed without a distribution suffix, so
        -- 25.0.2+10-open and openjdk-25.0.2+10 both name 25.0.2+10.
        local suffix = distribution_version.javafx_bundled and "-fx" or ""
        if distribution_version.distribution.short_name ~= "open" then
            suffix = "-" .. distribution_version.distribution.short_name .. suffix
        end
        -- vfox uses the returned version as is, so return the installed one it
        -- names or, without a match, the name for vfox to report as not installed.
        -- A bare major leaves out the releases that installing leaves out
        -- (Oracle GraalVM's feature releases), unless they are all there is.
        local name = distribution_version.version .. suffix
        local skip = distribution_version_parser.bare_major_skips(distribution_version.distribution)
        return {
            version = installed_version.find(ctx.installedSdks or {}, distribution_version.version, suffix, skip)
                or name,
        }
    else
        return {
            version = input_version,
        }
    end
end
