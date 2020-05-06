local Trt = require "lib.Trt"


local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"


local infUtilGameplay = require("classes.infoUtilGameplay")
local shtUtilGameplay = graphics.newImageSheet("images/gameplay/scnUtilGameplay.png", infUtilGameplay:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random
local sin = math.sin
local cos = math.cos
local round = math.round
local atan2 = math.atan2

local Powerup = {}
Powerup.count = 0

Powerup.reset = function()
    Powerup.count = 0
end

Powerup.tblColors = {
    {1, 1, .2}, -- SHIELD
    {.9, 0, 0}, -- RECOVERY HEALTH
    {.2, .2, .2}, -- BLACK HOLE
    {1, 1, 1}, -- FROZEN
    {1, .4, 0}, -- SUPER PHOENIX
}

local function _destroy(self)
    self:removeEventListener("touch", self)
    self._functionListeners = nil
    self._tableListeners = nil

    self:release()
    self.parent:remove(self)

    self = nil
end

local function _onTouch(self, event)
    if self.isTouchable and self.parent and self.parent.parent and self.parent.parent.parent and self.parent.parent.parent.powerupTouchOn then
        self.isTouchable = false
        Trt.cancel(self.trtPck)

        self.camera:addStat("nGetPowerups", 1)

        if self.powerupType == 5 then
            Jukebox:dispatchEvent({name="playSound", id="powerup"})
            self:pause()
            self:setFrame(9)
            local xTo, yTo = Powerup.tblPosSuperPhoenix[1], Powerup.tblPosSuperPhoenix[2]
            transition.to(self, {x=xTo, y=yTo, xScale=.5, yScale=.5, time=400, rotation=0, transition=easing.outQuad, onComplete=function()
                if self.parent and self.parent.parent and self.parent.parent.parent and self.parent.parent.parent.powerupTouchOn then
                    self:scale(1, 1)
                    self:release()
                    self.parent.parent.parent:powerupTouchOn({other=self})
                end
            end})
        else
            self:release()
            self.parent.parent.parent:powerupTouchOn({other=self})
        end
    end
end

local function _release(self)
    Trt.cancel(self.trtPck)

    if self.powerupType == 1 or self.powerupType == 5 then
        Trt.to(self, {time=1000, onComplete=function()
            Powerup.count = Powerup.count - 1
        end})
    else
        Powerup.count = Powerup.count - 1
    end

    self.isTouchable = false
    self.isVisible = false
    self:pause()
end

function Powerup:new(params)
    local tblParams = {}

    if params ~= nil then tblParams = params end
    if tblParams.powerupType == nil then tblParams.powerupType = 1 end

    local img = display.newSprite(shtUtilGameplay, {{name="standard", start=37, count=12, time=1200}})

    img:setFillColor(Powerup.tblColors[tblParams.powerupType][1], Powerup.tblColors[tblParams.powerupType][2], Powerup.tblColors[tblParams.powerupType][3])
    img.x, img.y = tblParams.x, tblParams.y

    -- PROPERTIES
    img.rotation = random(360)
    img.powerupType = tblParams.powerupType
    img.camera = tblParams.camera
    img.isTouchable = false

    -- METHODS/EVENTS
    img.destroy = _destroy
    img.release = _release
    img.touch = _onTouch
    img:addEventListener("touch", img)

    img.camera:add(img, 6)

    return img
end

function Powerup:init(camera, tblPosSuperPhoenix, tblStore, isHowToPlay)
    Powerup.tblStash = {}
    Powerup.tblPosSuperPhoenix = tblPosSuperPhoenix
    local tblData
    for i=1, 5 do
        tblData = tblStore[""..i]
        if (tblData.k == 1 or (i < 5 and tblData.v == 0)) and not isHowToPlay then
            Powerup.tblStash[i] = nil
        else
            local imgPowerup = Powerup:new({x=50, y=50, powerupType=i, camera=camera})
            imgPowerup.isVisible = false
            Powerup.tblStash[i] = imgPowerup
        end
    end
end

function Powerup:pick(numSuperPhoenix)
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
    local numSort = random(100)

    powerupType = 1 -- SHIELD 10%
    if numSort < 30 then
        powerupType = 3   -- BLACK HOLE 30%
    elseif numSort < 60 then
        powerupType = 2   -- RECOVERY HEALTH 30%
    elseif numSort < 75 then
        powerupType = 4   -- FROZEN 15%
    elseif numSort < 90 then
        powerupType = 5   -- SUPER PHOENIX 15%
    end

    --powerupType = 1

    if Powerup.tblStash[powerupType] == nil or Powerup.tblStash[powerupType].isVisible or (numSuperPhoenix == 9 and powerupType == 5) then 
        return nil
    end

    local imgPowerup = Powerup.tblStash[powerupType]
    imgPowerup.isVisible, imgPowerup.isTouchable, imgPowerup.xScale, imgPowerup.yScale = true, false, 1, 1
    if imgPowerup.play then
        imgPowerup:play()
        Powerup.count = Powerup.count + 1
        return imgPowerup
    end

    return nil
end

function Powerup:launch(x, y, numSuperPhoenix)
    local obj = Powerup:pick(numSuperPhoenix)
    if obj == nil then return end

    obj.x, obj.y = x, y
    obj.xScale, obj.yScale = .2, .2

    local NUM_PADDING = 100
    local x1, y1 = random(Constants.RIGHT - NUM_PADDING * 2) + NUM_PADDING, random(Constants.BOTTOM - NUM_PADDING * 2) + NUM_PADDING
    local a = atan2(y1-y, x1-x)
    local s = sin(a)
    local c = cos(a)
    local dx, dy = (50 * c), (50 * s)

    local xTo, yTo = x + dx, y + dy
    local numRotDiff = 180 + (random(2) == 1 and 1 or -1)
    local numRot = obj.rotation + numRotDiff
    local numTime = obj.camera.isFrozen and 100 or 400
    obj.trtPck = Trt.to(obj, {isLocked=true, rotation=numRot, x=xTo, y=yTo, xScale=1, yScale=1, time=numTime, transition="outQuad", onComplete=function()
        if obj then
            obj.isTouchable = true
            dx, dy = dx * 2, dy * 2

            xTo, yTo = obj.x + dx, obj.y + dy
            numRot = obj.rotation + numRotDiff * 2
            obj.trtPck = Trt.to(obj, {isLocked=true, rotation=numRot, x=xTo, y=yTo, time=6000, onComplete=function()
                obj.trtPck = Trt.to(obj, {isLocked=true, xScale=.1, yScale=.1, time=200, onComplete=function()
                    obj:release()
                end})
            end})
        end
    end})
    
    return obj
end

return Powerup