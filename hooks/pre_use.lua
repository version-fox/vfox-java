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

function PLUGIN:PreUse(ctx)
    local input_version = ctx.version
    local distribution_version = distribution_version_parser.parse_version(input_version)

    -- If it is a pure numeric major version (such as "8"), and the distribution is openjdk, let the core perform fuzzy matching.
    if distribution_version and distribution_version.distribution.short_name == "open" then
        if not string.find(distribution_version.version, "%.") then -- Pure numbers, no minor versions
            -- Return no result, let vfox core perform fuzzy matching. Not "": vfox
            -- after 1.0.12 rejects a bare string ("cannot unmarshal string").
            return nil
        end
    end

    if distribution_version and distribution_version.distribution.short_name ~= "open" then
        return {
            version = distribution_version.version
                .. "-"
                .. distribution_version.distribution.short_name
                .. (distribution_version.javafx_bundled and "-fx" or ""),
        }
    else
        return {
            version = input_version,
        }
    end
end
