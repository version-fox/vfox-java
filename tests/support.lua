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
