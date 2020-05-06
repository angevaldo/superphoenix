local Composer = require "composer"
local Widget = require "widget"
local objScene = Composer.newScene()


local Trt = require "lib.Trt"
local Vector2D = require "lib.Vector2D"
local I18N = require "lib.I18N"


local Wgt = require "classes.phoenix.business.Wgt"
local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"
local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"
local Nebula = require "classes.phoenix.entities.Nebula"


local infObstacles = require("classes.infoObstacles")
local shtObstacles = graphics.newImageSheet("images/gameplay/aniObstacles.png", infObstacles:getSheet())
local infUtilGameplay = require("classes.infoUtilGameplay")
local shtUtilGameplay = graphics.newImageSheet("images/gameplay/scnUtilGameplay.png", infUtilGameplay:getSheet())
local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random
local round = math.round


local _TBL_FRAMES_EXPLOSION = {{{10, 23}, {33, 19}}, {{61, 23}, {84, 19}}}
local _TIMER_MIN = 500

local function _lerp(v0, v1, t)
    return t * (v1 - v0)
end

local function _animeCounter(target, value, duration, onComplete)
    Runtime:removeEventListener("enterFrame", updateText)

    local valueNew = string.gsub(target.text, ",", "")
    local passes = duration * .03
    local increment = _lerp(valueNew, value, 1/passes)

    local count = 0
    local function updateText()
        if count < passes then
            valueNew = valueNew + increment
            target.text = " "..Util:formatNumber(string.format("%d", valueNew))
            count = count + 1
        else
            target.text = " "..Util:formatNumber(string.format("%d", value))
            Runtime:removeEventListener( "enterFrame", updateText )
            if onComplete then
                onComplete()
            end
        end
    end

    Runtime:addEventListener("enterFrame", updateText)
end

local function _onSuspendResume(event) end

