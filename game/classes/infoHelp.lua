--
-- created with TexturePacker (http://www.codeandweb.com/texturepacker)
--
-- $TexturePacker:SmartUpdate:8eab4a42310a0795414ef845e544430d:19667fb2a5bd1744c3f9efcfa522d98c:0539fa126f182b9579c53a9204743a20$
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
            -- 01_help/0000
            x=219,
            y=0,
            width=149,
            height=130,

            sourceX = 217,
            sourceY = 118,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0001
            x=411,
            y=100,
            width=226,
            height=90,

            sourceX = 132,
            sourceY = 135,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0002
            x=369,
            y=0,
            width=164,
            height=99,

            sourceX = 144,
            sourceY = 122,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0003
            x=707,
            y=87,
            width=178,
            height=81,

            sourceX = 91,
            sourceY = 131,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0004
            x=223,
            y=131,
            width=187,
            height=105,

            sourceX = 91,
            sourceY = 122,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0005
            x=0,
            y=141,
            width=222,
            height=118,

            sourceX = 91,
            sourceY = 114,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0006
            x=534,
            y=0,
            width=241,
            height=86,

            sourceX = 91,
            sourceY = 126,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0007
            x=0,
            y=0,
            width=218,
            height=140,

            sourceX = 91,
            sourceY = 87,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0008
            x=776,
            y=0,
            width=171,
            height=81,

            sourceX = 217,
            sourceY = 130,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0009
            x=651,
            y=174,
            width=131,
            height=85,

            sourceX = 193,
            sourceY = 141,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0010
            x=579,
            y=191,
            width=71,
            height=62,

            sourceX = 199,
            sourceY = 122,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0011
            x=638,
            y=87,
            width=68,
            height=86,

            sourceX = 207,
            sourceY = 111,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0012
            x=886,
            y=82,
            width=52,
            height=54,

            sourceX = 214,
            sourceY = 133,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0013
            x=411,
            y=191,
            width=95,
            height=73,

            sourceX = 191,
            sourceY = 125,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0014
            x=783,
            y=169,
            width=77,
            height=78,

            sourceX = 209,
            sourceY = 131,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0015
            x=929,
            y=140,
            width=82,
            height=55,

            sourceX = 198,
            sourceY = 129,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0016
            x=929,
            y=196,
            width=77,
            height=55,

            sourceX = 203,
            sourceY = 129,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0017
            x=861,
            y=169,
            width=67,
            height=74,

            sourceX = 207,
            sourceY = 124,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0018
            x=507,
            y=191,
            width=71,
            height=64,

            sourceX = 204,
            sourceY = 128,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0019
            x=948,
            y=0,
            width=66,
            height=76,

            sourceX = 205,
            sourceY = 122,
            sourceWidth = 480,
            sourceHeight = 320
        },
        {
            -- 01_help/0020
            x=948,
            y=77,
            width=66,
            height=62,

            sourceX = 207,
            sourceY = 129,
            sourceWidth = 480,
            sourceHeight = 320
        },
    },
    
    sheetContentWidth = 1014,
    sheetContentHeight = 264
}

SheetInfo.frameIndex =
{

    ["01_help/0000"] = 1,
    ["01_help/0001"] = 2,
    ["01_help/0002"] = 3,
    ["01_help/0003"] = 4,
    ["01_help/0004"] = 5,
    ["01_help/0005"] = 6,
    ["01_help/0006"] = 7,
    ["01_help/0007"] = 8,
    ["01_help/0008"] = 9,
    ["01_help/0009"] = 10,
    ["01_help/0010"] = 11,
    ["01_help/0011"] = 12,
    ["01_help/0012"] = 13,
    ["01_help/0013"] = 14,
    ["01_help/0014"] = 15,
    ["01_help/0015"] = 16,
    ["01_help/0016"] = 17,
    ["01_help/0017"] = 18,
    ["01_help/0018"] = 19,
    ["01_help/0019"] = 20,
    ["01_help/0020"] = 21,
}

function SheetInfo:getSheet()
    return self.sheet;
end

function SheetInfo:getFrameIndex(name)
    return self.frameIndex[name];
end

return SheetInfo
