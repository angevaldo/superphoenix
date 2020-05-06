local json = require "json"

local GGData = require "lib.GGData"
local profile = GGData:new("profile")

local strLanguage = profile:get("language")
local TBL_LANGUAGES = {}
TBL_LANGUAGES["pt"] = "pt"
TBL_LANGUAGES["en"] = "en"
TBL_LANGUAGES["es"] = "es"
TBL_LANGUAGES["ja"] = "ja"
TBL_LANGUAGES["zh"] = "zh"
TBL_LANGUAGES["de"] = "de"
TBL_LANGUAGES["ru"] = "ru"
TBL_LANGUAGES["fr"] = "fr"
if strLanguage == nil then
    strLanguage = system.getPreference("locale", "language")
end
if TBL_LANGUAGES[strLanguage] == nil then
    strLanguage = "en"
end

local I18N = {
    resource = "languages/strings",
    language = strLanguage,-- or system.getPreference("locale", "language") or system.getPreference("ui", "language"),
    --country = system.getPreference("locale", "country"),
}

local function loadStrings()
    I18N.files = nil
    I18N.files = {
        --I18N.resource..".txt",
        I18N.resource.."_"..I18N.language..".txt",
        --I18N.resource.."_"..I18N.language.."_"..I18N.country..".txt"
    }

    local strmap = {}
    --local str = ""
    for i = 1, #I18N.files do
        local path = system.pathForFile(I18N.files[i])
        --str = str .. "      ".. (path or "")
        if path then
            local fh = io.open(path, "r")
            if fh then 
                local contents = fh:read("*a")
                
                if contents then
                    local resmap = json.decode(contents)
                    if resmap then
                        strmap = resmap
                    end
                end
            end
            io.close(fh)
        end
    end
    --native.showAlert(I18N.resource.."_"..I18N.language.."_"..I18N.country..".txt", str, {#I18N.files})
    I18N.strings = strmap
end
loadStrings()

local function getString(self, key)
    return self.strings[key] or key
end

local function reloadLanguage(self, strLanguage)
    I18N.language = strLanguage
    loadStrings()
    return self.strings[key] or key
end

I18N.getString = getString
I18N.reloadLanguage = reloadLanguage


return I18N