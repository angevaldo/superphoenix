local Trt = require "lib.Trt"
local Vector2D = require "lib.Vector2D"


local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"


local infObstacles = require("classes.infoObstacles")
local shtObstacles = graphics.newImageSheet("images/gameplay/aniObstacles.png", infObstacles:getSheet())
local infUtilGameplay = require("classes.infoUtilGameplay")
local shtUtilGameplay = graphics.newImageSheet("images/gameplay/scnUtilGameplay.png", infUtilGameplay:getSheet())


local TBL_SCORES = {25, 50, 100}
local TBL_DAMAGES = {-3, -5, -7}
local TBL_SHOTS_FRAMES = {103}
local TBL_STANDARDS_FRAMES = {104, 106, 108}
local TBL_LIGHTS_FRAMES = {105, 107, 109}
local TBL_TRANSITIONS_EASING = {"outQuart", "inOutQuint", "inOutBack"}

local TBL_POINTS_STASH = {
    {{60,64},{120,64},{60,128},{120,128},{60,192},{120,192},{180,192},{60,256},{120,256},{180,256},{360,64},{420,64},{360,128},{420,128},{300,192},{360,192},{420,192},{300,256},{360,256},{420,256},{Constants.LEFT - 50, display.contentCenterY},{Constants.RIGHT + 50, display.contentCenterY}},
    {{60,64},{120,64},{180,64},{60,128},{120,128},{180,128},{60,192},{120,192},{60,256},{120,256},{300,64},{360,64},{420,64},{300,128},{360,128},{420,128},{360,192},{420,192},{360,256},{420,256},{Constants.LEFT - 50, display.contentCenterY},{Constants.RIGHT + 50, display.contentCenterY}},
    {{60,64},{120,64},{180,64},{240,64},{300,64},{60,128},{120,128},{180,128},{240,128},{300,128},{60,192},{120,192},{180,192},{240,192},{300,192},{60,256},{120,256},{180,256},{240,256},{300,256},{Constants.LEFT - 50, display.contentCenterY},{Constants.RIGHT + 50, display.contentCenterY}},
    {{180,64},{240,64},{300,64},{360,64},{420,64},{180,128},{240,128},{300,128},{360,128},{420,128},{180,192},{240,192},{300,192},{360,192},{420,192},{180,256},{240,256},{300,256},{360,256},{420,256},{Constants.LEFT - 50, display.contentCenterY},{Constants.RIGHT + 50, display.contentCenterY}},
    {{60,64},{120,64},{180,64},{60,128},{120,128},{60,192},{120,192},{60,256},{120,256},{180,256},{300,64},{360,64},{420,64},{360,128},{420,128},{360,192},{420,192},{300,256},{360,256},{420,256},{Constants.LEFT - 50, display.contentCenterY},{Constants.RIGHT + 50, display.contentCenterY}},
}

math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random
local round = math.round
local cos = math.cos
local sin = math.sin

local Spaceship = {}
Spaceship.count = 0
Spaceship.tblPositions = {}

Spaceship.reset = function()
    Spaceship.count = 0
    Spaceship.tblPositions = {}
end

local function _addSmoke(obj)
    if obj.x then
        local sptSmoke = display.newSprite(shtObstacles, {{name="s", start=random(139,141), count=1}})
        obj.camera:add(sptSmoke, 6)
        sptSmoke.alpha = 0
        sptSmoke:scale(.6, .6)

        local numDist = random(2, 6) * 10
        local angle = random(360) * 0.017453292519943295769236907684886
        local s = sin(angle)
        local c = cos(angle)
        local tblPos = {numDist * c, round(numDist * s)}
        sptSmoke.x, sptSmoke.y = obj.x + tblPos[1] * .1, obj.y + tblPos[2] * .1

        local tblFrom = {obj.x + tblPos[1] * .2, obj.y + tblPos[2] * .2}
        local tblTo = {obj.x + tblPos[1] * .8, obj.y + tblPos[2] * .8}
        local numRot = random(-360, 360)
        local numTime = random(1, 3) * 1000
        local numScale = random(10, 20) * .1
        transition.to(sptSmoke, {alpha=1, x=tblFrom[1], y=tblFrom[2], xScale=.6+numScale*.2, yScale=.6+numScale*.2, time=numTime*.2, rotation=numRot*.2, onComplete=function()
            transition.to(sptSmoke, {alpha=0, x=tblTo[1], y=tblTo[2], xScale=.6+numScale*.8, yScale=.6+numScale*.8, time=numTime*.8, rotation=numRot*.8, onComplete=function()
                if sptSmoke and sptSmoke.parent and sptSmoke.parent.remove then
                    sptSmoke.parent:remove(sptSmoke)
                end
                sptSmoke = nil
            end})
        end})
    end
end

local function _activateSmoke(obj)
    if obj ~= nil and obj.health > 0 then
        obj.isSmokeActive = true

        _addSmoke(obj)

        timer.performWithDelay(obj.health * 20, function()
            _activateSmoke(obj)
        end,1)
    end
end

local function _destroyShot(self)
    local ship = self.ship
    if ship.trtShp ~= nil then
        Trt.cancel(ship.trtShp)
        ship.trtShp = nil
    end
    if ship.trtShf ~= nil then
        Trt.cancel(ship.trtShf)
        ship.trtShf = nil
    end
    if ship and ship.camera ~= nil then
        ship.camera:rem(self, 3)
    end
end

local function _animeShot(self)
    local obj = self.ship
    obj.trtShf = Trt.to(self[2], {yScale=.8, xScale=1, time=300, transition=easing.inQuad, onComplete=function()
        obj.trtShf = Trt.to(self[2], {yScale=1, xScale=.9, time=300, transition=easing.outQuad, onComplete=function()
            self:animeShot()
        end})
    end})
end

local function _destroy(self)
    if self.isNotDestroyed then

        Spaceship.count = Spaceship.count - 1

        Spaceship.tblPositions[self.id] = nil

        self.grpShot:destroy()

        self.isNotDestroyed = false
        self:stopMove()
        self.parent:remove(self)
        self = nil
    end
end

local function _shot(self)
    local grpShot = self.grpShot
    self.trtShp = Trt.to(grpShot, {time=300, onComplete=function()
        if self and self.isNotDestroyed then
            if self.numPositionCurrent > 20 then
                if self.isShotActive then
                    self:shot()
                else
                    self:destroy()
                end
            else
                Jukebox:dispatchEvent({name="playSound", id="spaceshipShot"})

                grpShot.x, grpShot.y = self.x, self.y
                grpShot.isVisible = true

                local posCamera = self.camera:getTarget()
                local vecTo = Vector2D:new(self.x - posCamera.x, self.y - posCamera.y)
                local numTime = vecTo:magnitude() * 10
                grpShot.rotation = Vector2D:Vec2deg(vecTo)

                self.trtShp = Trt.to(grpShot, {x=posCamera.x, y=posCamera.y, time=numTime, transition="inQuad", onComplete=function()
                    if self and self.camera then
                        self.camera:starCollision({element=self})
                        self:shot()
                    end
                end})
            end
        end
    end})
end

local function _getRandomPosition(obj)
    local isPositionFound = false
    local numPositionNew
    local count = 1
    while not isPositionFound and count < 20 do
        if obj.camera:getTargetPos() == 5 then
            numPositionNew = (obj.numPositionCurrent < 11 or obj.numPositionCurrent == 21) and random(1, 10) or random(11, 20)
        else
            numPositionNew = random(1, 20)
        end
        isPositionFound = true
        count = count + 1
        for k,v in next, Spaceship.tblPositions do
            if v == numPositionNew then
                isPositionFound = false
                break
            end
        end
    end
    return numPositionNew
end

local function _generateNextPosition(obj)
    if obj.timePassed < obj.timeToLeave then
        obj.numPositionCurrent = _getRandomPosition(obj)
    else
        obj.numPositionCurrent = TBL_POINTS_STASH[obj.camera:getTargetPos()][obj.numPositionCurrent][1] < obj.camera:getTarget().x and 21 or 22
    end
    Spaceship.tblPositions[obj.id] = obj.numPositionCurrent
end

local function _onSpriteExplode(self, event)
    if event.phase == "ended" then
        local sptShip = self.parent
        transition.to(sptShip, {alpha=0, xScale=1.1, yScale=1.1, time=800, onComplete=function()
            sptShip:destroy()
        end})
    end
end

local function _onTouch(self, event)
    if event.phase ~= "ended" and not self.isExploding and self.isTouchable then
        if self.trtTouch ~= nil then transition.cancel(self.trtTouch) end
        self:removeEventListener("touch", self)
        self.trtTouch = transition.to(self, {time=250, onComplete=function(self)
            if self.addEventListener and not self.isExploding then
                self:addEventListener("touch", self)
            end
        end})
        self.camera:objectTouch({other=self})
    end
    return false
end

local function _onTap(self, event)
    if not self.isExploding and self.isTouchable then
        self.camera:objectTap({other=self})
    end

    return false
end

local function _blackHole(self)
    self:destroy()
end

local function _stopMove(self)
    if self.trtShm ~= nil then
        Trt.cancel(self.trtShm)
        self.trtShm = nil
    end
    if self[3].trtShr ~= nil then
        Trt.cancel(self[3].trtShr)
        self[3].trtShr = nil
    end
    if self.trtShp ~= nil then
        Trt.cancel(self.trtShp)
        self.trtShp = nil
    end
    if self.trtShf ~= nil then
        Trt.cancel(self.trtShf)
        self.trtShf = nil
    end

    self:removeEventListener("touch", self)
    self:removeEventListener("tap", self)
    self._functionListeners = nil
    self._tableListeners = nil
end

local function _hit(self, damageFactor)
    local health = self.health - (damageFactor*25) / self.size
    self.health = health > 0 and health or 0

    local sptHealth = self[2]
    if sptHealth and not self.isExploding then
        local numFrame = 48-round(self.health*.48)+1
        local sptHealthBar = self[1]
        sptHealth:setFrame(numFrame)
        sptHealth.alpha = 1
        if sptHealth.trtAlphaCancel ~= nil then transition.cancel(sptHealth.trtAlphaCancel) end
        sptHealth.trtAlphaCancel = transition.to(sptHealth, {alpha=0, delay=500, time=400})
        sptHealthBar.alpha = 1
        if sptHealthBar.trtAlphaCancel ~= nil then transition.cancel(sptHealthBar.trtAlphaCancel) end
        sptHealthBar.trtAlphaCancel = transition.to(sptHealthBar, {alpha=0, delay=500, time=400})

        if self.health > 0 then
            Jukebox:dispatchEvent({name="playSound", id="spaceshipHit"})
            if not self.isSmokeActive then
                _activateSmoke(self)
            end
        else
            self:explode()
        end
    end

end

local function _startShot(self)
    self.isShotActive = true
    self:shot()
    self.grpShot:animeShot()
end

local function _move(self)
    _generateNextPosition(self)

    self.trtShm = Trt.to(self, {x=TBL_POINTS_STASH[self.camera:getTargetPos()][self.numPositionCurrent][1], y=TBL_POINTS_STASH[self.camera:getTargetPos()][self.numPositionCurrent][2], time=800, transition=TBL_TRANSITIONS_EASING[self.size], onComplete=function()

        self.numCountMoves = self.numCountMoves + 1

        if self.numPositionCurrent > 20 then
            self.isShotActive = false
            return
        end

        if self.numCountMoves == 3 then
            self:startShot()
        end

        local numTimeWait = 3000 / self.size + random(500)
        self.timePassed = self.timePassed + numTimeWait

        local numRot = random(2) == 1 and self[3].rotation+360 or self[3].rotation-360
        self[3].trtShr = Trt.to(self[3], {rotation=numRot, transition="outQuad", time=numTimeWait})

        local numRotShip = self[4].rotation + 90 * self.size * (random(2) == 1 and 1 or -1)
        self.trtShl = Trt.to(self[5], {rotation=numRotShip, time=numTimeWait})
        self.trtShm = Trt.to(self[4], {rotation=numRotShip, time=numTimeWait, onComplete=function()
            self:move()
        end})

    end})
end

local function _getCurrentScore(self)
    return self.score
end

local function _explode(self)
    local sptShip = self[4]
    if sptShip and sptShip.sequence ~= "e" then

        self.isExploding = true
        self[1].isVisible = false

        self[5].isVisible = false

        self[3].isVisible = true
        self[3].rotation = -self.rotation
        transition.to(self[3], {alpha=1, time=200, xScale=1, yScale=1.5, onComplete=function()
            transition.to(self[3], {alpha=0, time=300, xScale=2, yScale=.1})
        end})
        
        sptShip.rotation = random(360)
        sptShip:setSequence("e")
        sptShip:play()
        sptShip:setFillColor(0)
        sptShip:addEventListener("sprite", sptShip)

        -- UPDATE STATS
        self.camera:addStat("nSpaceshipsDestroyed", 1)
        
        -- UPDATE SCORE
        self.camera:updateScore({currentScore=self:getCurrentScore(), x=self.x, y=self.y})

        -- REMOVE SHOT
        if self.grpShot and self.grpShot.isVisible then
            if self.trtShp ~= nil then
                Trt.cancel(self.trtShp)
                self.trtShp = nil
            end
            if self.trtShf ~= nil then
                Trt.cancel(self.trtShf)
                self.trtShf = nil
            end
            transition.to(self.grpShot, {xScale=.01, yScale=.01, time=200})
        end

        Jukebox:dispatchEvent({name="playSound", id="spaceshipExplosion"})

        self:stopMove()
    end
end

local function _extractParam(param)
    return "table" == type(param) and random(param[1], param[2]) or param
end

