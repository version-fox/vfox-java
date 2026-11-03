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

--- Reads the checksum of a download from what Foojay says about its package,
--- for vfox to verify the file against. PreInstall hands it over under the name
--- of its algorithm (sha256 = "..."), and vfox compares it with the digest of
--- what it downloaded before it unpacks anything. Without one, vfox prints
--- "WARNING: Checksum is not provided, skip verify...".
---
--- Foojay's record of a package (links.pkg_info_uri) names the algorithm
--- (checksum_type) for the packages it knows a checksum of. It holds the digest
--- itself (checksum) for some, such as Temurin, and for others only the address
--- of a file that does (checksum_uri), such as GraalVM Community's. Those files
--- do not all write a digest the same way, see entries.
local checksum = {}

-- The algorithms vfox verifies, with the length of their digests in
-- hexadecimal digits. Foojay names others too (sha3_256), which vfox ignores.
local LENGTH = {
    md5 = 32,
    sha1 = 40,
    sha256 = 64,
    sha512 = 128,
}

--- Returns value without the blanks around it, or "" if it is no string.
--- @param value any
--- @return string
local function text(value)
    if type(value) ~= "string" then
        return ""
    end
    return (value:match("^%s*(.-)%s*$"))
end

--- Returns the last part of a path written with / or \.
--- @param path string
--- @return string
local function base_name(path)
    return path:match("[^/\\]*$")
end

--- Returns the digests a checksum file holds, each with the name of the file
--- it is for where the line gives one. The files come in three forms:
---   <digest>                      GraalVM Community, Oracle, jdk.java.net, Corretto
---   <digest>  <name>              sha256sum's, also with * before the name:
---                                 Microsoft, JetBrains, Semeru, SAP, OJDKBuild
---   MD5 (<name>) = <digest>       BSD's tools, Tencent Kona
--- A byte order mark and CR LF line ends are left out, as files made on Windows
--- have them. Lines of any other form are skipped.
--- @param content string
--- @return table[] Entries with digest, and name if the line has one
local function entries(content)
    content = content:gsub("^\239\187\191", "")
    local result = {}
    for line in content:gmatch("[^\r\n]+") do
        line = text(line)
        local digest = line:match("^(%x+)$")
        local name
        if not digest then
            digest, name = line:match("^(%x+)%s+%*?(.+)$")
        end
        if not digest then
            name, digest = line:match("^[%w%-]+ %((.+)%) = (%x+)$")
        end
        if digest then
            table.insert(result, { digest = digest, name = name })
        end
    end
    return result
end

--- Returns the digest that a checksum file gives for a file, in lower case, as
--- vfox compares it with the digest it computes: the entry with one of the
--- file's names, else the one digest of a file that names none. Only digests of
--- the algorithm count, so a file that lists a SHA-1 next to a SHA-256 is read.
--- A file that lists other files only, such as the one Microsoft published for
--- the EA build of 11.0.14 for macOS, which names the GA build, or one with
--- several digests and no names, gives none: the digest of another file would
--- fail an install that is fine.
--- Returns nil and why not, as the end of a sentence about the file ("has no
--- digest"), where there is no digest to take.
--- @param content string Contents of the checksum file
--- @param kind string Algorithm of the digest, a key of LENGTH
--- @param names string[]|nil What the downloaded file is called, in a listing
--- @return string|nil
--- @return string|nil
function checksum.parse(content, kind, names)
    local length = LENGTH[kind]
    if not length then
        return nil, "a " .. tostring(kind) .. " digest, which vfox cannot verify"
    end
    local all = entries(content)
    if #all == 0 then
        return nil, "no digest"
    end
    local wanted = {}
    for _, name in ipairs(names or {}) do
        if name ~= "" then
            wanted[base_name(name)] = true
        end
    end
    local matching, bare, listed = {}, {}, 0
    for _, entry in ipairs(all) do
        if #entry.digest == length then
            if not entry.name then
                table.insert(bare, entry)
            else
                listed = listed + 1
                if wanted[base_name(entry.name)] then
                    table.insert(matching, entry)
                end
            end
        end
    end
    if listed + #bare == 0 then
        return nil, ("a digest of %d digits, where %s has %d"):format(#all[1].digest, kind, length)
    end
    local label = (names or {})[1] or "the file"
    local picked = listed == 0 and bare or matching
    if #picked == 0 then
        return nil, "no digest for " .. label
    end
    local digest = picked[1].digest:lower()
    for _, entry in ipairs(picked) do
        if entry.digest:lower() ~= digest then
            if listed == 0 then
                return nil, #picked .. " digests and no names to tell them apart"
            end
            return nil, "different digests for " .. label
        end
    end
    return digest
end

--- Returns what the download of a package is called: the name Foojay gives it,
--- and the last part of its address, which vfox names the file after.
--- @param info table Foojay's record of the package
--- @return string[]
local function names_of(info)
    local names = {}
    local filename = text(info.filename)
    if filename ~= "" then
        table.insert(names, filename)
    end
    local path = text(info.direct_download_uri):match("^[^?#]*")
    local name = base_name(path):gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
    if name ~= "" and name ~= filename then
        table.insert(names, name)
    end
    return names
end

--- Returns the checksum of the package that a Foojay record describes: the
--- algorithm, which is the key vfox takes it under, and the digest. The record's
--- own digest goes first, as it comes from Foojay and not from the vendor's
--- download site, which may be a mirror; the file is fetched only where the
--- record has no digest.
--- Returns nothing where Foojay knows no checksum, and nil and why not where it
--- does but there is no using it: the file cannot be fetched, holds no digest
--- for the package, or the algorithm is one vfox cannot verify. Installing
--- without a checksum is what vfox did before, so none of these stops it.
--- @param info table Foojay's record of the package
--- @param fetch fun(uri: string): string|nil, string|nil Returns the contents of the file at the address, or nil and why not
--- @return table|nil Checksum with the type of its algorithm and its digest
--- @return string|nil Why the package's checksum cannot be used
function checksum.lookup(info, fetch)
    local kind = text(info.checksum_type):lower()
    if kind == "" or kind == "none" then
        return nil
    end
    if not LENGTH[kind] then
        return nil, "vfox cannot verify a " .. kind .. " checksum"
    end
    local names = names_of(info)
    local reason
    local inline = text(info.checksum)
    if inline ~= "" then
        local digest, why = checksum.parse(inline, kind, names)
        if digest then
            return { type = kind, digest = digest }
        end
        reason = "the checksum in Foojay's record has " .. why
    end
    local uri = text(info.checksum_uri)
    if uri == "" then
        return nil, reason
    end
    local body, err = fetch(uri)
    if not body then
        return nil, "failed to fetch " .. uri .. ": " .. tostring(err)
    end
    local digest, why = checksum.parse(body, kind, names)
    if not digest then
        return nil, uri .. " has " .. why
    end
    return { type = kind, digest = digest }
end

return checksum
