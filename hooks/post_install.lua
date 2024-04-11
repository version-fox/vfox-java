local strings = require("vfox.strings")

function PLUGIN:PostInstall(ctx)
    if RUNTIME.osType ~= "darwin" then
        return
    end
    local sdkInfo = ctx.sdkInfo['java']
    local path = sdkInfo.path
    local majorVersion = sdkInfo.note
    local v = strings.split(sdkInfo.version, "+")[1]
    local needRemoveDir = {
        '/jdk-' .. v .. '.jdk',
        '/jdk-' .. majorVersion .. '.jdk',
        '/Contents/Home'
    }
    print("Checking if need to rename jdk files...")
    for _, dir in ipairs(needRemoveDir) do
        print("Checking path: " .. path .. dir)
        if checkDir(path .. dir) then
            print("Renaming jdk files: " .. path .. dir .. '/*')
            if os.execute('mv ' .. path .. dir .. '/*' .. ' ' .. path) == 1 then
                error('Failed to rename jdk files')
            end
        end
    end
end

function checkDir(path)
    return os.execute('[ -d "' .. path .. '" ]') == 0
end
