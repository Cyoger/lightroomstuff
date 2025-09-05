local LrTasks         = import "LrTasks"
local LrExportSession = import "LrExportSession"
local LrApplication   = import "LrApplication"
local LrDialogs       = import "LrDialogs"
local LrFileUtils     = import "LrFileUtils"
local LrPathUtils     = import "LrPathUtils"

local catalog = LrApplication.activeCatalog()

-- CONFIG
local LIST_PATH      = "C:/Exports/CUBA/file_list.txt"
local DEST_ROOT      = "C:/Exports/CUBA"
local DEST_SUBFOLDER = "FullRes"

-- Normalize a leaf filename to "stem" (no extension, lowercased, trimmed)
local function stem_of(name)
    if not name or #name == 0 then return nil end
    name = name:match("^%s*(.-)%s*$")           -- trim
    -- If your exports add suffixes, uncomment to normalize some common ones:
    -- name = name:gsub("%-Edit$", ""):gsub("%s+copy$", ""):gsub("%s*%(%d+%)$", "")
    local dot = name:match("()%.%w+$")          -- position of dot before extension
    local stem = dot and name:sub(1, dot-1) or name
    return stem:lower()
end

-- Read file lines
local function read_lines(path)
    local t = {}
    local f = io.open(path, "r")
    if not f then return nil, "Cannot open: " .. path end
    for line in f:lines() do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if #line > 0 then table.insert(t, line) end
    end
    f:close()
    return t
end

-- Build stem -> {photos} index from the whole catalog
local function build_stem_index()
    local index = {}
    local all = catalog:getAllPhotos()
    for _, p in ipairs(all) do
        local name = p:getFormattedMetadata("fileName")
        if name then
            local key = stem_of(name)
            if key and #key > 0 then
                index[key] = index[key] or {}
                table.insert(index[key], p)
            end
        end
    end
    return index
end

-- Prefer RAW over JPEG if multiple candidates share the same stem
local function choose_best(candidates)
    if #candidates == 1 then return candidates[1] end
    local raw_exts = { arw=true, cr2=true, cr3=true, nef=true, raf=true, orf=true, rw2=true, dng=true }
    local best_raw = nil
    for _, p in ipairs(candidates) do
        local name = p:getFormattedMetadata("fileName") or ""
        local ext = name:match("%.([%w]+)$")
        if ext and raw_exts[string.lower(ext)] then
            best_raw = best_raw or p
        end
    end
    return best_raw or candidates[1]
end

LrTasks.startAsyncTask(function()
    -- Ensure list exists
    if not LrFileUtils.exists(LIST_PATH) then
        LrDialogs.message("List not found", "Expected: " .. LIST_PATH)
        return
    end

    -- Read list of paths (likely JPG exports)
    local lines, err = read_lines(LIST_PATH)
    if not lines then
        LrDialogs.message("Error reading list", err or "")
        return
    end
    if #lines == 0 then
        LrDialogs.message("List is empty", "No paths found in: " .. LIST_PATH)
        return
    end

    -- Build index once
    local index = build_stem_index()

    -- Match by stem only (so .jpg will match .arw)
    local targetPhotos = {}
    local matchedByName = 0
    for _, path in ipairs(lines) do
        local leaf = LrPathUtils.leafName(path)
        local stem = stem_of(leaf)
        local candidates = (stem and index[stem]) or nil
        if candidates and #candidates > 0 then
            local chosen = choose_best(candidates)
            if chosen then
                table.insert(targetPhotos, chosen)
                matchedByName = matchedByName + 1
            end -- <-- fixed: was '}' before
        end
    end

    if #targetPhotos == 0 then
        LrDialogs.message(
            "No matching photos",
            string.format("List entries: %d\nMatched by file name (stem): %d", #lines, matchedByName)
        )
        return
    end

    -- Ensure destination exists
    if not LrFileUtils.exists(DEST_ROOT) then
        LrFileUtils.createAllDirectories(DEST_ROOT)
    end

    local exportSettings = {
        LR_format = "JPEG",
        LR_jpeg_quality = 1.0,

        LR_export_destinationType       = "specificFolder",
        LR_export_destinationPathPrefix = DEST_ROOT,
        LR_useSubfolder                 = true,
        LR_export_destinationPathSuffix = DEST_SUBFOLDER,

        -- Key: no resize → export at original/current pixel dimensions
        LR_export_useResize = false,

        LR_export_colorSpace     = "sRGB",
        LR_outputSharpeningOn    = false,
        LR_removeFaceMetadata    = false,
        LR_minimizeEmbeddedMetadata = false,
    }

    local session = LrExportSession {
        photosToExport = targetPhotos,
        exportSettings = exportSettings,
    }

    session:doExportOnCurrentTask()

    LrDialogs.message(
        "Re-export complete",
        string.format("From list: %d\nMatched by stem: %d\nExported to: %s\\%s",
                      #lines, matchedByName, DEST_ROOT, DEST_SUBFOLDER)
    )
end)
