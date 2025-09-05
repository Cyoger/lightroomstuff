local LrTasks        = import "LrTasks"
local LrExportSession= import "LrExportSession"
local LrApplication  = import "LrApplication"
local LrDialogs      = import "LrDialogs"
local LrFileUtils    = import "LrFileUtils"
local LrPathUtils    = import "LrPathUtils"

local catalog = LrApplication.activeCatalog()

-- CONFIG: where your list lives and where to export
local LIST_PATH      = "C:/Exports/CUBA/file_list.txt"
local DEST_ROOT      = "C:/Exports/CUBA"
local DEST_SUBFOLDER = "FullRes"

-- Read file lines into a Lua table
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

-- Build a filename -> {photos} index (only if we need it)
local function build_filename_index()
    local index = {}
    local all = catalog:getAllPhotos()
    for _, p in ipairs(all) do
        local name = p:getFormattedMetadata("fileName")
        if name then
            index[name:lower()] = index[name:lower()] or {}
            table.insert(index[name:lower()], p)
        end
    end
    return index
end

-- Choose one photo from a list of candidates (simple heuristic)
local function choose_best(candidates)
    -- If multiple candidates share the same file name, just pick the first.
    -- (You can improve this to prefer RAW, by capture time, folder path, etc.)
    return candidates[1]
end

