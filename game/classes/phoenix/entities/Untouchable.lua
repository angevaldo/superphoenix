local Trt = require "lib.Trt"
local Vector2D = require "lib.Vector2D"


local infStar = require("classes.infoStar")
local shtStar = graphics.newImageSheet("images/gameplay/aniStar.png", infStar:getSheet())


local TBL_POINTS_STASH = {{540,160},{530,82},{500,10},{452,-52},{390,-100},{318,-130},{240,-140},{162,-130},{90,-100},{28,-52},{-20,10},{-50,82},{-60,160},{-50,238},{-20,310},{28,372},{90,420},{162,450},{240,460},{318,450},{390,420},{452,372},{500,310},{530,238}};

math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random
local abs = math.abs

local Untouchable = {}
Untouchable.count = 0

Untouchable.reset = function()
    Untouchable.count = 0
end

local function _destroy(self)
    Trt.cancel(self.trtUts)

    if self.parent then
        Untouchable.count = Untouchable.count - 1

        self:removeEventListener("touch", self)
        self._functionListeners = nil
        self._tableListeners = nil
        self.parent:remove(self)
    end

    self = nil
end

local function _onTouch(self, event)
    if self.isTouchable then 
        self.camera:untouchable(self.x, self.y, event.x, event.y, self.rotation)
        self:destroy()
    end

    return true
end

local function _move(self)
    if self.tblPath[self.currentPathIndex] then
        self.trtUto = Trt.to(self, {x=self.tblPath[self.currentPathIndex].x, y=self.tblPath[self.currentPathIndex].y, time=self.tblPath[self.currentPathIndex].numTime, onComplete=function()
            if self.currentPathIndex + 1 <= #self.tblPath  then
                self.currentPathIndex = self.currentPathIndex + 1
                self:move()
            else
                self:destroy()
            end
        end})
    end
end

local function _generateElipticPath(self, vecPoint)
    local vecAcceleration = Vector2D:Sub(self.vecTarget, vecPoint)
    vecAcceleration:normalize()
    vecAcceleration:mult(self.vecAccelerationMax)

    self.vecVelocity:add(vecAcceleration)
    self.vecVelocity:normalize()
    self.vecVelocity:mult(self.vecVelocityMax)
    self.vecAccelerationMax = self.vecAccelerationMax + 1

    local vecPointNew = Vector2D:Add(vecPoint, self.vecVelocity)
    local vecDist = Vector2D:Sub(self.vecTarget, vecPointNew)
    local numDist = vecDist:magnitude()
    if numDist > self.vecVelocityMax and #self.tblPath < 60 then
        self.tblPath[#self.tblPath+1] = vecPointNew
        self.tblPath[#self.tblPath].numTime = self.timeToTarget * numDist * .00025
        self:generateElipticPath(vecPointNew)
    else
        self.tblPath[#self.tblPath+1] = self.vecTarget
        self.tblPath[#self.tblPath].numTime = self.tblPath[#self.tblPath-1].numTime * 2
    end
end

function Untouchable:new(params)
    local tbl = {}
    if params ~= nil then tbl = params end
    if tbl.pos == nil then tbl.pos = random(24) end
    if tbl.isTouchable == nil then tbl.isTouchable = true end
    if tbl.numDelay == nil then tbl.numDelay = random(40)*100 end
    if tbl.timeToTarget == nil then tbl.timeToTarget = random(40, 50) * 100 - tbl.currentGroup * 250 end

    -- MOON
    local img = display.newSprite(shtStar, {{name="s", start=42, count=1}})
    img.camera = tbl.camera
    img.camera:add(img, 6)

    -- INIT CALC
    local numVelocity = random(37, 41)
    local numDir = random(2) == 1 and 1 or - 1

    local numIDStartPoint = tbl.pos
    local vecStart = Vector2D:new(TBL_POINTS_STASH[numIDStartPoint][1], TBL_POINTS_STASH[numIDStartPoint][2])

    local numIDMiddlePoint = numIDStartPoint + 18 * numDir
    numIDMiddlePoint = numIDMiddlePoint > 24 and numIDMiddlePoint - 24 or numIDMiddlePoint
    numIDMiddlePoint = numIDMiddlePoint < 1 and numIDMiddlePoint + 24 or numIDMiddlePoint
    local vecMiddle = Vector2D:new(TBL_POINTS_STASH[numIDMiddlePoint][1], TBL_POINTS_STASH[numIDMiddlePoint][2])

    local numIDEndPoint = numIDStartPoint + 1 * numDir
    numIDEndPoint = numIDEndPoint > 24 and numIDEndPoint - 24 or numIDEndPoint
    numIDEndPoint = numIDEndPoint < 1 and numIDEndPoint + 24 or numIDEndPoint
    local vecTarget = Vector2D:new(TBL_POINTS_STASH[numIDEndPoint][1], TBL_POINTS_STASH[numIDEndPoint][2])

    local vecVelocity = Vector2D:Sub(vecMiddle, vecStart)
    vecVelocity:normalize()
    vecVelocity:mult(numVelocity)

    -- ATT
    img.x, img.y = vecStart.x, vecStart.y
    img.vecVelocity = vecVelocity
    img.vecVelocityMax = numVelocity
    img.vecAccelerationMax = 2
    img.vecTarget = vecTarget
    img.isTouchable = tbl.isTouchable
    img.timeToTarget = tbl.timeToTarget
    img.tblPath = {}
    img.isObstacle = true
    img.currentPathIndex = 1

    -- METHODS / EVENTS
    img.touch = _onTouch
    img:addEventListener("touch", img)
    img.destroy = _destroy
    img.move = _move
    img.pause = _pause
    img.generateElipticPath = _generateElipticPath

    local vecPoint = Vector2D:new(img.x, img.y)
    img:generateElipticPath(vecPoint)

    if tbl.numDelay > 0 then
        img.isVisible = false
        img.trtUts = Trt.to(img, {time=tbl.numDelay, onComplete=function(self)
            self.isVisible = true
            self:move()
        end})
    else
        img:move()
    end

    Untouchable.count = Untouchable.count + 1
    
    return img
end

return Untouchable