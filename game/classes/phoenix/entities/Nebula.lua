local Trt = require "lib.Trt"


local Constants = require "classes.phoenix.business.Constants"


local infNebula = require("classes.infoNebula")
local shtNebula = graphics.newImageSheet("images/gameplay/bkgNebula.png", infNebula:getSheet())
local infObstacles = require("classes.infoObstacles")
local shtObstacles = graphics.newImageSheet("images/gameplay/aniObstacles.png", infObstacles:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random


local Nebula = {}

local HALF_Y = display.contentCenterY

local NUM_INDEX_BG = 1
local NUM_INDEX_NEBULA = 3
local NUM_PADDING = 500
local NUM_POS_FROM = {-NUM_PADDING, -NUM_PADDING, -NUM_PADDING, -NUM_PADDING, -NUM_PADDING}
local NUM_POS_TO = {Constants.RIGHT, Constants.RIGHT + NUM_PADDING, Constants.RIGHT + NUM_PADDING, Constants.RIGHT + NUM_PADDING, Constants.RIGHT + NUM_PADDING}

local TBL_V_DEFAULT = {0, 0, .002, .003, .006}
local TBL_QTD_STARS = {2, 3, 2, 2, 3}
local TBL_GRADIENTS_FILL = {}
local TBL_GRADIENTS_DIF = {}
local TBL_GRADIENTS = {
    {{1, .9, .1},{.7, .2, 0}},
    {{.9, .9, 0},{.1, .3, 0}},
    {{1, .9, 0},{.3, .2, 0}},
    {{1, .9, .3},{.7, 0, .2}},
    {{.7, .6, .7},{.1, .1, .6}},
}
Nebula.TBL_GRADIENTS = TBL_GRADIENTS
for i=1, #TBL_GRADIENTS do
    TBL_GRADIENTS_DIF[i] = {
        TBL_GRADIENTS[i][2][1]-TBL_GRADIENTS[i][1][1],
        TBL_GRADIENTS[i][2][2]-TBL_GRADIENTS[i][1][2],
        TBL_GRADIENTS[i][2][3]-TBL_GRADIENTS[i][1][3]
    }
end
local TBL_SPRITES_BACK_NEBULA ={{19},{22},{25},{28},{31}}
local TBL_SPRITES_MIDDLE_NEBULA ={{20},{23},{26},{29},{32}}
local TBL_SPRITES_FRONT_NEBULA ={{21},{24},{27},{30},{33}}
local TBL_POSITIONS = {{0, -50}, {0, 50}, {100,0}, {-100,0}, {0,0}, {-110,0}}

local function _getColorFill(numIdCurrentNebula, y)
    local numYTranslate = y

    if y > HALF_Y then
        numYTranslate = y - HALF_Y
    end
    local tblDif = TBL_GRADIENTS_DIF[numIdCurrentNebula]
    local numPct = numYTranslate / HALF_Y

    return {TBL_GRADIENTS[numIdCurrentNebula][1][1]+tblDif[1]*numPct, TBL_GRADIENTS[numIdCurrentNebula][1][2]+tblDif[2]*numPct, TBL_GRADIENTS[numIdCurrentNebula][1][3]+tblDif[3]*numPct}
end

for numIdCurrentNebula=1, 5 do
    local tblColors = {}
    for y=1, Constants.BOTTOM do
        tblColors[y] = _getColorFill(numIdCurrentNebula, y)
    end
    TBL_GRADIENTS_FILL[numIdCurrentNebula] = tblColors
end

local function _destroy(self)
    self._functionListeners = nil
    self._tableListeners = nil
    if self.parent then
        self.parent:remove(self)
    end
    self = nil
end

local function _play(self)
    for i=3, 5 do
        Trt.resume(self.tblTrtCancel[i])
    end
end

local function _pause(self)
    for i=3, 5 do
        Trt.pause(self.tblTrtCancel[i])
    end
end

local function _jump(self, params)
    if params.numPos ~= self.currentPos then
        local numDistX = TBL_POSITIONS[params.numPos][1] - TBL_POSITIONS[self.currentPos][1]
        local numDistY = TBL_POSITIONS[params.numPos][2] - TBL_POSITIONS[self.currentPos][2]
        local numX = 0
        local numY = 0
        for i=1, 5 do
            numX = self[NUM_INDEX_NEBULA][i].x + numDistX * i * .25
            numY = params.numPos == 6 and self[NUM_INDEX_NEBULA][i].y or self[NUM_INDEX_NEBULA][i].y + numDistY * i * .25
            Trt.to(self[NUM_INDEX_NEBULA][i], {x=numX, y=numY, transition=params.easing, time=params.numTime})
        end
        Trt.to(self[NUM_INDEX_BG], {x=TBL_POSITIONS[params.numPos][1], y=TBL_POSITIONS[params.numPos][2], transition=params.easing, time=params.numTime})
        self.currentPos = params.numPos == 6 and self.currentPos or params.numPos
        Trt.to(self, {time=params.numTime, onComplete=params.onComplete})
    elseif params.onComplete then
        params.onComplete()
    end
end

local function _reposition(self, numPos)
    if numPos ~= self.currentPos then
        local numDistX = TBL_POSITIONS[numPos][1] - TBL_POSITIONS[self.currentPos][1]
        local numDistY = TBL_POSITIONS[numPos][2] - TBL_POSITIONS[self.currentPos][2]
        local numX = 0
        local numY = 0
        for i=1, 5 do
            numX = self[NUM_INDEX_NEBULA][i].x + numDistX * i * .3
            numY = numPos == 6 and self[NUM_INDEX_NEBULA][i].y or self[NUM_INDEX_NEBULA][i].y + numDistY * i * .2
            self[NUM_INDEX_NEBULA][i].x, self[NUM_INDEX_NEBULA][i].y = numX, numY
        end
        self[NUM_INDEX_BG].x = TBL_POSITIONS[numPos][1]
        self[NUM_INDEX_BG].y = TBL_POSITIONS[numPos][2]
        self.currentPos = numPos
    end
end

local function _randomizeStar(img)
    local numScale = random(13, 16) * .1
    if random(2) == 1 then
        img.rotation = 180
    end
    if random(2) == 1 then
        img.xScale = -numScale
    else
        img.xScale = numScale
    end
    if random(2) == 1 then
        img.yScale = -numScale
    else
        img.yScale = numScale
    end
    img.y = HALF_Y + random(-25, 25)
    img.alpha = random(3, 10) * .1
    img:setFrame(random(img.numFrames))

    return img
end

local function _getNextImageLayerStars(grpLayer, isFillUp, numIdCurrentNebula)
    local img
    if not isFillUp then
        img = display.newSprite(shtNebula, {{name="s", frames={1, 2, 3, 4, 5}}})
    else
        img = grpLayer[1]
    end

    if img.numFrames then
        _randomizeStar(img)
    else
        for i=1, TBL_QTD_STARS[numIdCurrentNebula] do
            _randomizeStar(img[i])
        end
    end
    return img
end

local function _getSortFrame(grpLayer, numFrames)
    grpLayer.numCountSorted = grpLayer.numCountSorted + 1
    local numFrame = random(numFrames)
    if grpLayer.tblSpriteUsed[numFrame] and grpLayer.numCountSorted <= numFrames then
        numFrame = _getSortFrame(grpLayer, numFrames)
    end

    return numFrame
end

local function _getNextImageLayerBack(grpLayer, isFillUp, numIdCurrentNebula)
    grpLayer.numCountSorted = 0

    local img
    if not isFillUp then
        img = display.newSprite(shtNebula, {{name="s", frames={TBL_SPRITES_BACK_NEBULA[numIdCurrentNebula][1],6,6,7,7,8,9,10,11,12}}})--6,6,7,7,
    else
        img = grpLayer[1]
    end

    grpLayer.tblSpriteUsed[img.frame] = false
    local numFrame = _getSortFrame(grpLayer, img.numFrames)
    img:setFrame(numFrame)
    grpLayer.tblSpriteUsed[numFrame] = true

    local numDirX, numDirY = random(2) == 1 and 1 or -1, random(2) == 1 and 1 or -1
    local numScale = random(3, 7)
    img.xScale, img.yScale = numScale * numDirX, numScale * numDirY
    img.rotation = random(360)
    img.y = HALF_Y + random(70, 100) * (random(2) == 1 and 1 or -1)

    if numFrame > 1 then
        img:setFillColor(TBL_GRADIENTS_FILL[numIdCurrentNebula][img.y][1], TBL_GRADIENTS_FILL[numIdCurrentNebula][img.y][2], TBL_GRADIENTS_FILL[numIdCurrentNebula][img.y][3])
    else
        img:setFillColor(1, 1, 1)
    end

    return img
end

local function _getNextImageLayerMiddle(grpLayer, isFillUp, numIdCurrentNebula)
    grpLayer.numCountSorted = 0

    local img
    if not isFillUp then
        img = display.newSprite(shtNebula, {{name="s", frames={TBL_SPRITES_MIDDLE_NEBULA[numIdCurrentNebula][1],6,6,6,7,7,7,13,14,15,16,17,18}}})--6,6,6,6,7,7,7,7,
    else
        img = grpLayer[1]
    end

    grpLayer.tblSpriteUsed[img.frame] = false
    local numFrame = _getSortFrame(grpLayer, img.numFrames)
    img:setFrame(numFrame)
    grpLayer.tblSpriteUsed[numFrame] = true

    local numScale = random(15, 20) * .1
    img.xScale, img.yScale = numScale, numScale
    img.rotation = random(-50, 50)
    img.y = HALF_Y + random(60, 90) * (random(2) == 1 and 1 or -1)

    if numFrame > 1 then
        img:setFillColor(TBL_GRADIENTS_FILL[numIdCurrentNebula][img.y][1], TBL_GRADIENTS_FILL[numIdCurrentNebula][img.y][2], TBL_GRADIENTS_FILL[numIdCurrentNebula][img.y][3])
    else
        img:setFillColor(1, 1, 1)
    end

    return img
end

local function _getNextImageLayerFront(grpLayer, isFillUp, numIdCurrentNebula)
    grpLayer.numCountSorted = 0

    local img
    if not isFillUp then
        img = display.newSprite(shtNebula, {{name="s", frames={TBL_SPRITES_FRONT_NEBULA[numIdCurrentNebula][1],6,6,6,7,7,7,13,14,15,16,17,18}}})--6,6,6,6,6,7,7,7,7,7,
    else
        img = grpLayer[1]
    end

    grpLayer.tblSpriteUsed[img.frame] = false
    local numFrame = _getSortFrame(grpLayer, img.numFrames)
    img:setFrame(numFrame)
    grpLayer.tblSpriteUsed[numFrame] = true

    local numScale = random(10, 15) * .1
    img.xScale, img.yScale = numScale, numScale
    img.rotation = random(-50, 50)
    img.y = HALF_Y + random(60, 90) * (random(2) == 1 and 1 or -1)

    if numFrame > 1 then
        img:setFillColor(TBL_GRADIENTS_FILL[numIdCurrentNebula][img.y][1], TBL_GRADIENTS_FILL[numIdCurrentNebula][img.y][2], TBL_GRADIENTS_FILL[numIdCurrentNebula][img.y][3])
    else
        img:setFillColor(1, 1, 1)
    end

    return img
end

local _anime = function() end
local _fillScreen = function() end

_anime = function(obj, numLayer)
    local grpLayer = obj[NUM_INDEX_NEBULA][numLayer]
    local ds = grpLayer[1].contentWidth
    local xTo = grpLayer.x - ds * grpLayer.dir
    local dt = ds / grpLayer.v
    obj.tblTrtCancel[numLayer] = Trt.to(grpLayer, {x=xTo, time=dt, onComplete=function()
        _fillScreen(obj, numLayer, true)
    end})
end

_fillScreen = function(obj, numLayer, isFillUp)
    local grpLayer = obj[NUM_INDEX_NEBULA][numLayer]
    local numIdCurrentNebula = obj.numIdCurrentNebula

    local img = display.newGroup()
    if numLayer < 3 then
        if numLayer == 1 and not isFillUp then
            for i=1, TBL_QTD_STARS[numIdCurrentNebula] do
                local img1 = _getNextImageLayerStars(grpLayer, isFillUp, numIdCurrentNebula)
                img:insert(img1)
            end
        else
            img = _getNextImageLayerStars(grpLayer, isFillUp, numIdCurrentNebula)
        end
    elseif numLayer == 3 then
        img = _getNextImageLayerBack(grpLayer, isFillUp, numIdCurrentNebula)
    elseif numLayer == 4 then
        img = _getNextImageLayerMiddle(grpLayer, isFillUp, numIdCurrentNebula)
    elseif numLayer == 5 then
        img = _getNextImageLayerFront(grpLayer, isFillUp, numIdCurrentNebula)
    end

    img.anchorX, img.anchorY = .5, .5
    local numPosFrom = NUM_POS_FROM[numLayer]
    local numPosTo = NUM_POS_TO[numLayer]
    if grpLayer.dir == -1 then
        numPosFrom = -NUM_POS_FROM[numLayer]
        numPosTo = -NUM_POS_TO[numLayer] * .5
    end
    img.x = grpLayer.numChildren == 0 and numPosFrom or grpLayer[grpLayer.numChildren].x + (grpLayer[grpLayer.numChildren].contentWidth * .5 + img.contentWidth * .5) * grpLayer.dir
    grpLayer:insert(img)

    local numX = obj[NUM_INDEX_NEBULA].x + grpLayer.x + grpLayer[grpLayer.numChildren].x
    if (grpLayer.dir == 1 and numX < numPosTo) or (grpLayer.dir == -1 and numX > numPosTo) then
        _fillScreen(obj, numLayer, false)
    elseif numLayer > 2 then
        _anime(obj, numLayer)
    end

    --[[]
    local numTotal = 0
    for i=1, 5 do
        local grp = obj[NUM_INDEX_NEBULA][i]
        numTotal = grp.numChildren + numTotal
    end
    print(numTotal)
    --]]
