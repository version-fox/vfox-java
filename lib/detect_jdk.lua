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

--- Finds JDKs that are already on the machine, for `vfox link --detect`.
--- Each result names the version the way `vfox install` names it,
--- `<runtime>-<short name>` from the `release` file, with `-fx` for JavaFX
--- builds and no suffix for OpenJDK.
local detect = {}

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function lower(value)
    return (value or ""):lower()
end

--- Returns the separator for the current platform: `\` on Windows, `/` elsewhere.
local function sep()
    if RUNTIME and RUNTIME.osType == "windows" then
        return "\\"
    end
    return "/"
end

--- Joins two path segments with the platform separator.
function detect.join(left, right)
    local s = sep()
    if left:sub(-1) == "/" or left:sub(-1) == "\\" then
        return left .. right
    end
    return left .. s .. right
end

--- Returns the user's home directory, or "".
local function home_dir()
    return os.getenv("HOME") or os.getenv("USERPROFILE") or ""
end

local function shell_quote(value)
    if RUNTIME and RUNTIME.osType == "windows" then
        return '"' .. value:gsub('"', '""') .. '"'
    end
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

--- Lists the immediate children of dir as full paths, or {}.
--- On Unix `ls` lists files too; callers keep the ones that look like JDKs.
function detect.list_children(dir)
    if dir == "" then
        return {}
    end
    local cmd
    if RUNTIME and RUNTIME.osType == "windows" then
        cmd = "dir /b /ad " .. shell_quote(dir) .. " 2>nul"
    else
        cmd = "ls -1 " .. shell_quote(dir) .. " 2>/dev/null"
    end
    local handle = io.popen(cmd, "r")
    if not handle then
        return {}
    end
    local result = {}
    for line in handle:lines() do
        line = trim(line)
        if line ~= "" and line ~= "." and line ~= ".." then
            table.insert(result, detect.join(dir, line))
        end
    end
    handle:close()
    return result
end

--- Reads the whole file, or nil.
local function read_file(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

--- Parses a `release` file into a table of KEY -> value.
function detect.parse_release(text)
    local fields = {}
    if type(text) ~= "string" then
        return fields
    end
    for line in text:gmatch("[^\r\n]+") do
        local key, value = line:match('^([A-Z_]+)=%s*"([^"]*)"%s*$')
        if not key then
            key, value = line:match("^([A-Z_]+)=%s*(.-)%s*$")
        end
        if key and value then
            fields[key] = value
        end
    end
    return fields
end

--- Extracts the leading `release+build` from a JAVA_RUNTIME_VERSION, such as
--- `21.0.8+9` from `21.0.8+9-LTS`, `22.0.2+9` from `22.0.2+9-70`,
--- `17.0.11+1` from `17.0.11+1-b1207.24` and `17.0.21.0.3+1` from Ubuntu's
--- `17.0.21.0.3+1-1-26.04.1-Ubuntu`. Early-access `28-ea+19` keeps its `-ea`.
--- Java 8 `1.8.0_422-b05` becomes `8.0.422+5`. Returns nil where there is none.
function detect.clean_runtime(value)
    if type(value) ~= "string" then
        return nil
    end
    value = trim(value)
    local runtime = value:match("^(%d+%-ea%+%d+)")
    if runtime then
        return runtime
    end
    runtime = value:match("^(%d[%d%.]*%+%d+)")
    if runtime then
        return runtime
    end
    local major, update, build = value:match("^1%.(%d+)%.0_(%d+).-b0*(%d+)")
    if major and update then
        return major .. ".0." .. update .. "+" .. build
    end
    local legacy_update = value:match("^1%.%d+%.0_(%d+)")
    if legacy_update then
        local java8 = value:match("^1%.(%d+)")
        return java8 .. ".0." .. legacy_update
    end
    return nil
end

--- Converts a legacy Java 8 JAVA_VERSION such as `1.8.0_422` to `8.0.422`.
local function java8_release(java_version)
    local major, update = java_version:match("^1%.(%d+)%.0_(%d+)")
    if major and update then
        return major .. ".0." .. update
    end
    return nil
end

--- Returns the version without the vendor suffix: GRAALVM_VERSION for the
--- GraalVM family that carries it, else the runtime version of the release
--- file, else the Java version. Returns nil where there is none.
function detect.version_base(fields)
    if type(fields) ~= "table" then
        return nil
    end
    local graalvm = fields["GRAALVM_VERSION"]
    if graalvm and trim(graalvm) ~= "" then
        local implementor = lower(fields["IMPLEMENTOR"])
        -- Mandrel's release file is the Temurin JDK it was built from, with
        -- no GRAALVM_VERSION of its own, so it never reaches here; it maps
        -- to tem below. Liberica NIK without its own GRAALVM_VERSION maps
        -- to librca the same way. Both stay usable JDKs under those names.
        if implementor:find("graalvm community", 1, true) or implementor:find("oracle", 1, true) then
            return trim(graalvm)
        end
        -- Any other vendor that carries a GraalVM version (Liberica NIK,
        -- Mandrel with one, Gluon) goes by it too; version_for maps the
        -- vendor from IMPLEMENTOR below.
        if
            implementor:find("bellsoft", 1, true)
            or implementor:find("red hat", 1, true)
            or implementor:find("gluon", 1, true)
        then
            return trim(graalvm)
        end
    end
    local semantic = fields["SEMANTIC_VERSION"]
    if semantic and trim(semantic) ~= "" then
        -- Temurin carries SEMANTIC_VERSION, which matches Foojay's
        -- java_version exactly (`21.0.8+9`). Others leave it out.
        return trim(semantic)
    end
    local runtime = detect.clean_runtime(fields["JAVA_RUNTIME_VERSION"] or "")
    if runtime then
        return runtime
    end
    local java_version = trim(fields["JAVA_VERSION"] or "")
    if java_version ~= "" then
        return java8_release(java_version) or java_version
    end
    return nil
end

--- Whether the JDK bundles JavaFX: its MODULES mention javafx, or its files
--- do. The release file alone tells FX from plain for Zulu and Liberica, and
--- the file check covers vendors whose release file does not.
function detect.is_fx(fields, home)
    local modules = fields["MODULES"] or ""
    if modules:find("javafx%.", 1) or modules:find("javafx", 1, true) then
        return true
    end
    if type(home) == "string" and home ~= "" then
        for _, relative in ipairs({
            "lib/javafx.base.jar",
            "jmods/javafx.base.jmod",
        }) do
            local file = io.open(detect.join(home, relative), "r")
            if file then
                file:close()
                return true
            end
        end
    end
    return false
end

--- Maps the release file to the plugin's short name, or nil for OpenJDK,
--- which carries no suffix. Unknown vendors map to nil as well, so the
--- version stays usable instead of carrying a made-up suffix.
function detect.vendor_short(fields, home)
    if type(fields) ~= "table" then
        return nil
    end
    local implementor = lower(fields["IMPLEMENTOR"] or "")
    local implementor_version = lower(fields["IMPLEMENTOR_VERSION"] or "")
    local jvm_variant = lower(fields["JVM_VARIANT"] or "")
    local graalvm = trim(fields["GRAALVM_VERSION"] or "")
    local has_graalvm = graalvm ~= ""
    local path = lower(home or "")

    if has_graalvm then
        if implementor:find("graalvm community", 1, true) then
            -- GraalVM Community Edition up to 22.3 is one distribution per
            -- JDK (grl8, grl11, ...); 25 and on is graalce. The JDK major
            -- tells them apart.
            local java_major = (fields["JAVA_VERSION"] or ""):match("^(%d+)")
            if java_major == "8" then
                return "grl8"
            elseif java_major == "11" then
                return "grl11"
            elseif java_major == "16" then
                return "grl16"
            elseif java_major == "17" then
                return "grl17"
            elseif java_major == "19" then
                return "grl19"
            end
            return "graalce"
        end
        if implementor:find("oracle", 1, true) then
            return "graal"
        end
        if implementor:find("bellsoft", 1, true) then
            return "nik"
        end
        if implementor:find("red hat", 1, true) then
            return "mandrel"
        end
        if implementor:find("gluon", 1, true) then
            return "gln"
        end
    end

    if implementor:find("eclipse adoptium", 1, true) then
        return "tem"
    end
    if implementor:find("azul", 1, true) then
        return "zulu"
    end
    if implementor:find("bellsoft", 1, true) then
        return "librca"
    end
    if implementor:find("amazon", 1, true) then
        return "amzn"
    end
    if implementor:find("microsoft", 1, true) then
        return "ms"
    end
    if implementor:find("sap", 1, true) then
        return "sapmchn"
    end
    if implementor:find("tencent", 1, true) or implementor_version:find("konajdk", 1, true) then
        return "kona"
    end
    if implementor:find("alibaba", 1, true) or implementor:find("dragonwell", 1, true) then
        return "albba"
    end
    if implementor:find("huawei", 1, true) or implementor:find("bisheng", 1, true) then
        return "bsg"
    end
    if implementor:find("jetbrains", 1, true) then
        return "jb"
    end
    if implementor:find("trava", 1, true) then
        return "trava"
    end
    if implementor:find("adoptopenjdk", 1, true) then
        if jvm_variant:find("openj9", 1, true) then
            return "adptj9"
        end
        return "adpt"
    end
    if implementor:find("openlogic", 1, true) then
        return "opnlgc"
    end
    if implementor:find("ojdkbuild", 1, true) then
        return "ojdkbld"
    end
    if implementor:find("red hat", 1, true) then
        return "rdht"
    end
    if implementor:find("ibm", 1, true) then
        if implementor_version:find("certified", 1, true) or path:find("certified", 1, true) then
            return "semcrt"
        end
        return "sem"
    end
    if implementor:find("eliya", 1, true) or implementor:find("asymm", 1, true) then
        return "eliya"
    end
    if implementor:find("gluon", 1, true) then
        return "gln"
    end
    if implementor:find("oracle", 1, true) then
        -- Oracle Corporation is both OpenJDK from jdk.java.net (no suffix)
        -- and Oracle JDK (-oracle). The directory name tells them apart
        -- where it names Oracle; otherwise this stays OpenJDK, the default
        -- distribution, so the version keeps working.
        if path:find("oracle", 1, true) or implementor_version:find("oracle", 1, true) then
            return "oracle"
        end
        return nil
    end
    -- System OpenJDKs (Debian, Ubuntu, Fedora) and jdk.java.net builds with
    -- IMPLEMENTOR "N/A" carry no vendor suffix, like open.
    return nil
end

--- Names the version the way `vfox install` names it: the runtime version,
--- GraalVM's own version for that family, then -<short name>, then -fx for
--- JavaFX builds. Returns nil where the release file names no version.
function detect.version_for(fields, home)
    local base = detect.version_base(fields)
    if not base or base == "" then
        return nil
    end
    local short = detect.vendor_short(fields, home)
    local version = base
    if short and short ~= "" and short ~= "open" then
        version = version .. "-" .. short
    end
    if detect.is_fx(fields, home) then
        version = version .. "-fx"
    end
    -- vfox refuses `latest` and names with anything else. A base that is
    -- exactly that (a hand-written release file) gets a suffix instead of
    -- being dropped.
    if version == "latest" then
        return nil
    end
    return version
end

--- Returns the JDK home under dir, or nil. dir itself may be the home
--- (release at its top), a macOS bundle (Contents/Home), or a Homebrew keg
--- (libexec/openjdk.jdk/Contents/Home).
local function jdk_home(dir)
    if read_file(detect.join(dir, "release")) then
        return dir
    end
    local bundle = detect.join(dir, "Contents/Home")
    if read_file(detect.join(bundle, "release")) then
        return bundle
    end
    local brew = detect.join(detect.join(dir, "libexec/openjdk.jdk"), "Contents/Home")
    if read_file(detect.join(brew, "release")) then
        return brew
    end
    return nil
end

--- Candidate roots whose immediate children may be JDK homes: {path, note}.
--- Roots with deep=true hold JDKs two levels down (CI tool cache,
--- Scoop apps), so they are scanned one level deeper.
function detect.candidate_roots()
    local roots = {}
    local function add(path, note, deep)
        if type(path) == "string" and path ~= "" then
            table.insert(roots, { path = path, note = note, deep = deep })
        end
    end

    local home = home_dir()
    local gradle_home = os.getenv("GRADLE_USER_HOME")
    local s = sep()
    local function child(base, ...)
        if base == "" then
            return ""
        end
        local parts = { ... }
        local result = base
        for _, part in ipairs(parts) do
            result = detect.join(result, part)
        end
        return result
    end

    if RUNTIME and RUNTIME.osType == "windows" then
        local userprofile = os.getenv("USERPROFILE") or home
        local programfiles = os.getenv("ProgramFiles") or ("C:" .. s .. "Program Files")
        local programfiles_x86 = os.getenv("ProgramFiles(x86)")
        local gradle_jdks = (gradle_home and gradle_home ~= "" and child(gradle_home, "jdks"))
            or child(userprofile, ".gradle", "jdks")
        add(gradle_jdks, "provisioned by Gradle")
        add(child(userprofile, ".jdks"), "downloaded by IntelliJ IDEA")
        add(child(userprofile, ".sdkman", "candidates", "java"), "installed by SDKMAN")
        -- mise manages JDKs on Windows the same way it does elsewhere;
        -- asdf has no native Windows port but its WSL homes are still
        -- worth a look, as are jabba's.
        add(child(userprofile, ".asdf", "installs", "java"), "installed by asdf")
        add(child(userprofile, ".local", "share", "mise", "installs", "java"), "installed by mise")
        add(child(userprofile, ".jabba", "jdk"), "installed by jabba")
        -- Scoop keeps one directory per app with the builds beneath it
        -- (`temurin-lts-jdk/current`), so it needs the deeper scan.
        add(child(userprofile, "scoop", "apps"), "installed by Scoop", true)
        -- winget, Chocolatey and the vendor installers all land in
        -- Program Files, so one set of roots covers them:
        -- `winget install EclipseAdoptium.Temurin.21.JDK` ends up under
        -- `Eclipse Adoptium`, `Microsoft.OpenJDK.21` under `Microsoft`, etc.
        add(child(programfiles, "Java"), "system JDK")
        add(child(programfiles, "Eclipse Adoptium"), "system JDK")
        add(child(programfiles, "Microsoft"), "system JDK")
        add(child(programfiles, "Amazon Corretto"), "system JDK")
        add(child(programfiles, "Zulu"), "system JDK")
        add(child(programfiles, "BellSoft"), "system JDK")
        add(child(programfiles, "OpenJDK"), "system JDK")
        add(child(programfiles, "GraalVM"), "system JDK")
        add(child(programfiles, "SapMachine"), "system JDK")
        add(child(programfiles, "JetBrains"), "system JDK")
        add(child(programfiles, "Oracle"), "system JDK")
        if programfiles_x86 and programfiles_x86 ~= "" then
            add(child(programfiles_x86, "Java"), "system JDK")
        end
        local java_home = os.getenv("JAVA_HOME")
        if java_home and java_home ~= "" then
            add(java_home, "pointed to by JAVA_HOME")
        end
        return roots
    end

    local gradle_jdks = (gradle_home and gradle_home ~= "" and child(gradle_home, "jdks"))
        or child(home, ".gradle", "jdks")
    add(gradle_jdks, "provisioned by Gradle")
    add(child(home, ".sdkman", "candidates", "java"), "installed by SDKMAN")
    -- asdf, mise and jabba hold JDKs the same way SDKMAN does; finding them
    -- lets `vfox link --detect` adopt them instead of downloading a copy.
    -- nvm manages Node.js only, so there is nothing Java-related to find
    -- in it.
    add(child(home, ".asdf", "installs", "java"), "installed by asdf")
    add(child(home, ".local", "share", "mise", "installs", "java"), "installed by mise")
    add(child(home, ".jabba", "jdk"), "installed by jabba")

    if RUNTIME and RUNTIME.osType == "darwin" then
        add(child(home, "Library", "Java", "JavaVirtualMachines"), "downloaded by IntelliJ IDEA")
        add(child(home, ".jdks"), "downloaded by IntelliJ IDEA")
        add("/Library/Java/JavaVirtualMachines", "system JDK")
        add("/opt/homebrew/opt", "installed by Homebrew")
        add("/usr/local/opt", "installed by Homebrew")
        -- Linuxbrew on an Intel Mac installs beside Homebrew.
        add("/home/linuxbrew/.linuxbrew/opt", "installed by Homebrew")
        add(child(home, ".linuxbrew", "opt"), "installed by Homebrew")
        add("/opt", "system JDK")
    else
        add(child(home, ".jdks"), "downloaded by IntelliJ IDEA")
        add("/usr/lib/jvm", "system JDK")
        add("/opt", "system JDK")
        add("/usr/java", "system JDK")
        add("/usr/local", "system JDK")
        -- Homebrew on Linux installs beside the system directories.
        add("/home/linuxbrew/.linuxbrew/opt", "installed by Homebrew")
        add(child(home, ".linuxbrew", "opt"), "installed by Homebrew")
        add("/opt/hostedtoolcache", "CI runner tool cache", true)
    end

    local java_home = os.getenv("JAVA_HOME")
    if java_home and java_home ~= "" then
        add(java_home, "pointed to by JAVA_HOME")
    end
    return roots
end

--- Finds the JDKs under one candidate root.
local function find_in_root(root, note, seen_paths, out)
    -- The root itself may be a JDK home (JAVA_HOME, /opt/java).
    local home = jdk_home(root)
    if home then
        if not seen_paths[home] then
            seen_paths[home] = true
            local text = read_file(detect.join(home, "release"))
            local fields = detect.parse_release(text or "")
            local version = detect.version_for(fields, home)
            if version then
                table.insert(out, { version = version, path = home, note = note })
            end
        end
        return
    end
    for _, dir in ipairs(detect.list_children(root)) do
        local candidate = jdk_home(dir)
        if candidate and not seen_paths[candidate] then
            seen_paths[candidate] = true
            local text = read_file(detect.join(candidate, "release"))
            local fields = detect.parse_release(text or "")
            local version = detect.version_for(fields, candidate)
            if version then
                table.insert(out, { version = version, path = candidate, note = note })
            end
        end
    end
end

--- Finds JDKs nested two levels down: the CI runner tool cache
--- (`Java_Temurin-Hotspot_jdk/21.0.8-9/x64`) and Scoop apps
--- (`temurin-lts-jdk/current`).
local function find_deep(root, note, seen_paths, out)
    for _, vendor_dir in ipairs(detect.list_children(root)) do
        for _, version_dir in ipairs(detect.list_children(vendor_dir)) do
            local home = jdk_home(version_dir)
            if home and not seen_paths[home] then
                seen_paths[home] = true
                local text = read_file(detect.join(home, "release"))
                local fields = detect.parse_release(text or "")
                local version = detect.version_for(fields, home)
                if version then
                    table.insert(out, { version = version, path = home, note = note })
                end
            end
            for _, arch_dir in ipairs(detect.list_children(version_dir)) do
                local nested = jdk_home(arch_dir)
                if nested and not seen_paths[nested] then
                    seen_paths[nested] = true
                    local text = read_file(detect.join(nested, "release"))
                    local fields = detect.parse_release(text or "")
                    local version = detect.version_for(fields, nested)
                    if version then
                        table.insert(out, { version = version, path = nested, note = note })
                    end
                end
            end
        end
    end
end

--- Returns true for paths vfox itself manages, which must never be detected:
--- anything under a `.vfox` directory.
local function is_vfox_managed(path)
    local p = lower(path or "")
    return p:find("/.vfox/", 1, true) ~= nil or p:find("\\.vfox\\", 1, true) ~= nil
end

--- Finds every JDK on the machine. Results are sorted by version then path
--- so `vfox link --detect` offers them deterministically.
function detect.find_all()
    local out = {}
    local seen_paths = {}
    for _, root in ipairs(detect.candidate_roots()) do
        if not is_vfox_managed(root.path) then
            if root.deep then
                find_deep(root.path, root.note, seen_paths, out)
            else
                find_in_root(root.path, root.note, seen_paths, out)
            end
        end
    end
    -- Drop vfox-managed homes that slipped in through JAVA_HOME, and
    -- duplicates of one directory reached through several roots.
    local filtered = {}
    local seen_versions = {}
    for _, item in ipairs(out) do
        if not is_vfox_managed(item.path) then
            table.insert(filtered, item)
        end
    end
    table.sort(filtered, function(a, b)
        if a.version ~= b.version then
            return a.version < b.version
        end
        return a.path < b.path
    end)
    -- One entry per version: vfox links the first it sees and skips the rest
    -- as installed or linked, so keep the first path of each version.
    local result = {}
    for _, item in ipairs(filtered) do
        if not seen_versions[item.version] then
            seen_versions[item.version] = true
            table.insert(result, item)
        end
    end
    return result
end

return detect
