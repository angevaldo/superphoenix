--
-- created with TexturePacker (http://www.codeandweb.com/texturepacker)
--
-- $TexturePacker:SmartUpdate:f882ab59d50c2f5dda6c95135b37dcf2:71ef373f94a4c4f58d1e7dff249d4e44:77a1fd9669835224c1364a4f0cd9b0a0$
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
            -- bkgSceneario1 (4)
            x=0,
            y=0,
            width=960,
            height=640,

        },
        {
            -- bkgSceneario2 (2)
            x=962,
            y=0,
            width=960,
            height=640,

        },
        {
            -- bkgSceneario3 (2)
            x=0,
            y=642,
            width=960,
            height=640,

        },
        {
            -- bkgSceneario4 (1)
            x=962,
            y=642,
            width=960,
            height=640,

        },
        {
            -- bkgSceneario5 (1)
            x=0,
            y=1284,
            width=960,
            height=640,

        },
    },
    
    sheetContentWidth = 1922,
    sheetContentHeight = 1924
}

SheetInfo.frameIndex =
{

    ["bkgSceneario1 (4)"] = 1,
    ["bkgSceneario2 (2)"] = 2,
    ["bkgSceneario3 (2)"] = 3,
    ["bkgSceneario4 (1)"] = 4,
    ["bkgSceneario5 (1)"] = 5,
}

function SheetInfo:getSheet()
    return self.sheet;
end

function SheetInfo:getFrameIndex(name)
    return self.frameIndex[name];
end

return SheetInfo