end

local function _animate(self)
    for i=2, 5 do
        _anime(self, i)
    end
end

local function _setNebula(self, numIdCurrentNebula)
    numIdCurrentNebula = numIdCurrentNebula % 5
    numIdCurrentNebula = numIdCurrentNebula == 0 and 5 or numIdCurrentNebula
    self.numIdCurrentNebula = numIdCurrentNebula

    self[NUM_INDEX_BG][1].fill.effect.color1 = TBL_GRADIENTS[numIdCurrentNebula][1]
    self[NUM_INDEX_BG][1].fill.effect.color2 = TBL_GRADIENTS[numIdCurrentNebula][2]
    self[NUM_INDEX_BG].x = TBL_POSITIONS[self.currentPos][1] * .8
    self[NUM_INDEX_BG].y = TBL_POSITIONS[self.currentPos][2] * .8

    self.x = display.contentCenterX
    for i=1, 5 do
        Trt.cancel(self.tblTrtCancel[i])
        self.tblTrtCancel[i] = nil

        local grpLayer = self[NUM_INDEX_NEBULA][i]
        for j=grpLayer.numChildren, 1, -1 do
            grpLayer:remove(j)
            grpLayer[j] = nil
        end

        grpLayer.dir = i == 2 and self[NUM_INDEX_NEBULA][1].dir or (random(2) == 1 and 1 or -1)
        grpLayer.dir = i == 1 and 1 or (i == 5 and self[NUM_INDEX_NEBULA][4].dir * -1 or grpLayer.dir)
        grpLayer.anchorX, grpLayer.anchorY = grpLayer.dir == -1 and 1 or 0, 0
        grpLayer.x, grpLayer.y = grpLayer.dir == -1 and NUM_POS_TO or NUM_POS_FROM, -display.actualContentHeight * .5
        grpLayer.tblSpriteUsed = {}

        _fillScreen(self, i, false)
    end
