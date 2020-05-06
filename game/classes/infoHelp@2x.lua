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
            x=438,
            y=0,
            width=298,
            height=260,

            sourceX = 434,
            sourceY = 236,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0001
            x=822,
            y=200,
            width=452,
            height=180,

            sourceX = 264,
            sourceY = 270,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0002
            x=738,
            y=0,
            width=328,
            height=198,

            sourceX = 288,
            sourceY = 244,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0003
            x=1414,
            y=174,
            width=356,
            height=162,

            sourceX = 182,
            sourceY = 262,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0004
            x=446,
            y=262,
            width=374,
            height=210,

            sourceX = 182,
            sourceY = 244,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0005
            x=0,
            y=282,
            width=444,
            height=236,

            sourceX = 182,
            sourceY = 228,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0006
            x=1068,
            y=0,
            width=482,
            height=172,

            sourceX = 182,
            sourceY = 252,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0007
            x=0,
            y=0,
            width=436,
            height=280,

            sourceX = 182,
            sourceY = 174,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0008
            x=1552,
            y=0,
            width=342,
            height=162,

            sourceX = 434,
            sourceY = 260,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0009
            x=1302,
            y=348,
            width=262,
            height=170,

            sourceX = 386,
            sourceY = 282,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0010
            x=1158,
            y=382,
            width=142,
            height=124,

            sourceX = 398,
            sourceY = 244,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0011
            x=1276,
            y=174,
            width=136,
            height=172,

            sourceX = 414,
            sourceY = 222,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0012
            x=1772,
            y=164,
            width=104,
            height=108,

            sourceX = 428,
            sourceY = 266,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0013
            x=822,
            y=382,
            width=190,
            height=146,

            sourceX = 382,
            sourceY = 250,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0014
            x=1566,
            y=338,
            width=154,
            height=156,

            sourceX = 418,
            sourceY = 262,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0015
            x=1858,
            y=280,
            width=164,
            height=110,

            sourceX = 396,
            sourceY = 258,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0016
            x=1858,
            y=392,
            width=154,
            height=110,

            sourceX = 406,
            sourceY = 258,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0017
            x=1722,
            y=338,
            width=134,
            height=148,

            sourceX = 414,
            sourceY = 248,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0018
            x=1014,
            y=382,
            width=142,
            height=128,

            sourceX = 408,
            sourceY = 256,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0019
            x=1896,
            y=0,
            width=132,
            height=152,

            sourceX = 410,
            sourceY = 244,
            sourceWidth = 960,
            sourceHeight = 640
        },
        {
            -- 01_help/0020
            x=1896,
            y=154,
            width=132,
            height=124,

            sourceX = 414,
            sourceY = 258,
            sourceWidth = 960,
            sourceHeight = 640
        },
    },
    
    sheetContentWidth = 2028,
    sheetContentHeight = 528
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
