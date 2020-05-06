local Composer = require "composer"
local objScene = Composer.newScene()


local Wgt = require "classes.phoenix.business.Wgt"
local I18N = require "lib.I18N"
local Controller = require "classes.phoenix.business.Controller"
local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"


local infHelp = require("classes.infoHelp")
local shtHelp = graphics.newImageSheet("images/ui/scnHelp.png", infHelp:getSheet())
local infUtilGameplay = require("classes.infoUtilGameplay")
local shtUtilGameplay = graphics.newImageSheet("images/gameplay/scnUtilGameplay.png", infUtilGameplay:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random


local NUM_STATUS_OLD = 1


function objScene:create(event)
    local grpView = self.view

    local params = event.params


    local grpHud = display.newGroup()
    grpView:insert(grpHud)


    local transientContinue = Controller:getData():getStore("8")


    local txtTitle = display.newText(grpHud, I18N:getString("doContinue"), 0, 0, "Maassslicer", 20)
    txtTitle:setFillColor(1)
    txtTitle.anchorX, txtTitle.anchorY = .5, .5
    txtTitle.x, txtTitle.y, txtTitle.alpha = 0, -85, 0
    transition.to(txtTitle, {y=-45, delay=400, alpha=1, time=400, transition=easing.outBack})

    local strLeft = I18N:getString("leftContinueN")
    if transientContinue.v == 0 then
        strLeft = I18N:getString("leftContinueOver")
    elseif transientContinue.v == 1 then
        strLeft = I18N:getString("leftContinue")
    end
    strLeft = string.gsub(strLeft, "xx", ""..transientContinue.v)
    local txtDesctiption = display.newText(grpHud, strLeft, 0, 0, "Maassslicer", 12)
    txtDesctiption:setFillColor(1)
    txtDesctiption.anchorX, txtDesctiption.anchorY = .5, .5
    txtDesctiption.x, txtDesctiption.y, txtDesctiption.alpha = 0, -125, 0
    transition.to(txtDesctiption, {y=-85, alpha=1, delay=300, time=400, transition=easing.outBack})


    local numTimer = 10
    local txtTimer = display.newText(grpHud, " "..numTimer, 0, 0, "Maassslicer", 20)
    txtTimer:setFillColor(1, 1, .2)
    txtTimer.anchorX, txtTimer.anchorY = .5, .5
    txtTimer.x, txtTimer.y = 0, 1
    local TIMER_TEXT_CANCEL = timer.performWithDelay(1000, function() 
        numTimer = numTimer - 1
        txtTimer.text = " "..numTimer
        Jukebox:dispatchEvent({name="playSound", id="countdown"})
    end, 10)


    local infButtons = require("classes.infoButtons")
    local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())


    local grpYes = display.newGroup()
    local grpNo = display.newGroup()
    local bntNoRelease = function() end


    local TIMER_CANCEL = nil
    local TIMES_UP = false


    local function _onTimerSprite(self, event)
        if event.phase == "ended" then
            grpYes.isActive = false
            grpNo.isActive = false
            TIMER_CANCEL = timer.performWithDelay(250, function() 
                bntNoRelease()
            end, 1)
        end
    end
    local sptTimer = display.newSprite(shtUtilGameplay, {{name="s", start=49, count=49, time=10000, loopCount=1}})
    sptTimer:setFillColor(1, 1, .2)
    sptTimer.xScale, sptTimer.yScale = .6, .6
    sptTimer.anchorX, sptTimer.anchorY = .5, .5
    sptTimer.x, sptTimer.y = 0, 0
    sptTimer.sprite = _onTimerSprite
    sptTimer:addEventListener("sprite", sptTimer)
    sptTimer:play()
    grpHud:insert(sptTimer)


    bntNoRelease = function()
        if not TIMES_UP then
            TIMES_UP = true
            sptTimer:pause()

            if TIMER_CANCEL ~= nil then
                timer.cancel(TIMER_CANCEL)
                TIMER_CANCEL = nil
            end
            if TIMER_TEXT_CANCEL ~= nil then
                timer.cancel(TIMER_TEXT_CANCEL)
                TIMER_TEXT_CANCEL = nil
            end

            Controller:setStatus(NUM_STATUS_OLD, true)
            params.camera:continue(false)
        end

        return true
    end
    local bntNo = Wgt.newButton {
        sheet = shtButtons,
        defaultFrame = 4,
        overFrame = 4,
        onRelease = bntNoRelease
    }
    grpNo:insert(bntNo)
    grpNo.anchorX, grpNo.anchorY = .5, .5
    grpNo.x, grpNo.y = 50, 60
    grpNo.xScale, grpNo.yScale, grpNo.alpha = .01, .01, 0
    transition.to(grpNo, {xScale=1, yScale=1, alpha=1, delay=500, time=500, transition=easing.outBack})
    grpHud:insert(grpNo)


    local function bntYesRelease()
        if not TIMES_UP then
            TIMES_UP = true
            sptTimer:pause()

            if TIMER_CANCEL ~= nil then
                timer.cancel(TIMER_CANCEL)
                TIMER_CANCEL = nil
            end
            if TIMER_TEXT_CANCEL ~= nil then
                timer.cancel(TIMER_TEXT_CANCEL)
                TIMER_TEXT_CANCEL = nil
            end

            transientContinue.v = transientContinue.v - 1
            Controller:getData():setStore("8", transientContinue)

            local rctOverlay2 = display.newRect(grpView, -10, -10, 500, 350)
            rctOverlay2.anchorX, rctOverlay2.anchorY = 0, 0
            rctOverlay2:setFillColor(0)
            rctOverlay2.alpha = 0
            transition.to(rctOverlay2, {alpha=1, time=300, onComplete=function()
                grpHud.isVisible = false
                Controller:setStatus(NUM_STATUS_OLD, true)
                params.camera:continue(true)
            end})
        end

        return true
    end
    local bntYes = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 11,
        overFrame = 11,
        onRelease = bntYesRelease
    }
    grpYes:insert(bntYes)
    grpYes.anchorX, grpYes.anchorY = .5, .5
    grpYes.rotation = 180
    grpYes.x, grpYes.y = - 50, 60
    grpYes.xScale, grpYes.yScale, grpYes.alpha = .01, .01, 0
    transition.to(grpYes, {xScale=1, yScale=1, alpha=1, delay=500, time=500, transition=easing.outBack})
    grpHud:insert(grpYes)


    grpHud.anchorX, grpHud.anchorY = .5, .5
    grpHud.x, grpHud.y = display.contentCenterX, display.contentCenterY
    grpHud.alpha = 0
    grpHud:scale(2, 2)


end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        parent:overlayBegan()

    elseif phase == "did" then

        NUM_STATUS_OLD = Controller:getStatus()
        Controller:setStatus(10, true)

        transition.to(grpView[1], {xScale=1, yScale=1, alpha=1, time=500, transition=easing.outExpo})

    end
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        parent:overlayEnded()

    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene