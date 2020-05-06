local Composer = require "composer"
local objScene = Composer.newScene()


local Vector2D = require "lib.Vector2D"
local I18N = require "lib.I18N"


local Wgt = require "classes.phoenix.business.Wgt"
local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"
local Constants = require "classes.phoenix.business.Constants"
local Jukebox = require "classes.phoenix.business.Jukebox"


local infHelp = require("classes.infoHelp")
local shtHelp = graphics.newImageSheet("images/ui/scnHelp.png", infHelp:getSheet())
local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())
local infUtilGameplay = require("classes.infoUtilGameplay")
local shtUtilGameplay = graphics.newImageSheet("images/gameplay/scnUtilGameplay.png", infUtilGameplay:getSheet())
local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random


local NUM_PREVIOUS_STATUS = 0


local bntBackRelease = function(event)
    if NUM_PREVIOUS_STATUS == 2 then
        Controller:showSceneOverlay(2)
    else
        Composer.hideOverlay(false, "fade", 200)
        Controller:setStatus(NUM_PREVIOUS_STATUS)
    end
    return true
end


function objScene:create(event)
    local grpView = self.view
    grpView.isVisible = false


    globals_bntBackRelease = bntBackRelease


    if Composer.getSceneName("current") ~= "classes.phoenix.controller.scenes.GamePlay" then
        local rctOverlay = display.newRect(grpView, -10, -10, 500, 350)
        rctOverlay.anchorX, rctOverlay.anchorY = 0, 0
        rctOverlay:setFillColor(0, .97)
    end


    local grpBg = display.newGroup()
    grpView:insert(grpBg)


    local grpFrame = display.newGroup()
    grpView:insert(grpFrame)


    local params = event.params
    local currentID = 1
    local tblID = {1, 9, 8, 2, 3}


    local tblTxtOptions = {
        parent = grpView,
        text = "",
        width = Constants.RIGHT - 150,
        font = "Maassslicer",
        align = "center"
    }

    local txtUnlocked = {}
    if params then
        -- ID
        if params.tblID then
            tblID = params.tblID
        end

        -- UNLOCKED
        if params.helpType == 2 then
            
            local grpFx1 = display.newGroup()
            grpBg:insert(grpFx1)
            local grpFx2 = display.newGroup()
            grpBg:insert(grpFx2)


            local rctBg = display.newRect(grpBg, 0, 0, 900, 600)
            rctBg.fill.effect = "generator.radialGradient"
            rctBg.fill.effect.color1 = {.05, .05, .05}
            rctBg.fill.effect.color2 = {0, 0, 0}
            rctBg.fill.effect.center_and_radiuses  =  {0.5, 0.5, 0, .5}
            rctBg.fill.effect.aspectRatio  = 1
            rctBg.anchorX, rctBg.anchorY = .5, .5
            rctBg.x, rctBg.y = display.contentCenterX, display.contentCenterY

            -- STARS
            local _reposition = function(self, numDelay)
                if self.scale then
                    self.alpha = 0
                    self.rotation = random(360)
                    self.x, self.y = random(Constants.RIGHT), random(Constants.BOTTOM)
                    self:scale(.1, .1)
                    numDelay = numDelay or 0
                    local numD = numDelay + random(10) * 20
                    local vecTo = Vector2D:new(self.x - display.contentCenterX, self.y - display.contentCenterY)
                    vecTo:normalize()
                    vecTo:mult(random(1, 10) * 10)
                    local numAlpha = random(3, 8) * .1
                    local numTime = random(5, 10) * 100
                    local numScale = random(15, 25) * .1
                    local numRot = self.rotation + random(1, 5) * 10
                    local tblFrom = {vecTo.x*.5+self.x, vecTo.y*.5+self.y, numAlpha, numRot*.5, numTime*.5, numScale*.5}
                    local tblTo = {vecTo.x+self.x, vecTo.y+self.y, 0, numRot, numTime*.5, numScale}
                    transition.to(self, {x=tblFrom[1], y=tblFrom[2], alpha=tblFrom[3], rotation=tblFrom[4], time=tblFrom[5], xScale=tblFrom[6], yScale=tblFrom[6], delay=numD, onComplete=function()
                        if self.rotation then
                            transition.to(self, {x=tblTo[1], y=tblTo[2], alpha=tblTo[3], rotation=tblTo[4], time=tblTo[5], xScale=tblTo[6], yScale=tblTo[6], onComplete=function()
                                if self.reposition then
                                    self:reposition()
                                end
                            end})
                        end
                    end})
                end
            end
            for i=1, 6 do
                local sptStar = display.newSprite(shtUtilUi, { {name="s", start=13, count=1} })
                grpView:insert(sptStar)
                sptStar.reposition = _reposition
                local numScale = .1 * random(5, 10)
                sptStar:scale(numScale, numScale)
                sptStar:reposition(random(3) * 100)
            end


            for i=1, 8 do
                local numFrame = random(5)
                local imgFx = display.newSprite(shtUtilGameplay, { {name="standard", frames={1+numFrame}} })
                imgFx:setFillColor(random(1, 10)*.01)
                imgFx.anchorX, imgFx.anchorY = 0, .5
                imgFx.x, imgFx.y = 0, 0
                imgFx.rotation = i * 45
                grpFx1:insert(imgFx)
            end
            grpFx1:scale(2, 2)
            grpFx1.anchorX, grpFx1.anchorY, grpFx1.alpha = .5, .5, .4
            grpFx1.x, grpFx1.y = display.contentCenterX, display.contentCenterY
            transition.to(grpFx1, {type=2, rotation=grpFx1.rotation + 10000, time=600000})

            for i=1, 8 do
                local numFrame = random(5)
                local imgFx = display.newSprite(shtUtilGameplay, { {name="standard", frames={1+numFrame}} })
                imgFx:setFillColor(random(1, 10)*.01)
                imgFx.anchorX, imgFx.anchorY = 0, .5
                imgFx.x, imgFx.y = 0, 0
                imgFx.rotation = i * 45
                grpFx2:insert(imgFx)
            end
            grpFx2:scale(2, 2)
            grpFx2.anchorX, grpFx2.anchorY, grpFx2.alpha = .5, .5, .4
            grpFx2.x, grpFx2.y = display.contentCenterX, display.contentCenterY
            transition.to(grpFx2, {type=2, rotation=grpFx2.rotation - 10000, time=500000})

            tblTxtOptions.text = I18N:getString("avaliable")
            tblTxtOptions.fontSize = 12

            txtUnlocked = display.newText(tblTxtOptions)
            txtUnlocked:setFillColor(1, 1, .2)
            txtUnlocked.anchorX, txtUnlocked.anchorY = .5, 1
            txtUnlocked.x, txtUnlocked.y = display.contentCenterX, Constants.BOTTOM - 20


            timer.performWithDelay(100, function()
                Jukebox:dispatchEvent({name="playSound", id="unlocked"})
            end, 1)

        end

        -- CALLBACK
        if params.callback then
            grpView.callback = params.callback
        end
    end


    tblTxtOptions.fontSize = 14
    local txtTitle = display.newText(tblTxtOptions)

    local function _getStrCounter()
        if #tblID == 1 then
            return ""
        end
        return " " .. currentID .. " / " .. #tblID
    end

    tblTxtOptions.text = _getStrCounter()
    tblTxtOptions.fontSize = 9
    local txtCounter = display.newText(tblTxtOptions)
    txtCounter:setFillColor(.3)


    local bntPrevious
    local bntNext
    local bntBack


    local function _refreshImage()
        bntPrevious.isVisible = currentID > 1 and #tblID > 1
        bntNext.isVisible = currentID < #tblID and #tblID > 1
        transition.to(grpView[grpView.numChildren], {alpha=0, time=250, onComplete=function(self)
            if self and self.parent then
                self.parent:remove(self)
            end
        end})

        local imgHelp = display.newSprite(shtHelp, {
            {name="s", start=tblID[currentID], count=1},
        })
        imgHelp.anchorX, imgHelp.anchorY = .5, .5
        imgHelp.x, imgHelp.y, imgHelp.alpha = display.contentCenterX, display.contentCenterY, 0
        transition.to(imgHelp, {alpha=1, time=250})
        grpView:insert(imgHelp)

        bntBack.isVisible = not (params and params.isObrigatory) or currentID == #tblID

        txtTitle.text = I18N:getString("help"..tblID[currentID])
        txtTitle.height = 50
        txtTitle.anchorX, txtTitle.anchorY = .5, 0
        txtTitle.x, txtTitle.y = display.contentCenterX, Constants.TOP

        txtCounter.text = _getStrCounter()
        txtCounter.anchorX, txtCounter.anchorY = .5, 0
        txtCounter.x, txtCounter.y = display.contentCenterX, Constants.TOP + 45
    end


    local function bntPreviousRelease(event)
        currentID = currentID - 1
        _refreshImage()
        return true
    end
    bntPrevious = Wgt.newButton {
        sheet = shtButtons,
        defaultFrame = 14,
        onRelease = bntPreviousRelease
    }
    bntPrevious.isVisible = currentID > 1 and #tblID > 1


    local function bntNextRelease(event)
        currentID = currentID + 1
        _refreshImage()
        return true
    end
    bntNext = Wgt.newButton {
        sheet = shtButtons,
        defaultFrame = 27,
        onRelease = bntNextRelease
    }
    bntNext.isVisible = currentID < #tblID and #tblID > 1


    bntBack = Wgt.newButton {
        sheet = shtButtons,
        defaultFrame = 11,
        onRelease = globals_bntBackRelease
    }
    bntBack.isVisible = #tblID == 1 or (#tblID < 8 and currentID == #tblID) or #tblID > 7


    Util:generateFrame(grpFrame, bntPrevious, bntNext, bntBack, nil)


    display.newRect(grpView, -2, -2, -1, -1)
    

    _refreshImage()


end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        globals_bntBackRelease = bntBackRelease

        if parent.overlayBegan then
            parent:overlayBegan()
        end

    elseif phase == "did" then

        NUM_PREVIOUS_STATUS = Controller:getStatus()
        Controller:setStatus(7, true)

    end
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "did" then

        if grpView.callback then
            grpView.callback()
        end

        if parent.overlayEnded then
            parent:overlayEnded()
        end

    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene