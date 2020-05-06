local Composer = require "composer"
local objScene = Composer.newScene()


local Trt = require "lib.Trt"
local I18N = require "lib.I18N"


local Wgt = require "classes.phoenix.business.Wgt"
local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"
local Jukebox = require "classes.phoenix.business.Jukebox"
local ViewPort = require "classes.phoenix.controller.cameras.ViewPort"
local Constants = require "classes.phoenix.business.Constants"
local Star = require "classes.phoenix.entities.Star"
local Persistence = require "classes.phoenix.persistence.Persistence"


local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())
local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random

local grpHud
local grpViewPort

local tblStats = {}
tblStats.dTimeStarted = 0
tblStats.dTimePaused = 0

local txtRankingTitle = {}
local txtRanking = {}
local numTypeRanking = 1
local tblRankings = {I18N:getString("connecting"), I18N:getString("connecting"), I18N:getString("connecting"), I18N:getString("connecting")}
local cnlRecord = nil
local cnlProgress = nil
local cnlRanking = nil


local rctOverlay = display.newRect(-10, -10, 1, 1)


local _onNetwork = function(event)
    if not event.isError and event.response ~= nil then
        local json = require "json"
        local response = json.decode(event.response)

        if response == nil or response.e ~= nil then
            tblRankings = {I18N:getString("noServer"), I18N:getString("noServer"), I18N:getString("noServer"), I18N:getString("noServer")}
        else
            tblRankings = {}
            for i = 1, 4 do
                tblRankings[i] = Util:formatNumber(response[1][i].r).."º"
            end
            txtRankingTitle.text = " "..I18N:getString("rank"..numTypeRanking)
            txtRanking.text = tblRankings[numTypeRanking] == "0º" and I18N:getString("none") or " "..tblRankings[numTypeRanking]
        end
    else
        tblRankings = {I18N:getString("noConnection"), I18N:getString("noConnection"), I18N:getString("noConnection"), I18N:getString("noConnection")}
    end
end

