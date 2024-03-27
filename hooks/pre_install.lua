--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    local runtimeVersion = ctx.runtimeVersion
    return {
        --- Version number
        version = "xxx",
        --- remote URL or local file path [optional]
        url = "xxx",
        --- SHA256 checksum [optional]
        sha256 = "xxx",
        --- md5 checksum [optional]
        md5 = "xxx",
        --- sha1 checksum [optional]
        sha1 = "xxx",
        --- sha512 checksum [optional]
        sha512 = "xx",
        --- additional need files [optional]
        addition = {
            {
                --- additional file name !
                name = "xxx",
                --- remote URL or local file path [optional]
                url = "xxx",
                --- SHA256 checksum [optional]
                sha256 = "xxx",
                --- md5 checksum [optional]
                md5 = "xxx",
                --- sha1 checksum [optional]
                sha1 = "xxx",
                --- sha512 checksum [optional]
                sha512 = "xx",
            }
        }
    }
end