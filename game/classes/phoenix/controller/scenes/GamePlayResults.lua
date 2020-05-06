local Composer = require "composer"
local objScene = Composer.newScene()


local I18N = require "lib.I18N"


local Wgt = require "classes.phoenix.business.Wgt"
local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"
local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"
local AdsGame = require "classes.phoenix.business.AdsGame"


local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())
local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())
local infAchievements = require("classes.infoAchievements")
local shtAchievements = graphics.newImageSheet("images/ui/scnAchievements.png", infAchievements:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random

local function _lerp(v0, v1, t)
    return t * (v1 - v0)
end

local CANCEL_FX
local TIMER_VERIFY_RANKING

local IS_EXITED = false
local TBL_URL = {}
TBL_URL["facebook"] = "https://facebook.com/superphoenix2015"
TBL_URL["twitter"] = "https://twitter.com/ajtechlabs"

local txtRankingTitle = {}
local txtRanking = {}
local numTypeRanking = 1
local tblRankings = {I18N:getString("connecting"), I18N:getString("connecting"), I18N:getString("connecting"), I18N:getString("connecting")}
local cnlRecord = nil
local cnlProgress = nil
local cnlRanking = nil

local _onNetwork = function(event)
    if not event.isError and event.response ~= nil and txtRanking and txtRanking.parent then
        transition.to(txtRanking.parent, {y=Constants.TOP + 3, transition=easing.outBack, time=400})

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


local function _animeCounter(target, value, duration, onComplete)
    Runtime:removeEventListener("enterFrame", updateText)

    if target.text then
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
end

local function _getSeparator(txt1, txt2)
    local numWidthSeparator = txt2.x - txt1.x - (txt1.width + txt2.width)
    local strSeparator = ""
    for i=1, numWidthSeparator * .18 do
        strSeparator = strSeparator .. ". "
    end
    return strSeparator
end

local function _generateStar(grpView, numScale, width, x, y)
    if grpView.insert then
        local sptStar = display.newSprite(shtUtilUi, {{name="s", start=11, count=1}})
        sptStar.anchorX, sptStar.anchorY = .5, .5
        sptStar.x, sptStar.y = x, y
        sptStar:scale(numScale, numScale)
        grpView:insert(sptStar)
        sptStar.xTo = x - width
        local numTime = 1800 * width * .007
        transition.to(sptStar, {x=sptStar.xTo, time=numTime, transition=easing.outExpo, alpha=0, onComplete=function(self)
            if grpView and grpView.remove then
                grpView:remove(self)
                self = nil
            end
        end})
    end
end

local function _nextScene(params)
    local nPlayed = Controller:getData():getProfile("nPlayedCount")

    Composer.stage.alpha = 0
    local options = {
        effect = "fade",
        time = 0,
        params = params
    }

    local _goNextScene = function() 
        Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
    end

    globals_adCallbackListener = function(params)
        phase = params.phase
        if phase == "hidden" or phase == "bug" then
            _goNextScene()
            globals_adCallbackListener = function() end
        end
    end

    if nPlayed % Constants.NUM_GAMES_PLAYED_TO_SHOW_RATE == 0 and random(2) == 1 and not Controller:getData():getProfile("isBeenRated") then
        Composer.gotoScene("classes.phoenix.controller.scenes.RateIt", options)

    elseif nPlayed % Constants.NUM_GAMES_PLAYED_TO_SHOW_AD == 0 and Controller:getData():getProfile("ads") then
        local isShowingAd = AdsGame:show()
        if not isShowingAd then
            _goNextScene()
        end

    else
        _goNextScene()
    end
end


function objScene:create(event)
    local grpView = self.view
    grpView.isVisible = false


    local grpFrame = display.newGroup()
    grpView:insert(grpFrame)
    local grpHud = display.newGroup()
    grpView:insert(grpHud)


    local  grpRanking = display.newGroup()
    grpHud:insert(grpRanking)


    local params = {}
    local statsProfile = event.params.statsProfile
    local codAssist = event.params.codAssist

    -- INIT
    local _verifyIsCompletedMissions = function() end

    -- CASH
    local grpCash = display.newGroup()
    grpHud:insert(grpCash)

    local NUM_SCORE_BONUS = statsProfile.nScoreBonus.v
    local NUM_TIME_BONUS = statsProfile.nTimeBonus.v
    local NUM_COMBOS_BONUS = statsProfile.nCombosBonus.v
    local NUM_CASH_COLLECTED = NUM_SCORE_BONUS + NUM_TIME_BONUS + NUM_COMBOS_BONUS
    if codAssist == 11 then
        NUM_CASH_COLLECTED = NUM_CASH_COLLECTED * 2
    end

    local tblTxtOptions = {
        parent = grpCash,
        text = " "..Util:formatNumber(Controller:getData():getCash() - NUM_CASH_COLLECTED),
        font = "Maassslicer",
        fontSize = 26,
        align = "right"
    }
    local txtCash = display.newText(tblTxtOptions)
    txtCash:setFillColor(1, 1, .2)
    txtCash.anchorX, txtCash.anchorY = 1, .5
    txtCash.x, txtCash.y = 0, -3

    local imgCashCoin = display.newSprite(shtUtilUi, { {name="s", start=9, count=1} })
    imgCashCoin.anchorX, imgCashCoin.anchorY = 0, .5
    imgCashCoin.x, imgCashCoin.y = 0, -5
    grpCash:insert(imgCashCoin)

    grpCash.anchorChildren = true
    grpCash.anchorX, grpCash.anchorY = 1, 0
    grpCash.x, grpCash.y = Constants.RIGHT, Constants.TOP
    grpCash.alpha = 0


    local grpCoins = display.newGroup( )
    local function animCoin(self)
        if self.cancel ~= nil then
            transition.cancel(self.cancel)
            self.cancel = nil
        end
        self.x, self.y, self.alpha = self.xFrom, self.yFrom, self.alphaFrom
        self.cancel = transition.to(self, {time=400, x=self.xTo, y=self.yTo, alpha=self.alphaTo, onComplete=function(self)
            if grpView then
                self:animCoin()
            end
        end})

        if grpCash.x then
            local sptStar = self.sptStar
            sptStar.rotation = random(360)
            sptStar.xScale, sptStar.yScale, sptStar.alpha = .1, .1, 0
            sptStar.x, sptStar.y = grpCash.x - random(35), grpCash.y + random(35)
            transition.to(sptStar, {time=100, rotation=sptStar.rotation+45, xScale=.7, yScale=.7, alpha=1, onComplete=function()
                if sptStar and sptStar.rotation then
                    transition.to(sptStar, {time=300, rotation=sptStar.rotation+60, xScale=.1, yScale=.1, alpha=0})
                end
            end} )
        end
    end 
    for i=1, 4 do
        local imgCoin = display.newSprite(shtUtilUi, { {name="s", start=9, count=1} })
        imgCoin.id, imgCoin.anchorX, imgCoin.anchorY, imgCoin.x, imgCoin.y = i, 0, .5, 1000, 1000
        imgCoin.animCoin = animCoin
        grpCoins:insert(imgCoin)

        local sptStar = display.newSprite(shtUtilUi, { {name="s", start=13, count=1} })
        sptStar:setFillColor(1, .9, 0)
        grpHud:insert(sptStar)
        sptStar.rotation = random(360)
        sptStar.x, sptStar.y = 1000, 1000
        imgCoin.sptStar = sptStar
    end
    local function animCoins(dir)
        if grpCoins.cancel ~= nil then
            transition.cancel(grpCoins.cancel)
            grpCoins.cancel = nil
        end
        grpCoins.alpha = 1
        if dir == nil then
            Jukebox:dispatchEvent({name="stopSoundCoins"})
            grpCoins.cancel = transition.to(grpCoins, {alpha=.01, time=200, onComplete=function()
                if grpCoins.numChildren then
                    for i=1, grpCoins.numChildren do
                        local img = grpCoins[i]
                        if img.cancel ~= nil then
                            transition.cancel(img.cancel)
                            img.cancel = nil
                        end
                    end
                end
            end})
        elseif not IS_EXITED then
            Jukebox:dispatchEvent({name="playSoundCoins"})
            if grpCoins.numChildren then
                for i=1, grpCoins.numChildren do
                    local img = grpCoins[i]
                    img.xFrom, img.yFrom, img.alphaFrom = -img.width, img.height * .5, 1
                    img.xTo, img.yTo, img.alphaTo = img.xFrom + random(-10, 10) * 2, 70, 0
                    if dir == -1 then
                        local xFrom, yFrom, alphaFrom = img.xFrom, img.yFrom, img.alphaFrom
                        img.xFrom, img.yFrom, img.alphaFrom = img.xTo, img.yTo - 10, img.alphaTo
                        img.xTo, img.yTo, img.alphaTo = xFrom, yFrom, alphaFrom
                    end
                    img.x, img.y, img.alpha = img.xFrom, img.yFrom, img.alphaFrom
                    timer.performWithDelay(img.id * 150, function()
                        if img and img.animCoin then
                            img:animCoin()
                        end
                    end, 1)
                end
            end
        end
    end
    grpCoins.x, grpCoins.y = grpCash.x, grpCash.y
    grpCoins.anchorX, grpCoins.anchorY = grpCash.anchorX, grpCash.anchorY
    grpHud:insert(grpCoins)
    grpCoins:toBack()

    -- SCORE
    local grpScoreGame = display.newGroup()
    grpView:insert(grpScoreGame)
    local strScore = Util:formatNumber(statsProfile.nScore.v)
    local txtScore = display.newText(grpScoreGame, " "..strScore, 0, 0, "Maassslicer", 125)
    txtScore.anchorX, txtScore.anchorY = .5, .5
    txtScore.x, txtScore.y = 0, 0

    -- STARS
    local _reposition = function(self, numWidth, numHeight, numDelay)
        if txtScore.x and txtScore.width then
            self.alpha = 0
            self.rotation = random(360)
            self.x, self.y = txtScore.x + (random(numWidth) * (random(2) == 1 and 1 or -1)), txtScore.y + (random(numHeight) * (random(2) == 1 and 1 or -1))
            numDelay = numDelay or 0
            local numD = numDelay + random(10) * 20
            transition.to(self, {alpha=1, delay=numD, rotation=self.rotation+40, time=300, onComplete=function()
                if self and self.rotation then
                    local numRot = self.rotation + random(5, 10) * 10
                    local numTime = random(4, 10) * 100
                    transition.to(self, {alpha=0, rotation=numRot, time=numTime, onComplete=function()
                        if self.reposition then
                            self:reposition(numWidth, numHeight)
                        end
                    end})
                end
            end})
        end
    end
    for i=1, 3 do
        local sptStar = display.newSprite(shtUtilUi, { {name="s", start=13, count=1} })
        grpScoreGame:insert(sptStar)
        local numWidth = txtScore.width * .5
        local numHeight = txtScore.height * .5
        sptStar.reposition = _reposition
        sptStar:scale(2, 2)
        sptStar:reposition(numWidth, numHeight, random(3) * 100)
    end

    if statsProfile.nScoreH.b == 1 then
        local imgRecord = display.newSprite(shtUtilUi, { {name="s", start=11, count=1} })
        grpScoreGame:insert(imgRecord)
        imgRecord.anchorX, imgRecord.anchorY = 0, .5
        imgRecord.x, imgRecord.y, imgRecord.alpha = txtScore.x + txtScore.width * .5 + 150, txtScore.y - 10, 0
        imgRecord:scale(2, 2)
        transition.to(imgRecord, {alpha=1, x=imgRecord.x - 150, transition=easing.inQuad, time=250, delay=800, onComplete=function()
            Jukebox:dispatchEvent({name="playSound", id="recordScore"})
            if txtScore and txtScore.width then
                _generateStar(grpView, 1, txtScore.width * .5 + 25, grpScoreGame.x + grpScoreGame.width * .4 * .5, grpScoreGame.y - 4, .25)
            end
        end})
    end

    grpScoreGame.x, grpScoreGame.y, grpScoreGame.alpha, grpScoreGame.xScale, grpScoreGame.yScale = display.contentCenterX, display.contentCenterY, 0, 1, 1


    -- SCORE
    local grpScore = display.newGroup()
    grpScore.alpha = 0
    grpView:insert(grpScore)

    local txtScoreLabel = display.newText(grpScore, I18N:getString("score"), 0, 0, "Maassslicer", 10)
    txtScoreLabel.anchorX, txtScoreLabel.anchorY = 0, 1
    txtScoreLabel:setFillColor(1)
    txtScoreLabel.x, txtScoreLabel.y = -100, 0

    local txtScoreValue = display.newText(grpScore, " +"..Util:formatNumber(NUM_SCORE_BONUS), 0, 0, "Maassslicer", 10)
    txtScoreValue.anchorX, txtScoreValue.anchorY = 1, 1
    txtScoreValue:setFillColor(1)
    txtScoreValue.x, txtScoreValue.y = 100, 0

    local txtScoreSeparator = display.newText(grpScore, _getSeparator(txtScoreLabel, txtScoreValue), 0, 0, "Maassslicer", 9)
    txtScoreSeparator.anchorX, txtScoreSeparator.anchorY = 0, 1
    txtScoreSeparator.x, txtScoreSeparator.y, txtScoreSeparator.alpha = txtScoreLabel.x + txtScoreLabel.width, -1, .2

    local imgRecordS = display.newSprite(shtUtilUi, { {name="s", start=11, count=1} })
    imgRecordS:scale(.5, .5)
    imgRecordS.anchorX, imgRecordS.anchorY = 0, 1
    imgRecordS.x, imgRecordS.y, imgRecordS.alpha = txtScoreValue.x + 50, 6, 0
    grpScore:insert(imgRecordS)

    grpScore.anchorChildren = true
    grpScore.anchorX, grpScore.anchorY = .5, .5
    grpScore.x, grpScore.y = 0, grpScoreGame.y + txtScore.height * .25 + 60


    -- TIME
    local grpTime = display.newGroup()
    grpTime.alpha = 0
    grpView:insert(grpTime)

    local txtTimeLabel = display.newText(grpTime, I18N:getString("time"), 0, 0, "Maassslicer", 10)
    txtTimeLabel.anchorX, txtTimeLabel.anchorY = 0, 1
    txtTimeLabel:setFillColor(1)
    txtTimeLabel.x, txtTimeLabel.y = -100, 0

    local txtTimeValue = display.newText(grpTime, " +"..Util:formatNumber(NUM_TIME_BONUS), 0, 0, "Maassslicer", 10)
    txtTimeValue.anchorX, txtTimeValue.anchorY = 1, 1
    txtTimeValue:setFillColor(1)
    txtTimeValue.x, txtTimeValue.y = 100, 0

    local txtTimeSeparator = display.newText(grpTime, _getSeparator(txtTimeLabel, txtTimeValue), 0, 0, "Maassslicer", 9)
    txtTimeSeparator.anchorX, txtTimeSeparator.anchorY = 0, 1
    txtTimeSeparator.x, txtTimeSeparator.y, txtTimeSeparator.alpha = txtTimeLabel.x + txtTimeLabel.width, -2, .2

    local imgRecordT = display.newSprite(shtUtilUi, { {name="s", start=11, count=1} })
    imgRecordT:scale(.5, .5)
    imgRecordT.anchorX, imgRecordT.anchorY = 0, 1
    imgRecordT.x, imgRecordT.y, imgRecordT.alpha = txtTimeValue.x + 55, 6, 0
    grpTime:insert(imgRecordT)

    grpTime.anchorChildren = true
    grpTime.anchorX, grpTime.anchorY = .5, .5
    grpTime.x, grpTime.y = 0, grpScoreGame.y + txtScore.height * .25 + 60


    -- COMBOS
    local grpCombos = display.newGroup()
    grpCombos.alpha = 0
    grpView:insert(grpCombos)

    local txtCombosLabel = display.newText(grpCombos, I18N:getString("combos"), 0, 0, "Maassslicer", 10)
    txtCombosLabel.anchorX, txtCombosLabel.anchorY = 0, 1
    txtCombosLabel:setFillColor(1)
    txtCombosLabel.x, txtCombosLabel.y = -100, 0

    local txtCombosValue = display.newText(grpCombos, " +"..Util:formatNumber(NUM_COMBOS_BONUS), 0, 0, "Maassslicer", 10)
    txtCombosValue.anchorX, txtCombosValue.anchorY = 1, 1
    txtCombosValue:setFillColor(1)
    txtCombosValue.x, txtCombosValue.y = 100, 0

    local txtCombosSeparator = display.newText(grpCombos, _getSeparator(txtCombosLabel, txtCombosValue), 0, 0, "Maassslicer", 9)
    txtCombosSeparator.anchorX, txtCombosSeparator.anchorY = 0, 1
    txtCombosSeparator.x, txtCombosSeparator.y, txtCombosSeparator.alpha = txtCombosLabel.x + txtCombosLabel.width, -2, .2

    local imgRecordC = display.newSprite(shtUtilUi, { {name="s", start=11, count=1} })
    imgRecordC:scale(.5, .5)
    imgRecordC.anchorX, imgRecordC.anchorY = 0, 1
    imgRecordC.x, imgRecordC.y, imgRecordC.alpha = txtCombosValue.x + 55, 6, 0
    grpCombos:insert(imgRecordC)

    grpCombos.anchorChildren = true
    grpCombos.anchorX, grpCombos.anchorY = .5, .5
    grpCombos.x, grpCombos.y = 0, grpScoreGame.y + txtScore.height * .25 + 60


    -- COINS
    local grpCoinsCollect = display.newGroup()
    grpCoinsCollect.alpha = 0
    grpView:insert(grpCoinsCollect)

    local txtCoinsLabel = display.newText(grpCoinsCollect, I18N:getString("coins"), 0, 0, "Maassslicer", 14)
    txtCoinsLabel.anchorX, txtCoinsLabel.anchorY = 0, 1
    txtCoinsLabel:setFillColor(1, 1)
    txtCoinsLabel.x, txtCoinsLabel.y = -102, 0

    local txtCoinsValue = display.newText(grpCoinsCollect, " "..Util:formatNumber(NUM_CASH_COLLECTED), 0, 0, "Maassslicer", 14)
    txtCoinsValue:setFillColor(1, 1, .2)
    txtCoinsValue.anchorX, txtCoinsValue.anchorY = 1, 1
    txtCoinsValue.x, txtCoinsValue.y = 102, 0

    local sptCoinCollect = display.newSprite(shtUtilUi, {{name="s", start=10, count=1}})
    sptCoinCollect.anchorX, sptCoinCollect.anchorY = 0, 1
    sptCoinCollect.x, sptCoinCollect.y = txtCoinsValue.x, txtCoinsValue.y - 3
    grpCoinsCollect:insert(sptCoinCollect)

    local txtCoinsSeparator = display.newText(grpCoinsCollect, _getSeparator(txtCoinsLabel, txtCoinsValue), 0, 0, "Maassslicer", 9)
    txtCoinsSeparator.anchorX, txtCoinsSeparator.anchorY = 0, 1
    txtCoinsSeparator.x, txtCoinsSeparator.y, txtCoinsSeparator.alpha = txtCoinsLabel.x + txtCoinsLabel.width, -2, .4

    txtCoinsValue.text = " 0"

    grpCoinsCollect.anchorChildren = true
    grpCoinsCollect.anchorX, grpCoinsCollect.anchorY = .5, .5
    grpCoinsCollect.x, grpCoinsCollect.y = 0, grpScoreGame.y + txtScore.height * .25 + 20    


    local grpRecord = display.newGroup()
    grpRecord.alpha = 0
    grpView:insert(grpRecord)

    local NUM_RECORD = Controller:getData():getDecryptedScore()
    local txtRecord = display.newText(grpRecord, I18N:getString("bestFrontend").." :"..Util:formatNumber(NUM_RECORD), 0, 0, "Maassslicer", 14)
    txtRecord:setFillColor(1)
    txtRecord.anchorX, txtRecord.anchorY = .5, .5
    txtRecord.x, txtRecord.y = 0, 0

    grpRecord.anchorX, grpRecord.anchorY = .5, .5
    grpRecord.x, grpRecord.y = display.contentCenterX, grpCoinsCollect.y


    local posX = display.contentCenterX + 40
    grpScore.x, grpTime.x, grpCombos.x, grpCoinsCollect.x = posX - 9, posX - 5, posX - 5, posX - 40


    local bntShare = {}
    local grpTwitter = display.newGroup()
    local grpFacebook = display.newGroup()
    local bntOk = {}
    local bntTize = {}

    local function onShareReleased(event)
        local serviceName = event.target.id
        local isAvailable = system.getInfo("platformName") == "Android" and true or native.canShowPopup("social", serviceName)

        if isAvailable then
            grpScore.isVisible = false
            grpTime.isVisible = false
            grpCombos.isVisible = false
            grpCoinsCollect.isVisible = false
            grpCash.alpha = 1
            grpRecord.alpha = 1
            grpFacebook.isVisible = false
            grpTwitter.isVisible = false
            bntShare.isVisible = false
            bntOk.isVisible = false
            grpRanking.isVisible = false
            grpScoreGame.xScale, grpScoreGame.yScale = .5, .5
            txtCash.text = " "..Util:formatNumber(Controller:getData():getCash())

            Runtime:removeEventListener("enterFrame", updateText)
            if CANCEL_FX ~= nil then 
                transition.cancel(CANCEL_FX) 
                CANCEL_FX = nil
            end
            if bntTize and bntTize.removeSelf then          
                bntTize:removeSelf()
                bntTize = nil
            end

            local grpScreen = display.newGroup()
            grpView:insert(grpScreen)
            grpScreen:toBack()
            local screenCap = display.captureScreen(false)
            local screenWidth, screenHeight = screenCap.contentWidth, screenCap.contentHeight
            grpScreen:insert(screenCap)
            local sptBrand = display.newSprite(shtUtilUi, { {name="s", start=1, count=1} })
            grpScreen:insert(sptBrand)
            sptBrand:scale(.9, .9)
            sptBrand.anchorX, sptBrand.anchorY = 0, 1
            sptBrand.x, sptBrand.y = -screenWidth* .5 + 2, screenHeight * .5 - 2
            local sptIcon = display.newSprite(shtUtilUi, { {name="s", start=51, count=1} })
            grpScreen:insert(sptIcon)
            sptIcon.anchorX, sptIcon.anchorY = 1, 1
            sptIcon.x, sptIcon.y = screenWidth * .5 - 2, screenHeight * .5 - 2
            grpScreen.x, grpScreen.y = display.contentCenterX, display.contentCenterY
            --[
            display.save(grpScreen, {filename="super_phoenix.png", isFullResolution=true, baseDir=system.CachesDirectory, backgroundColor={0,0,0}})

            native.showPopup("social", {
                service = serviceName, 
                message = "",
                image = {
                    {filename="super_phoenix.png", baseDir=system.CachesDirectory},
                },
                url = { 
                    TBL_URL[serviceName],
                }
            })

            grpView:remove(grpScreen)
            grpScreen = nil
            --]]
            grpFacebook.isVisible = true
            grpTwitter.isVisible = true
            bntShare.isVisible = true
            bntOk.isVisible = true
            grpRanking.isVisible = true
        else
            local strAlertTitle = string.gsub(I18N:getString("shareErrorTitle"), "xxx", serviceName)
            local strAlertDescription = string.gsub(I18N:getString("shareErrorDescription"), "xxx", serviceName)
            native.showAlert(strAlertTitle, strAlertDescription, {"OK"})
            Util:hideStatusbar()
        end

        return true
    end


    grpHud:insert(grpTwitter)
    local bntTwitter = Wgt.newButton{
        sheet = shtButtons,
        id = "twitter",
        defaultFrame = 6,
        onRelease = onShareReleased
    }
    grpTwitter:insert(bntTwitter)
    grpTwitter.anchorX, grpTwitter.anchorY = 0, 1
    grpTwitter.x, grpTwitter.y = Constants.LEFT - 100, Constants.BOTTOM - 80
    grpTwitter:scale(.6, .6)


    grpHud:insert(grpFacebook)
    local bntFacebook = Wgt.newButton{
        sheet = shtButtons,
        id = "facebook",
        defaultFrame = 3,
        onRelease = onShareReleased
    }
    grpFacebook:insert(bntFacebook)
    grpFacebook.anchorX, grpFacebook.anchorY = 0, 1
    grpFacebook.x, grpFacebook.y = Constants.LEFT - 100, Constants.BOTTOM - 120
    grpFacebook:scale(.6, .6)


    local function onBntShareReleased(event)
        bntShare.isOn = not bntShare.isOn
        local x = bntShare.isOn and Constants.LEFT + 30 or Constants.LEFT - 30
        if bntShare.trtCancel ~= nil then transition.cancel(bntShare.trtCancel) end
        bntShare.trtCancel = transition.to(grpTwitter, {x=x, time=300, transition=easing.outBack, onComplete=function()
            bntShare.trtCancel = transition.to(grpFacebook, {x=x, transition=easing.outBack, time=300})
        end})
        return true
    end
    bntShare = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = system.getInfo("platformName") == "Android" and 44 or 18,
        onRelease = system.getInfo("platformName") == "Android" and onShareReleased or onBntShareReleased
    }
    bntShare.trtCancel = nil
    bntShare.isOn = false


    -- OK
    local bntOkRelease = function()
        _nextScene({scene="classes.phoenix.controller.scenes.Store"})
        return true
    end
    bntOk = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 11,
        onRelease = bntOkRelease
    }


    -- ACHIEVEMENTS
    local function btnAchievementsRelease()
        _nextScene({scene="classes.phoenix.controller.scenes.Achievement"})
        return true
    end
    local bntAchievements = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 29,
        onRelease = btnAchievementsRelease
    }

    -- TOTALIZE
    local canTize = false
    local function bntTizeRelease(self, event)
        if event.phase == "ended" then
    		Runtime:removeEventListener("enterFrame", updateText)
            if CANCEL_FX ~= nil then 
                transition.cancel(CANCEL_FX) 
                CANCEL_FX = nil
                transition.to(grpCash, {alpha=1, time=200})
                transition.to(grpRecord, {time=300, alpha=1})
                transition.to(grpScoreGame, {time=300, alpha=1, yScale=.5, xScale=.5, transition=easing.outBack})
            end
            if txtCoinsValue.text then
                txtCoinsValue.text = " 0"
            end
            transition.to(grpCoinsCollect, {alpha=0, time=200})
            transition.to(grpScore, {alpha=0, time=200})
            transition.to(grpTime, {alpha=0, time=200})
            transition.to(grpCombos, {alpha=0, time=200, onComplete=function()
                grpCoinsCollect.isVisible = false
                grpScore.isVisible = false
                grpTime.isVisible = false
                grpCombos.isVisible = false
            end})
            txtCash.text = " "..Util:formatNumber(Controller:getData():getCash())
            animCoins()
            self:removeSelf()
            self = nil
        end
        return false
    end
    bntTize = display.newRect(grpView, 0, 0, display.actualContentWidth, display.actualContentHeight)
    bntTize.touch = bntTizeRelease
    bntTize:addEventListener("touch", bntTize)
    bntTize.anchorX, bntTize.anchorY = .5, .5
    bntTize.x, bntTize.y, bntTize.alpha = display.contentCenterX, display.contentCenterY, .01
    bntTize:toBack()

    timer.performWithDelay(1, function()
        Jukebox:dispatchEvent({name="playSound", id="gameover"})
    end, 1)
    
    -- FX
    grpScoreGame.alpha = .3
    CANCEL_FX = transition.to(grpScoreGame, {alpha=1, time=400, yScale=.4, xScale=.4, transition=easing.outBack, onComplete=function()

        if grpCoinsCollect.y then
        CANCEL_FX = transition.to(grpCoinsCollect, {alpha=1, time=300, delay=1000, onComplete=function()

            -- SCORE
            if grpScore.y then
            if NUM_SCORE_BONUS > 0 then Jukebox:dispatchEvent({name="playSound", id="bonusCollected"}) end
            CANCEL_FX = transition.to(grpScore, {alpha=1, time=300, y=grpScore.y-20, transition=easing.outExpo, onComplete=function()
            if statsProfile.nScoreBonusH.b ~= 1 then
                imgRecordS.isVisible = false
            elseif imgRecordS.x then
                transition.to(imgRecordS, {alpha=1, x=imgRecordS.x - 30, transition=easing.inQuad, time=100, onComplete=function()
                    transition.to(imgRecordS, {alpha=0, delay=450, time=100, onComplete=function(self)
                        if self.x then self.x = self.x + 30 end
                    end})
                    Jukebox:dispatchEvent({name="playSound", id="recordScoreBonus"})
                    if grpScore and grpScore.width then
                        _generateStar(grpView, .5, grpScore.width + 15, grpScore.x + grpTime.width * .5 - 40, grpScore.y, 1)
                    end
                end})
            end
            if grpScore.y then
            local yTo = NUM_SCORE_BONUS > 0 and (grpScore.y - 25) or grpScore.y + 20
            CANCEL_FX = transition.to(grpScore, {alpha=0, delay=700, time=200, y=yTo, onComplete=function()
            if NUM_SCORE_BONUS > 3 then Jukebox:dispatchEvent({name="playSoundCoins"}) end
            _animeCounter(txtCoinsValue, NUM_SCORE_BONUS, 500, function()
                Jukebox:dispatchEvent({name="stopSoundCoins"})

                -- TIME
                if grpTime.y then
                if NUM_TIME_BONUS > 0 then Jukebox:dispatchEvent({name="playSound", id="bonusCollected"}) end
                CANCEL_FX = transition.to(grpTime, {alpha=1, time=300, y=grpTime.y-20, transition=easing.outExpo, onComplete=function()
                if statsProfile.nTimeBonusH.b ~= 1 then
                    imgRecordT.isVisible = false
                elseif imgRecordT.x then
                    transition.to(imgRecordT, {alpha=1, x=imgRecordT.x - 30, transition=easing.inQuad, time=100, onComplete=function()
                        transition.to(imgRecordT, {alpha=0, delay=450, time=100, onComplete=function(self)
                            if self.x then self.x = self.x + 30 end
                        end})
                        Jukebox:dispatchEvent({name="playSound", id="recordTimeBonus"})
                        if grpTime and grpTime.width then
                            _generateStar(grpView, .5, grpTime.width + 15, grpTime.x + grpTime.width * .5 - 35, grpTime.y, 1)
                        end
                    end})
                end
                if grpTime.y then
                local yTo = NUM_TIME_BONUS > 0 and (grpTime.y - 25) or grpTime.y + 20
                CANCEL_FX = transition.to(grpTime, {alpha=0, delay=700, time=200, y=yTo, onComplete=function()
                if NUM_TIME_BONUS > 3 then Jukebox:dispatchEvent({name="playSoundCoins"}) end
                _animeCounter(txtCoinsValue, (NUM_SCORE_BONUS + NUM_TIME_BONUS), 500, function()
                    Jukebox:dispatchEvent({name="stopSoundCoins"})

                    -- COMBOS
                    if grpCombos.y then
                    if NUM_COMBOS_BONUS > 0 then Jukebox:dispatchEvent({name="playSound", id="bonusCollected"}) end
                    CANCEL_FX = transition.to(grpCombos, {alpha=1, time=300, y=grpCombos.y-20, transition=easing.outExpo, onComplete=function()
                    if statsProfile.nCombosBonusH.b ~= 1 then
                        imgRecordC.isVisible = false
                    elseif imgRecordC.x then
                        transition.to(imgRecordC, {alpha=1, x=imgRecordC.x - 30, transition=easing.inQuad, time=100, onComplete=function()
                            transition.to(imgRecordC, {alpha=0, delay=450, time=100, onComplete=function(self)
                                if self.x then self.x = self.x + 30 end
                            end})
                            Jukebox:dispatchEvent({name="playSound", id="recordComboBonus"})
                            if grpCombos and grpCombos.width then
                                _generateStar(grpView, .5, grpCombos.width + 15, grpCombos.x + grpCombos.width * .5 - 35, grpCombos.y, 1)
                            end
                        end})
                    end
                    if grpCombos.y then
                    local yTo = NUM_COMBOS_BONUS > 0 and (grpCombos.y - 25) or grpCombos.y + 20
                    CANCEL_FX = transition.to(grpCombos, {alpha=0, delay=700, time=200, y=yTo, onComplete=function()

                        CANCEL_FX = transition.to(grpCash, {alpha=1, time=500})

                        -- COINS
                        if txtCoinsValue.text then
                        if NUM_COMBOS_BONUS > 3 then Jukebox:dispatchEvent({name="playSoundCoins"}) end
                        _animeCounter(txtCoinsValue, (NUM_SCORE_BONUS + NUM_TIME_BONUS + NUM_COMBOS_BONUS), 500, function()
                            Jukebox:dispatchEvent({name="stopSoundCoins"})

                            local numDelay = 0
                            if codAssist == 11 then
                                local imgAssist = display.newSprite(shtButtons, { {name="s", start=36, count=1} })
                                grpCoinsCollect:insert(imgAssist)
                                imgAssist.anchorX, imgAssist.anchorY = .5, .5
                                imgAssist.xScale, imgAssist.yScale, imgAssist.alpha = .1, .1, 0
                                imgAssist.x, imgAssist.y = 142, sptCoinCollect.y - sptCoinCollect.height * .5
                                numDelay = 1000
                                transition.to(imgAssist, {alpha=1, time=numDelay * .75, xScale=.9, yScale=.9, transition=easing.outElastic})
                                Jukebox:dispatchEvent({name="playSound", id="recordScoreBonus"})
                            end
                            CANCEL_FX = transition.to(grpCoinsCollect, {time=numDelay, onComplete=function()
                                if txtCoinsValue.text then
                                    if codAssist == 11 then Jukebox:dispatchEvent({name="playSoundCoins"}) end
                                    _animeCounter(txtCoinsValue, NUM_CASH_COLLECTED, 500, function()
                                        Jukebox:dispatchEvent({name="stopSoundCoins"})
                                        CANCEL_FX = transition.to(grpView, {delay=numDelay, time=300, onComplete=function()
                                            if txtCoinsValue.text and txtCash.text then
                                                _animeCounter(txtCoinsValue, 0, 1000)
                                                if string.gsub(txtCoinsValue.text, ",", "") ~= " 0" then
                                                    animCoins(-1)
                                                end
                                                _animeCounter(txtCash, Controller:getData():getCash(), 1000, function()
                                                    animCoins()
                                                    if grpView and bntTize and bntTize.removeSelf then
                                                        grpView:remove(bntTize)
                                                        bntTize = nil
                                                    end
                                                    CANCEL_FX = transition.to(grpCoinsCollect, {alpha=0, delay=300, time=500, onComplete=function()
                                                        transition.to(grpRecord, {time=300, alpha=1})
                                                        transition.to(grpScoreGame, {time=300, alpha=1, yScale=.5, xScale=.5, transition=easing.outBack})
                                                    end})
                                                end)
                                            end
                                        end})
                                    end)
                                end
                            end})

                        end)
                        end

                    end})
                    end
                    end})
                    end

                end)
                end})
                end
                end})
                end

            end)
            end})
            end
            end})
            end

        end})
        end

    end})


    -- ACHIEVEMENTS
    _verifyIsCompletedMissions = function()

        if grpView then

            Controller:verifyIsCompletedMissions()
            local tblMissions = Controller:getData():getDescribeMissions()

            local grpMissions = display.newGroup()
            grpView:insert(grpMissions)
            grpMissions:toBack()

            local numLineHeight = 35

            for i=1, #tblMissions do
                local tblMission = tblMissions[i]

                local sptIcon = display.newSprite(shtAchievements, { {name="s", start=tblMission.numType, count=1} })
                grpMissions:insert(sptIcon)
                sptIcon:scale(.5, .5)
                sptIcon.anchorX, sptIcon.anchorY = .5, .5
                sptIcon.x, sptIcon.y = 10, i * numLineHeight * .5 - 1

                local tblTxtOptions = {
                    parent = grpMissions,
                    font = "Maassslicer",
                    align = "left",
                    fontSize = 12
                }

                tblTxtOptions.text = " "..Util:formatNumber(tblMission.numTotal)
                local txtTotal = display.newText(tblTxtOptions)
                txtTotal:setFillColor(1, 1)
                txtTotal.anchorX, txtTotal.anchorY = 0, .5
                txtTotal.x, txtTotal.y = sptIcon.x + 8, i * numLineHeight * .5

                tblTxtOptions.text = tblMission.numToGo == nil and "" or " [ "..Util:formatNumber(tblMission.numToGo).." ] "
                local txtToGo = display.newText(tblTxtOptions)
                txtToGo:setFillColor(1, .4)
                txtToGo.anchorX, txtTotal.anchorY = 0, .5
                txtToGo.x, txtToGo.y = txtTotal.x + txtTotal.width, i * numLineHeight * .5
            end

            grpMissions.anchorX, grpMissions.anchorY = 0, 0
            grpMissions.x, grpMissions.y = Constants.LEFT + 20, Constants.TOP - 7
            grpMissions.alpha = 0
            transition.to(grpMissions, {alpha=1, x=Constants.LEFT + 63, time=400, delay=500, transition=easing.outBack})

        end
    end
    timer.performWithDelay(1, _verifyIsCompletedMissions, 1)


    -- RANKING
    local tblTxtOptions = {
        font = "Maassslicer",
        align = "center",
    }

    tblTxtOptions.text = I18N:getString("rank"..numTypeRanking)
    tblTxtOptions.fontSize = 9
    tblTxtOptions.parent = grpRanking

    txtRankingTitle = display.newText(tblTxtOptions)
    txtRankingTitle:setFillColor(1)
    txtRankingTitle.anchorX, txtRankingTitle.anchorY = .5, 1
    txtRankingTitle.x, txtRankingTitle.y = 0, -1

    tblTxtOptions.text = I18N:getString("connecting")
    tblTxtOptions.fontSize = 10
    tblTxtOptions.parent = grpRanking

    txtRanking = display.newText(tblTxtOptions)
    txtRanking:setFillColor(1, 1, .2)
    txtRanking.anchorX, txtRanking.anchorY = .5, 0
    txtRanking.x, txtRanking.y = 0, 1

    local function _onRankingChange()
        timer.cancel(cnlRanking)
        numTypeRanking = numTypeRanking == 4 and 1 or (numTypeRanking + 1)
        local numRank = numTypeRanking
        transition.fadeOut(grpRanking, {time=250, onComplete=function()
            txtRankingTitle.text = " "..I18N:getString("rank"..numRank)
            txtRanking.text = tblRankings[numRank] == "0º" and I18N:getString("none") or " "..tblRankings[numRank]
            transition.fadeIn(grpRanking, {time=250})
        end})

        cnlRanking = timer.performWithDelay(3000, _onRankingChange, 1)
    end

    grpRanking.anchorChildren = true
    grpRanking.anchorX, grpRanking.anchorY = .5, 0
    grpRanking.x, grpRanking.y = display.contentCenterX, Constants.TOP - 50

    local function _onRankingTouch(self, event)
        local phase = event.phase
        if phase == "ended" then
            Jukebox:dispatchEvent({name="playSound", id="button"})
            _nextScene({scene="classes.phoenix.controller.scenes.Ranking", numTypeRanking=numTypeRanking})
        end
        return true
    end

    local function _verifyRanking()
        Controller:getData():getRanking(_onNetwork, {r=numTypeRanking, m=1})
        cnlRanking = timer.performWithDelay(4000, _onRankingChange, 1)

        local rctRankingOverlay = display.newRect(0, 0, txtRankingTitle.width + 30, 50)
        grpHud:insert(rctRankingOverlay)
        rctRankingOverlay.anchorX, rctRankingOverlay.anchorY = .5, 0
        rctRankingOverlay.x, rctRankingOverlay.y, rctRankingOverlay.alpha = display.contentCenterX, Constants.TOP, .01
        rctRankingOverlay:toBack()
        rctRankingOverlay.touch = _onRankingTouch
        rctRankingOverlay:addEventListener("touch", rctRankingOverlay)
    end

    TIMER_VERIFY_RANKING = timer.performWithDelay(5000, _verifyRanking, 1)


    Util:generateFrame(grpFrame, bntAchievements, sptCashBG, bntOk, bntShare)


    bntTize:toFront()


end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase

    if phase == "will" then

        globals_bntBackRelease = nil

        IS_EXITED = false

    elseif phase == "did" then

        Controller:setStatus(3, true)

        Jukebox:dispatchEvent({name="stopSoundCoins"})
        
    end
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase

    if phase == "will" then

        IS_EXITED = true
        
        if CANCEL_FX ~= nil then 
            transition.cancel(CANCEL_FX) 
            CANCEL_FX = nil
        end

        if TIMER_VERIFY_RANKING ~= nil then
            timer.cancel(TIMER_VERIFY_RANKING)
            TIMER_VERIFY_RANKING = nil
        end
        
    elseif phase == "did" then

        --Controller:setStatus(0)

        Jukebox:dispatchEvent({name="stopSoundCoins"})

    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene