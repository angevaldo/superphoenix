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
            y=412,
            width=88,
            height=96,

            sourceX = 20,
            sourceY = 16,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0001
            x=268,
            y=412,
            width=80,
            height=88,

            sourceX = 24,
            sourceY = 20,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0002
            x=184,
            y=412,
            width=80,
            height=96,

            sourceX = 24,
            sourceY = 20,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0003
            x=252,
            y=0,
            width=104,
            height=96,

            sourceX = 12,
            sourceY = 16,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0004
            x=0,
            y=0,
            width=124,
            height=72,

            sourceX = 0,
            sourceY = 28,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0005
            x=252,
            y=100,
            width=104,
            height=92,

            sourceX = 12,
            sourceY = 20,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0006
            x=92,
            y=412,
            width=88,
            height=96,

            sourceX = 20,
            sourceY = 16,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0007
            x=0,
            y=76,
            width=120,
            height=96,

            sourceX = 4,
            sourceY = 16,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0008
            x=124,
            y=116,
            width=120,
            height=96,

            sourceX = 4,
            sourceY = 16,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0009
            x=0,
            y=176,
            width=120,
            height=96,

            sourceX = 4,
            sourceY = 16,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0010
            x=124,
            y=216,
            width=120,
            height=96,

            sourceX = 4,
            sourceY = 16,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0011
            x=128,
            y=0,
            width=120,
            height=112,

            sourceX = 4,
            sourceY = 8,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0012
            x=248,
            y=304,
            width=96,
            height=104,

            sourceX = 16,
            sourceY = 12,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0013
            x=116,
            y=316,
            width=92,
            height=88,

            sourceX = 16,
            sourceY = 20,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0014
            x=0,
            y=276,
            width=112,
            height=100,

            sourceX = 8,
            sourceY = 16,
            sourceWidth = 128,
            sourceHeight = 128
        },
        {
            -- scnAchievements/0015
            x=248,
            y=196,
            width=108,
            height=104,

            sourceX = 12,
            sourceY = 12,
            sourceWidth = 128,
            sourceHeight = 128
        },
    },
    
    sheetContentWidth = 356,
    sheetContentHeight = 508
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
