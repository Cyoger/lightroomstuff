return {
    LrSdkVersion = 12.0,
    LrPluginName = "Re-Export Full Resolution (Auto from List)",
    LrToolkitIdentifier = "com.yourname.reexportfullres.autolist",

    -- This creates a menu item under File → Plug-in Extras
    LrExportMenuItems = {
        {
            title = "Re-Export (Full Res) from file_list.txt",
            file  = "ReExport.lua",
        },
    },

    VERSION = { major = 1, minor = 0 },
}
