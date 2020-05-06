local Composer = require "composer"
local objScene = Composer.newScene()
local Widget = require "widget"


local Trt = require "lib.Trt"
local I18N = require "lib.I18N"
local Vector2D = require "lib.Vector2D"


local Wgt = require "classes.phoenix.business.Wgt"
local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"
local Jukebox = require "classes.phoenix.business.Jukebox"
local Powerup = require "classes.phoenix.entities.Powerup"
local Constants = require "classes.phoenix.business.Constants"
local Nebula = require "classes.phoenix.entities.Nebula"
local Star = require "classes.phoenix.entities.Star"


local infObstacles = require("classes.infoObstacles")
local shtObstacles = graphics.newImageSheet("images/gameplay/aniObstacles.png", infObstacles:getSheet())
local infUtilGameplay = require("classes.infoUtilGameplay")
local shtUtilGameplay = graphics.newImageSheet("images/gameplay/scnUtilGameplay.png", infUtilGameplay:getSheet())
local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())
local infNebulaIntro = require("classes.infoNebulaIntro")
local shtNebulaIntro = graphics.newImageSheet("images/gameplay/bkgNebulaIntro.jpg", infNebulaIntro:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random
local round = math.round
local pow = math.pow
local abs = math.abs
local cos = math.cos
local sin = math.sin
local pi  = math.pi


local _onSuspendResume = function(event) end


local CANCEL_ALERT


function objScene:create(event)
    local grpView = self.view


    local params = event.params
    local camera = params.camera

    local numScoreAdd = 500 * camera.currentNebula
    local numCountBots = 2 + camera.currentNebula
    local tblBots = {}
    local imgStar = params.imgStar


    local NUM_DAMAGE_BOT = -10
    local NUM_DIST_TO_BOT = 9 + Controller.ai:getGroup() * .5
    local NUM_TIME_TO_CHALLENGE = 3 
    local NUM_TIME_INTERVAL_BOTS = 5000
    local NUM_TAPS_TO_DESTROY_TOTAL = 4 + camera.currentNebula * 2
    local NUM_TAPS_TO_DESTROY_CURRENT = NUM_TAPS_TO_DESTROY_TOTAL


    -- RESETING TIMESCALE
    Trt.timeScaleAll(1)


    local bntPause = {}
    local bntPauseEvent = function(event) end
    _onSuspendResume = function(event)
        if NUM_TAPS_TO_DESTROY_CURRENT > 0 and "applicationSuspend" == event.type then
            bntPauseEvent({phase="began"})
        end
    end
    Runtime:addEventListener("system", _onSuspendResume)


    local count
    local oldX, oldY, dx, dy = grpView.x, grpView.y, grpView.x, grpView.y
    local _doShake = function() end
    _doShake = function()
        count = count + .1
        dx = pow (4, -count) * (random(2) == 1 and 1 or -1) * 4
        dy = pow (4, -count) * (random(2) == 1 and 1 or -1) * 4
        grpView.x, grpView.y = oldX + dx, oldY + dy
        if grpView.cnlShake ~= nil then transition.cancel(grpView.cnlShake) end
        grpView.cnlShake = transition.to(grpView, {time=30, onComplete=function()
            if grpView.x then
                if count < .2 then
                    _doShake()
                else
                    grpView.x, grpView.y = oldX, oldY
                end
            end
        end})
    end
    local function _doShakeAnime()
        count = -.2
        _doShake()
    end

    local NUM_NEBULA_ID = (camera.currentNebula - 1) % 5
    NUM_NEBULA_ID = NUM_NEBULA_ID == 0 and 5 or NUM_NEBULA_ID
    local rctBg = display.newRect(grpView, 0, 0, 500, 350)
    rctBg.fill.effect = "generator.radialGradient"
    rctBg.fill.effect.color1 = Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][1]
    rctBg.fill.effect.color2 = Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][2]
    rctBg.fill.effect.center_and_radiuses  =  {0.5, 1, 0, 1}
    rctBg.fill.effect.aspectRatio  = 1.5
    rctBg.anchorX, rctBg.anchorY = .5, .5
    rctBg.x, rctBg.y = display.contentCenterX, display.contentCenterY

    local rctTouch = display.newRect(grpView, 0, 0, 500, 350)
    rctTouch:setFillColor(0)
    rctTouch.anchorX, rctTouch.anchorY = 0, 0
    rctTouch.alpha = .01

    local grpContent = display.newGroup()
    grpView:insert(grpContent)

    local grpFx = display.newGroup()
    grpContent:insert(grpFx)

    local _moveFx = function(self)
        if self and self.x then
            local xTo = -60
            if self.x < display.contentCenterX then
                xTo = 500
            end
            local tTo = random(4, 10) * 500
            Trt.to(self, {x=xTo, time=tTo, onComplete=function()
                if self and self.moveFx then
                    self.x = random(2) == 1 and -60 or 500
                    self:moveFx()
                end
            end})
        end
    end
    for i=1, 15 do
        local rctFx  = display.newRect(grpFx, 0, 0, random(15, 20) * 10, 350)
        rctFx:setFillColor(Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][1][1], Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][1][2], Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][1][3], random(3,6) * .01)
        rctFx.x, rctFx.y = random(0, 25) * 25, display.contentCenterY
        rctFx.moveFx = _moveFx

        transition.to(grpView, {time=1, onComplete=function() 
            if rctFx and rctFx.moveFx then 
                rctFx:moveFx() 
            end
        end})
    end


    local grpStar = display.newGroup()
    grpContent:insert(grpStar)

    local sptStarIcing = display.newSprite(shtUtilGameplay, {{name="standard", start=9, count=1}})
    grpStar:insert(sptStarIcing)
    sptStarIcing.anchorX, sptStarIcing.anchorY = .5, 1
    sptStarIcing.x, sptStarIcing.y = 0, 28

    local sptMagma = display.newSprite(shtUtilGameplay, {{name="standard", start=101, count=1}})
    grpStar:insert(sptMagma)
    sptMagma.anchorX, sptMagma.anchorY = .5, 1
    sptMagma.x, sptMagma.y = 0, 28
    sptMagma.fill.effect = Star.TBL_COLORS[NUM_NEBULA_ID][1]
    if Star.TBL_COLORS[NUM_NEBULA_ID][1] ~= nil then
        sptMagma.fill.effect.r = Star.TBL_COLORS[NUM_NEBULA_ID][2]
        sptMagma.fill.effect.g = Star.TBL_COLORS[NUM_NEBULA_ID][3]
        sptMagma.fill.effect.b = Star.TBL_COLORS[NUM_NEBULA_ID][4]
        sptMagma.fill.effect.a = Star.TBL_COLORS[NUM_NEBULA_ID][5]
    end

    local sptStarBright = display.newSprite(shtUtilGameplay, {{name="standard", start=8, count=1}})
    grpStar:insert(sptStarBright)
    sptStarBright.anchorX, sptStarBright.anchorY = .5, 1
    sptStarBright.x, sptStarBright.y = 0, 28
    sptStarBright:setFillColor(1, 1, .2)

    local grpShield = display.newGroup()
    for i=1, imgStar.numQttShieldsActive do
        local sptStarShield = display.newSprite(shtUtilGameplay, {{name="standard", start=8, count=1}})
        grpShield:insert(sptStarShield)
        sptStarShield.anchorX, sptStarIcing.anchorY = .5, 1
        sptStarShield.x, sptStarShield.y = 0, - i * 1 - 22
        sptStarShield:setFillColor(Powerup.tblColors[1][1], Powerup.tblColors[1][2], Powerup.tblColors[1][3])
    end
    grpStar:insert(grpShield)

    grpStar.anchorX, grpStar.anchorY = .5, 1
    grpStar.x, grpStar.y = display.contentCenterX, Constants.BOTTOM + grpStar.height


    local grpHud = display.newGroup()
    grpView:insert(grpHud)


    local grpShot = display.newGroup()
    grpView:insert(grpShot)


    local tblTxtOptions = {
        parent = grpHud,
        text = I18N:getString("waveChallenge"),
        font = "Maassslicer",
        fontSize = 128,
        align = "center"
    }
    local txtTitle = display.newText(tblTxtOptions)
    txtTitle:setFillColor(1)
    txtTitle.anchorX, txtTitle.anchorY = .5, .5


    local _getScale = function(y)
        local numScale = .3 + (y / ((Constants.BOTTOM - 30) * 1.7)) * 2
        numScale = numScale > 1 and 1 or numScale
        -- print(y, numScale)
        return numScale
    end


    local _start = {}
    local _cleanMemory = {}
    local _onTouch = {}
    local _transitionCinematic = {}
    local _challengeWin = {}
    local _challengeLoose = {}
    local _onSpriteDestroy = {}
    local _shot = {}
    local _drop = {}
    local _moveStar = {}
    local _moveTopBottomChallenge = {}
    local _moveChallenge = {}
    local _moveBot = {}
    local _newBot = {}
    local _onTouchBot = {}
    local _hit = {}
    local _adjustApereance = {}
    local _getRandomX = {}

    _moveStar = function(self)
        self.trtCancel = Trt.to(self, {y=Constants.BOTTOM + 2, time=1000, onComplete=function()
            self.trtCancel = Trt.to(self, {y=Constants.BOTTOM - 2, time=1000, onComplete=function()
                if self and self.moveStar then
                    self:moveStar()
                end
            end})
        end})
    end

    -- CHALLENGE
    local grpChallenge = display.newGroup()
    grpChallenge.numTimeToHide = os.time() - NUM_TIME_TO_CHALLENGE + 2.5

    local grpImgChallenge = display.newGroup()
    grpImgChallenge.isActive = true
    grpImgChallenge.isSmokeActive = false
    local numIdRelativeNebula = camera.currentNebula - 1 > 5 and 5 or camera.currentNebula - 1
    for i=1, numIdRelativeNebula do
        local imgChallenge = display.newSprite(shtObstacles, {{name="standard", frames={109+i}}})
        grpImgChallenge:insert(imgChallenge)
        if i > 3 then
            imgChallenge:toBack()
        end
    end
    local imgChallengeNeon = display.newSprite(shtObstacles, {{name="standard", frames={115}}})
    transition.blink(imgChallengeNeon, {time=1500})
    grpImgChallenge:insert(imgChallengeNeon)

    grpChallenge:insert(grpImgChallenge)

    local function _addSmoke(obj)
        if obj and obj.x then
            local sptSmoke = display.newSprite(shtObstacles, {{name="s", start=random(139,141), count=1}})
            grpHud:insert(sptSmoke)
            sptSmoke.alpha = 0
            sptSmoke:scale(.6, .6)

            local numDist = random(1, 5) * 10
            local angle = random(360) * 0.017453292519943295769236907684886
            local s = sin(angle)
            local c = cos(angle)
            local tblPos = {numDist * c, round(numDist * s)}
            sptSmoke.x, sptSmoke.y = obj.x + obj.parent.x + tblPos[1] * .3, obj.y + obj.parent.y + 30 + tblPos[2] * .1

            local tblFrom = {obj.x + obj.parent.x + tblPos[1] * .4, obj.y + obj.parent.y + 30 + tblPos[2] * .2}
            local tblTo = {obj.x + obj.parent.x + tblPos[1] * .8, obj.y + obj.parent.y + 30 + tblPos[2] * .8}
            local numRot = random(-360, 360)
            local numTime = random(1, 2) * 1500
            local numScale = _getScale(sptSmoke.y) * 3.5
            transition.to(sptSmoke, {alpha=1, x=tblFrom[1], y=tblFrom[2], xScale=.6+numScale*.2, yScale=.6+numScale*.2, time=numTime*.1, rotation=numRot*.2, onComplete=function()
                transition.to(sptSmoke, {alpha=0, x=tblTo[1], y=tblTo[2], xScale=.6+numScale*.8, yScale=.6+numScale*.8, time=numTime*.9, rotation=numRot*.8, onComplete=function()
                    if sptSmoke and sptSmoke.parent and sptSmoke.parent.remove then
                        sptSmoke.parent:remove(sptSmoke)
                    end
                    sptSmoke = nil
                end})
            end})
        end
    end

    local _activateSmoke = function(obj) end
    _activateSmoke = function(obj)
        if obj ~= nil then
            obj.isSmokeActive = true
            local numDelay = random(10, 20) * 100
            timer.performWithDelay(numDelay, function()
                _addSmoke(obj)
            end, 1)
            local numPerc = NUM_TAPS_TO_DESTROY_CURRENT / NUM_TAPS_TO_DESTROY_TOTAL
            timer.performWithDelay(numPerc * 1500, function()
                _activateSmoke(obj)
            end, 1)
        end
    end

    _getRandomX = function()
        if grpChallenge and grpChallenge.width then
            local xTo = random(Constants.LEFT + grpChallenge.width * .5, Constants.RIGHT - grpChallenge.width * .5)
            if abs(xTo - grpChallenge.x) < 100 and _getRandomX then
                xTo = _getRandomX()
            end
            return xTo
        end
        return 240
    end

    _moveChallenge = function(self)
        if self.y then
            if self.numTimeToHide + NUM_TIME_TO_CHALLENGE < os.time() then
                self.trtCancel1 = Trt.to(self, {type=1, y=-200, time=700, transition="outQuad", onComplete=function()
                    if self and self.width then
                        self.x = _getRandomX()
                        local numTime = 2000 + camera.currentNebula * 1000
                        local numScale = _getScale(-100)

                        self.trtCancel1 = Trt.to(self, {type=1, delay=numTime, xScale=numScale, yScale=numScale, y=-100, transition="inOutBack", time=700, onComplete=function()
                            self.numTimeToHide = os.time()
                            if self and self.move then
                                self:move()
                            end
                        end})
                    end
                end})
            else
                local xTo = _getRandomX()
                local yTo = Constants.TOP + random(0, 11) * 10


                local numDelay = random(5, 12) * 100
                local numTime = 10 - camera.currentNebula * 2
                local numScale = _getScale(yTo)
                numTime = (numTime < 3 and 3 or numTime) * 100
                self.trtCancel1 = Trt.to(self, {type=1, x=xTo, y=yTo, xScale=numScale, yScale=numScale, time=numTime, transition="inOutBack", delay=numDelay, onComplete=function()
                    if self and self.move then
                        self:move()
                    end
                end})
            end
        end
    end
    grpChallenge.move = _moveChallenge

    _destroyChallenge = function(self)

        Jukebox:dispatchEvent({name="playSound", id="challengeExploding"})

        local _doShakeChallenge = function() end
        local _numRotChallenge = 0
        local _numDirChallenge = 1
        _doShakeChallenge = function ()
            _numDirChallenge = _numDirChallenge * - 1
            _numRotChallenge = _numRotChallenge + 1

            if _numRotChallenge > 30 then
                _transitionCinematic()
            else
                Trt.to(grpImgChallenge, {time=100 - _numRotChallenge * 2, rotation=_numRotChallenge * _numDirChallenge, onComplete=_doShakeChallenge})
            end
        end
        _doShakeChallenge()
    end
    grpChallenge.destroy = _destroyChallenge

    grpChallenge.anchorChildren = true
    grpChallenge.anchorX, grpChallenge.anchorY = .5, 0
    grpChallenge.x, grpChallenge.y = _getRandomX(), -100
    grpChallenge.xScale, grpChallenge.yScale = .4, .4
    grpHud:insert(grpChallenge)


    local grpPercent = display.newGroup()
    grpHud:insert(grpPercent)
    local rctBar = display.newRect(grpPercent, 0, 0, 200, 5)
    rctBar.anchorX, rctBar.anchorY = 0, .5
    rctBar.x, rctBar.y = 0, 0
    rctBar:setFillColor(1, .6)
    local rctPercent = display.newRect(grpPercent, 0, 0, 200, 5)
    rctPercent.anchorX, rctPercent.anchorY = 0, .5
    rctPercent.x, rctPercent.y = 0, 0
    rctPercent:setFillColor(0)

    grpPercent.anchorChildren = true
    grpPercent.anchorX, grpPercent.anchorY = .5, 0
    grpPercent.x, grpPercent.y, grpPercent.alpha = display.contentCenterX, Constants.TOP + 5, 0


    local grpPercentStar = display.newGroup()
    grpHud:insert(grpPercentStar)
    local rctBarStar = display.newRect(grpPercentStar, 0, 0, 200, 5)
    rctBarStar.anchorX, rctBarStar.anchorY = 0, .5
    rctBarStar.x, rctBarStar.y = 0, 0
    rctBarStar:setFillColor(1, .6)
    local rctPercentStar = display.newRect(grpPercentStar, 0, 0, 200, 5)
    rctPercentStar.anchorX, rctPercentStar.anchorY = 0, .5
    rctPercentStar.x, rctPercentStar.y = 0, 0
    rctPercentStar:setFillColor(.9, 0, 0)
    rctPercentStar.xScale = imgStar.health * .01

    grpPercentStar.anchorChildren = true
    grpPercentStar.anchorX, grpPercentStar.anchorY = .5, 1
    grpPercentStar.x, grpPercentStar.y, grpPercentStar.alpha = display.contentCenterX, Constants.BOTTOM - 5, 0


    _cleanMemory = function()
        collectgarbage()
    end

    _adjustApereance = function()
        local numAlpha = .2 + imgStar.health * .01
        if sptStarBright.CANCEL_ALPHA ~= nil then
            transition.cancel(sptStarBright.CANCEL_ALPHA)
            sptStarBright.CANCEL_ALPHA = nil 
        end
        sptStarBright.CANCEL_ALPHA = transition.to(sptStarBright, {alpha=numAlpha, time=300})

        local numAlpha = imgStar.health * .01
        if sptMagma.CANCEL_ALPHA ~= nil then
            transition.cancel(sptMagma.CANCEL_ALPHA)
            sptMagma.CANCEL_ALPHA = nil 
        end
        sptMagma.CANCEL_ALPHA = transition.to(sptMagma, {alpha=numAlpha, time=300})
    end
    _adjustApereance()

    -- ALERT
    local grpAlert = display.newGroup()
    local rctAlert = display.newRect(grpAlert, 0, 0, 500, 350)
    rctAlert.anchorX, rctAlert.anchorY = .5, .5
    rctAlert.fill.effect = "generator.radialGradient"
    rctAlert.fill.effect.color1 = {0, 0, 0}
    rctAlert.fill.effect.color2 = {1, 0, 0}
    rctAlert.fill.effect.center_and_radiuses  =  {0.5, 0.5, .3, 1}
    rctAlert.fill.effect.aspectRatio = 1
    grpAlert.isVisible, grpAlert.alpha = false, 1
    grpAlert.x, grpAlert.y = display.contentCenterX, display.contentCenterY
    grpHud:insert(grpAlert)
    _verifyAlert = function()
        if imgStar.health < Star.HEALTH_LIMIT + 1 then
            if CANCEL_ALERT ~= nil then
                transition.cancel(CANCEL_ALERT)
                CANCEL_ALERT = nil
            end
            local numTime = imgStar.health * 100
            numTime = numTime < 1000 and 1000 or numTime
            if not grpAlert.isVisible then
                grpAlert.isVisible = true
            end
            Jukebox:dispatchEvent({name="playSound", id="alert"})
            grpAlert.alpha = 1
            CANCEL_ALERT = transition.blink(grpAlert, {time=numTime, iterations=-1, onRepeat=function()
                if grpAlert and grpAlert.alpha then
                    grpAlert.alpha = 1
                    Jukebox:dispatchEvent({name="playSound", id="alert"})
                end
            end})
        end
    end
    _verifyAlert()

    _hit = function()
        if grpChallenge then
            local isLoose = false

            if imgStar:addHealth(NUM_DAMAGE_BOT, true) then

                camera:turnoffCombo()

                if imgStar.health > 0 then
                    _doShakeAnime()
                    _verifyAlert()
                else
                    isLoose = true
                end

                _adjustApereance()
                
                if rctPercentStar.cnlScale ~= nil then
                    Trt.cancel(rctPercentStar.cnlScale)
                    rctPercentStar.cnlScale = nil
                end
                local numScale = imgStar.health * .01 + .001
                rctPercentStar.cnlScale = Trt.to(rctPercentStar, {type=1, xScale=numScale, time=200, transition="outQuad", onComplete=function()
                    if isLoose then
                        _challengeLoose()
                    end
                end})

            else

                local sptStarShield = grpShield[imgStar.numQttShieldsActive+1]
                if sptStarShield then
                    Trt.to(sptStarShield, {alpha=0, yScale=4, xScale=3, time=1000, onComplete=function(obj)
                        if grpShield and grpShield.remove then
                            grpShield:remove(obj)
                        end
                        obj = nil
                    end})
                end

            end

            _adjustApereance()
        end
    end

    _onTouchChallenge = function(self, event)
        if event.phase == "began" then
            if self.isActive then
                
                self.isActive = false
                Trt.to(grpView, {type=1, time=200, onComplete=function()
                    if self and self.y then 
                        self.isActive = true
                    end
                end})

                Jukebox:dispatchEvent({name="playSound", id="spaceshipHit"})

                NUM_TAPS_TO_DESTROY_CURRENT = NUM_TAPS_TO_DESTROY_CURRENT - 1
                local numScale = NUM_TAPS_TO_DESTROY_CURRENT / NUM_TAPS_TO_DESTROY_TOTAL
                numScale = numScale > 0 and numScale or .01
                if rctPercent.cnlScale ~= nil then
                    Trt.cancel(rctPercent.cnlScale)
                    rctPercent.cnlScale = nil
                end
                if NUM_TAPS_TO_DESTROY_CURRENT == 0 then
                    Trt.cancel(grpChallenge.trtCancel1)
                    Trt.cancel(grpChallenge.trtCancel2)
                end
                rctPercent.cnlScale = Trt.to(rctPercent, {type=1, xScale=numScale, time=200, transition="outQuad", onComplete=function()
                    if NUM_TAPS_TO_DESTROY_CURRENT == 0 then
                        _challengeWin()
                    end
                end})

                imgChallengeNeon:setFillColor(numScale, numScale, numScale)

                if not grpImgChallenge.isSmokeActive then
                    _activateSmoke(grpImgChallenge)
                end

                -- DESTROYED
                if NUM_TAPS_TO_DESTROY_CURRENT == 0 then

                    -- REMOVE TOUCHS
                    grpChallenge[1]:removeEventListener("touch", grpChallenge[1])
                    rctTouch:removeEventListener("touch", rctTouch)
                    bntPause.isVisible = false

                    local numTime = 1200 / (#tblBots + 2)
                    for i=1, #tblBots do
                        local botTemp = tblBots[i]
                        if botTemp.setFillColor then
                            botTemp:setFillColor(0)
                            botTemp:removeEventListener("touch", botTemp)
                            if botTemp.trtCancel then
                                transition.cancel(botTemp.trtCancel)
                                botTemp.trtCancel = nil
                            end
                            botTemp.trtCancel = Trt.to(botTemp, {time=(i - 1) * numTime, onComplete=function()
                                if botTemp and botTemp.destroy then
                                    Jukebox:dispatchEvent({name="playSound", id="spaceshipExplosion"})
                                    botTemp:destroy()
                                end
                            end})
                        end
                    end

                end
            end
        end
        return false
    end

    _transitionCinematic = function()

        -- REMOVE OBJECTS
        grpView:remove(grpContent)
        grpView:remove(grpHud)

        rctBg.fill.effect.center_and_radiuses  =  {0.5, 0.5, 0, 1}
        rctBg.fill.effect.aspectRatio  = 1

        -- FX
        local grpCinematic = display.newGroup()

        local grpFx1 = display.newGroup()
        grpCinematic:insert(grpFx1)
        for i=1, 8 do
            local numFrame = random(4)
            local imgFx = display.newSprite(shtUtilGameplay, { {name="standard", frames={1+numFrame}} })
            imgFx:setFillColor(Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][1][1], Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][1][2], Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][1][3])
            imgFx.anchorX, imgFx.anchorY = 0, .5
            imgFx.x, imgFx.y = 0, 0
            imgFx.alpha = random(0, 20) * .01
            imgFx.rotation = i * 45
            grpFx1:insert(imgFx)
        end
        grpFx1:scale(2, 2)
        Trt.to(grpFx1, {type=1, rotation=grpFx1.rotation - 2000, time=60000})
        grpCinematic:insert(grpFx1)

        local grpFx2 = display.newGroup()
        for i=1, 8 do
            local numFrame = random(4)
            local imgFx = display.newSprite(shtUtilGameplay, { {name="standard", frames={1+numFrame}} })
            imgFx:setFillColor(Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][1][1], Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][1][2], Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][1][3])
            imgFx.anchorX, imgFx.anchorY = 0, .5
            imgFx.x, imgFx.y = 0, 0
            imgFx.alpha = random(0, 20) * .01
            imgFx.rotation = i * 45
            grpFx2:insert(imgFx)
        end
        grpFx2:scale(2, 2)
        Trt.to(grpFx2, {type=1, rotation=grpFx2.rotation + 2000, time=70000})
        grpCinematic:insert(grpFx2)

        local imgExplosion = display.newSprite(shtObstacles, { {name="e", start=121, count=1} })
        imgExplosion:scale(4, 4)
        imgExplosion:rotate(random(360))
        imgExplosion:setFillColor(0)
        Trt.to(imgExplosion, {type=1, transition="outQuad", xScale=5, yScale=5, time=1000})
        grpCinematic:insert(imgExplosion)


        local tblPos = {{{-20,0},{-250,0}}, {{0,0},{-250,-230}}, {{-20,10},{-200,100}}, {{0,0},{230,240}}, {{0,-20},{130,-140}}, {{0,-10},{0,-150}}, {{10,-10},{180,-300}}, {{0,0},{150,0}}, {{0,10},{0,200}}}
        local grpParticles = display.newGroup()
        grpCinematic:insert(grpParticles)

        for i=1, #tblPos do
            local imgParticle = display.newSprite(shtObstacles, {{name="s", start=random(142,145), count=1}})
            imgParticle:rotate(random(-360, 360))
            imgParticle.x, imgParticle.y = tblPos[i][1][1], tblPos[i][1][2]
            grpParticles:insert(imgParticle)

            local numScaleFromX, numScaleFromY = random(2, 4) * .1, random(2, 4) * .1
            local numScaleToX, numScaleToY = random(8, 10) * .1, random(8, 10) * .1
            local easingTemp = random(2) == 1 and easing.outQuad or easing.outExpo
            local numAlpha = random(0, 10) * .1
            local numTime = random(20, 40) * 100

            imgParticle:scale(numScaleFromX, numScaleFromY)
            transition.to(imgParticle, {transition=easingTemp, alpha=numAlpha, rotation=random(-100, 100), xScale=numScaleToX, yScale=numScaleToY, x=tblPos[i][2][1], y=tblPos[i][2][2], time=numTime})
        end
        grpParticles:rotate(random(360))

        grpCinematic.anchorChildren = true
        grpCinematic.anchorX, grpCinematic.anchorY = .5, .5
        grpCinematic.x, grpCinematic.y = display.contentCenterX, display.contentCenterY

        local tblTxtOptions = {
            parent = grpCinematic,
            text = I18N:getString("waveChallengeWin"),
            font = "Maassslicer",
            fontSize = 100,
            align = "center"
        }
        local txtWin = display.newText(tblTxtOptions)
        txtWin:setFillColor(1)
        txtWin.anchorX, txtWin.anchorY = .5, .5
        txtWin.x, txtWin.y = 0, 0
        Trt.to(txtWin, {type=1, xScale=.5, yScale=.5, time=500, transition="outBack"})

        grpView:insert(grpCinematic)

        -- SOUND
        Jukebox:dispatchEvent({name="stopMusic"})
        Jukebox:dispatchEvent({name="playSound", id="challengeExploded"})
        Jukebox:dispatchEvent({name="playSound", id="challengeWin"})

        -- GROUP NEBULA TRANSITION
        local grpNext = display.newGroup()
        grpView:insert(grpNext)

        -- FADE
        local rctFrame = display.newRect(grpView, -10, -10, 500, 350)
        rctFrame:setFillColor(0)
        rctFrame.anchorX, rctFrame.anchorY = 0, 0
        rctFrame.alpha = 0

        -- ANIME
        transition.to(rctFrame, {delay=300, time=500, alpha=1, onComplete=function()

            local numFrame = NUM_NEBULA_ID + 1 == 6 and 1 or NUM_NEBULA_ID + 1
            local imgBkg = display.newSprite(shtNebulaIntro, { {name="s", frames={numFrame}} })
            imgBkg:scale(1, 1)
            imgBkg.anchorX, imgBkg.anchorY = .5, .5
            imgBkg.x, imgBkg.y = display.contentCenterX, display.contentCenterY --+ 10
            grpNext:insert(imgBkg)

            local tblTxtOptions = {
                parent = grpNext,
                text = I18N:getString("waveChallengeNext") .. " "..numFrame,
                font = "Maassslicer",
                fontSize = 40,
                align = "center"
            }
            local txtNext = display.newText(tblTxtOptions)
            txtNext:setFillColor(1)
            txtNext.anchorX, txtNext.anchorY = .5, 0--.5
            txtNext.x, txtNext.y = display.contentCenterX, Constants.TOP + 5--display.contentCenterY - 5--Constants.TOP + 5
            txtNext.alpha = 0
            txtNext:scale(.9, .9)

            numScoreAdd = Controller.isPassThrough and 0 or numScoreAdd
            local strScore = Controller.isPassThrough and "" or " +"..Util:formatNumber(numScoreAdd)
            local txtScore = display.newText(grpView, strScore, 0, 0, "Maassslicer", 60)
            txtScore:setFillColor(1)
            txtScore.anchorX, txtScore.anchorY = .5, .5
            txtScore.alpha = 0
            txtScore.x, txtScore.y = Constants.LEFT + txtScore.width * .5, Constants.BOTTOM - txtScore.height * .5
            txtScore:scale(.1, .1)
            grpNext:insert(txtScore)

            if camera and camera.addScore then
                camera:addScore(numScoreAdd)
            end

            Jukebox:dispatchEvent({name="playMusic", id=2})

            transition.to(imgBkg, {yScale=1.05, xScale=1.05, time=3000})
            transition.to(rctFrame, {alpha=0, time=500, onComplete=function()

                _cleanMemory()
                
                transition.to(txtScore, {transition=easing.outBack, delay=100, alpha=1, time=300, xScale=1, yScale=1, onComplete=function()

                    -- REMOVE OBJECTS
                    grpView:remove(grpCinematic)

                    -- UPDATE GAMEPLAY
                    camera:updateNebula()
                    camera:hide(false)
                    if params.onComplete then
                        params.onComplete()
                    end

                    transition.to(txtNext, {delay=100, alpha=1, xScale=1, yScale=1, time=1500, transition=easing.outExpo})

                    transition.to(txtScore, {time=800, onComplete=function()

                        Composer.hideOverlay(true, "fade", 500)
                        Controller:setStatus(1, true)
                        Controller.isPassThrough = false

                    end})

                end})

            end})

        end})

    end

    _challengeWin = function()
        grpView:remove(grpShot)

        -- CANCEL ALERT
        if CANCEL_ALERT ~= nil then
            transition.cancel(CANCEL_ALERT)
            CANCEL_ALERT = nil
        end

        -- PERCENTS
        transition.to(grpPercent, {alpha=0, time=500})
        transition.to(grpPercentStar, {alpha=0, time=500})

        -- CANCEL OBJECTS
        Trt.cancelType(1)
        
        -- HIDE STAR
        if grpStar.trtCancel ~= nil then
            Trt.cancel(grpStar.trtCancel)
        end
        grpStar.trtCancel = nil
        transition.to(grpStar, {y=Constants.BOTTOM + 100, time=500})

        -- SHAKE
        grpChallenge:destroy()
    end

    _challengeLoose = function()
        if rctTouch and rctTouch.removeEventListener and grpHud.isVisible then

            -- CANCEL ALERT
            if CANCEL_ALERT ~= nil then
                transition.cancel(CANCEL_ALERT)
                CANCEL_ALERT = nil
            end

            -- CANCEL OBJECTS
            Trt.cancelType(1)

            rctTouch:removeEventListener("touch", rctTouch)
            rctTouch:toFront()
            rctTouch.alpha = 1

            for i=1, #tblBots do
                local imgBot = tblBots[i]
                if imgBot.removeEventListener then
                    imgBot:removeEventListener("touch", imgBot)
                end
            end

            grpContent.isVisible = false
            grpHud.isVisible = false

            camera:hide(false)

            Composer.hideOverlay(true, "fade", 0)
            Trt.to(grpView,{type=1, time=1, onComplete=function()
                _cleanMemory()
                Controller:setStatus(1)
                if camera and camera.doGameOver then
                    camera:doGameOver(true)
                end
            end})

        end
    end

    _moveBot = function(self, yTo, numDelay)
        local xTo = random(Constants.LEFT + 30, Constants.RIGHT - 30)
        local isOnStar = false
        if yTo > Constants.BOTTOM - 50 then
            isOnStar = true
            yTo = Constants.BOTTOM - 10 + abs(display.contentCenterX - xTo) * .15
        end
        
        local transitionType = "inExpo"
        local numTime = isOnStar and 1500 or random(8, 12) * 100

        local numScaleTo = _getScale(yTo)
        self.trtCancel = Trt.to(self, {type=1, x=xTo, y=yTo, xScale=numScaleTo, yScale=numScaleTo, delay=numDelay, time=numTime, transition=transitionType, onComplete=function()
            if self and self.move and grpChallenge then
                if isOnStar then
                    _hit()
                    self:destroy()
                else
                    local _yTo = self.y + random(NUM_DIST_TO_BOT - 5, NUM_DIST_TO_BOT) * 10
                    local _numDelay = random(0, 2) * 200
                    self:move(_yTo, _numDelay)
                end
            end
        end})
    end

    _onSpriteDestroy = function (self, event)
        if event.phase == "ended" then
            local numScaleTo = self.xScale + .3 
            Trt.to(self, {alpha=0, xScale=numScaleTo, yScale=numScaleTo, time=1000, onComplete=function()
                if self and self.parent then
                    self.parent:remove(self)
                    self = nil
                end
            end})
        end
    end

    _destroyBot = function(self)
        if self.sequence ~= "e" and self.scale then
            self:removeEventListener("touch", self)

            if self.trtCancel ~= nil then
                Trt.cancel(self.trtCancel)
            end
            self.trtCancel = nil

            self:scale(.8, .8)
            self:rotate(random(360))
            self:setFillColor(.1)
            self:setSequence("e")
            self:play()
            self:addEventListener("sprite", self)
        end
    end


    _onTouchBot = function(self, event)
        if event.phase == "began" then
            Jukebox:dispatchEvent({name="playSound", id="spaceshipExplosion"})

            self:destroy()
        end
        return false
    end

    _newBot = function()
        if grpContent.insert then
            local numFramesExplosion = random(2,4)
            local numTimeExplosion = 60 * numFramesExplosion
            local imgBot = display.newSprite(shtObstacles, {
                {name="s", start=127, count=10, time=800},
                {name="e", start=117, count=numFramesExplosion, time=numTimeExplosion, loopCount=1},
            })
            imgBot:scale(.5, .5)
            imgBot:play()
            imgBot:rotate(random(360))
            imgBot.anchorX, imgBot.anchorY = .5, .5
            imgBot.x, imgBot.y = grpChallenge.x, grpChallenge.y + grpChallenge.height * .3
            tblBots[#tblBots+1] = imgBot
            imgBot.index = #tblBots

            local numScaleTo = _getScale(imgBot.y)
            imgBot.xScale, imgBot.yScale = numScaleTo, numScaleTo

            imgBot.move = _moveBot
            imgBot.destroy = _destroyBot
            imgBot.sprite = _onSpriteDestroy
            imgBot.touch = _onTouchBot
            imgBot:addEventListener( "touch", imgBot )

            grpContent:insert(imgBot)
            local yTo = random(5, 10) * 10
            imgBot:move(yTo, 0)
        end
    end

    _drop = function(isRecursive)
        for i=1, numCountBots do
            Trt.to(grpView, {type=1, time=i * 1000, onComplete=_newBot})
        end
        numCountBots = numCountBots > 8 and 8 or numCountBots + 1
        if isRecursive then
            Trt.to(grpView, {type=1, time=NUM_TIME_INTERVAL_BOTS, onComplete=function()
                _drop(isRecursive)
            end})
        end
    end

    _shot = function(self, event)
        if event.phase == "began" then
            local shot = display.newSprite(shtUtilGameplay, {{name="standard", start=36, count=1}})

            local numRGB = imgStar.health * .02
            numRGB = numRGB > 1 and 1 or numRGB
            shot:setFillColor(numRGB, numRGB, numRGB)

            local xFrom = event.x - (display.contentCenterX - event.x) * .5
            local yFrom = Constants.BOTTOM + 20
            shot.x, shot.y, shot.xScale, shot.yScale = xFrom, yFrom, 1, 1
            grpShot:insert(shot)

            Trt.to(shot, {type=1, x=event.x, y=event.y, xScale=.6, yScale=.6, time=200, transition="outQuad", onComplete=function()
                if shot.xScale then
                    Trt.to(shot, {type=1, time=500, xScale=.01, yScale=.01, onComplete=function()
                        if grpShot and grpShot.remove then
                            grpShot:remove(shot)
                        end
                        shot = nil
                    end})
                end
            end})
        end
    end

    _start = function()
        if camera and camera.isGameOver then
            Controller:setStatus(1, true)
            Composer.hideOverlay(true, "fade", 0)
        end

        Trt.to(grpStar, {type=1, y=Constants.BOTTOM - 5, time=500, transition="outQuad"})

        if rctTouch and rctTouch.addEventListener then
            _drop()

            grpStar.moveStar = _moveStar
            grpStar:moveStar()

            rctTouch.touch = _shot
            rctTouch:addEventListener("touch", rctTouch)

            -- PERCENTS
            transition.to(grpPercent, {alpha=1, delay=500, time=500})
            transition.to(grpPercentStar, {alpha=1, delay=500, time=500})

            grpChallenge:move()
            grpChallenge[1].touch = _onTouchChallenge
            grpChallenge[1]:addEventListener("touch", grpChallenge[1])
            _drop(true)
        end
    end


    grpView:insert(rctTouch)
    txtTitle.x, txtTitle.y, txtTitle.alpha = display.contentCenterX, display.contentCenterY, 1
    if Controller.isPassThrough then
        _transitionCinematic()
    else
        Trt.to(txtTitle, {type=1, xScale=.4, yScale=.4, time=500, transition="outBack", onComplete=function()
            Trt.to(txtTitle, {type=1, xScale=.38, yScale=.38, time=500, alpha=0, onComplete=function()
                if txtTitle.y then
                    txtTitle.y, txtTitle.isVisible = Constants.TOP, false
                end
            end})
        end})
        Trt.to(rctTouch, {type=1, time=100, onComplete=function()
            _start()
        end})
    end


    bntPauseEvent = function(event)
        if "began" == event.phase and Controller:validateNextStatus(2) then
            Trt.pauseType(1)
            Jukebox:dispatchEvent({name="stopMusic"})
            Controller:setStatus(2, true)

            local grpPause = display.newGroup()
            grpView:insert(grpPause)

            local rctOverlay = display.newRect(grpPause, -10, -10, 500, 350)
            local function _onTouchPause(self, event)
                return true
            end
            rctOverlay.touch = _onTouchPause
            rctOverlay:addEventListener("touch", rctOverlay)
            rctOverlay.anchorX, rctOverlay.anchorY = 0, 0
            rctOverlay:setFillColor(0, 1)


            local grpMenu = display.newGroup()
            local numButtonDistance = 60

            local function bntEffectsRelease(event)
                local isSoundActive = not Controller:getData():getProfile("isSoundActive")
                Controller:getData():setProfile("isSoundActive", isSoundActive)
                event.target:setFillColor(isSoundActive and 1 or .4)
                Jukebox:activateSounds(isSoundActive)
                return false
            end
            local bntEffects = Wgt.newButton{
                sheet = shtButtons,
                defaultFrame = 12,
                onRelease = bntEffectsRelease
            }
            bntEffects.x, bntEffects.y = numButtonDistance * 0, 0
            grpMenu:insert(bntEffects)

            local function bntSoundRelease(event)
                local isMusicActive = not Controller:getData():getProfile("isMusicActive")
                Controller:getData():setProfile("isMusicActive", isMusicActive)
                event.target:setFillColor(isMusicActive and 1 or .4)
                Jukebox:activateMusics(isMusicActive)
                return false
            end
            local bntSound = Wgt.newButton{
                sheet = shtButtons,
                defaultFrame = 13,
                onRelease = bntSoundRelease
            }
            bntSound.x, bntSound.y = numButtonDistance * 1, 0
            grpMenu:insert(bntSound)

            local function bntResetRelease(event)
                Composer.stage.alpha = 0

                local options = {
                    effect = "fade",
                    time = 0,
                    params = {isReload=true}
               }
                Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
                return false
            end
            local bntReset = Wgt.newButton{
                sheet = shtButtons,
                defaultFrame = 15,
                onRelease = bntResetRelease
            }
            bntReset.x, bntReset.y = numButtonDistance * 2, 0
            grpMenu:insert(bntReset)

            grpMenu.anchorChildren = true
            grpMenu.anchorX, grpMenu.anchorY = .5, .5
            for i=1, grpMenu.numChildren do
                grpMenu[i]:scale(.1, .1)
            end
            grpMenu.x, grpMenu.y = display.contentCenterX, display.contentCenterY

            grpPause:insert(grpMenu)

            if bntEffects and bntEffects[2] then
                bntEffects[2]:setFillColor(Controller:getData():getProfile("isSoundActive") and 1 or .4)
                bntSound[2]:setFillColor(Controller:getData():getProfile("isMusicActive") and 1 or .4)
            end
            if bntEffects then
                transition.to(bntEffects, {xScale=1, yScale=1, transition=easing.outBack, time=250})
                transition.to(bntReset, {xScale=1, yScale=1, transition=easing.outBack, time=250, onComplete=function()
                    if bntSound then
                        transition.to(bntSound, {xScale=1, yScale=1, transition=easing.outBack, time=250})
                    end
                end})
            end


            local function bntMenuRelease(event)
                Composer.stage.alpha = 0

                local options = {
                    effect = "fade",
                    time = 0
                }
                Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
                return true
            end
            local bntMenu = Wgt.newButton{
                sheet = shtButtons,
                defaultFrame = 16,
                onRelease = bntMenuRelease
            }

            local bntBackRelease = function(event)
                grpPause:removeSelf()
                Trt.resumeType(1)
                Controller:setStatus(4, true)
                Util:hideStatusbar()
            end
            local bntPlay = Wgt.newButton{
                sheet = shtButtons,
                defaultFrame = 1,
                onRelease = bntBackRelease
            }
            transition.blink(bntPlay[2], {time=2000})

            Util:generateFrame(grpPause, nil, nil, bntPlay, bntMenu)
        end

        return true
    end
    bntPause = Widget.newButton{
        sheet = shtButtons,
        defaultFrame = 7,
        onEvent = bntPauseEvent
    }
    bntPause.anchorX, bntPause.anchorY = 1, 1
    bntPause.x, bntPause.y = Constants.RIGHT, Constants.BOTTOM
    bntPause.alpha = 1
    grpHud:insert(bntPause)
end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        parent:overlayBegan(true)

    elseif phase == "did" then

        Controller:setStatus(4, true)
        
        Jukebox:dispatchEvent({name="playSound", id="woosh"})

        Trt.resumeType(1)

    end
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "did" then

        if CANCEL_ALERT ~= nil then
            transition.cancel(CANCEL_ALERT)
            CANCEL_ALERT = nil
        end

        parent:overlayEnded(true)
        Runtime:removeEventListener("system", _onSuspendResume)

    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene