local Trt = require "lib.Trt"
local Vector2D = require "lib.Vector2D"


local Jukebox = require "classes.phoenix.business.Jukebox"


local infObstacles = require("classes.infoObstacles")
local shtObstacles = graphics.newImageSheet("images/gameplay/aniObstacles.png", infObstacles:getSheet())
local infUtilGameplay = require("classes.infoUtilGameplay")
local shtUtilGameplay = graphics.newImageSheet("images/gameplay/scnUtilGameplay.png", infUtilGameplay:getSheet())


local TBL_SCORES = {{5,7}, {7,9}, {12,15}}
local TBL_DAMAGES = {{-25,-25}, {-50,-50}, {-75,-75}}--{{-50,-55}, {-55,-50}, {-50,-55}}--{{-0,-0}, {-0,-0}, {-0,-0}}--
local TBL_RAIOS = {17, 19, 20}
local TBL_STANDARDS_FRAMES = {{{1,2,3}, {4,5,6}, {7,8,9}}, {{52,53,54}, {55,56,57}, {58,59,60}}}
local TBL_EXPLOSIONS_FRAMES = {{{10,23}, {33,19}}, {{61,23}, {84,19}}}
local TBL_EXPLOSIONS_SCALES = {{.6, .8, 1.4}, {.7, .9, 1.5}}
local TBL_EXPLOSIONS_TIMES = {700, 800, 900}
local NUM_RANGE_TO_TARGET = .002
local NUM_TIME_TO_TARGET_MIN = 2700
local NUM_TIME_TO_ALERT_LIMIT = 1499
local NUM_TIME_TO_ALERT = 1200
local NUM_SCREEN_PROP = display.actualContentWidth * .5 * (display.actualContentHeight / display.actualContentWidth)

local TBL_POINTS_STASH = {
    {{-60,160},{-50,238},{-20,310},{28,372},{90,420},{162,450},{240,460},{318,450},{390,420},{452,372},{500,310},{530,238},{540,160},{530,238},{500,310},{452,372},{390,420},{318,450},{240,460},{162,450},{90,420},{28,372},{-20,310},{-50,238}},
    {{540,160},{530,82},{500,10},{452,-52},{390,-100},{318,-130},{240,-140},{162,-130},{90,-100},{28,-52},{-20,10},{-50,82},{-60,160},{-50,82},{-20,10},{28,-52},{90,-100},{162,-130},{240,-140},{318,-130},{390,-100},{452,-52},{500,10},{530,82}},
    {{240,-140},{162,-130},{90,-100},{28,-52},{-20,10},{-50,82},{-60,160},{-50,238},{-20,310},{28,372},{90,420},{162,450},{240,460},{162,450},{90,420},{28,372},{-20,310},{-50,238},{-60,160},{-50,82},{-20,10},{28,-52},{90,-100},{162,-130}},
    {{240,460},{318,450},{390,420},{452,372},{500,310},{530,238},{540,160},{530,82},{500,10},{452,-52},{390,-100},{318,-130},{240,-140},{318,-130},{390,-100},{452,-52},{500,10},{530,82},{540,160},{530,238},{500,310},{452,372},{390,420},{318,450}},
    {{540,160},{530,82},{500,10},{452,-52},{390,-100},{318,-130},{240,-140},{162,-130},{90,-100},{28,-52},{-20,10},{-50,82},{-60,160},{-50,238},{-20,310},{28,372},{90,420},{162,450},{240,460},{318,450},{390,420},{452,372},{500,310},{530,238}}
}

math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random
local abs = math.abs
local floor = math.floor
local sqrt = math.sqrt

local Particle = {}
Particle.count = 0

Particle.reset = function()
    Particle.count = 0
end

local function _destroy(self)
    if self.isNotDestroyed then

        Particle.count = Particle.count - 1

        --[[
        if self[2] and self[2].removeSelf then
           self[2]:removeSelf()
           self[2] = nil
        end
        --]]

        self.isNotDestroyed = false
        self:stopMove()
        self.parent:remove(self)
        self = nil
    end
end