local _createHudFrontend = function(grpView)
    grpHud = display.newGroup()
    --grpHud.isVisible = false


    local numDelay = (Composer.getSceneName("previous") == "classes.phoenix.controller.scenes.LoadingGameIn") and 800 or 300


    local grpFrame = display.newGroup()
    grpHud:insert(grpFrame)


    local grpStats = display.newGroup()
    grpHud:insert(grpStats)

    local numWidth = 130

    local grpRecord = display.newGroup()
    grpRecord.isShowBest = false
    grpStats:insert(grpRecord)

    local strLastScore = Util:formatNumber(Controller:getData():getDecryptedScoreLast().."")
    local strBestScore = Util:formatNumber(Controller:getData():getDecryptedScore().."")

    local tblTxtOptions = {
        font = "Maassslicer",
        align = "center",
    }

    tblTxtOptions.text = I18N:getString("lastFrontend")
    tblTxtOptions.fontSize = 12
    tblTxtOptions.parent = grpRecord
    tblTxtOptions.width = numWidth

    txtRecordTitle = display.newText(tblTxtOptions)
    txtRecordTitle:setFillColor(0)
    txtRecordTitle.anchorX, txtRecordTitle.anchorY = 0, 1
    txtRecordTitle.x, txtRecordTitle.y = 0, -7

    tblTxtOptions.text = strLastScore
    tblTxtOptions.fontSize = 11
    tblTxtOptions.parent = grpRecord
    tblTxtOptions.width = txtRecordTitle.width

    txtRecord = display.newText(tblTxtOptions)
    txtRecord:setFillColor(1, 1, .2)
    txtRecord.anchorX, txtRecord.anchorY = 0, .5
    txtRecord.x, txtRecord.y = txtRecordTitle.x, 0

    local function _onRecordChange()
        timer.cancel(cnlRecord)
        if grpRecord.isShowBest then
            grpRecord.isShowBest = false
            transition.fadeOut(grpRecord, {time=250, onComplete=function()
                txtRecordTitle.text =  I18N:getString("lastFrontend")
                txtRecord.text = strLastScore
                transition.fadeIn(grpRecord, {time=250})
            end})
        else
            grpRecord.isShowBest = true
            transition.fadeOut(grpRecord, {time=250, onComplete=function()
                txtRecordTitle.text =  I18N:getString("bestFrontend")
                txtRecord.text = strBestScore
                transition.fadeIn(grpRecord, {time=250})
            end})
        end
        cnlRecord = timer.performWithDelay(7000, _onRecordChange, 1)
    end
    cnlRecord = timer.performWithDelay(4000, _onRecordChange, 1)

    grpRecord.anchorChildren = true
    grpRecord.anchorX, grpRecord.anchorY = .5, 1
    grpRecord.x, grpRecord.y = -95, 0


    local grpProgress = display.newGroup()
    grpStats:insert(grpProgress)

    local grpProgressDescription = display.newGroup()
    grpProgress:insert(grpProgressDescription)

    local tblProgress = Controller:getData():getAchievementsProgress()

    local rctBar = display.newRect(grpProgressDescription, 0, -10, 30, 9)
    rctBar.anchorX, rctBar.anchorY = 0, .5
    rctBar.x, rctBar.y = 15, 0
    rctBar:setFillColor(0, .7)
    local rctProgress = display.newRect(grpProgressDescription, 2, -8, 26, 4)
    rctProgress:setFillColor(1, 1, .2)
    rctProgress.anchorX, rctProgress.anchorY = 0, .5
    rctProgress.x, rctProgress.y = rctBar.x + 2, 0
    rctProgress.xScale = (tblProgress.numProgress / 100) + .001

    tblTxtOptions.text = I18N:getString("achievements")
    tblTxtOptions.width = 85
    tblTxtOptions.fontSize = 12
    tblTxtOptions.parent = grpProgress

    local txtProgressTitle = display.newText(tblTxtOptions)
    txtProgressTitle:setFillColor(0)
    txtProgressTitle.anchorX, txtProgressTitle.anchorY = 0, 1
    txtProgressTitle.x, txtProgressTitle.y = 0, -7

    tblTxtOptions.text = " "..tblProgress.numProgress.."%"
    tblTxtOptions.width = nil
    tblTxtOptions.fontSize = 11
    tblTxtOptions.parent = grpProgressDescription

    local txtProgress = display.newText(tblTxtOptions)
    txtProgress:setFillColor(1, 1, .2)
    txtProgress.anchorX, txtProgress.anchorY = 0, .5
    txtProgress.x, txtProgress.y = rctBar.x + rctBar.width + 2, 0

    tblTxtOptions.text = " "..tblProgress.numQttUnlocked.. " / " .. tblProgress.numQttT
    tblTxtOptions.width = 80
    tblTxtOptions.fontSize = 11
    tblTxtOptions.parent = grpProgressDescription

    local txtProgressDescription = display.newText(tblTxtOptions)
    txtProgressDescription:setFillColor(1, 1, .2)
    txtProgressDescription.anchorX, txtProgressDescription.anchorY = 0, .5
    txtProgressDescription.x, txtProgressDescription.y, txtProgressDescription.isVisible = 1, 0, false

    local function _onProgressChange()
        timer.cancel(cnlProgress)
        if txtProgressDescription.isVisible then
            transition.fadeOut(grpProgressDescription, {time=250, onComplete=function()
                txtProgress.isVisible = true
                rctProgress.isVisible = true
                rctBar.isVisible = true
                txtProgressDescription.isVisible = false
                transition.fadeIn(grpProgressDescription, {time=250})
            end})
        else
            transition.fadeOut(grpProgressDescription, {time=250, onComplete=function()
                txtProgress.isVisible = false
                rctProgress.isVisible = false
                rctBar.isVisible = false
                txtProgressDescription.isVisible = true
                transition.fadeIn(grpProgressDescription, {time=250})
            end})
        end
        cnlProgress = timer.performWithDelay(7000, _onProgressChange, 1)
    end
    cnlProgress = timer.performWithDelay(5000, _onProgressChange, 1)

    grpProgress.anchorChildren = true
    grpProgress.anchorX, grpProgress.anchorY = .5, 1
    grpProgress.x, grpProgress.y = 95, 0

    local rctProgressOverlay = display.newRect(0, 0, txtProgressTitle.width - 20, 60)
    grpStats:insert(rctProgressOverlay)
    rctProgressOverlay.anchorX, rctProgressOverlay.anchorY = .5, 0
    rctProgressOverlay.x, rctProgressOverlay.y, rctProgressOverlay.alpha = grpProgress.x, -40, .01


    local grpRanking = display.newGroup()
    grpStats:insert(grpRanking)

    tblTxtOptions.text = I18N:getString("rank"..numTypeRanking)
    tblTxtOptions.fontSize = 12
    tblTxtOptions.parent = grpRanking
    tblTxtOptions.width = numWidth

    txtRankingTitle = display.newText(tblTxtOptions)
    txtRankingTitle:setFillColor(0)
    txtRankingTitle.anchorX, txtRankingTitle.anchorY = 0, 1
    txtRankingTitle.x, txtRankingTitle.y = 0, -7

    tblTxtOptions.text = I18N:getString("connecting")
    tblTxtOptions.fontSize = 11
    tblTxtOptions.parent = grpRanking
    tblTxtOptions.width = txtRankingTitle.width

    txtRanking = display.newText(tblTxtOptions)
    txtRanking:setFillColor(1, 1, .2)
    txtRanking.anchorX, txtRanking.anchorY = 0, .5
    txtRanking.x, txtRanking.y = txtRankingTitle.x, 0

    local rctRankingOverlay = display.newRect(0, 0, txtRankingTitle.width - 20, 60)
    grpStats:insert(rctRankingOverlay)
    rctRankingOverlay.anchorX, rctRankingOverlay.anchorY = .5, 0
    rctRankingOverlay.x, rctRankingOverlay.y, rctRankingOverlay.alpha = 0, -40, .01

    local function _onRankingChange()
        timer.cancel(cnlRanking)
        numTypeRanking = numTypeRanking == 4 and 1 or (numTypeRanking + 1)
        local numRank = numTypeRanking
        transition.fadeOut(grpRanking, {time=250, onComplete=function()
            txtRankingTitle.text = " "..I18N:getString("rank"..numRank)
            txtRanking.text = tblRankings[numRank] == "0º" and I18N:getString("none") or " "..tblRankings[numRank]
            transition.fadeIn(grpRanking, {time=250})
        end})

        cnlRanking = timer.performWithDelay(7000, _onRankingChange, 1)
    end
    cnlRanking = timer.performWithDelay(4500, _onRankingChange, 1)

    grpRanking.anchorChildren = true
    grpRanking.anchorX, grpRanking.anchorY = .5, 1
    grpRanking.x, grpRanking.y = -2, 0

    local function _onAchievementsTouch(self, event)
        local phase = event.phase
        if phase == "ended" then
            Jukebox:dispatchEvent({name="playSound", id="button"})
            Composer.stage.alpha = 0
            local options = {
                effect = "fade",
                time = 0,
                params = {scene="classes.phoenix.controller.scenes.Achievement"}
            }
            Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
        end
        return true
    end
    rctProgressOverlay.touch = _onAchievementsTouch
    rctProgressOverlay:addEventListener("touch", rctProgressOverlay)

    local function _onRankingTouch(self, event)
        local phase = event.phase
        if phase == "ended" then
            Jukebox:dispatchEvent({name="playSound", id="button"})
            Composer.stage.alpha = 0
            local options = {
                effect = "fade",
                time = 0,
                params = {scene="classes.phoenix.controller.scenes.Ranking", numTypeRanking=numTypeRanking}
            }
            Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
        end
        return true
    end
    rctRankingOverlay.touch = _onRankingTouch
    rctRankingOverlay:addEventListener("touch", rctRankingOverlay)

    grpStats.anchorChildren = true
    grpStats.anchorX, grpStats.anchorY = .5, 1
    grpStats.x, grpStats.y, grpStats.alpha = display.contentCenterX - 10, Constants.BOTTOM  + 8, 0
    grpStats.trtCancel = transition.to(grpStats, {alpha=1, delay=numDelay + 1200, time=800})

    Controller:getData():getRanking(_onNetwork, {r=numTypeRanking, m=1})


    local sptBrand = display.newSprite(shtUtilUi, { {name="s", start=1, count=1} })
    grpHud:insert(sptBrand)
    sptBrand.anchorX, sptBrand.anchorY = .5, 0
    sptBrand.x, sptBrand.y = display.contentCenterX, Constants.TOP - 100
    local function _onTouchBrand(self, event)
        local phase = event.phase
        if phase == "ended" then
            Jukebox:dispatchEvent({name="playSound", id="button"})
            local options = {
                isModal = true,
                effect = "fade",
                time = 250,
                params = {source="classes.phoenix.controller.scenes.GamePlay"}
            }
            Composer.showOverlay("classes.phoenix.controller.scenes.About", options)
        end 
        return true
    end
    sptBrand.touch = _onTouchBrand
    sptBrand:addEventListener("touch", sptBrand)
    sptBrand.trtCancel = transition.to(sptBrand, {y=Constants.TOP + 2, delay=numDelay + 700, transition=easing.outBack, time=600})


    local grpLogo = display.newGroup()
    grpHud:insert(grpLogo)
    local rctTouch = display.newRect(grpLogo, 0, 0, 250, 200)
    rctTouch.alpha = .01
    local sptLogoFx1 = display.newSprite(shtUtilUi, { {name="s", start=2, count=1} })
    grpLogo:insert(sptLogoFx1)
    sptLogoFx1.rotation = 90
    sptLogoFx1.alpha = .5
    sptLogoFx1.trtCancel = transition.to( sptLogoFx1, {rotation=0, transition=easing.outExpo, delay=numDelay + 900, time=2000} )
    local sptLogoFx2 = display.newSprite(shtUtilUi, { {name="s", start=2, count=1} })
    grpLogo:insert(sptLogoFx2)
    sptLogoFx2.rotation = 180
    sptLogoFx2.alpha = .25
    sptLogoFx2.trtCancel = transition.to( sptLogoFx2, {rotation=0, transition=easing.outExpo, delay=numDelay + 1100, time=2000} )
    local sptLogo = display.newSprite(shtUtilUi, { {name="s", start=2, count=1} })
    grpLogo:insert(sptLogo)
    local sptLogoEye = display.newSprite(shtUtilUi, { {name="s", frames={3,3,4,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6}, time=5000} })
    sptLogoEye.x, sptLogoEye.y = -16, -60
    sptLogoEye:play()
    grpLogo:insert(sptLogoEye)
    local function _rotateLogo(self, numDelay)
        local numRot = -360

        if self.trtCancel ~= nil then transition.cancel(self.trtCancel) end
        if sptLogoFx1.trtCancel ~= nil then transition.cancel(sptLogoFx1.trtCancel) end
        if sptLogoFx2.trtCancel ~= nil then transition.cancel(sptLogoFx2.trtCancel) end

        self.trtCancel = transition.to(self, {time=numDelay, onComplete=function()
            if Controller:getStatus() == 0 then
                self.rotation = 0
                self.trtCancel = transition.to(self, {rotation=numRot, time=1200, transition=easing.outExpo, onComplete=function()
                    self.trtCancel = nil
                    if self ~= nil and self.rotateLogo ~= nil then
                        self.rotation = 0
                        sptLogoFx1.rotation = 0
                        sptLogoFx2.rotation = 0

                        self:rotateLogo(15000)
                    end
                end})
                sptLogoFx1.rotation = 90
                sptLogoFx1.trtCancel = transition.to( sptLogoFx1, {rotation=numRot, transition=easing.outExpo, delay=75, time=1200} )
                sptLogoFx2.rotation = 180
                sptLogoFx2.trtCancel = transition.to( sptLogoFx2, {rotation=numRot, transition=easing.outExpo, delay=150, time=1200} )
            end
        end})
    end
    grpLogo.rotateLogo = _rotateLogo
    local function _onTouchLogo(self, event)
        local phase = event.phase
        if phase == "began" then
            Jukebox:dispatchEvent({name="playSound", id="phoenix"})
            self:rotateLogo(10)
        end 
        return true
    end
    grpLogo.touch = _onTouchLogo
    grpLogo:scale(.1, .1)
    grpLogo.rotation = 720
    grpLogo.alpha = 0
    grpLogo.anchorX, grpLogo.anchorY = .5, .5
    grpLogo.x, grpLogo.y = display.contentCenterX, display.contentCenterY
    local numScaleTo = ((display.actualContentHeight + 12) * .6) / sptLogo.height
    grpLogo.trtCancel = transition.to(grpLogo, {rotation=0, alpha=1, xScale=numScaleTo, yScale=numScaleTo, delay=numDelay + 1000, transition=easing.outExpo, time=2000, onComplete=function()
        if grpLogo ~= nil and grpLogo.addEventListener ~= nil then
            grpLogo:rotateLogo(11700)
            grpLogo:addEventListener("touch", grpLogo)
        end
    end})


    local function bntLikeRelease(event)
        system.openURL("https://www.facebook.com/superphoenix2015")
        return false
    end
    local bntLike = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 5,
        onRelease = bntLikeRelease
    }


    local bntStore = nil
    if Controller:getData():getProfile("isSeenHelpStore") then
        local function bntStoreRelease()
            local options = {
                effect = "fade",
                time = 0,
                params = {scene="classes.phoenix.controller.scenes.Store"}
            }
            Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
            return true
        end
        bntStore = Wgt.newButton{
            sheet = shtButtons,
            defaultFrame = 19,
            onRelease = bntStoreRelease
        }
    end

    local countStoreNew = Controller:getData():getStoreQttNew()
    local grpNew = display.newGroup()
    grpHud:insert(grpNew)
    if countStoreNew > 0 then
        grpNew.xScale, grpNew.yScale, grpNew.alpha = .01, .01, 0

        local sptNew = display.newSprite(shtUtilUi, { {name="s", start=12, count=1} })
        sptNew.anchorX, sptNew.anchorY = .5, .5
        sptNew.x, sptNew.y = 0, 0
        grpNew:insert(sptNew)

        local txtNew = display.newText(grpNew, " "..countStoreNew, 0, 0, "Maassslicer", 9)
        txtNew.anchorX, txtNew.anchorY = .5, .5
        txtNew.x, txtNew.y = 0, 1

        grpNew.anchorX, grpNew.anchorY = .5, .5
        grpNew.x, grpNew.y = Constants.RIGHT - 8, Constants.TOP + 10, 0
        grpNew.CANCEL_ANIM = transition.to(grpNew, {delay=2000, alpha=1, xScale=1, yScale=1, transition=easing.outElastic, time=700})
    end


    local bntOptionsRelease = function()
        local options = {
            isModal = true,
            effect = "fade",
            time = 200
        }
        Composer.showOverlay("classes.phoenix.controller.scenes.Options", options)
        return false
    end
    local bntOptions = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 9,
        onRelease = bntOptionsRelease
    }


    local function bntPlayRelease(event)
        _onAchievementsTouch = function() end
        _onRankingTouch = function() end
        _onTouchLogo = function() end
        bntLikeRelease = function() end
        bntStoreRelease = function() end
        bntOptionsRelease = function() end

        if grpNew.numChildren > 0 then
            if grpNew.CANCEL_ANIM ~= nil then
                transition.cancel(grpNew.CANCEL_ANIM)
                grpNew.CANCEL_ANIM = nil
            end
            transition.to(grpNew, {alpha=0, xScale=.1, yScale=.1, transition=easing.inElastic, time=600})
        end

        if bntLike.trtCancel ~= nil then transition.cancel(bntLike.trtCancel) end
        timer.cancel(cnlRanking)
        timer.cancel(cnlProgress)
        timer.cancel(cnlRecord)
        if grpStats.trtCancel ~= nil then 
            transition.cancel(grpStats.trtCancel)
            grpStats.trtCancel = nil 
        end
        if sptBrand.trtCancel ~= nil then 
            transition.cancel(sptBrand.trtCancel) 
            sptBrand.trtCancel = nil 
        end
        if grpLogo.trtCancel ~= nil then 
            transition.cancel(grpLogo.trtCancel) 
            grpLogo.trtCancel = nil 
        end
        if sptLogoFx1.trtCancel ~= nil then 
            transition.cancel(sptLogoFx1.trtCancel) 
            sptLogoFx1.trtCancel = nil 
        end
        if sptLogoFx2.trtCancel ~= nil then 
            transition.cancel(sptLogoFx2.trtCancel) 
            sptLogoFx2.trtCancel = nil 
        end
        transition.to(grpStats, {alpha=0, time=400})
        transition.to(sptBrand, {y=sptBrand.y-100, delay=100, time=300})
        transition.to(sptLogoFx1, {rotation=200, transition=easing.inExpo, delay=80, time=800})
        transition.to(sptLogoFx2, {rotation=200, transition=easing.inExpo, delay=0, time=800})


        grpLogo:removeEventListener("touch", grpLogo)


        -- HIDE FRAME
        for i=1, grpFrame.numChildren do
            local obj = grpFrame[i]
            if obj.trtCancel ~= nil then transition.cancel(obj.trtCancel) end
            if i == 3 or (grpFrame.numChildren == 3 and i == 2) then
                transition.to(obj, {alpha=0, time=300})
            else
                transition.to(obj, {x=obj.xFrom, y=obj.yFrom, time=300})
            end
        end


        globals_bntBackRelease = nil
        event.target.isVisible = false

        grpLogo.trtCancel = transition.to(grpLogo, {time=800, xScale=.125, yScale=.125, rotation=-720, transition=easing.inExpo, onComplete=function()
            grpViewPort:start()
            tblStats.dTimeStarted = os.time()
            grpLogo.trtCancel = transition.to(grpLogo, {alpha=0, x=Star.TBL_POSITIONS[grpViewPort:getTargetPos()][1], y=Star.TBL_POSITIONS[grpViewPort:getTargetPos()][2], time=400, rotation=-1440, transition=easing.outExpo, onComplete=function()
                grpHud:removeSelf()
                grpHud = nil
            end})
        end})

        return true
    end
    local bntPlay = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 1,
        onRelease = bntPlayRelease
    }
    local bntPlayBlink = function() end
    bntPlayBlink = function()
        if bntPlay and bntPlay[2] then
            bntPlay[2].alpha = 1
            transition.to(bntPlay[2], {alpha=0, time=1000, onComplete=function()
                bntPlayBlink()
            end})
        end
    end
    bntPlayBlink()


    Util:generateFrame(grpFrame, bntOptions, bntStore, bntPlay, bntLike, numDelay)
    

    grpView:insert(grpHud)


    return grpHud
end


function objScene:create(event)
    local grpView = self.view
    grpView.isVisible = false

    globals_bntBackRelease = nil

    grpViewPort = ViewPort.new(grpView, 1)

    local params = event.params
    if params.isReload then
        tblStats.dTimeStarted = os.time()
        grpViewPort:start()
    else
        grpHud = _createHudFrontend(grpView)
    end

    -- OVERLAY
    rctOverlay = display.newRect(-10, -10, 500, 350)
    rctOverlay.trtCancel = nil
    rctOverlay.anchorX, rctOverlay.anchorY = 0, 0
    rctOverlay:setFillColor(0, .95)
    rctOverlay.alpha = 0
    grpView:insert(rctOverlay)
end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase

    if phase == "will" then

        Composer.stage.alpha = 1

        Controller:setStatus(0)

    elseif phase == "did" then

        if Composer.getSceneName("previous") == "classes.phoenix.controller.scenes.LoadingGameIn" then
            Composer.showOverlay("classes.phoenix.controller.scenes.LoadingGameOut", {isModal = true})

            grpHud:toFront( )
        else
            grpView.isVisible = true
        end

    end
    
    rctOverlay:toFront( )
end


function objScene:destroy(event)
    local grpView = self.view

    if cnlRanking ~= nil then
        timer.cancel(cnlRanking)
        cnlRanking = nil
    end
    if cnlProgress ~= nil then
        timer.cancel(cnlProgress)
        cnlProgress = nil
    end
    if cnlRecord ~= nil then
        timer.cancel(cnlRecord)
        cnlRecord = nil
    end

    grpViewPort:destroy()
    grpViewPort = nil
end


function objScene:overlayBegan(isHideOverlay)
    tblStats.dTimePaused = TIME_PAUSED or os.time()
    TIME_PAUSED = nil

    Trt.pauseAll()

    -- OVERLAY
    if not grpViewPort.isGameOver then
        if rctOverlay.trtCancel ~= nil then
            transition.cancel(rctOverlay.trtCancel)
            rctOverlay.trtCancel = nil
        end
        if isHideOverlay == nil or not isHideOverlay  then
            rctOverlay.alpha = 1
        else
            rctOverlay.alpha = 0
        end
    end
end


function objScene:doCountDown()
    transition.to(rctOverlay, {alpha=.5, time=300, onComplete=function()
        local grpView = rctOverlay.parent

        local tblTxtOptions = {
            parent = grpView,
            text = " 4",
            font = "Maassslicer",
            fontSize = 128,
            align = "center"
        }
        local txtCountDown = display.newText(tblTxtOptions)
        txtCountDown:setFillColor(1)
        txtCountDown.anchorX, txtCountDown.anchorY = .5, .5
        txtCountDown.alpha = 0

        local doCount = function() end
        doCount = function()
            local count = tonumber(txtCountDown.text)
            count = count - 1

            txtCountDown.text = " "..count
            txtCountDown.anchorX, txtCountDown.anchorY = .5, .5
            txtCountDown.x, txtCountDown.y, txtCountDown.alpha = display.contentCenterX, display.contentCenterY, 0
            txtCountDown.xScale, txtCountDown.yScale = 1, 1

            Jukebox:dispatchEvent({name="playSound", id="countdown"})
            transition.to(txtCountDown, {alpha=1, xScale=.5, yScale=.5, delay=100, time=600, transition=easing.outBack, onComplete=function()
                if count == 1 then
                    transition.to(txtCountDown, {alpha=0, xScale=.2, yScale=.2, time=150, onComplete=function()
                        grpView:remove(txtCountDown)
                    end})
                    Controller:setStatus(1)
                    Composer.hideOverlay(false, "fade", 0)
                else
                    doCount()
                end
            end})
        end
        doCount()

    end})
