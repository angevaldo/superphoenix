--
-- created with TexturePacker (http://www.codeandweb.com/texturepacker)
--
-- $TexturePacker:SmartUpdate:b62141dd49b11c63e23a97f6c2ec7a5a:066dd27e18384a4f7fbd4da18f5b06f2:d2ec389eb273792b7ed5ffe10dca430f$
--
-- local sheetInfo = require("mysheet")
-- local myImageSheet = graphics.newImageSheet( "mysheet.png", sheetInfo:getSheet() )
-- local sprite = display.newSprite( myImageSheet , {frames={sheetInfo:getFrameIndex("sprite")}} )
--

local SheetInfo = {}

SheetInfo.sheet =
{
    frames = {
    
        {
            -- scnAchievements/0000
            x=0,
            y=206,
            width=44,
            height=48,

            sourceX = 10,
            sourceY = 8,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0001
            x=134,
            y=206,
            width=40,
            height=44,

            sourceX = 12,
            sourceY = 10,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0002
            x=92,
            y=206,
            width=40,
            height=48,

            sourceX = 12,
            sourceY = 10,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0003
            x=126,
            y=0,
            width=52,
            height=48,

            sourceX = 6,
            sourceY = 8,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0004
            x=0,
            y=0,
            width=62,
            height=36,

            sourceX = 0,
            sourceY = 14,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0005
            x=126,
            y=50,
            width=52,
            height=46,

            sourceX = 6,
            sourceY = 10,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0006
            x=46,
            y=206,
            width=44,
            height=48,

            sourceX = 10,
            sourceY = 8,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0007
            x=0,
            y=38,
            width=60,
            height=48,

            sourceX = 2,
            sourceY = 8,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0008
            x=62,
            y=58,
            width=60,
            height=48,

            sourceX = 2,
            sourceY = 8,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0009
            x=0,
            y=88,
            width=60,
            height=48,

            sourceX = 2,
            sourceY = 8,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0010
            x=62,
            y=108,
            width=60,
            height=48,

            sourceX = 2,
            sourceY = 8,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0011
            x=64,
            y=0,
            width=60,
            height=56,

            sourceX = 2,
            sourceY = 4,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0012
            x=124,
            y=152,
            width=48,
            height=52,

            sourceX = 8,
            sourceY = 6,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0013
            x=58,
            y=158,
            width=46,
            height=44,

            sourceX = 8,
            sourceY = 10,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0014
            x=0,
            y=138,
            width=56,
            height=50,

            sourceX = 4,
            sourceY = 8,
            sourceWidth = 64,
            sourceHeight = 64
        },
        {
            -- scnAchievements/0015
            x=124,
            y=98,
            width=54,
            height=52,

            sourceX = 6,
            sourceY = 6,
            sourceWidth = 64,
            sourceHeight = 64
        },
    },
    
    sheetContentWidth = 178,
    sheetContentHeight = 254
}

SheetInfo.frameIndex =
{

    ["scnAchievements/0000"] = 1,
    ["scnAchievements/0001"] = 2,
    ["scnAchievements/0002"] = 3,
    ["scnAchievements/0003"] = 4,
    ["scnAchievements/0004"] = 5,
    ["scnAchievements/0005"] = 6,
    ["scnAchievements/0006"] = 7,
    ["scnAchievements/0007"] = 8,
    ["scnAchievements/0008"] = 9,
    ["scnAchievements/0009"] = 10,
    ["scnAchievements/0010"] = 11,
    ["scnAchievements/0011"] = 12,
    ["scnAchievements/0012"] = 13,
    ["scnAchievements/0013"] = 14,
    ["scnAchievements/0014"] = 15,
    ["scnAchievements/0015"] = 16,
}

function SheetInfo:getSheet()
    return self.sheet;
end

function SheetInfo:getFrameIndex(name)
    return self.frameIndex[name];
end

return SheetInfo