local function _generateElipticPath(self, vecPoint)
    local vecDist = Vector2D:Sub(vecPoint, self.camera:getTarget())
    local vecRot = Vector2D:Mult(Vector2D:RotateVector(vecDist, 15 * self.dir), self.gravityForce)
    local numDist = vecRot:magnitude()
    if numDist > TBL_RAIOS[self.size] then
        vecRot:add(self.camera:getTarget())
        self.tblPath[#self.tblPath+1] = vecRot
        self.tblPath[#self.tblPath].numTime = self.timeToTarget * (numDist) * .0005
        self:generateElipticPath(vecRot)
    end
end

local function _onSpriteExplode(self, event)
    if (event.phase == "ended") then
        local particle = self.parent.parent
        particle:destroy()
    end
end

local function _onTouch(self, event)
    local obj = self.parent
    if (event.phase == "began" or event.phase == "moved") and obj.isTouchable then
        obj.camera:objectTouch({other=obj})
    end
    return false
end

local function _onTap(self, event)
    local obj = self.parent
    if obj.isTouchable and not obj.isExploding then
        obj.camera:objectTap({other=obj})
    end
    return false
end

local function _blackHole(self)
    if not self.isExploding then

        -- REMOVE TRAIL
        local sptFx = self[1]
        if sptFx[1] then
            sptFx[1].parent:remove(sptFx[1])
            sptFx[1] = nil
        end
        
        self:destroy()
    end
end

local function _stopMove(self)
    if self.trtRot ~= nil then
        Trt.cancel(self.trtRot)
        self.trtRot = nil 
    end
    if self.trtPtc ~= nil then
        Trt.cancel(self.trtPtc)
        self.trtPtc = nil 
    end
    if self.trtPtm ~= nil then
        Trt.cancel(self.trtPtm)
        self.trtPtm = nil 
    end
    if self.trtPts ~= nil then
        Trt.cancel(self.trtPts)
        self.trtPts = nil 
    end

    if self[2] and self[2].removeEventListener then
        self[2]:removeEventListener("tap", self[2])
        self[2]:removeEventListener("touch", self[2])
    end

    self._functionListeners = nil
    self._tableListeners = nil
end

local function _hit(self)
    self:explode()
end

local function _move(self)
    if self.tblPath[self.currentPathIndex] then
        local numRot = self.rotation+self.angularVelocity
        if self[2] then
            self.trtRot = Trt.to(self[2], {rotation=self[2].rotation+self.angularVelocity, time=self.tblPath[self.currentPathIndex].numTime})
            numRot = self.rotation
        end

        self.trtPtc = Trt.to(self, {rotation=numRot, transition=self.easing, x=self.tblPath[self.currentPathIndex].x, y=self.tblPath[self.currentPathIndex].y, time=self.tblPath[self.currentPathIndex].numTime, onComplete=function()
            self.isTouchable = true
            if self.currentPathIndex + 1 <= #self.tblPath  then
                self.currentPathIndex = self.currentPathIndex + 1
                self:move()
            elseif not self.isExploding then
                self.isOnStar = true
                self:explode()
            end
        end})
    end
end

local function _getCurrentScore(self)
    local target = self.camera:getTarget()

    local x = target.x - self.x
    local y = target.y - self.y
    local percDist = sqrt(x*x + y*y) * NUM_RANGE_TO_TARGET
    local score = floor(self.score * self.score * percDist)

    return score
end

local function _explode(self)
    local sptMain = self[2]
    if sptMain and sptMain[1] and sptMain[1].sequence ~= "e" then


        self.isExploding = true
        self:stopMove()

        sptMain[1]:setSequence("e")
        sptMain[1]:play()
        sptMain[1]:addEventListener("sprite", sptMain[1])

        -- REMOVE TRAIL
        local sptFx = self[1]
        if sptFx[1] then
            transition.to(sptFx[1], {alpha=0, xScale=1, yScale=.1, time=300, onComplete=function()
                if sptFx[1] then
                    sptFx[1].parent:remove(sptFx[1])
                    sptFx[1] = nil
                end
            end})
        end

        -- ADJUST SCALE XPLOSION
        local numScale = random(8, 10) * .1
        self:scale(TBL_EXPLOSIONS_SCALES[self.isAsteroid+1][self.size] * numScale, TBL_EXPLOSIONS_SCALES[self.isAsteroid+1][self.size] * numScale)
        if sptMain[2] then
            sptMain[2].isVisible = false
        end

        if self.isOnStar then
            self.camera:starCollision({element=self})

        elseif self.camera then
            local strId = ((self.isAsteroid == 1) and "stone" or "ice")..(self.size == 3 and "Big" or "")
            Jukebox:dispatchEvent({name="playSound", id=strId})

            -- UPDATE STATS
            if self.isAsteroid == 1 then
                self.camera:addStat("nAsteroidsDestroyed", 1)
            else
                self.camera:addStat("nIcesDestroyed", 1)
            end

            local target = self.camera:getTarget()

            -- UPDATE SCORE
            self.camera:updateScore({currentScore=self:getCurrentScore(), x=self.x, y=self.y})

            -- DIVIDE
            if self.size == 3 then
                local path1 = Vector2D:new(self.x - target.x, self.y - target.y)
                path1:normalize()
                local path2 = path1:copy()

                path1:mult(random(20, 60))
                path1:rotateVector(random(30, 60)*-1)
                path2:mult(random(60, 100))
                path2:rotateVector(random(30, 60))

                local numGravity = self.gravityForce and self.gravityForce * 10 or nil
                self.trtPts = Trt.to(self, {time=1, onComplete=function()
                    if self.camera then
                        Particle:new({self.isAsteroid, 0, self.timeToTarget, 1, 0, numGravity, -1, x=self.x, y=self.y, xTo=self.x+path1.x, yTo=self.y+path1.y, isTouchable=false, camera=self.camera, currentGroup=self.currentGroup})
                    end
                    self.trtPts = Trt.to(self, {time=60, onComplete=function()
                        if self.camera then
                            Particle:new({self.isAsteroid, 0, self.timeToTarget, 1, 0, numGravity, 1, x=self.x, y=self.y, xTo=self.x+path2.x, yTo=self.y+path2.y, isTouchable=false, camera=self.camera, currentGroup=self.currentGroup})
                        end
                    end})
                end})
            end

            -- PICKUP
            if self.isPowerup then
                self.camera:addPowerup(self.x, self.y)
            end

        end
    end
end

local function _extractParam(param)
    return "table" == type(param) and random(param[1], param[2]) or param
end

function Particle:new(params)
    local camera = params.camera
    if camera == nil or camera:getTarget() == nil or camera:getTarget().x == nil then
        return nil
    end

    local NUM_ASSIST_FACTOR = camera.codAssist == 9 and .8 or 1

    -- INIT
    local tbl = {}
    if params ~= nil then tbl = params end
    if tbl[1] == nil then tbl[1] = 0 end
    if tbl[6] == nil then tbl[6] = 8.5 end
    if tbl[7] == nil then tbl[7] = 1 end
    if tbl.isTouchable == nil then tbl.isTouchable = true end
    if tbl.numDelay == nil then tbl.numDelay = 0 end
    if tbl.isPowerup == nil then tbl.isPowerup = random(NUM_ASSIST_FACTOR * (35 - tbl.currentGroup)) == 1 end
    if tbl.easing == nil then tbl.easing = "linear" end

    local dir = _extractParam(tbl[7])
    dir = dir == 0 and (random(2) and 1 or -1) or dir
    local size = _extractParam(tbl[4])
    --print(unpack(params))
    local pos = _extractParam(tbl[5])
    local posOld = tbl.pOld and _extractParam(tbl.pOld)
    local posTarget = camera:getTargetPos()
    local isAsteroid = _extractParam(tbl[1])

    if posOld then
        local newPos = tbl.pOldLaunched + pos - posOld
        newPos = newPos > #TBL_POINTS_STASH[posTarget] and newPos - #TBL_POINTS_STASH[posTarget] or newPos
        newPos = newPos <= 0 and newPos + #TBL_POINTS_STASH[posTarget] or newPos
        pos = newPos
    else
        pos = random(#TBL_POINTS_STASH[posTarget])
    end

    -- IMAGE
    local numIndexFrames = isAsteroid == 1 and 1 or 2
    local img = display.newGroup()


    local grpFx = display.newGroup()
    img:insert(grpFx)

    local grpMain = display.newGroup()
    img:insert(grpMain)


    -- SPRITE BOTTOM
    local numFrameStandard = TBL_STANDARDS_FRAMES[numIndexFrames][size][random(3)]
    local i = random(2)
    local spriteBottom = display.newSprite(shtObstacles, {
        {name="s", start=numFrameStandard, count=1},
        {name="e", start=TBL_EXPLOSIONS_FRAMES[numIndexFrames][i][1], count=TBL_EXPLOSIONS_FRAMES[numIndexFrames][i][2], time=TBL_EXPLOSIONS_TIMES[size], loopCount=1},
    })
    if size == 3 then
        spriteBottom:scale(.8, .8)
    end
    local numDirSprites = {random(2) == 1 and 1 or -1, random(2) == 1 and 1 or -1}
    spriteBottom.xScale, spriteBottom.yScale = spriteBottom.xScale * numDirSprites[1], spriteBottom.yScale * numDirSprites[2]
    spriteBottom.sprite = _onSpriteExplode
    grpMain:insert(spriteBottom)

    -- SPRITE TOP
    if size > 1 or random(2) == 1 then
        local numFrameStandard = TBL_STANDARDS_FRAMES[numIndexFrames][size][random(3)]
        local spriteTop = display.newSprite(shtObstacles, {
            {name="s", start=numFrameStandard, count=1}
        })
        if size == 3 then
            spriteTop:scale(.8, .8)
        end
        spriteTop.alpha = isAsteroid == 1 and 1 or (random(4, 8) * .1)
        spriteTop.rotation = random(360)
        local numDirSprites = {random(2) == 1 and 1 or -1, random(2) == 1 and 1 or -1}
        spriteTop.xScale, spriteTop.yScale = spriteTop.xScale * numDirSprites[1], spriteTop.yScale * numDirSprites[2]
        grpMain:insert(spriteTop)
    end

    -- EVENTS
    img.explode = _explode
    img.destroy = _destroy
    img.blackHole = _blackHole
    img.hit = _hit
    img[2].tap = _onTap
    img[2]:addEventListener("tap", img[2])
    img[2].touch = _onTouch
    img[2]:addEventListener("touch", img[2])
    img.stopMove = _stopMove
    img.move = _move
    img.getCurrentScore = _getCurrentScore

    --print("pos", posTarget, pos)

    -- PROPERTIES
    img.tblPath = {}
    img.isExploding = false
    img.isNotDestroyed = true
    img.currentPathIndex = 1
    img.easing = tbl.easing
    img.size = size
    img.x = tbl.x or TBL_POINTS_STASH[posTarget][pos][1]
    img.y = tbl.y or TBL_POINTS_STASH[posTarget][pos][2]
    img.posLaunched = pos
    img.currentGroup = tbl.currentGroup
    img.angularVelocity = random(10 * img.currentGroup) * (random(2) == 1 and 1 or -1)
    img.isPowerup = tbl.isPowerup
    img.damage = TBL_DAMAGES[size][isAsteroid+1]
    img.score = TBL_SCORES[size][isAsteroid+1]
    img.isTouchable = tbl.isTouchable
    img.camera = camera
    img.timeToTarget = (camera:getTargetPos() ~= 5) and _extractParam(tbl[3]) * .9 or _extractParam(tbl[3])
    img.timeToTarget = img.timeToTarget > NUM_TIME_TO_TARGET_MIN and img.timeToTarget or NUM_TIME_TO_TARGET_MIN
    img.timeToTargetReal = 0
    img.isAsteroid = isAsteroid
    img.isObstacle = true
    img.gravityForce = tbl[6] and _extractParam(tbl[6]) * .1 or nil
    img.dir = dir

    --print(img.timeToTarget)

    local vecPoint = Vector2D:new(img.x, img.y)
    if tbl.xTo then
        vecPoint = Vector2D:new(tbl.xTo, tbl.yTo)
        img.tblPath[#img.tblPath+1] = vecPoint
        img.tblPath[#img.tblPath].numTime = 300
    end
    if isAsteroid == 1 then
        img.generateElipticPath = _generateElipticPath
        img:generateElipticPath(vecPoint)
    else
        local vecDir = Vector2D:Sub(camera:getTarget(), vecPoint)

        local vecRaio = Vector2D:Normalize(vecDir)
        vecRaio:mult(TBL_RAIOS[size], TBL_RAIOS[size])
        vecDir:sub(vecRaio)
        img.tblPath[#img.tblPath+1] = Vector2D:Add(vecPoint, vecDir)
        img.angularVelocity = random(2) == 1 and 270 or -270
        local numTime = img.timeToTarget / (#img.tblPath * 2)
        numTime = numTime < NUM_TIME_TO_ALERT_LIMIT and NUM_TIME_TO_ALERT or numTime
        img.tblPath[#img.tblPath].numTime = numTime

        --print(img.timeToTarget, numTime, NUM_TIME_TO_ALERT_LIMIT)

        if tbl.isTouchable and numTime == NUM_TIME_TO_ALERT then

            tbl.numDelay = 500
            
            img.angularVelocity = random(2) == 1 and 180 or -180
            img[2][1]:setFillColor(0)
            if img[2][2] then
                img[2][2]:setFillColor(0)
            end

            local vecAlert = Vector2D:Normalize(vecDir)
            vecAlert:mult(NUM_SCREEN_PROP)

            local imgAlert = display.newSprite(shtUtilGameplay, {{name="s", start=98, count=1}})
            camera:add(imgAlert, 7)
            local target = camera:getTarget()
            imgAlert.x, imgAlert.y, imgAlert.alpha = target.x - vecAlert.x, target.y - vecAlert.y, 1
            imgAlert.rotation = Vector2D:Vec2deg(vecAlert)
            imgAlert.numTimeToRemove = img.timeToTarget * .6
            imgAlert.numTime = system.getTimer() 
            local _blinkAlert = function() end
            _blinkAlert = function()
                Jukebox:dispatchEvent({name="playSound", id="alert"})
                imgAlert.alpha = 1
                if system.getTimer()  - imgAlert.numTime > imgAlert.numTimeToRemove then
                    if camera and camera.rem then
                        camera:rem(imgAlert, 7)
                        imgAlert = nil
                    end
                else
                    Trt.to(imgAlert, {delay=400, alpha=0, time=100, onComplete=function()
                        Trt.to(imgAlert, {time=300, onComplete=function()
                            _blinkAlert()
                        end})
                    end})
                end
            end
            _blinkAlert()

            local imgTrail = display.newSprite(shtObstacles, {{name="s", frames={137}}})
            grpFx:insert(imgTrail)
            imgTrail:scale(-TBL_EXPLOSIONS_SCALES[img.isAsteroid+1][size] * 11, TBL_EXPLOSIONS_SCALES[img.isAsteroid+1][size] * 1.5)
            imgTrail.anchorX, imgTrail.anchorY = 0, .5
            imgTrail:setFillColor(0)
            imgTrail.rotation = imgAlert.rotation


            local numTime = tbl.numDelay or 0
            img.trtPtm = Trt.to(img, {delay=numTime + 300, onComplete=function(self)
                Jukebox:dispatchEvent({name="playSound", id="meteory"})
            end})
        end
    end
    for i=1, #img.tblPath do
        img.timeToTargetReal = img.timeToTargetReal + img.tblPath[i].numTime
    end

    if tbl.numDelay > 0 then
        img.isVisible = false
        img.trtPtc = Trt.to(img, {delay=tbl.numDelay, onComplete=function(self)
            self.isVisible = true
            self:move()
        end})
    else
        img:move()
    end

    camera:add(img, 5)
    img:toBack()

    Particle.count = Particle.count + 1

    return img
end

return Particle