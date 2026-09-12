local function shellQuote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

function PLUGIN:PostInstall(ctx)
    if RUNTIME.osType ~= "darwin" then
        return
    end
    local path = ctx.sdkInfo.java.path
    -- Archives may contain a flat JDK, Contents/Home, or a vendor-named
    -- bundle. Identify the Java home by its executable, not its version name.
    -- Move directory entries rather than copying so symlinks remain intact.
    local script = [[
root=$1
if [ -x "$root/bin/java" ]; then
    exit 0
fi
home=
candidate() {
    if [ -d "$1" ] && [ ! -L "$1" ] && [ -x "$1/bin/java" ]; then
        if [ -n "$home" ] && [ "$home" != "$1" ]; then
            echo "Multiple Java homes found in $root" >&2
            exit 1
        fi
        home=$1
    fi
}
if [ ! -L "$root/Contents" ]; then
    candidate "$root/Contents/Home"
fi
for bundle in "$root"/*; do
    [ -d "$bundle" ] && [ ! -L "$bundle" ] || continue
    candidate "$bundle"
    if [ ! -L "$bundle/Contents" ]; then
        candidate "$bundle/Contents/Home"
    fi
done
if [ -z "$home" ]; then
    echo "No Java home containing bin/java found in $root" >&2
    exit 1
fi
# Check all destinations before moving anything, including hidden entries.
for entry in "$home"/* "$home"/.[!.]* "$home"/..?*; do
    [ -e "$entry" ] || [ -L "$entry" ] || continue
    target="$root/${entry##*/}"
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "Cannot normalize Java home: destination already exists: $target" >&2
        exit 1
    fi
done
for entry in "$home"/* "$home"/.[!.]* "$home"/..?*; do
    [ -e "$entry" ] || [ -L "$entry" ] || continue
    mv "$entry" "$root/" || exit 1
done
]]
    print("Checking Java home layout...")
    if os.execute('sh -c ' .. shellQuote(script) .. ' sh ' .. shellQuote(path)) ~= 0 then
        error('Failed to normalize Java home: ' .. path)
    end
end