function objScene:create(event)
    local grpView = self.view


    local numTimeOnScreen = 2000 - Controller.ai:getGroup() * 100
    local numScoreT = 0
    local numTimeDropped = 0
    local numCountHitted = 0
    local numTimeTimer = 1


    local _starSortPositionTo = function(self)
        local vecTo = Vector2D:new(0, 400)
        vecTo:rotateVector(random(360))
        self.vecTo = vecTo

        local vecFrom = Vector2D:Mult(vecTo, random(2) * .025)
        self.x, self.y = vecFrom.x, vecFrom.y
        self.xScale, self.yScale = .2, .2
        self.alpha = 0
        self.rotation = Vector2D:Vec2deg(vecTo)
        self.delay = random(0, 8) * 100
        self.numTime = random(10, 15) * 100
    end

    local _starAnimate = function(self)
        self:sortPosition()
        local alphaTo = 1
        Trt.to(self, {type=2, x=self.vecTo.x, y=self.vecTo.y, time=self.numTime, delay=self.delay, xScale=4, yScale=1.5, alpha=alphaTo, transition="inExpo", onComplete=function()
            if self.vecTo then
                self:animate()
            end
        end})
    end

    local _getStarField = function()
        local grpStarField = display.newGroup()
        for i=1,60 do
            local sptStar = display.newSprite(shtUtilGameplay, { {name="standard", frames={99}} })
            sptStar.width = sptStar.width * random(1, 3)
            sptStar.animate = _starAnimate
            sptStar.sortPosition = _starSortPositionTo
            grpStarField:insert(sptStar)

            sptStar:animate()
        end

        return grpStarField
    end


    local bntPauseEvent = function(event) end
    _onSuspendResume = function(event)
        if "applicationSuspend" == event.type then
            bntPauseEvent({phase="began"})
        end
    end
    Runtime:addEventListener("system", _onSuspendResume)


    local rctBright = display.newRect(-10, -10, 500, 350)
    rctBright:setFillColor(0)
    rctBright.anchorX, rctBright.anchorY = 0, 0
    rctBright.alpha = 0

    local sptTimer = {}

    local params = event.params

    local camera = params.camera

    local grpContent = display.newGroup()
    grpView:insert(grpContent)

    local grpBG = display.newGroup()
    grpContent:insert(grpBG)

    local NUM_NEBULA_ID = camera.currentNebula % 5
    NUM_NEBULA_ID = NUM_NEBULA_ID == 0 and 5 or NUM_NEBULA_ID
    local rctBg = display.newRect(grpBG, 0, 0, 1200, 1200)
    rctBg.fill.effect = "generator.radialGradient"
    rctBg.fill.effect.color1 = {Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][1][1] * .9, Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][1][2] * .9, Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][1][3] * .9}
    rctBg.fill.effect.color2 = {Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][2][1] * 1.6, Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][2][2] * 1.6, Nebula.TBL_GRADIENTS[NUM_NEBULA_ID][2][3] * 1.6}
    rctBg.fill.effect.center_and_radiuses  =  {0.5, 0.5, 0, .25}
    rctBg.fill.effect.aspectRatio  = 1
    rctBg.anchorX, rctBg.anchorY = .5, .5
    rctBg.x, rctBg.y = 0, 0

    local grpFx1 = display.newGroup()
    grpBG:insert(grpFx1)
    for i=1, 8 do
        local numFrame = random(5)
        local imgFx = display.newSprite(shtUtilGameplay, { {name="standard", frames={1+numFrame}} })
        imgFx.anchorX, imgFx.anchorY = 0, .5
        imgFx.x, imgFx.y = 0, 0
        imgFx.alpha = random(0, 20) * .01
        imgFx.rotation = i * 45
        grpFx1:insert(imgFx)
    end
    grpFx1:scale(2, 2)
    Trt.to(grpFx1, {type=2, rotation=grpFx1.rotation + 2000, time=60000})
    grpBG:insert(grpFx1)

    local grpFx2 = display.newGroup()
    grpBG:insert(grpFx2)
    for i=1, 8 do
        local numFrame = random(5)
        local imgFx = display.newSprite(shtUtilGameplay, { {name="standard", frames={1+numFrame}} })
        imgFx.anchorX, imgFx.anchorY = 0, .5
        imgFx.x, imgFx.y = 0, 0
        imgFx.alpha = random(0, 20) * .01
        imgFx.rotation = i * 45
        grpFx2:insert(imgFx)
    end
    grpFx2:scale(2, 2)
    Trt.to(grpFx2, {type=2, rotation=grpFx2.rotation - 2000, time=100000})
    grpBG:insert(grpFx2)

    grpBG:insert(_getStarField())

    grpBG.anchorChildren = true
    grpBG.anchorX, grpBG.anchorY = .5, .5
    grpBG.x, grpBG.y = display.contentCenterX, display.contentCenterY

    local grpHud = display.newGroup()
    grpView:insert(grpHud)

    local tblTxtOptions = {
        parent = grpView,
        text = " 0 ",
        font = "Maassslicer",
        fontSize = 30,
        align = "left"
    }

    local txtScoreT = display.newText(tblTxtOptions)
    txtScoreT:setFillColor(0, 0, 0, .4)
    txtScoreT.anchorX, txtScoreT.anchorY = 0, 1
    txtScoreT.x, txtScoreT.y = Constants.LEFT, Constants.BOTTOM

    local tblTxtOptions = {
        parent = grpHud,
        text = I18N:getString("waveBonus"),
        font = "Maassslicer",
        fontSize = 35,
        align = "center"
    }

    local txtTitle = display.newText(tblTxtOptions)
    txtTitle:setFillColor(1, 1, 1)
    txtTitle.anchorX, txtTitle.anchorY = .5, .5
    txtTitle.x, txtTitle.y = display.contentCenterX, display.contentCenterY
    txtTitle:scale(.01, .01)

    local tblTxtOptions = {
        parent = grpHud,
        text = "",
        font = "Maassslicer",
        fontSize = 35,
        align = "center"
    }

    local txtMessage = display.newText(tblTxtOptions)
    txtMessage:setFillColor(1)
    txtMessage.anchorX, txtMessage.anchorY = .5, 0
    txtMessage.x, txtMessage.y, txtMessage.isVisible = display.contentCenterX, Constants.TOP-txtMessage.height * 2, false

    local tblTxtOptions = {
        parent = grpHud,
        text = "",
        width = 128,
        font = "Maassslicer",
        fontSize = 30,
        align = "center"
    }

    local txtScore = display.newText(tblTxtOptions)
    txtScore:setFillColor(1, 1, 1)
    txtScore.anchorX, txtScore.anchorY = .5, .5

    local sptObstacle = nil

    local _drop = {}
    local _sort = {}
    local _onTouch = {}
    local _onSpriteExplode = {}
    local _bonusEnded = {}
    local _move = {}
    local _start = {}

    local trtMoveCancel = nil
    _move = function()
        local x, y = random(display.contentCenterX - 100, display.contentCenterX + 100), random(display.contentCenterY - 100, display.contentCenterY + 100)

        if trtMoveCancel ~= nil then 
            Trt.cancel(trtMoveCancel) 
            trtMoveCancel = nil 
        end
        trtMoveCancel = Trt.to(grpBG, {type=2, x=x, y=y, time=200, transition="outQuad", onComplete=function()
            _sort()
        end})
    end

    _onSpriteExplode = function(self, event)
        if event.phase == "ended" and self.parent then
            _move()

            self.parent:remove(self)
            self = nil

            sptObstacle = nil
        end
    end

    _drop = function(x, y)
        local numDir = random(2) == 1 and -1 or 1
        local isAsteroid = random(2) == 1 and 1 or 0

        local numScale1 = .4
        local numScale2 = .7
        local numScale3 = .8
        local numOriginX, numOriginY = grpBG.x, grpBG.y
        local vecDirection2 = Vector2D:new(x - numOriginX, y - numOriginY)
        local vecDirection3 = Vector2D:Normalize(vecDirection2)
        vecDirection3:mult(100)
        vecDirection3:add(vecDirection2)
        local vecDirection1 = Vector2D:Mult(vecDirection2, numScale2)
        local numFrameBottom = isAsteroid == 1 and random(7, 9) or random(58, 60)
        local numFrameTop = isAsteroid == 1 and random(7, 9) or random(58, 60)
        local numRot = random(360) * numDir
        local numRotTo = random(4, 7) * 100 * numDir
        
        local numTimeScale = .2 + numCountHitted * .025
        numTimeTimer = numTimeOnScreen * .4 / numTimeScale

        local numPitch = 1 + numCountHitted * .01
        Jukebox:setPitch(numPitch)

        local grpImg = display.newGroup()

        local grpObstacle = display.newGroup()
        grpImg:insert(grpObstacle)

        local numIndexFrames = isAsteroid == 1 and 1 or 2
        local i = random(2)
        local spriteBottom = display.newSprite(shtObstacles, {
            {name="s", start=numFrameBottom, count=1},
            {name="e", start=_TBL_FRAMES_EXPLOSION[numIndexFrames][i][1], count=_TBL_FRAMES_EXPLOSION[numIndexFrames][i][2], time=500, loopCount=1},
        })
        spriteBottom.sprite = _onSpriteExplode
        spriteBottom.rotation = random(360)
        spriteBottom.isAsteroid = isAsteroid
        grpObstacle:insert(spriteBottom)

        local spriteTop = display.newSprite(shtObstacles, {
            {name="s", start=numFrameTop, count=1}
        })
        spriteTop.alpha = isAsteroid == 1 and 1 or (random(4, 8) * .1)
        grpObstacle:insert(spriteTop)

        sptTimer = display.newSprite(shtUtilGameplay, {{name="s", start=49, count=49, time=numTimeTimer - 50, loopCount=1}})
        sptTimer:setFillColor(0, .2)
        sptTimer.rotation = -numRot
        sptTimer.xScale, sptTimer.yScale = 1.7, 1.7
        sptTimer.numFrame = 1
        sptTimer:pause()
        grpImg:insert(sptTimer)

        grpImg.anchorX, grpImg.anchorY = .5, .5
        grpImg.x, grpImg.y = numOriginX, numOriginY
        grpImg.xScale, grpImg.yScale, grpImg.alpha, grpImg.rotation = numScale1, numScale1, 0, numRot
        grpContent:insert(grpImg)

        -- SOUND
        Jukebox:dispatchEvent({name="playSound", id="bonusObstacle"})

        -- ANIM ROTATION
        grpObstacle.cnlTransition = Trt.to(grpObstacle, {type=2, rotation=numRotTo * .7, time=numTimeOnScreen * .2, transition="inQuad", onComplete=function()
            if grpObstacle.rotation then
                grpObstacle.cnlTransition = Trt.to(grpObstacle, {type=2, rotation=numRotTo * .9, time=numTimeOnScreen * .4, transition="outQuad", onComplete=function()
                    if grpObstacle.rotation then
                        grpObstacle.cnlTransition = Trt.to(grpObstacle, {type=2, rotation=numRotTo, time=100, transition="outQuad"})
                    end
                end})
            end
        end})

        -- ANIM DIRECTION
        grpImg.cnlTransition = Trt.to(grpImg, {type=2, x=numOriginX+vecDirection1.x, y=numOriginY+vecDirection1.y, xScale=numScale2, yScale=numScale2, alpha=1, time=numTimeOnScreen * .2, transition="inQuad", onComplete=function()
            if grpImg.rotation then

                sptTimer:play()
                numTimeDropped = system.getTimer()
                Trt.timeScaleAll(numTimeScale)

                grpObstacle.touch = _onTouch
                grpObstacle:addEventListener("touch", grpObstacle)

                grpImg.cnlTransition = Trt.to(grpImg, {type=2, xScale=numScale3, yScale=numScale3, x=numOriginX+vecDirection2.x, y=numOriginY+vecDirection2.y, time=numTimeOnScreen * .4, transition="outQuad", onComplete=function()

                    sptTimer.isVisible = false
                    Trt.timeScaleAll(1)

                    if grpImg.rotation then
                        grpObstacle:removeEventListener("touch", grpObstacle)
                        grpImg.cnlTransition = Trt.to(grpImg, {type=2, xScale=3, yScale=3, x=numOriginX+vecDirection3.x, y=numOriginY+vecDirection3.y, time=100, transition="outQuad", onComplete=function()
                            _bonusEnded()
                        end})
                    end
                end})
            end
        end})
    end

    _sort = function()
        local numBorder = 40
        local x = numBorder + random(Constants.RIGHT - numBorder * 2)
        local y = numBorder * 2 + random(Constants.BOTTOM - numBorder * 4)

        _drop(x, y)

        numTimeOnScreen = numTimeOnScreen > _TIMER_MIN and numTimeOnScreen - 50 or numTimeOnScreen
    end

    _onTouch = function(self, event)
        if event.phase == "began" then
            self:removeEventListener("touch", self)

            Trt.timeScaleAll(1)

            local strId = (self.isAsteroid == 1) and "stone" or "ice"
            Jukebox:dispatchEvent({name="playSound", id=strId})

            local grpImg = self.parent
            if grpImg.cnlTransition ~= nil then
                Trt.cancel(grpImg.cnlTransition)
                grpImg.cnlTransition = nil
            end
            if self.cnlTransition ~= nil then
                Trt.cancel(self.cnlTransition)
                self.cnlTransition = nil
            end

            numCountHitted = numCountHitted + 1

            local numPerc = (system.getTimer() - numTimeDropped) / numTimeTimer
            local numScoreAdd = round((1 - numPerc) * 40) * 10
            numScoreAdd = numScoreAdd < 0 and 0 or numScoreAdd
            numScoreT = numScoreT + numScoreAdd
            _animeCounter(txtScoreT, numScoreT, 1000)

            if txtScore.cnlTransition ~= nil then
                Trt.cancel(txtScore.cnlTransition)
                txtScore.cnlTransition = nil
            end
            txtScore.x, txtScore.y = grpImg.x - 10, grpImg.y
            txtScore.text = " +"..Util:formatNumber(numScoreAdd)
            txtScore.alpha = 0
            txtScore:scale(.5, .5)
            txtScore.cnlTransition = Trt.to(txtScore, {type=2, alpha=1, time=300, xScale=1, yScale=1, transition="outBack", onComplete=function()
                txtScore.cnlTransition = Trt.to(txtScore, {type=2, delay=100, alpha=0, time=300})
            end})

            if numCountHitted % 5 == 0 then
                Jukebox:dispatchEvent({name="playSound", id="stage"})

                local numTextId = numCountHitted > 25 and 25 or numCountHitted
                local yTo = Constants.TOP-txtMessage.height * 2
                txtMessage.text = I18N:getString("bonus"..numTextId)
                txtMessage.y, txtMessage.alpha, txtMessage.isVisible = yTo, 1, true
                transition.to(txtMessage, {y=Constants.TOP, transition=easing.outExpo, time=300, onComplete=function()
                    transition.to(txtMessage, {alpha=0, delay=800, time=400, onComplete=function()
                        txtMessage.y, txtMessage.isVisible = yTo, false
                    end})
                end})
            end

            sptObstacle = self[1]
            sptObstacle:setSequence("e")
            if random(2) == 1 then
                sptObstacle.xScale = -1.5
            else
                sptObstacle.xScale = 1.5
            end
            if random(2) == 1 then
                sptObstacle.yScale = -1.5
            else
                sptObstacle.yScale = 1.5
            end
            sptObstacle:play()
            sptObstacle:addEventListener("sprite", sptObstacle)

            self[2].isVisible = false

            local sptTimer = grpImg[2]
            sptTimer:pause()
            transition.to(sptTimer, {xScale=.1, yScale=.1, time=300, onComplete=function()
                grpImg:remove(sptTimer)
            end})

        end
    end

    _bonusEnded = function()
        if camera.addScore then
            camera:addScore(numScoreT)
        end
        
        Trt.cancelType(2)

        camera:hide(false)

        rctBright.isVisible = true
        rctBright.alpha = 1

        grpContent.isVisible = false
        grpHud.isVisible = false
        txtScoreT.isVisible = false

        if grpView.onComplete then
            grpView.onComplete()
        end

        local txtScore = display.newText(grpView, " +"..Util:formatNumber(numScoreT), 0, 0, "Maassslicer", 60)
        txtScore:setFillColor(0)
        txtScore.anchorX, txtScore.anchorY = .5, .5
        txtScore.alpha = 0
        txtScore.x, txtScore.y = Constants.LEFT + txtScore.width * .5, Constants.BOTTOM - txtScore.height * .5
        txtScore:scale(.1, .1)

        Trt.to(rctBright, {type=2, alpha=0, delay=100, time=300})
        Trt.to(txtScore, {type=2, transition="outBack", delay=100, alpha=1, time=400, xScale=1, yScale=1, onComplete=function()

            Trt.to(txtScore, {type=2, time=300, onComplete=function()
                Controller:setStatus(1, true)
            end})
            Composer.hideOverlay(true, "fade", 301)

        end})
    end

    _start = function ()
        if camera.isGameOver then

            Controller:setStatus(1, true)
            Composer.hideOverlay(true, "fade", 0)

        else

            Trt.to(txtTitle, {type=2, xScale=1, yScale=1, time=600, transition="outBack", onComplete=function()
                if txtScoreT.height then
                    _move()

                    Trt.to(txtTitle, {type=2, xScale=.9, yScale=.9, time=300, transition="inQuad", alpha=0, onComplete=function()
                        if txtTitle.height then
                            txtTitle.y, txtTitle.isVisible = Constants.TOP, false
                        end
                    end})
                end
            end})
            
        end
    end

    grpView:insert(rctBright)
    camera:hide(true)
    camera:blink()
    transition.to(rctBright, {time=100, onComplete=function()
        if rctBright then
            rctBright.isVisible = false
        end
        _start()
    end})

    bntPauseEvent = function(event)
        if "began" == event.phase and Controller:validateNextStatus(2) then
            Trt.pauseType(2)
            Jukebox:dispatchEvent({name="stopMusic"})
            Controller:setStatus(2, true)

            if sptObstacle ~= nil and sptObstacle.sequence == "e" then
                sptObstacle:pause()
            end

            if sptTimer.pause ~= nil then
                sptTimer:pause()
            end

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
                grpMenu[i]:scale(.01, .01)
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
                if sptObstacle ~= nil and sptObstacle.sequence == "e" then
                    sptObstacle:play()
                end
                if sptTimer.play ~= nil then
                    sptTimer:play()
                end
                Trt.resumeType(2)
                Controller:setStatus(5, true)
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
    local bntPause = Widget.newButton{
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

        Controller:setStatus(5, true)
        
        Jukebox:dispatchEvent({name="playSound", id="woosh"})
        timer.performWithDelay(400, function()
            Jukebox:dispatchEvent({name="playSound", id="yes"})
        end, 1)
        
        Trt.resumeType(2)

    end

    --[[
    grpView:scale(.2, .2)
    grpView.x, grpView.y = display.contentCenterX, display.contentCenterY
    --]]
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        Trt.timeScaleAll(1)
        Jukebox:setPitch(1)
        Jukebox:dispatchEvent({name="playSound", id="shoow"})

    elseif phase == "did" then

        parent:overlayEnded(true)
        Runtime:removeEventListener("system", _onSuspendResume)

    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene