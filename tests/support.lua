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

package.path = "./lib/?.lua;" .. package.path
package.preload["vfox.strings"] = function()
    local function has_prefix(value, prefix)
        return value:sub(1, #prefix) == prefix
    end
    return {
        split = function(value, separator)
            local result = {}
            local start = 1
            while true do
                local position = value:find(separator, start, true)
                if not position then
                    table.insert(result, value:sub(start))
                    return result
                end
                table.insert(result, value:sub(start, position - 1))
                start = position + #separator
            end
        end,
        has_prefix = has_prefix,
        trim_prefix = function(value, prefix)
            return has_prefix(value, prefix) and value:sub(#prefix + 1) or value
        end,
        contains = function(value, substring)
            return value:find(substring, 1, true) ~= nil
        end,
    }
end
