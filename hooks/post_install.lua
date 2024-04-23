local strings = require("vfox.strings")

function PLUGIN:PostInstall(ctx)
    if RUNTIME.osType ~= "darwin" then
        return
    end
    local sdkInfo = ctx.sdkInfo['java']
    local path = sdkInfo.path
    local majorVersion = sdkInfo.note
    local version = strings.split(sdkInfo.version, "-")[1]
    local v = strings.split(version, "+")[1]
    local needRemoveDir = {
        ['/jdk-' .. v .. '.jdk'] = true,
        ['/jdk-' .. majorVersion .. '.jdk'] = true,
        ['/jdk-' .. version .. '.jdk'] = true,
        ['/Contents/Home'] = true,
    }
    print("Checking if need to rename jdk files...")
    for dir, _ in pairs(needRemoveDir) do
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