end

function Nebula:new(params)
    local tbl = {}
    if (params ~= nil) then tbl = params end

    local numIndexCount = 0

    -- IMAGE GROUP
    local img = display.newGroup()

    -- TABLE TRANSITIONS
    img.tblTrtCancel = {}

    -- SPRITE OBSTACLE CACHE
    --[[]
    numIndexCount = numIndexCount + 1
    local sptTemp = display.newSprite(shtObstacles, {{name="s", start=1, count=117}})
    img:insert(sptTemp)
    --]]

    -- ATT
    img.x, img.y = tbl.x, tbl.y
    --img.isVisible = false
    img.currentPos = 5
    img.numIdCurrentNebula = 1

    -- BG
    numIndexCount = numIndexCount + 1
    NUM_INDEX_BG = numIndexCount
    local grpBkg = display.newGroup()
    local rct = display.newRect(0, 0, 750, 450)
    rct.fill.effect = "generator.radialGradient"
    rct.fill.effect.color1 = TBL_GRADIENTS[img.numIdCurrentNebula][1]
    rct.fill.effect.color2 = TBL_GRADIENTS[img.numIdCurrentNebula][2]
    rct.fill.effect.center_and_radiuses  =  {0.5, 0.5, 0, .42}
    rct.fill.effect.aspectRatio  = 1
    rct.anchorX, rct.anchorY = .5, .5
    grpBkg:insert(rct)
    img:insert(grpBkg)

    -- METHODS / EVENTS
    img.destroy = _destroy
    img.play = _play
    img.pause = _pause
    img.setNebula = _setNebula
    img.jump = _jump
    img.reposition = _reposition
    img.animate = _animate

    -- LAYERS
    numIndexCount = numIndexCount + 1
    NUM_INDEX_NEBULA = numIndexCount
    local grpLayers = display.newGroup()
    --grpLayers.isVisible = false
    for i=1, 5 do
        local grpLayer = display.newGroup()
        grpLayer.dir = i == 2 and grpLayers[1].dir or (random(2) == 1 and 1 or -1)
        grpLayer.dir = i == 1 and 1 or (i == 5 and grpLayers[4].dir * -1 or grpLayer.dir)
        grpLayer.anchorX, grpLayer.anchorY = grpLayer.dir == -1 and 0 or 1, 0
        grpLayer.x, grpLayer.y = grpLayer.dir == -1 and NUM_POS_TO or NUM_POS_FROM, -display.actualContentHeight * .5
        grpLayer.tblSpriteUsed = {}
        grpLayer.v = TBL_V_DEFAULT[i]
        --if i ~= 1 then grpLayer.isVisible = false end

        grpLayers:insert(grpLayer)
    end
    img:insert(grpLayers)
    for i=1, 5 do
        _fillScreen(img, i, false)
    end

    return img
end

return Nebula