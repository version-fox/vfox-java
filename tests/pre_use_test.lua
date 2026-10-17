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
}
for _, case in ipairs(cases) do
    local result = PLUGIN:PreUse({ version = case[1] })
    -- vfox decodes the result as a table; releases after 1.0.12 reject a bare string.
    assert(result == nil or type(result) == "table", case[1] .. ": expected a table or nil, got " .. type(result))
    local version = result and result.version
    assert(version == case[2], case[1] .. ": expected " .. tostring(case[2]) .. ", got " .. tostring(version))
end
print("PASS: " .. #cases .. " PreUse regression cases")