function Spaceship:new(params)
    -- INIT
    local tbl = {}
    if (params ~= nil) then tbl = params end
    if tbl.isTouchable == nil then tbl.isTouchable = true end
    if tbl.numDelay == nil then tbl.numDelay = 0 end

    local size = _extractParam(tbl[4])
    local pos = _extractParam(tbl[5])

    local img = display.newGroup()

    -- HEALTH BAR
    local sptHealthBar = display.newSprite(shtUtilGameplay, {{name="s", start=49, count=1}})
    sptHealthBar.alpha = 0
    sptHealthBar:setFillColor(1, 1, 1, 0.3)
    sptHealthBar.trtCancel = nil
    img:insert(sptHealthBar)

    -- HEALTH
    local sptHealth = display.newSprite(shtUtilGameplay, {{name="s", start=49, count=49}})
    sptHealth.alpha = 0
    sptHealth:setFillColor(0)
    img:insert(sptHealth)

    -- FX
    local ray = display.newSprite(shtObstacles, {{name="s", start=138, count=1}})
    ray.anchorX, ray.anchorY = .5, .5
    ray.x, ray.y = 0, 0
    ray:scale(.5, .5)
    ray.isVisible = false
    ray.alpha = 0
    img:insert(ray)

    -- SHIP
    local numIndexFramesExplode = random(4)
    local sptShip = display.newSprite(shtObstacles, {
        {name="s", start=TBL_STANDARDS_FRAMES[size], count=1, loopCount=1},
        {name="e", frames={116,116,116,117,118,119,120}, time=300, loopCount=1},
    })
    sptShip.sprite = _onSpriteExplode
    img:insert(sptShip)
    --[[
    local a = ""
    for i=1, 20 do
        a = a..","..(106+i)
    end
    print(a)
    --]]

    -- LIGHT
    local sptLight = display.newSprite(shtObstacles, {
        {name="s", start=TBL_LIGHTS_FRAMES[size], count=1}
    })
    transition.blink(sptLight, {time=2500})
    img:insert(sptLight)

    -- EVENTS
    img.explode = _explode
    img.destroy = _destroy
    img.blackHole = _blackHole
    img.hit = _hit
    img.tap = _onTap
    img:addEventListener("tap", img)
    img.touch = _onTouch
    img:addEventListener("touch", img)
    img.stopMove = _stopMove
    img.move = _move
    img.shot = _shot
    img.startShot = _startShot
    img.getCurrentScore = _getCurrentScore

    local posCamera = tbl.camera:getTargetPos()

    -- PROPERTIES
    img.numPositionCurrent = TBL_POINTS_STASH[posCamera][pos][1] < tbl.camera:getTarget().x and 21 or 22
    img.x = TBL_POINTS_STASH[posCamera][img.numPositionCurrent][1]
    img.y = TBL_POINTS_STASH[posCamera][img.numPositionCurrent][2]
    img.isExploding = false
    img.isShotActive = false
    img.isNotDestroyed = true
    img.isObstacle = true
    img.numCountMoves = 1
    img.health = 100
    img.id = system.getTimer()
    img.size = size
    img.isTouchable = tbl.isTouchable
    img.damage = TBL_DAMAGES[size]
    img.score = TBL_SCORES[size]
    img.camera = tbl.camera
    img.timeToLeave = _extractParam(tbl[3])
    img.timePassed = 0
    img.isSmokeActive = false

    img.camera:add(img, 5)

    -- SHOT
    local grpShot = display.newGroup()
    tbl.camera:add(grpShot, 3)
    local sptShotTrail = display.newSprite(shtObstacles, {{name="s", start=137, count=1}})
    grpShot:insert(sptShotTrail)
    sptShotTrail.anchorX = 0
    sptShotTrail.alpha = 1
    sptShotTrail.x = 0
    sptShotTrail.xScale = .7
    local sptShot = display.newSprite(shtObstacles, {{name="s", start=TBL_SHOTS_FRAMES[1], count=1}})
    grpShot:insert(sptShot)
    local numScale = .4 + size * .2
    grpShot.width = grpShot.width * numScale
    grpShot.height = grpShot.height * numScale
    grpShot.isVisible = false
    grpShot.isObstacle = true
    grpShot.ship = img
    grpShot.destroy = _destroyShot
    grpShot.animeShot = _animeShot
    grpShot:toBack()
    img.grpShot = grpShot

    if tbl.numDelay > 0 then
        img.isVisible = false
        img.trtShm = Trt.to(img, {delay=tbl.numDelay, onComplete=function(self)
            self.isVisible = true
            self:move()
        end})
    else
        img:move()
    end

    Spaceship.count = Spaceship.count + 1
    
    return img
end

return Spaceship