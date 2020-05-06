--
-- created with TexturePacker (http://www.codeandweb.com/texturepacker)
--
-- $TexturePacker:SmartUpdate:bfe022c99b73ebb3370b7a0437a8afe2:3d55214802f0f8ddd2534d643f62c695:0594592fa11f9be209c74a21a37345b6$
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
            -- bkgScenario0
            x=0,
            y=0,
            width=960,
            height=640,

        },
        {
            -- bkgScenario1.fw
            x=962,
            y=0,
            width=960,
            height=640,

        },
    },
    
    sheetContentWidth = 1922,
    sheetContentHeight = 640
}

SheetInfo.frameIndex =
{

    ["bkgScenario0"] = 1,
    ["bkgScenario1.fw"] = 2,
}

function SheetInfo:getSheet()
    return self.sheet;
end

function SheetInfo:getFrameIndex(name)
    return self.frameIndex[name];
end

return SheetInfo
