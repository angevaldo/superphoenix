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
            y=103,
            width=22,
            height=24,

            sourceX = 5,
            sourceY = 4,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0001
            x=67,
            y=103,
            width=20,
            height=22,

            sourceX = 6,
            sourceY = 5,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0002
            x=46,
            y=103,
            width=20,
            height=24,

            sourceX = 6,
            sourceY = 5,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0003
            x=63,
            y=0,
            width=26,
            height=24,

            sourceX = 3,
            sourceY = 4,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0004
            x=0,
            y=0,
            width=31,
            height=18,

            sourceX = 0,
            sourceY = 7,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0005
            x=63,
            y=25,
            width=26,
            height=23,

            sourceX = 3,
            sourceY = 5,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0006
            x=23,
            y=103,
            width=22,
            height=24,

            sourceX = 5,
            sourceY = 4,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0007
            x=0,
            y=19,
            width=30,
            height=24,

            sourceX = 1,
            sourceY = 4,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0008
            x=31,
            y=29,
            width=30,
            height=24,

            sourceX = 1,
            sourceY = 4,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0009
            x=0,
            y=44,
            width=30,
            height=24,

            sourceX = 1,
            sourceY = 4,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0010
            x=31,
            y=54,
            width=30,
            height=24,

            sourceX = 1,
            sourceY = 4,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0011
            x=32,
            y=0,
            width=30,
            height=28,

            sourceX = 1,
            sourceY = 2,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0012
            x=62,
            y=76,
            width=24,
            height=26,

            sourceX = 4,
            sourceY = 3,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0013
            x=29,
            y=79,
            width=23,
            height=22,

            sourceX = 4,
            sourceY = 5,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0014
            x=0,
            y=69,
            width=28,
            height=25,

            sourceX = 2,
            sourceY = 4,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- scnAchievements/0015
            x=62,
            y=49,
            width=27,
            height=26,

            sourceX = 3,
            sourceY = 3,
            sourceWidth = 32,
            sourceHeight = 32
        },
    },
    
    sheetContentWidth = 89,
    sheetContentHeight = 127
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