end


function objScene:overlayEnded(isHideOverlay)
    local grpView = self.view

    grpView.isVisible = true

    globals_bntBackRelease = nil

    Trt.resumeAll()

    tblStats.dTimeStarted = os.time() - (tblStats.dTimePaused-tblStats.dTimeStarted)

    -- OVERLAY
    if not grpViewPort.isGameOver then
        if rctOverlay.trtCancel ~= nil then
            transition.cancel(rctOverlay.trtCancel)
            rctOverlay.trtCancel = nil
        end
        if isHideOverlay == nil or not isHideOverlay  then
            rctOverlay.trtCancel = transition.to(rctOverlay, {alpha=0, time=150, delay=50})
        else
            rctOverlay.alpha = 0
        end
    end
end


function objScene:gameOver()
    local grpView = self.view

    local numTime = os.time() - tblStats.dTimeStarted
    local strScore, numReplaced = string.gsub(grpViewPort.txtScore.text, ",", "")
    local numScore = tonumber(strScore)
    Controller:getData():updateResults({stats=grpViewPort:getStats(), statsProfile=grpViewPort:getStatsProfile(), numScore=numScore, codAssist=grpViewPort.codAssist, numTime=numTime})

    if rctOverlay.trtCancel ~= nil then
        transition.cancel(rctOverlay.trtCancel)
        rctOverlay.trtCancel = nil
    end
    rctOverlay.alpha = .8

    grpViewPort[2].isVisible = false

    local rctOverlayBlack = display.newRect(grpView, 0, 0, 500, 350)
    rctOverlayBlack.anchorX, rctOverlayBlack.anchorY = 0, 0
    rctOverlayBlack:setFillColor(0)

    transition.to(rctOverlayBlack, {time=100, onComplete=function()
        transition.to(rctOverlayBlack, {alpha=0, delay=400, time=1000})
        local params = {statsProfile=grpViewPort:getStatsProfile(), codAssist=grpViewPort.codAssist}
        Controller:showSceneOverlay(3, params, true)
    end})
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)
objScene:addEventListener("destroy", objScene)


return objScene