LrTasks.startAsyncTask(function()
    -- Ensure list exists
    if not LrFileUtils.exists(LIST_PATH) then
        LrDialogs.message("List not found", "Expected: " .. LIST_PATH)
        return
    end

    -- Read list of paths (can be exported JPEGs or original paths)
    local lines, err = read_lines(LIST_PATH)
    if not lines then
        LrDialogs.message("Error reading list", err or "")
        return
    end
    if #lines == 0 then
        LrDialogs.message("List is empty", "No paths found in: " .. LIST_PATH)
        return
    end

    local targetPhotos = {}
    local missingByPath = {}
    local foundByPath = 0

    -- 1) Try direct path matches first
    for _, path in ipairs(lines) do
        local p = catalog:findPhotoByPath(path)
        if p then
            table.insert(targetPhotos, p)
            foundByPath = foundByPath + 1
        else
            table.insert(missingByPath, path)
        end
    end

    -- 2) For those not found by full path, try matching by file name
    local matchedByName = 0
    if #missingByPath > 0 then
        local index = build_filename_index()
        for _, path in ipairs(missingByPath) do
            local base = LrPathUtils.leafName(path)
            local lower = base and base:lower() or nil
            if lower and index[lower] and #index[lower] > 0 then
                local chosen = choose_best(index[lower])
                if chosen then
                    table.insert(targetPhotos, chosen)
                    matchedByName = matchedByName + 1
                end
            end
        end
    end

    if #targetPhotos == 0 then
        LrDialogs.message(
            "No matching photos",
            ("List entries: %d\nMatched by full path: %d\nMatched by file name: %d")
                :format(#lines, foundByPath, matchedByName)
        )
        return
    end

    -- Ensure destination exists
    local destRootOk = LrFileUtils.exists(DEST_ROOT)
    if not destRootOk then
        LrFileUtils.createAllDirectories(DEST_ROOT)
    end

    local exportSettings = {
        LR_format = "JPEG",
        LR_jpeg_quality = 1.0,
        LR_export_destinationType = "specificFolder",
        LR_export_destinationPathPrefix = DEST_ROOT,
        LR_useSubfolder = true,
        LR_export_destinationPathSuffix = DEST_SUBFOLDER,

        -- Key bit: no resizing (export at current/original pixel dimensions)
        LR_export_useResize = false,

        -- Other common settings
        LR_export_colorSpace = "sRGB",
        LR_outputSharpeningOn = false,
        LR_removeFaceMetadata = false,
        LR_minimizeEmbeddedMetadata = false,
    }

    local session = LrExportSession {
        photosToExport = targetPhotos,
        exportSettings = exportSettings,
    }

    session:doExportOnCurrentTask()

    LrDialogs.message(
        "Re-export complete",
        ("From list: %d\nMatched by full path: %d\nMatched by file name: %d\nExported to: %s\\%s")
            :format(#lines, foundByPath, matchedByName, DEST_ROOT, DEST_SUBFOLDER)
    )
end)
local LrTasks        = import "LrTasks"
local LrExportSession= import "LrExportSession"
local LrApplication  = import "LrApplication"
local LrDialogs      = import "LrDialogs"
local LrFileUtils    = import "LrFileUtils"
local LrPathUtils    = import "LrPathUtils"

local catalog = LrApplication.activeCatalog()

-- CONFIG: where your list lives and where to export
local LIST_PATH      = "C:/Exports/CUBA/file_list.txt"
local DEST_ROOT      = "C:/Exports/CUBA"
local DEST_SUBFOLDER = "FullRes"

-- Read file lines into a Lua table
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

-- Build a filename -> {photos} index (only if we need it)
local function build_filename_index()
    local index = {}
    local all = catalog:getAllPhotos()
    for _, p in ipairs(all) do
        local name = p:getFormattedMetadata("fileName")
        if name then
            index[name:lower()] = index[name:lower()] or {}
            table.insert(index[name:lower()], p)
        end
    end
    return index
end

-- Choose one photo from a list of candidates (simple heuristic)
local function choose_best(candidates)
    -- If multiple candidates share the same file name, just pick the first.
    -- (You can improve this to prefer RAW, by capture time, folder path, etc.)
    return candidates[1]
end

LrTasks.startAsyncTask(function()
    -- Ensure list exists
    if not LrFileUtils.exists(LIST_PATH) then
        LrDialogs.message("List not found", "Expected: " .. LIST_PATH)
        return
    end

    -- Read list of paths (can be exported JPEGs or original paths)
    local lines, err = read_lines(LIST_PATH)
    if not lines then
        LrDialogs.message("Error reading list", err or "")
        return
    end
    if #lines == 0 then
        LrDialogs.message("List is empty", "No paths found in: " .. LIST_PATH)
        return
    end

    local targetPhotos = {}
    local missingByPath = {}
    local foundByPath = 0

    -- 1) Try direct path matches first
    for _, path in ipairs(lines) do
        local p = catalog:findPhotoByPath(path)
        if p then
            table.insert(targetPhotos, p)
            foundByPath = foundByPath + 1
        else
            table.insert(missingByPath, path)
        end
    end

    -- 2) For those not found by full path, try matching by file name
    local matchedByName = 0
    if #missingByPath > 0 then
        local index = build_filename_index()
        for _, path in ipairs(missingByPath) do
            local base = LrPathUtils.leafName(path)
            local lower = base and base:lower() or nil
            if lower and index[lower] and #index[lower] > 0 then
                local chosen = choose_best(index[lower])
                if chosen then
                    table.insert(targetPhotos, chosen)
                    matchedByName = matchedByName + 1
                end
            end
        end
    end

    if #targetPhotos == 0 then
        LrDialogs.message(
            "No matching photos",
            ("List entries: %d\nMatched by full path: %d\nMatched by file name: %d")
                :format(#lines, foundByPath, matchedByName)
        )
        return
    end

    -- Ensure destination exists
    local destRootOk = LrFileUtils.exists(DEST_ROOT)
    if not destRootOk then
        LrFileUtils.createAllDirectories(DEST_ROOT)
    end

    local exportSettings = {
        LR_format = "JPEG",
        LR_jpeg_quality = 1.0,
        LR_export_destinationType = "specificFolder",
        LR_export_destinationPathPrefix = DEST_ROOT,
        LR_useSubfolder = true,
        LR_export_destinationPathSuffix = DEST_SUBFOLDER,

        -- Key bit: no resizing (export at current/original pixel dimensions)
        LR_export_useResize = false,

        -- Other common settings
        LR_export_colorSpace = "sRGB",
        LR_outputSharpeningOn = false,
        LR_removeFaceMetadata = false,
        LR_minimizeEmbeddedMetadata = false,
    }

    local session = LrExportSession {
        photosToExport = targetPhotos,
        exportSettings = exportSettings,
    }

    session:doExportOnCurrentTask()

    LrDialogs.message(
        "Re-export complete",
        ("From list: %d\nMatched by full path: %d\nMatched by file name: %d\nExported to: %s\\%s")
            :format(#lines, foundByPath, matchedByName, DEST_ROOT, DEST_SUBFOLDER)
    )
end)
