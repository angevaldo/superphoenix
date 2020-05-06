local Composer = require "composer"
local Widget = require "widget"


local Trt = require "lib.Trt"
local Vector2D = require "lib.Vector2D"
local I18N = require "lib.I18N"


local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"
local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"


local Star = require "classes.phoenix.entities.Star"
local Nebula = require "classes.phoenix.entities.Nebula"
local Powerup = require "classes.phoenix.entities.Powerup"


local infUtilGameplay = require("classes.infoUtilGameplay")
local shtUtilGameplay = graphics.newImageSheet("images/gameplay/scnUtilGameplay.png", infUtilGameplay:getSheet())
local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random
local pow = math.pow
local sqrt = math.sqrt
local floor = math.floor


local ViewPort = {}


local CANCEL_ALERT


local function new(grpViewParent, mode)
    local grpView = display.newGroup()
    
    grpView.codAssist = 0
    grpView.isFrozen = false
    grpView.isGameOver = false
    grpView.numMultiplier = 1
    Trt.timeScaleAll(1)

    local bntPauseEvent = function(event)
        if event.phase == "began" and not grpView.isGameOver and Controller.status == 1 then
            Controller:showSceneOverlay(2)
            Trt.timeScaleAll(1)
        end
        return true
    end

    local NUM_RECORD = Controller:getData():getDecryptedScore()
    local IS_RECORD_BEATEN = false
    local CURRENT_HOW_TO_PLAY = Controller:getData():getProfile("nCurrentHowToPlayID")
    local IS_HOW_TO_PLAY = CURRENT_HOW_TO_PLAY < 6
    local NUM_VORTEX_SIZE = IS_HOW_TO_PLAY and 220 or Controller:getData():getStore("3").v
    local NUM_VORTEX_PROP = .5 + (NUM_VORTEX_SIZE / Controller:getData():getStore("3").s[10]) * .5
    local NUM_DELAY_STANDARD = IS_HOW_TO_PLAY and 0 or 500
    local NUM_ID_STAGE_CURRENT = 1
    local IS_GAMEOVER_IN_CHALLENGE = false

    local layer = {true, true, true, true, true, true, true}
    local numLayers = 7
    local mode = mode or 1
    local cnlBonus = nil
    local countUntouchables = 0
    local countDestroyed = 0
    local countCombos = 0
    local stats = {}
    local statsProfile = {}

    local _tblStashTap = {}
    grpView.tblStashTap = _tblStashTap
    local _tblStashTouch = {}
    grpView.tblStashTouch = _tblStashTouch

    local grpNebula = display.newGroup()

    local grpHud = display.newGroup()
    grpHud.isVisible = false
    grpHud.alpha = 0

    local grpContent = display.newGroup()

    grpView:insert(grpNebula)
    grpView:insert(grpHud)
    grpView:insert(grpContent)


    local bntPause = Widget.newButton{
        sheet = shtButtons,
        defaultFrame = 7,
        onEvent = bntPauseEvent
    }
    bntPause.anchorX, bntPause.anchorY = 1, 1
    bntPause.x, bntPause.y = Constants.RIGHT, Constants.BOTTOM
    bntPause.alpha = 1
    grpHud:insert(bntPause)

    local tblTxtOptions = {
        parent = grpHud,
        width = 400,
        font = "Maassslicer",
        align = "left"
    }

    tblTxtOptions.text = ""
    tblTxtOptions.align = "center"
    tblTxtOptions.fontSize = 20
    local txtTitle = display.newText(tblTxtOptions)
    txtTitle:setFillColor(1)
    txtTitle.anchorX, txtTitle.anchorY = .5, 0
    txtTitle.yTo = IS_HOW_TO_PLAY and Constants.TOP + 25 or Constants.TOP + 5
    txtTitle.x = display.contentCenterX
    txtTitle.isVisible = false
    grpHud:insert(txtTitle)

    tblTxtOptions.text = I18N:getString("best")..":"..Util:formatNumber(NUM_RECORD)
    tblTxtOptions.align = "left"
    tblTxtOptions.fontSize = 9
    local txtRecord = display.newText(tblTxtOptions)
    txtRecord:setFillColor(0, 0, 0, .3)
    txtRecord.anchorX, txtRecord.anchorY = 0, 1
    txtRecord.x, txtRecord.y = Constants.LEFT + 5, Constants.BOTTOM
    grpHud:insert(txtRecord)

    tblTxtOptions.text = " 0 "
    tblTxtOptions.align = "left"
    tblTxtOptions.fontSize = 26
    local txtScore = display.newText(tblTxtOptions)
    txtScore:setFillColor(0, 0, 0, .4)
    txtScore.anchorX, txtScore.anchorY = 0, 1
    txtScore.x, txtScore.y = Constants.LEFT, txtRecord.y - txtRecord.height + 4
    grpView.txtScore = txtScore

    local function _updateScoreText(numValue)
        if txtScore.text then
            txtScore.text = " "..Util:formatNumber(numValue)
            if numValue > NUM_RECORD and not IS_RECORD_BEATEN then
                if not IS_HOW_TO_PLAY then
                    IS_RECORD_BEATEN = true
                    local numX = Constants.LEFT - txtRecord.width - 15
                    transition.to(txtRecord, {x=numX, transition=easing.inExpo, time=500})
                    transition.to(txtScore, {x=numX, transition=easing.inExpo, time=500,onComplete=function()
                        Jukebox:dispatchEvent({name="playSound", id="record"})
                        local strScore = txtScore.text
                        local tblTxtOptions = {
                            parent = grpHud,
                            text = strScore,
                            width = 400,
                            font = "Maassslicer",
                            fontSize = 32,
                            align = "left"
                        }
                        if txtScore.parent then
                            txtScore.parent:remove(txtScore)
                            txtScore = display.newText(tblTxtOptions)
                            txtScore:setFillColor(0, 0, 0, .4)
                            txtScore.anchorX, txtScore.anchorY = 0, 1
                            txtScore.x, txtScore.y = Constants.LEFT - txtScore.width, Constants.BOTTOM
                            grpHud:insert(txtScore)
                            grpView.txtScore = txtScore
                            transition.to(txtScore, {x=Constants.LEFT, transition=easing.outElastic, time=1000})
                        end
                    end})
                end
            end
        end
    end

    tblTxtOptions.text = ""
    tblTxtOptions.fontSize = 24
    local txtMultiplier = display.newText(tblTxtOptions)
    txtMultiplier:setFillColor(0, 0, 0, .4  )
    txtMultiplier.anchorX, txtMultiplier.anchorY = 0, 1
    txtMultiplier.x, txtMultiplier.y, txtMultiplier.isVisible = Constants.LEFT, txtScore.y - txtScore.height + 2, false
    grpHud:insert(txtMultiplier)

    -- UNTOUCHABLES
    local grpUntouchable = display.newGroup()
    local numScale = 0
    local tblDist = {0, 4, 2}
    for i=1, 3 do
        local imgUntouchable = display.newSprite(shtUtilGameplay, {{name="s", start=31, count=2}})
        imgUntouchable.anchorX, imgUntouchable.anchorY = 1, .5
        imgUntouchable.x  = imgUntouchable.width * i - tblDist[i]
        numScale = .4 + i * .2
        imgUntouchable:scale(numScale, numScale)
        grpUntouchable:insert(imgUntouchable)
    end
    
    grpUntouchable.anchorChildren = true
    grpUntouchable.anchorX, grpUntouchable.anchorY = 1, 0
    grpUntouchable.x, grpUntouchable.y = Constants.RIGHT, Constants.TOP - 3
    grpHud:insert(grpUntouchable)
    for i = 1, numLayers do
        layer[i] = display.newGroup()
        grpContent:insert(layer[i])
    end

    function grpView:add(obj, idLayer)
        if layer[idLayer] then
            layer[idLayer]:insert(obj)
        end
    end

    function grpView:rem(obj, idLayer)
        if layer[idLayer] then
            layer[idLayer]:remove(obj)
        end
        obj = nil
    end

    function grpView:setStat(name, value)
        if stats[name] then
            stats[name].v = value
        end
    end

    function grpView:addStat(name, value)
        if stats[name] then
            stats[name].v = stats[name].v + value
        end
    end

    function grpView:getStats()
        return stats
    end

    function grpView:addStatProfile(name, value)
        if statsProfile[name] then
            statsProfile[name].v = statsProfile[name].v + value
        end
    end

    function grpView:getStatsProfile()
        return statsProfile
    end

    -- CONSTRUCT LAYOUT

    -- VORTEX
    local imgVortex = display.newSprite(shtUtilGameplay, {{name="s", start=7, count=1} })
    imgVortex.isVisible = false
    grpView:add(imgVortex, 4)

    -- BRIGHT
    local rctFrame = display.newRect(0, 0, 500, 350)
    rctFrame:setFillColor(0)
    rctFrame.anchorX, rctFrame.anchorY, rctFrame.alpha = 0, 0, 0
    rctFrame.isVisible = false
    grpView:insert(rctFrame)

    -- BG
    local imgNebula = Nebula:new({x=display.contentCenterX,y=display.contentCenterY})
    imgNebula:play()
    grpNebula:insert(imgNebula)

    -- STAR
    local imgStar = Star:new({camera=grpView, x=imgNebula.x, y=imgNebula.y, isHowToPlay=IS_HOW_TO_PLAY, currentHowToPlay=CURRENT_HOW_TO_PLAY})


    -- BONUS
    local grpBonus = display.newGroup()
    grpBonus.isVisible = false
    local numBonusHeight = (Constants.BOTTOM - Constants.TOP - 130) * .22 
    for i = 4, 1, -1 do
        local rctBonusBG = display.newRect(grpBonus, 0,0, 6,numBonusHeight - 2)
        rctBonusBG:setFillColor(0, .1)
        rctBonusBG.anchorX, rctBonusBG.anchorY = .5, 0
        rctBonusBG.x, rctBonusBG.y = 0, (i - 1) * numBonusHeight - numBonusHeight * 2 + 2
    end
    local rctBonus = display.newRect(grpBonus, 0,0, 6,0)
    rctBonus:setFillColor(0)
    rctBonus.alpha = .5
    rctBonus.anchorX, rctBonus.anchorY = .5, 1
    rctBonus.x, rctBonus.y = 0, numBonusHeight * 2
    local sptBonus = display.newSprite(shtUtilGameplay, {
        {name="0", frames={10}, loopCount=1},
        {name="1", frames={11,11,12,13,14,15}, time=360, loopCount=1},
        {name="2", frames={16,16,17,18,19,20}, time=360, loopCount=1},
        {name="3", frames={21,21,22,23,24,25}, time=360, loopCount=1},
        {name="4", frames={26,26,27,28,29,30}, time=360, loopCount=1},
    })
    grpBonus:insert(sptBonus)
    sptBonus.x, sptBonus.y = 1, -numBonusHeight * 2 - sptBonus.height * .5 - 2
    grpBonus.anchorX, grpBonus.anchorY = .5, 1
    grpBonus.x, grpBonus.y = Constants.LEFT - 20, display.contentCenterY
    grpHud:insert(grpBonus)


    -- COMBOS
    local tblCombosStash = {}
    for i=1, 4 do
        local sptCombo = display.newSprite(shtUtilGameplay, {{name="s", frames={1}}})
        sptCombo.anchorX, sptCombo.anchorY = 0, .5
        sptCombo.isVisible = false
        sptCombo.x = Constants.LEFT - 150
        sptCombo.y = grpBonus.y + grpBonus[i].y + grpBonus[i].height * .5 + 2
        grpHud:insert(sptCombo)

        -- TEXT POINTS
        local tblTxtOptions = {
            text = " ",
            font = "Maassslicer",
            fontSize = 20,
            align = "center",
        }
        local txtPoints = display.newText(tblTxtOptions)
        grpView:add(txtPoints, 6)
        txtPoints.anchorX, txtPoints.anchorY = .5, .5
        txtPoints.x, txtPoints.y, txtPoints.alpha = sptCombo.x, sptCombo.y, 0
        sptCombo.txtPoints = txtPoints

        tblCombosStash[i] = sptCombo
    end


    -- COMBO BG
    local grpCombo = display.newGroup()
    grpCombo.currentPos = 5
    grpHud:insert(grpCombo)
    grpCombo:toBack( )
    local rctComboFrame = display.newRect(grpView, 0, 0, 900, 450)
    rctComboFrame.anchorX, rctComboFrame.anchorY = .5, .5
    rctComboFrame.isVisible = false
    rctComboFrame:setFillColor(0, .3)
    grpCombo:insert(rctComboFrame)
    local cirCombo = display.newCircle(0, 0, 500)
    cirCombo.strokeWidth = 500
    cirCombo:setFillColor(1, 1, 1, 0)
    cirCombo:setStrokeColor(0, 0, 0, .05)
    cirCombo.isVisible = false
    grpCombo:insert(cirCombo)
    grpCombo.anchorX, grpCombo.anchorY = .5, .5
    local _doComboAnime = function() end
    _doComboAnime = function(isAnime)
        if cirCombo.trtCancel ~= nil then 
            Trt.cancel(cirCombo.trtCancel) 
            cirCombo.trtCancel = nil
        end
        if isAnime then
            cirCombo.xScale, cirCombo.yScale = .02, .02
            rctComboFrame.isVisible = true
            cirCombo.isVisible = true
            cirCombo.trtCancel = Trt.to(cirCombo, {isLocked=true, delay=700, time=1000, xScale=1, yScale=1, onComplete=function()
                if grpCombo.isVisible then
                    _doComboAnime(isAnime)
                end
            end})
        else
            rctComboFrame.isVisible = false
            cirCombo.isVisible = false
        end
    end
    local _jumpCombo = function(self, params)
        if params.numPos ~= self.currentPos then

            local numX = Star.TBL_POSITIONS[params.numPos][1]
            local numY = params.numPos == 6 and self.y or Star.TBL_POSITIONS[params.numPos][2]
            Trt.to(self, {x=numX, y=numY, time=params.numTime, transition=params.easing, onComplete=params.onComplete})

            if params.numPos ~= 6 then
                self.currentPos = params.numPos
            end

        elseif params.onComplete then
            params.onComplete()
        end
    end
    local _reposition = function(self, numPos)
        self.currentPos = numPos
        self.x = Star.TBL_POSITIONS[self.currentPos][1]
        self.y = Star.TBL_POSITIONS[self.currentPos][2]
    end
    grpCombo.jump = _jumpCombo
    grpCombo.reposition = _reposition


    local grpHudData = display.newGroup()
    grpHud:insert(grpHudData)

    -- SUPER PHOENIX
    local grpSuperPhoenix = display.newGroup()
    grpHudData:insert(grpSuperPhoenix)
    local imgSuperPhoenix = display.newSprite(shtUtilGameplay, {{name="standard", start=45, count=1}})
    imgSuperPhoenix.anchorX, imgSuperPhoenix.anchorY = 1, .5
    imgSuperPhoenix.x, imgSuperPhoenix.y = 2, 0
    imgSuperPhoenix:scale(.5, .5)
    imgSuperPhoenix:setFillColor(Powerup.tblColors[5][1], Powerup.tblColors[5][2], Powerup.tblColors[5][3])
    grpSuperPhoenix:insert(imgSuperPhoenix)
    tblTxtOptions.fontSize = 12
    tblTxtOptions.align = "left"
    tblTxtOptions.width = 40
    tblTxtOptions.text = " :"..Controller:getData():getStore("5").v
    local txtSuperPhoenix = display.newText(tblTxtOptions)
    txtSuperPhoenix:setFillColor(0)
    txtSuperPhoenix.anchorX, txtSuperPhoenix.anchorY = 0, .5
    txtSuperPhoenix.x, txtSuperPhoenix.y = 0, 2
    grpSuperPhoenix:insert(txtSuperPhoenix)
    grpSuperPhoenix.anchorX, grpSuperPhoenix.anchorY = 1, .5
    grpSuperPhoenix.x, grpSuperPhoenix.y = 0, 0

    -- SHOT
    local grpShot = display.newGroup()
    grpHudData:insert(grpShot)
    local imgShot = display.newSprite(shtUtilGameplay, {{name="standard", start=35, count=1}})
    imgShot.anchorX, imgShot.anchorY = 1, .5
    imgShot.x, imgShot.y = 2, 0
    grpShot:insert(imgShot)
    tblTxtOptions.fontSize = 12
    tblTxtOptions.align = "left"
    tblTxtOptions.width = 50
    tblTxtOptions.text = " :"..Controller:getData():getStore("6").v
    local txtShot = display.newText(tblTxtOptions)
    txtShot:setFillColor(0)
    txtShot.anchorX, txtShot.anchorY = 0, .5
    txtShot.x, txtShot.y = 0, 2
    grpShot:insert(txtShot)
    grpShot.anchorX, grpShot.anchorY = 1, .5
    grpShot.x, grpShot.y = grpSuperPhoenix.width * .8, 0

    grpHudData.anchorChildren = true
    grpHudData.anchorX, grpHudData.anchorY = 0, 0
    grpHudData.x, grpHudData.y = Constants.LEFT, Constants.TOP

    -- PICKUP
    local tblPosSuperPhoenix = {grpHudData.x + grpSuperPhoenix[1].x + grpSuperPhoenix[1].width * .25, grpHudData.y + grpSuperPhoenix.y + grpSuperPhoenix.height * .5}
    Powerup:init(grpView, tblPosSuperPhoenix, Controller:getData().store, IS_HOW_TO_PLAY)

    -- FROZEN
    local grpFrozen = display.newGroup()
    local rctOverlay = display.newRect(grpFrozen, 0, 0, 500, 350)
    rctOverlay.anchorX, rctOverlay.anchorY = .5, .5
    rctOverlay.fill.effect = "generator.radialGradient"
    rctOverlay.fill.effect.color1 = {0, 0, 0}
    rctOverlay.fill.effect.color2 = {1, 1, 1}
    rctOverlay.fill.effect.center_and_radiuses  =  {0.5, 0.5, .2, 1.5}
    rctOverlay.fill.effect.aspectRatio = 1
    grpFrozen.isVisible, grpFrozen.alpha = false, 0
    grpFrozen.x, grpFrozen.y = display.contentCenterX, display.contentCenterY
    grpView:add(grpFrozen, 7)

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
    grpView:add(grpAlert, 7)

    local function _unfrozen()
        if grpView and grpView.isFrozen then
            grpView.isFrozen = false
            grpFrozen.isVisible = false
            Trt.timeScaleAll(1)
        end
    end

    local function _frozen()
        grpView.isFrozen = true
        grpFrozen.isVisible = true
        Trt.timeScaleAll(.6)
    end

    function grpView:blink(isIn)
        if rctFrame and rctFrame.alpha > 0 and isIn then
            isIn = false
        end

        rctFrame.alpha = isIn and 0 or 1
        local numAlphaTo = isIn and 1 or 0
        local visibilityTo = isIn and true or false
        rctFrame.isVisible = true

        if rctFrame and rctFrame.trtCancel ~= nil then
            transition.cancel(rctFrame.trtCancel)
            rctFrame.trtCancel = nil
        end
        rctFrame.trtCancel = transition.to(rctFrame, {alpha=numAlphaTo, time=300, onComplete=function()
            if rctFrame then
                rctFrame.isVisible = visibilityTo
            end
        end})
    end

    local function _cleanScreen()
        for j = 1, numLayers  do
            local layerCurrent = layer[j]
            for i = layerCurrent.numChildren, 1, -1  do
                local obj = layerCurrent[i]
                if obj and obj.isObstacle then
                    obj:destroy()
                end
            end
        end

        collectgarbage("collect")
    end

    local function _showSceneOverlay(sceneStatus, params)
        if grpView and Controller:showSceneOverlay(sceneStatus, params) then
            imgStar:dispatchEvent({name="touchOff", target=imgStar})
            if not params.isNotCleanScreen then
                transition.to(grpView, {time=500, onComplete=function()
                    _cleanScreen()
                end})
            end
        end
    end

    local function _touch(event)
        if event.phase == "ended" then
            imgStar:dispatchEvent({name="touchOff", target=imgStar, phase=event.phase})
        else
            imgStar:dispatchEvent({name="touchOn", target=imgStar, phase=event.phase, id=event.id, x=event.x, y=event.y})
        end
    end

    local function _tap(event)
        local numShots = imgStar:shot(event)
        txtShot.text = " :"..numShots
        if numShots == 0 then
            Runtime:removeEventListener("tap", _tap)
        end
    end

    function grpView:turnoffCombo()
        if grpCombo.isVisible then
            _doComboAnime(false)

            grpView.numMultiplier = 1
            txtMultiplier.isVisible = false
        end
    end

    function grpView:hide(isHide)
        grpView.isVisible = not isHide
    end

    local _exit = function()
        Composer.hideOverlay(false, "fade", 0)

        Trt.cancelAll()

        grpView.powerupTouchOn = nil
        grpView.particleTouchOn = nil
        grpView._functionListeners = nil
        grpView._tableListeners = nil

        imgStar.isVisible = false

        local scnCurrent = Composer.getScene(Composer.getSceneName("current"))
        scnCurrent:gameOver()
    end

    function grpView:continue(isContinue)
        Composer.hideOverlay(false, "fade", 0)

        if isContinue then  

            -- SETTING FLAGS
            grpView:listeningTouchEvents(true, true, true)
            grpView.isGameOver = false

            -- RESUME OBJECTS
            local layerCurrent = layer[6]
            local obj = 1
            for i = layerCurrent.numChildren, 1, -1  do
                obj = layerCurrent[i]
                if obj.play then obj:play() end
            end  
            -- ALREADY RESUMING IN OVERLAY ENDING     
            -- Trt.resumeAll()

            -- RENEWING SCREEN
            if IS_GAMEOVER_IN_CHALLENGE then
                imgStar:reset(grpView.currentNebula)
                grpView:verifyAlert()
                
                grpView:showChallenge()
            else
                imgStar:rebirth(grpView.currentNebula)
                _cleanScreen()
            end

        else
            _exit()
        end
    end

    local _starExplodeCallback = function()
        if Controller:getData():getStore("8").v > 0 then
            _showSceneOverlay(10, {camera=grpView, isNotCleanScreen=true})
        else
            _exit()
        end
    end

    function grpView:doGameOver(isChallenge)
        -- GAMEOVER IN CHALLENGE
        IS_GAMEOVER_IN_CHALLENGE = isChallenge

        -- CANCEL ANIMES
        if grpContent.cnlShake ~= nil then
            timer.cancel(grpContent.cnlShake)
            grpContent.cnlShake = nil
            grpContent.x, grpContent.y = oldX, oldY
        end
        if CANCEL_ALERT ~= nil then
            transition.cancel(CANCEL_ALERT)
            CANCEL_ALERT = nil
        end

        -- PAUSE OBJECTS
        local layerCurrent = layer[6]
        local obj = 1
        for i = layerCurrent.numChildren, 1, -1  do
            obj = layerCurrent[i]
            if obj.pause then obj:pause() end
        end
        Trt.pauseAll()

        -- SETTING FLAGS
        imgStar:dispatchEvent({name="touchOff", target=imgStar})
        grpAlert.isVisible = false
        grpView.isGameOver = true
        grpView:listeningTouchEvents(false, true, true)

        imgStar:explode(_starExplodeCallback)
    end

    function grpView:listeningTouchEvents(isListen, isTouch, isTap)
        if isListen then
            if isTouch then
                Runtime:addEventListener("touch", _touch)
            end
            if isTap then
                Runtime:addEventListener("tap", _tap)
            end
        else
            if isTouch then
                Runtime:removeEventListener("touch", _touch)
            end
            if isTap then
                Runtime:removeEventListener("tap", _tap)
            end
            imgStar:dispatchEvent({name="touchOff", target=imgStar})
        end
    end

    function grpView:addPowerup(x, y)
        Powerup:launch(x, y, imgStar.transientSuperPhoenix.v)
    end

    function grpView:addScore(numScore)
        local str = string.gsub(txtScore.text, ",", "")
        local numValue = tonumber(str) + numScore
        if numValue < 0 then
            numValue = 0
        end

        _updateScoreText(numValue)
    end

    function grpView:doSuperPhoenix()
        if Controller:validateNextStatus(6) then

            grpView:addStat("nDoSuperPhoenix", 1)

            local numScore = 0
            local layerCurrent = layer[5]
            local obj
            local tblDestroy = {}

            -- GETTING SCORE TOTAL
            for i = layerCurrent.numChildren, 1, -1  do
                obj = layerCurrent[i]
                if obj and obj.getCurrentScore then
                    numScore = numScore + obj:getCurrentScore() * grpView.numMultiplier
                    tblDestroy[#tblDestroy] = obj
                end
            end

            _showSceneOverlay(6, {camera=grpView, numScore=numScore})

            -- DESTROYING OBJECTS
            timer.performWithDelay(1, function()
                for i = 1, #tblDestroy  do
                    obj = tblDestroy[i]
                    -- PICKUP
                    if obj.isPowerup then
                        grpView:addPowerup(obj.x, obj.y)
                    end
                    -- DESTROY
                    obj:destroy()
                end
            end, 1)
            
            txtSuperPhoenix.text = " :"..imgStar.transientSuperPhoenix.v

            collectgarbage("collect")

            Controller:doSuperPhoenix()

            return true
        end

        return false
    end

    function grpView:destroy()

        if not grpView.isGameOver then
            Trt.cancelAll()

            grpView:listeningTouchEvents(false, true, true)
            grpView.powerupTouchOn = nil
            grpView.particleTouchOn = nil
            grpView._functionListeners = nil
            grpView._tableListeners = nil
            if grpContent.cnlShake ~= nil then 
                timer.cancel(grpContent.cnlShake) 
                grpContent.cnlShake = nil
            end
        end

        for n = numLayers, 1, -1  do
            for i = layer[n].numChildren, 1, -1  do
                if layer[n][1] and layer[n][1].tblPath then
                    layer[n][1]:destroy()
                end
                layer[n]:remove(layer[n][1])
            end
            layer[n]:removeSelf()
            layer[n] = nil
        end

        grpViewParent:remove(grpView)
        grpView = nil

        return true
    end


    function grpView:untouchableEnded()
        if countUntouchables >= 3 then
            if grpView.CANCEL_GAME_OVER_UNTOUCHABLE ~= nil then
                transition.cancel(grpView.CANCEL_GAME_OVER_UNTOUCHABLE)
                grpView.CANCEL_GAME_OVER_UNTOUCHABLE = nil
            end
            grpView.CANCEL_GAME_OVER_UNTOUCHABLE = transition.to(grpView, {time=200, onComplete=function()
                grpView:doGameOver(false)
            end})
        elseif countUntouchables > 0 then
            grpUntouchable[countUntouchables]:setFrame(2)
        end
    end


    local function _untouchableHowToPlay(self)
        if not self.isGameOver then
            self:doGameOver(false)
        end
    end

    local function _untouchable(self, x, y, touchX, touchY, rotation)
        if not self.isGameOver then
            local transientPlanetReflect = Controller:getData():getStore("7")
            if transientPlanetReflect.v > 0 then
                transientPlanetReflect.v = transientPlanetReflect.v - 1
                Controller:getData():setStore("7", transientPlanetReflect)

                local vecDir = Vector2D:new(x - touchX, y - touchY)

                _showSceneOverlay(8, {camera=self, x=x, y=y, rotation=rotation, vecDir=vecDir, numLeft=transientPlanetReflect.v, isNotCleanScreen=true})
            else
                self:turnoffCombo()

                countUntouchables = countUntouchables + 1

                _showSceneOverlay(8, {camera=self, x=x, y=y, numLeft=3-countUntouchables})

                transition.to(self, {time=500, onComplete=function()
                    _cleanScreen()
                end})
            end
        end
    end
    grpView.untouchable = IS_HOW_TO_PLAY and _untouchableHowToPlay or _untouchable


    function grpView:updateNebula()
        self:setStat("nIdNebula", self.currentNebula)
        imgNebula:setNebula(self.currentNebula)
    end


    local _showTextTitle = function(strText, isFadeout)
        txtTitle.text = strText
        txtTitle.isVisible = true
        txtTitle.y = -30

        Trt.to(grpView, {isLocked=true, delay=NUM_DELAY_STANDARD, time=1, onComplete=function()
            Jukebox:dispatchEvent({name="playSound", id="stage"})
        end})

        Trt.to(txtTitle, {isLocked=true, y=txtTitle.yTo, delay=NUM_DELAY_STANDARD, transition="outExpo", time=300, onComplete=function()
            if isFadeout then
                Trt.to(txtTitle, {isLocked=true, y=-30, delay=2000, time=500, transition="inExpo", onComplete=function()
                    txtTitle.isVisible = false
                end})
            end
        end})
    end

    function grpView:showChallenge()
        grpView:hide(true)
        grpView:blink()
        _showSceneOverlay(4, {camera=grpView, imgStar=imgStar, onComplete=function()
            if imgStar then
                imgStar:reset(grpView.currentNebula)
                grpView:verifyAlert()

                Controller:setActiveLaunch(true)

                local strText = I18N:getString("wave").." "..NUM_ID_STAGE_CURRENT.."  /  "..Controller.NUM_MAX_STAGES
                _showTextTitle(strText, true)
            end
        end})
    end

    function grpView:showCurrentHowToPlay(id)
        _showTextTitle(I18N:getString("howToPlay"..id), false)
    end

    function grpView:showCurrentStage(numIdNebula, numIdStage, numPos)
        if grpView then

            imgStar:setActive(false)

            grpView.currentNebula = numIdNebula
            NUM_ID_STAGE_CURRENT = numIdStage

            Trt:cancelUnlocked()

            local strText = I18N:getString("wave").." "..NUM_ID_STAGE_CURRENT.."  /  "..Controller.NUM_MAX_STAGES

            if numIdNebula > 1 and numIdStage == 1 then
                if imgStar.isPerfectDefense then
                    grpView:addStat("nPerfectDefense", 1)
                end

                -- FADE IN
                grpView:blink(true)

                -- ANIMS
                imgStar:jump({numPos=6, numTime=400, easing="inExpo"})
                grpCombo:jump({numPos=6, numTime=400, easing="inExpo"})
                imgNebula:jump({numPos=6, numTime=500, easing="inExpo", onComplete=function()

                    -- CANCEL ALERT
                    if CANCEL_ALERT ~= nil then
                        transition.cancel(CANCEL_ALERT)
                        CANCEL_ALERT = nil
                        grpAlert.isVisible = false
                    end

                    if imgStar then
                        grpView:showChallenge()

                        local numPos = Controller.ai:chooseJumpPos()
                        imgNebula:reposition(numPos)
                        grpCombo:reposition(numPos)
                        imgStar:reposition(numPos)

                        imgStar:setActive(true)

                        -- RESET FLAG PERFECT DEFENSE ONLY NEW NEBULAS
                        imgStar.isPerfectDefense = true
                    end
                end})

            else

                imgStar:jump({numPos=numPos, numTime=800, easing="outExpo"})
                grpCombo:jump({numPos=numPos, numTime=800, easing="outExpo"})
                imgNebula:jump({numPos=numPos, numTime=801, easing="outExpo", onComplete=function()
                    if imgStar then
                        imgNebula:animate()

                        imgStar:setActive(true)

                        Controller:setActiveLaunch(true)

                        _showTextTitle(strText, true)
                    end
                end})

            end
        end
    end

    function grpView:flame()
        imgStar:start()
    end

    function grpView:setActiveStar(isActive)
        imgStar:setActive(isActive)
    end

    local _startHowToPlay = function()
        local grpItems = display.newGroup()
        grpHud:insert(grpItems)
        for i=1,5 do
            local numHeight = CURRENT_HOW_TO_PLAY >= i and 5 or 3
            local rctItem = display.newRect(grpItems, 0, 0, 25, numHeight)
            rctItem.anchorX, rctItem.anchorY = 0, .5
            rctItem.x, rctItem.y = (i - 1) * (rctItem.width + 2) - rctItem.width * .75, 0
            rctItem.alpha = CURRENT_HOW_TO_PLAY == i and 1 or (CURRENT_HOW_TO_PLAY > i and .5 or .1)
        end
        grpItems.anchorX, grpItems.anchorY = .5, 0
        grpItems.x, grpItems.y = display.contentCenterX - grpItems.width * .5 + 20, Constants.TOP + 15

        txtScore.isVisible = false
        txtRecord.isVisible = false
        bntPause.isVisible = false
        grpUntouchable.isVisible = CURRENT_HOW_TO_PLAY >= 4
        grpShot.isVisible = CURRENT_HOW_TO_PLAY >= 3
        grpSuperPhoenix.isVisible = CURRENT_HOW_TO_PLAY >= 5

        Controller:startHowToPlay(grpView)

        imgStar:start()
    end

    local _startPlay = function()
        stats = Controller:getData():getStatsClean()
        statsProfile = Controller:getData():getStatsProfileClean()

        -- COUNT NUM PLAY GAMES
        local nPlayedCount = Controller:getData():getProfile("nPlayedCount")
        nPlayedCount = nPlayedCount + 1
        Controller:getData():setProfile("nPlayedCount", nPlayedCount)

        Controller:start(grpView)

        grpView:listeningTouchEvents(true, true, true)
        imgStar:start()

        -- ASSIST
        Trt.to(txtMultiplier, {time=1, onComplete=function()
            if grpView.codAssist == 13 or grpView.codAssist == 14 then
                grpView.numMultiplier = grpView.codAssist == 13 and 2 or 4
                txtMultiplier.text = " x" .. grpView.numMultiplier
                txtMultiplier.isVisible = true
                _doComboAnime(true)
            elseif grpView.codAssist > 14 then
                Controller.numCurrentNebula = grpView.codAssist - 13
                Controller.isPassThrough = true
            end
        end})

    end

    function grpView:start()
        grpHud.isVisible = true

        Trt.to(grpHud, {isLocked=true, delay=NUM_DELAY_STANDARD, alpha=1, time=300})

        if IS_HOW_TO_PLAY then
            _startHowToPlay()
        else
            _startPlay()
        end

        if Controller:getData():haveAssist() then
            _showSceneOverlay(11, {camera=grpView, isNotCleanScreen=true})
        end

        -- COMMENT ON PRODUCTION
        --[[]
        timer.performWithDelay(500, function()
            _showSceneOverlay(4, {camera=grpView, imgStar=imgStar})
        end, 1)
        timer.performWithDelay(500, function()
            --_showSceneOverlay(5, {camera=grpView, imgStar=imgStar})
        end, 1)
        --]]
    end

    --[
    --grpView:scale(.5, .5)
    --grpView.x, grpView.y = display.contentCenterX * .5, display.contentCenterY * .5
    local oldX, oldY, dx, dy = grpView.x, grpView.y, grpView.x, grpView.y
    local count = 0
    local _doShake = function() end
    _doShake = function(size)
        count = count + .1
        dx = pow (1, -count) * (random(2) == 1 and 1 or -1) * size
        dy = pow (1, -count) * (random(2) == 1 and 1 or -1) * size
        grpView.x, grpView.y = oldX + dx, oldY + dy
        grpView.cnlShake = timer.performWithDelay(30, function()
            if grpView then
                if count < .3 then
                    _doShake(size)
                else
                    grpView.x, grpView.y = oldX, oldY
                end
            end
        end, 1)
    end
    local function _doShakeAnime(size)
        count = -.2 * size
        if grpView.cnlShake ~= nil then timer.cancel(grpView.cnlShake) end
        _doShake(size)
    end
    --]]


    -- METHODS / EVENTS

    local _bonusTimerRepeat = function() end

    local function _bonusTimerAnim()
        if rctBonus.CANCEL_ANIM ~= nil then
            transition.cancel(rctBonus.CANCEL_ANIM)
            rctBonus.CANCEL_ANIM = nil
        end
        rctBonus.CANCEL_ANIM = transition.to(rctBonus, {time=3000, height=rctBonus.height-numBonusHeight, iterations=countCombos, onRepeat=_bonusTimerRepeat, onComplete=function()
            countCombos = 0
            if sptBonus and sptBonus.setSequence then
                sptBonus:setSequence(countCombos.."")
                sptBonus:play()
            end
            if grpBonus.CANCEL_ANIM ~= nil then
                transition.cancel(grpBonus.CANCEL_ANIM)
                grpBonus.CANCEL_ANIM = nil
            end
            grpBonus.CANCEL_ANIM = transition.to(grpBonus, {delay=5000, time=500, x=Constants.LEFT - 20, onComplete=function()
                grpBonus.isVisible = false
            end}) 
        end}) 
    end

    _bonusTimerRepeat = function()
        countCombos = countCombos - 1
        if sptBonus and sptBonus.setSequence then
            sptBonus:setSequence(countCombos.."")
            sptBonus:setFrame(6)
        end
        if countCombos > 0 then
            _bonusTimerAnim()
        end
    end

    local function _showBonus()
        rctBonus.height = countCombos * numBonusHeight
        sptBonus:setSequence(countCombos.."")
        sptBonus:play()
        Jukebox:dispatchEvent({name="playSound", id="combo"})
        grpBonus.isVisible = true

        if grpBonus.CANCEL_ANIM ~= nil then
            transition.cancel(grpBonus.CANCEL_ANIM)
            grpBonus.CANCEL_ANIM = nil
        end
        if countCombos > 3 then
            -- RESET DISPLAY COMBOS
            countCombos = 0
            if Controller:validateNextStatus(5) then
                if rctBonus.CANCEL_ANIM ~= nil then
                    transition.cancel(rctBonus.CANCEL_ANIM)
                    rctBonus.CANCEL_ANIM = nil
                end
                rctBonus.CANCEL_ANIM = Trt.to(rctBonus, {time=250, onComplete=function()
                    -- SHOW BONUS STAGE
                    _showSceneOverlay(5, {camera=grpView, imgStar=imgStar})
                    -- RESET DISPLAY COMBOS
                    countCombos = 0
                    if sptBonus and sptBonus.setSequence then
                        sptBonus:setSequence(countCombos.."")
                        sptBonus:play()
                    end
                    grpBonus.x = Constants.LEFT - 20
                    grpBonus.isVisible = false
                end})
            end
        else
            grpBonus.CANCEL_ANIM = transition.to(grpBonus, {time=500, x=Constants.LEFT + 10, transition=easing.outBack}) 
            _bonusTimerAnim()
        end
    end

    local function _showCombo(id)
        countCombos = countCombos + 1
        local numScale = id * .15 + .4

        local sptCombo = tblCombosStash[countCombos]
        if sptCombo == nil then
            return false
        end

        local txtPoints = sptCombo.txtPoints

        if sptCombo.cnlTransition ~= nil then
            transition.cancel(sptCombo.cnlTransition)
            sptCombo.cnlTransition = nil
        end
        if txtPoints.cnlTransition ~= nil then
            transition.cancel(txtPoints.cnlTransition)
            txtPoints.cnlTransition = nil
        end

        sptCombo.xScale, sptCombo.yScale = numScale, numScale
        sptCombo.x = Constants.LEFT - 150
        sptCombo.alpha = 1
        sptCombo.isVisible = true

        txtPoints.isVisible = true
        txtPoints.x, txtPoints.y, txtPoints.alpha = sptCombo.x, sptCombo.y, 0


        -- UPDATE STATS
        if countCombos == 1 then
            grpView:addStat("nCombosSimple", 1)
        elseif countCombos == 2 then
            grpView:addStat("nCombosDouble", 1)
        elseif countCombos == 3 then
            grpView:addStat("nCombosTriple", 1)
        elseif countCombos == 4 then
            grpView:addStat("nCombosQuad", 1)
        end

        grpView:addStatProfile("nCombos", 1)


        grpView.numMultiplier = grpView.numMultiplier < 6 and (grpView.numMultiplier + 1) or grpView.numMultiplier
        txtMultiplier.text = " x" .. grpView.numMultiplier
        txtMultiplier.isVisible = true

        if not rctComboFrame.isVisible then
            grpCombo.x, grpCombo.y = Star.TBL_POSITIONS[grpView:getTargetPos()][1], Star.TBL_POSITIONS[grpView:getTargetPos()][2]
            _doComboAnime(true)
        end

        local numScaleTo = sptCombo.xScale
        local yTo = sptCombo.y - 15
        sptCombo.cnlTransition = transition.to(sptCombo, {isLocked=true, x=Constants.LEFT + 15, transition=easing.outElastic, time=500, onComplete=function()
            local numScore = id * 20
            grpView:addScore(numScore)
            txtPoints.text = " +"..numScore
            txtPoints.x, txtPoints.alpha, txtPoints.xScale, txtPoints.yScale = sptCombo.x + sptCombo.width * sptCombo.xScale * .4, 0, .1, .1
            txtPoints.cnlTransition = transition.to(txtPoints, {delay=500, time=200, alpha=.5, xScale=numScaleTo, yScale=numScaleTo, transition=easing.outBack, onComplete=function(obj)
                txtPoints.cnlTransition = transition.to(txtPoints, {delay=100, time=300, alpha=0, y=yTo, transition=easing.inQuad, onComplete=function(obj)
                    if obj then
                        obj.isVisible = false
                    end
                end})
            end})
            sptCombo.cnlTransition = transition.to(sptCombo, {isLocked=true, alpha=0, delay=300, time=200, onComplete=function()
                if sptCombo then
                    sptCombo.isVisible = false
                end
            end})
        end})

        _showBonus()
    end

    function grpView:verifyAlert()
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
            CANCEL_ALERT = transition.to(grpAlert, {alpha=0, time=numTime, iterations=-1, onRepeat=function()
                if grpAlert and grpAlert.alpha and Controller:getStatus() == 1 then
                    grpAlert.alpha = 1
                    Jukebox:dispatchEvent({name="playSound", id="alert"})
                end
            end})
        elseif grpAlert.isVisible then
            if CANCEL_ALERT ~= nil then
                transition.cancel(CANCEL_ALERT)
                CANCEL_ALERT = nil
            end
            grpAlert.isVisible = false
        end
    end

    function grpView:getTarget()
        return Vector2D:new(imgStar.x, imgStar.y)
    end

    function grpView:getTargetPos()
        return imgStar:getCurrentPos()
    end

    local function _onStarCollision(self, params)
        if imgStar:collision(params) then

            grpView:turnoffCombo()

            if imgStar.health > 0 then
                _doShakeAnime(params.element.size)
                grpView:verifyAlert()
            else
                grpView:doGameOver(false)
            end

        end
    end
    grpView.starCollision = _onStarCollision


    local function _objectTouch(self, params)
        _tblStashTouch[#_tblStashTouch+1] = params.other
    end
    grpView.objectTouch = _objectTouch


    local function _objectTap(self, params)
        _tblStashTap[#_tblStashTap+1] = params.other
    end
    grpView.objectTap = _objectTap


    local function _countParticleDestroyed()
        if countDestroyed > 5 then
            if countDestroyed > 10 then countDestroyed = 10 end
            local numScoreCombo = countDestroyed - 5
            _showCombo(numScoreCombo)
        end
        countDestroyed = 0
    end


    local function _updateScore(self, params)
        countDestroyed = countDestroyed + 1
        if cnlBonus ~= nil then timer.cancel(cnlBonus) end
        cnlBonus = timer.performWithDelay(200, _countParticleDestroyed, 1)

        if params.currentScore > 0 then
            local numScore = params.currentScore * grpView.numMultiplier
            grpView:addScore(numScore)

            local numSize = 10 + numScore * .2
            numSize = numSize > 25 and 25 or numSize
            local tblTxtOptions = {
                text = " +"..numScore.." ",
                font = "Maassslicer",
                fontSize = numSize,
                align = "center",
            }

            -- TEXT POINTS
            local txtPoints = display.newText(tblTxtOptions)
            grpView:add(txtPoints, 6)
            txtPoints.anchorX, txtPoints.anchorY = .5, .5
            txtPoints.x, txtPoints.y, txtPoints.alpha = params.x, params.y, 0
            txtPoints:scale(.1, .1)
            local numAlpha = rctComboFrame.isVisible and .5 or .8
            transition.to(txtPoints, {delay=300, time=200, alpha=numAlpha, xScale=1, yScale=1, transition=easing.outBack, onComplete=function(obj)
                transition.to(txtPoints, {delay=100, time=300, alpha=0, y=params.y-15, transition=easing.inQuad, onComplete=function(obj)
                    if layer[6] and layer[6].remove then
                        layer[6]:remove(obj)
                    end
                    obj = nil
                end})
            end})
        end
    end
    local function _noUpdateScore(self, params)
    end
    grpView.updateScore = IS_HOW_TO_PLAY and _noUpdateScore or _updateScore


    local function _onPowerupTouchOn(self, event)

        if event.other.powerupType == 3 then
            local obj
            local numDist
            local sx, sy = event.other.x, event.other.y
            local dx, dy
            local layerCurrent = layer[5]
            local numVortexSize = NUM_VORTEX_SIZE
            local numScore = 0
            local nCount = 0
            for i = layerCurrent.numChildren, 1, -1  do
                obj = layerCurrent[i]
                dx, dy = obj.x - sx, obj.y - sy
                numDist = sqrt(dx*dx + dy*dy)
                if obj.getCurrentScore and not obj.isExploding and not obj.isOnStar and numDist < numVortexSize then
                    nCount = nCount + 1
                    if obj.stopMove then obj:stopMove() end
                    if obj[1] then
                        obj[1].parent:remove(obj[1])
                        obj[1] = nil
                    end
                    Trt.to(obj, {isLocked=true, x=sx, y=sy, time=numDist*2, transition="inQuad", onComplete=function(self)
                        Trt.to(self, {isLocked=true, xScale=.2, yScale=.2, alpha=0, time=200, onComplete=function(self)
                            if self.blackHole then
                                numScore = numScore + self:getCurrentScore()
                                self:blackHole()
                            end
                        end})
                    end})
                end
            end
            numScore = numScore * grpView.numMultiplier
            if nCount > 4 then
                grpView:addStat("nBlackHole", 1)
            end
            imgVortex.x, imgVortex.y, imgVortex.isVisible = event.other.x, event.other.y, true
            imgVortex.xScale, imgVortex.yScale = .1, .1

            Trt.to(imgVortex, {isLocked=true, time=300, rotation=imgVortex.rotation + 30, xScale=NUM_VORTEX_PROP, yScale=NUM_VORTEX_PROP, onComplete=function(self)
                Jukebox:dispatchEvent({name="playSound", id="vortex"})
                
                if imgVortex.rotation then
                    Trt.to(imgVortex, {isLocked=true, time=600, rotation=imgVortex.rotation + 90, onComplete=function(self)
                        if imgVortex.rotation then

                            grpView:updateScore({currentScore=numScore, size=15, x=imgVortex.x, y=imgVortex.y})

                            Trt.to(imgVortex, {isLocked=true, time=200, rotation=imgVortex.rotation + 360, xScale=.01, yScale=.01, onComplete=function(self)
                                self.isVisible = false
                            end})
                        end
                    end})
                end
            end})
            grpView:add(imgVortex, 4)

        elseif event.other.powerupType == 2 then
            imgStar:recoveryHealth()
            grpView:verifyAlert()

        elseif event.other.powerupType == 1 then
            Jukebox:dispatchEvent({name="playSound", id="powerup"})
            imgStar:activeShield()

        elseif event.other.powerupType == 4 then
            Jukebox:dispatchEvent({name="playSound", id="frozen"})
            _frozen()

            local layerCurrent = layer[5]
            for i = layerCurrent.numChildren, 1, -1  do layerCurrent[i].isTouchable = true end
            layerCurrent = layer[6]
            for i = layerCurrent.numChildren, 1, -1  do layerCurrent[i].isTouchable = true end

            local function _resume()
                Jukebox:dispatchEvent({name="playSound", id="unfrozen"})
                _unfrozen()
            end

            if grpView.trtFrozen ~= nil then
                transition.cancel(grpView.trtFrozen)
                grpView.trtFrozen = nil
            end
            local numAlpha = rctComboFrame.isVisible and .8 or 1
            grpView.trtFrozen = transition.to(grpFrozen, {xScale=1, yScale=1, alpha=numAlpha, time=200, onComplete=function()
                grpView.trtFrozen = transition.to(grpFrozen, {xScale=1.1, yScale=1.1, alpha=0, transition=easing.inQuad, time=Controller:getData():getStore("4").v, onComplete=_resume})
            end})

        elseif event.other.powerupType == 5 then
            if imgStar:addSuperPhoenix(1) then
                txtSuperPhoenix.text = " :"..imgStar.transientSuperPhoenix.v
            end

        end

    end
    grpView.powerupTouchOn = _onPowerupTouchOn

    grpViewParent:insert(grpView)

    return grpView
end

ViewPort.new = new

return ViewPort