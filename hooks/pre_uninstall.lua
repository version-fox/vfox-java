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

local idea_links = require("idea_links")

--- Removes the link PostInstall created in the folder IntelliJ IDEA and
--- Gradle look in, when VFOX_JAVA_JDKS_LINKS asks for it. Only a link goes:
--- a real directory of the same name is left alone. Cleanup never fails the
--- uninstall.
function PLUGIN:PreUninstall(ctx)
    local main = ctx.main
    if not main or not main.version or not idea_links.enabled() then
        return
    end
    local ok, err = idea_links.remove_link(main.version)
    if not ok then
        print("warning: could not remove the link from " .. idea_links.dir() .. ": " .. tostring(err))
    end
end
