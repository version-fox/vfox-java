package.path = './lib/?.lua;' .. package.path
package.preload['vfox.strings'] = function()
    return { split = function(value, separator)
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
    end }
end
PLUGIN = {}
dofile('hooks/pre_use.lua')
local cases = {
    {'8.0.482+8-zulu-fx', '8.0.482+8-zulu-fx'},
    {'zulu-8.0.482+8-fx', '8.0.482+8-zulu-fx'},
    {'17.0.17-liberica-fx', '17.0.17-librca-fx'},
    {'8.0.482+8-zulu', '8.0.482+8-zulu'},
    {'temurin-21.0.1', '21.0.1-tem'},
    {'21.0.1-fx', '21.0.1-fx'},
    {'21.0.1', '21.0.1'},
    {'21', ''},
}
for _, case in ipairs(cases) do
    local result = PLUGIN:PreUse({version = case[1]})
    local version = type(result) == 'table' and result.version or result
    assert(version == case[2], case[1] .. ': expected ' .. case[2] .. ', got ' .. tostring(version))
end
print('PASS: ' .. #cases .. ' PreUse regression cases')
