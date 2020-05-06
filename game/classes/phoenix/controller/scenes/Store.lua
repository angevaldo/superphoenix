local Composer = require "composer"
local objScene = Composer.newScene()


local Widget = require "widget"
local I18N = require "lib.I18N"


local Wgt = require "classes.phoenix.business.Wgt"
local Powerup = require "classes.phoenix.entities.Powerup"
local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"
local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"


local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())
local infUtilGameplay = require("classes.infoUtilGameplay")
local shtUtilGameplay = graphics.newImageSheet("images/gameplay/scnUtilGameplay.png", infUtilGameplay:getSheet())
local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())
local infScenario = require("classes.infoScenario")
local shtScenario = graphics.newImageSheet("images/ui/bkgScenario.jpg", infScenario:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random


local txtCash
local NUM_ITEM_ICON_SCALE = .63
local helpTblID = {}
local grpCoins


local bntBackRelease = function(event)
    local options = {
        effect = "fade",
        time = 0
    }
    Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
    return true
end


local function _lerp( v0, v1, t )
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
            Runtime:removeEventListener("enterFrame", updateText)
            if onComplete then
                onComplete()
            end
        end
    end

    Runtime:addEventListener("enterFrame", updateText)
end

local function _animCoin(self)
    if self.cancel ~= nil then
        transition.cancel(self.cancel)
        self.cancel = nil
    end
    self.x, self.y, self.alpha = self.xFrom, self.yFrom, self.alphaFrom
    self.cancel = transition.to(self, {time=500, x=self.xTo, y=self.yTo, alpha=self.alphaTo, onComplete=function(self)
        if self.parent then
            self:_animCoin()
        end
    end})

    local sptStar = self.sptStar
    sptStar.xScale, sptStar.yScale, sptStar.alpha = .1, .1, 0
    sptStar.rotation = random(360)
    sptStar.x, sptStar.y = Constants.RIGHT - random(35), Constants.TOP + random(35)
    transition.to(sptStar, {time=200, rotation=sptStar.rotation+45, xScale=NUM_ITEM_ICON_SCALE, yScale=NUM_ITEM_ICON_SCALE, alpha=1, onComplete=function()
        if sptStar and sptStar.rotation then
            transition.to(sptStar, {time=300, rotation=sptStar.rotation+60, xScale=.1, yScale=.1, alpha=0})
        end
    end} )
end 

local function _initCoins(grp)
    grpCoins = display.newGroup()
    for i=1, 4 do
        local imgCoin = display.newSprite(shtUtilUi, { {name="s", start=9, count=1} })
        imgCoin.id, imgCoin.anchorX, imgCoin.anchorY, imgCoin.x, imgCoin.y = i, 0, .5, 1000, 1000
        imgCoin._animCoin = _animCoin
        grpCoins:insert(imgCoin)

        local sptStar = display.newSprite(shtUtilUi, { {name="standard", start=13, count=1} })
        sptStar:setFillColor(1, .9, 0)
        grp:insert(sptStar)
        sptStar.rotation = random(360)
        sptStar.x, sptStar.y = 1000, 1000
        imgCoin.sptStar = sptStar
    end
    grpCoins.anchorX, grpCoins.anchorY = 1, 0
    grpCoins.x, grpCoins.y = Constants.RIGHT, Constants.TOP
    grp:insert(grpCoins)
    grpCoins:toBack()
end

local function _animCoins(dir)
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
    else
        Jukebox:dispatchEvent({name="playSoundCoins"})
        for i=1, grpCoins.numChildren do
            if grpCoins.numChildren then
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
                    if img and img._animCoin then
                        img:_animCoin()
                    end
                end, 1)
            end
        end
    end
end

function objScene:create(event)
    local grpView = self.view
    grpView.isVisible = false


    helpTblID = Controller:verifyIsUnlockedStore()


    local imgBkg = display.newSprite(shtScenario, { {name="s", frames={2}} })
    imgBkg.anchorX, imgBkg.anchorY = .5, .5
    imgBkg.x, imgBkg.y = display.contentCenterX, display.contentCenterY
    grpView:insert(imgBkg)


    local tblStore = Controller:getData():getStoresSorted()


    globals_bntBackRelease = bntBackRelease


    local SCRVIEW_HEIGHT = Constants.BOTTOM - 110-- display.actualContentHeight - 75


    -- ITENS STORE    
    local grpStore = display.newGroup()


    local rctScroll = display.newRect(0,0, 2,1)


    -- SCROLL
    local SCROLL_IS_MOVED = false
    local btnTouched = nil
    local function _scrViewListener(event)
        local x, y = event.target:getContentPosition()
        rctScroll.y = -y * (1 + rctScroll.numHeightProp)
        if event.phase == "ended" then
            if btnTouched ~= nil and btnTouched.active ~= nil then
                btnTouched:active()
            end
            btnTouched = nil
            SCROLL_IS_MOVED = false
        elseif event.phase == "moved" then
            local dy = math.abs( ( event.y - event.yStart ) )
            if ( dy > 10 ) then
                SCROLL_IS_MOVED = true
            end
        end
        return false
    end
    local scrView = Widget.newScrollView{
        width = display.actualContentWidth+2,
        height = SCRVIEW_HEIGHT,
        backgroundColor = {0, 0, 0, .7},
        horizontalScrollDisabled = true,
        hideBackground = false,
        hideScrollBar = true,
        isBounceEnabled = false,
        friction = 0,
        autoHideScrollBar = true,
        keepPositionOnInsert = true,
        topPadding = 0, 
        bottomPadding = 0,
        leftPadding = 0, 
        rightPadding = 0,
        listener = _scrViewListener,
    }
    grpView:insert(scrView)


    local grpFrame = display.newGroup()
    grpView:insert(grpFrame)
    local grpHud = display.newGroup()
    grpView:insert(grpHud)


    _initCoins(grpHud)


    -- CASH
    local grpCash = display.newGroup()
    grpHud:insert(grpCash)

    local tblTxtBuy = {
        parent = grpCash,
        text = " "..Util:formatNumber(Controller:getData():getCash()),
        font = "Maassslicer",
        fontSize = 26,
        align = "right"
    }
    txtCash = display.newText(tblTxtBuy)
    txtCash:setFillColor(1, 1, .2)
    txtCash.anchorX, txtCash.anchorY = 1, .5
    txtCash.x, txtCash.y = 0, -3

    local imgCashCoin = display.newSprite(shtUtilUi, { {name="standard", start=9, count=1} })
    imgCashCoin.anchorX, imgCashCoin.anchorY = 0, .5
    imgCashCoin.x, imgCashCoin.y = 0, -5
    grpCash:insert(imgCashCoin)

    grpCash.anchorChildren = true
    grpCash.anchorX, grpCash.anchorY = 1, 0
    grpCash.x, grpCash.y = Constants.RIGHT, Constants.TOP


    -- TITTLE
    local txtTitle = display.newText(grpHud, I18N:getString("store"), 0, 0, "Maassslicer", 17)
    txtTitle.anchorX, txtTitle.anchorY = .5, 0
    txtTitle.x, txtTitle.y = display.contentCenterX, Constants.TOP


    local bntBuyRelease = function(event)
        local options = {
            isModal = true,
            effect = "fade",
            time = 200
        }
        Composer.showOverlay("classes.phoenix.controller.scenes.Buy", options)
        return false
    end


    -- SHADOW
    local sptShadowTop = display.newSprite(shtUtilUi, { {name="s", start=44, count=1} })
    sptShadowTop.width = 500
    sptShadowTop.anchorX, sptShadowTop.anchorY = .5, 0
    sptShadowTop.yScale = 2
    sptShadowTop.x, sptShadowTop.y = display.contentCenterX, display.contentCenterY - SCRVIEW_HEIGHT * .5 + 5
    sptShadowTop.alpha = .4
    grpView:insert(sptShadowTop)
    local sptShadowBottom = display.newSprite(shtUtilUi, { {name="s", start=44, count=1} })
    sptShadowBottom.width = 500
    sptShadowBottom.anchorX, sptShadowBottom.anchorY = .5, 1
    sptShadowBottom.x, sptShadowBottom.y = display.contentCenterX, display.contentCenterY + SCRVIEW_HEIGHT * .5 - 10
    sptShadowBottom.yScale = 2
    sptShadowBottom.rotation = 180
    sptShadowBottom.alpha = .4
    grpView:insert(sptShadowBottom)


    -- ITENS UPDATABLE
    local numCols = 4
    local numRows = 1
    local function bntItemUpdateRelease(self, event)
        btnTouched = self
        return false
    end
    local function bntItemUpdateActive(self)
        if not SCROLL_IS_MOVED then
            local tblData = self.tblData
            local tblDescription = self.tblDescription

            if tblData.k == 1 then
                local params = {}
                params.strMsg = tblDescription.strDescription
                params.strTitle = I18N:getString("unlockTitle") .. I18N:getString(tblData.l)
                params.numID = tblData.i
                params.numPriceUnlock = tblData.o * 5000

                local options = {
                    isModal = true,
                    effect = "fade",
                    params = params,
                    time = 0
                }
                Composer.showOverlay("classes.phoenix.controller.scenes.Alert", options)
                Jukebox:dispatchEvent({name="playSound", id="negation"})
                return false
            end

            local numCurrent = tblData.c + 1
            if (numCurrent == 11 and tblData.i ~= 1) or (numCurrent == 6 and tblData.i == 1) then
                Jukebox:dispatchEvent({name="playSound", id="negation"})
                return false
            end

            local numPrice = tblData.p[numCurrent]

            if numPrice > Controller:getData():getCash() then
                Jukebox:dispatchEvent({name="playSound", id="negation"})
                bntBuyRelease()
                return false
            end

            if txtCash.tmrCancel ~= nil then timer.cancel(txtCash.tmrCancel) end
            txtCash.text = Controller:getData():getCash()
            Controller:getData():addCash(-numPrice)

            tblData.v = tblData.s[numCurrent]
            tblData.c = nil
            if tblData.n == 1 then
                tblData.n = 0
                self.sptNew.isVisible = false
                self.txtNew.isVisible = false
            end
            Controller:getData():setStore(tblData.i.."", tblData)
            tblData.c = numCurrent
            self["bullet"..numCurrent]:setFrame(2)

            local strValue = I18N:getString("max")
            if (tblData.c < 10 and tblData.i ~= 1) or (tblData.c < 5 and tblData.i == 1) then
                strValue = tblData.p[tblData.c+1]
                self.txtItemValue.text = " "..I18N:getString(strValue)
            else
                local grpParent = self.txtItemValue.parent

                grpParent:remove(self.imgCoin)
                self.imgCoin = nil

                self:setFillColor(.3)
                self.sptFx:setFillColor(0)
                self.txtItemValue:setFillColor(1, .4)
                self.txtItemValue.text = " "..I18N:getString(strValue)
                self.txtItemValue.anchorX, self.txtItemValue.anchorY = .5, .5
                self.txtItemValue.x, self.txtItemValue.y = 0, 0

                grpParent.anchorX = .5
                grpParent.x = 0
            end

            Jukebox:dispatchEvent({name="playSound", id="coins"})

            local sptItemFx = self.sptItemFx
            if sptItemFx ~= nil then
                if sptItemFx.trtCancel ~= nil then transition.cancel(sptItemFx.trtCancel) end
                sptItemFx.xScale, sptItemFx.yScale, sptItemFx.alpha = NUM_ITEM_ICON_SCALE, NUM_ITEM_ICON_SCALE, 1
                sptItemFx.trtCancel = transition.to(sptItemFx, {alpha=0, xScale=2, yScale=2, time=1000})
            end
            
            _animCoins(1)
            _animeCounter(txtCash, Controller:getData():getCash(), 1500, _animCoins)
        end
        return false
    end
    for i = 0, numRows - 1 do
        for j = 1, numCols do
            local pos = i * numCols + j
            local tblData = Controller:getData():getStore(tblStore[pos].i.."")
            local tblDescription = Controller:getData():getStoreDescribeMission(tblData.i)

            tblData.c = 0
            for i=1, 10 do
                if tblData.v == tblData.s[i] then
                    tblData.c = i
                    break
                end
            end

            local grpItem = display.newGroup()
            grpStore:insert(grpItem)

            local bntItem = display.newSprite(shtButtons, {{name="s", start=20, count=1}})
            bntItem.touch = bntItemUpdateRelease
            bntItem.active = bntItemUpdateActive
            bntItem:addEventListener("touch", bntItem)
            bntItem.anchorX, bntItem.anchorY = .5, .5
            bntItem.x, bntItem.y = 0, 0
            local numRandom = random(4)
            local numRot = numRandom == 1 and 0 or (numRandom == 2 and 90 or (numRandom == 3 and 180 or 270))
            bntItem:rotate(numRot, numRot)
            local numScaleX, numScaleY = random(2) == 1 and 1 or -1, random(2) == 1 and 1 or -1 
            bntItem:scale(numScaleX, numScaleY)
            bntItem.tblData = tblData
            bntItem.tblDescription = tblDescription
            grpItem:insert(bntItem)

            local sptFx = display.newSprite(shtButtons, {{name="s", start=20, count=1}})
            bntItem.sptFx = sptFx
            local numRandom = random(4)
            local numRot = numRandom == 1 and 0 or (numRandom == 2 and 90 or (numRandom == 3 and 180 or 270))
            sptFx:rotate(numRot, numRot)
            local numScaleX, numScaleY = random(2) == 1 and 1 or -1, random(2) == 1 and 1 or -1 
            sptFx:scale(numScaleX, numScaleY)
            sptFx.alpha = .6
            grpItem:insert(sptFx)

            if tblData.c == 10 or (tblData.c == 5 and tblData.i == 1) then
                bntItem:setFillColor(.3)
                sptFx:setFillColor(0)
            else
                bntItem:setFillColor(.15)
                sptFx:setFillColor(0)
            end

            if tblData.n == 1 then
                local sptNew = display.newSprite(shtUtilUi, { {name="s", start=12, count=1} })
                bntItem.sptNew = sptNew
                sptNew.x, sptNew.y = bntItem.height*.5 - 4, -bntItem.width*.5 + 9
                grpItem:insert(sptNew)

                local txtNew = display.newText(grpItem, " !", 0, 0, "Maassslicer", 9)
                bntItem.txtNew = txtNew
                txtNew.anchorX, txtNew.anchorY = .5, .5
                txtNew.x, txtNew.y = sptNew.x, sptNew.y + 1
            end

            if tblData.v >= 0 then

                local grpBullet = display.newGroup()
                grpItem:insert(grpBullet)
                for i=1, 10 do
                    if tblData.i == 1 and i > 5 then
                        break
                    end
                    local imgBullet = display.newSprite(shtButtons, { {name="s", start=22, count=2} })
                    imgBullet.x = 3.5 * i
                    if tblData.c >= i then
                        imgBullet:setFrame(2)
                    end
                    if tblData.k == 1 then
                        imgBullet.alpha = 0
                    end
                    grpBullet:insert(imgBullet)
                    bntItem["bullet"..i] = imgBullet
                end
                grpBullet.anchorChildren = true
                grpBullet.anchorX, grpBullet.anchorY = .5, .5
                grpBullet.x, grpBullet.y = 0, 12

                local numFrame = random(42, 45)
                local sptItem = display.newSprite(shtUtilGameplay, { {name="s", frames={numFrame}} })
                sptItem.xScale, sptItem.yScale = NUM_ITEM_ICON_SCALE, NUM_ITEM_ICON_SCALE
                grpItem:insert(sptItem)
                sptItem:rotate(random(360))
                sptItem.anchorX, sptItem.anchorY = .5, .5
                sptItem.y = -7
                sptItem.alpha = tblData.k == 1 and .2 or 1
                sptItem:setFillColor(Powerup.tblColors[tblData.i][1], Powerup.tblColors[tblData.i][2], Powerup.tblColors[tblData.i][3])

                local sptItemFx = display.newSprite(shtUtilGameplay, { {name="s", frames={numFrame}} })
                sptItemFx.alpha, sptItemFx.rotation, sptItemFx.y = 0, sptItem.rotation, sptItem.y
                sptItemFx:setFillColor(Powerup.tblColors[tblData.i][1], Powerup.tblColors[tblData.i][2], Powerup.tblColors[tblData.i][3])
                bntItem.sptItemFx = sptItemFx
                grpItem:insert(sptItemFx)

                local grpItemValue = display.newGroup()
                grpItem:insert(grpItemValue)
                if tblData.k == 1 then
                    local sptLocked = display.newSprite(shtButtons, { {name="standard", start=28, count=1} })
                    sptLocked:setFillColor(1)
                    sptLocked:scale(.9, .9)
                    grpItemValue:insert(sptLocked)
                    grpItemValue.anchorX, grpItemValue.anchorY = .5, .5
                    grpItemValue.x, grpItemValue.y = 0, 7

                    local txtItemLocked = display.newText(grpItemValue, " "..tblDescription.numToGo, 0, 0, "Maassslicer", 10)
                    txtItemLocked:setFillColor(.4)
                    txtItemLocked.anchorX, txtItemLocked.anchorY = .5, .5
                    txtItemLocked.x, txtItemLocked.y = sptLocked.x, sptLocked.y + 4
                else
                    local numNext = tblData.c + 1
                    local strValue = I18N:getString("max")
                    local txtItemValue = display.newText(grpItemValue, "", 0, 0, "Maassslicer", 9)
                    txtItemValue:setFillColor(1, 1, .2)

                    if (numNext < 11 and tblData.i ~= 1) or (numNext < 6 and tblData.i == 1) then
                        strValue = " "..tblData.p[numNext]

                        local imgCoin = display.newSprite(shtUtilUi, { {name="s", start=10, count=1} })
                        imgCoin.anchorX, imgCoin.anchorY = 0, .5
                        imgCoin.x, imgCoin.y = 0, -1
                        grpItemValue:insert(imgCoin)
                        bntItem.imgCoin = imgCoin
                    else
                        txtItemValue:setFillColor(1, .4)
                    end

                    txtItemValue.text = I18N:getString(strValue)
                    txtItemValue.anchorX, txtItemValue.anchorY = 1, .5
                    txtItemValue.x, txtItemValue.y = 0, 0
                    bntItem.txtItemValue = txtItemValue
                    
                    grpItemValue.anchorChildren = true
                    grpItemValue.anchorX, grpItemValue.anchorY = .5, 1
                    grpItemValue.x, grpItemValue.y = 0, 35
                end
            end

            local strLabel = I18N:getString(tblData.l)
            local txtItemLabel = display.newText(grpItem, strLabel, 0, 0, "Maassslicer", 8)
            txtItemLabel.anchorX, txtItemLabel.anchorY = .5, 1
            txtItemLabel.alpha = tblData.k == 1 and .4 or 1
            txtItemLabel.x, txtItemLabel.y = 0, -23

            grpItem.anchorX, grpItem.anchorY = 0, 0
            grpItem.x, grpItem.y = j * (bntItem.width + 30) - 6, 65
        end
    end



    -- ITENS RENEWABLE
    local numCols = 4
    local numRows = 4
    local function bntItemRenewRelease(self, event)
        btnTouched = self
        return false
    end
    local function bntItemRenewActive(self)
        if not SCROLL_IS_MOVED then
            local tblData = self.tblData
            local tblDescription = self.tblDescription

            if tblData.k == 1 then
                local params = {}
                params.strMsg = tblDescription.strDescription
                params.strTitle = I18N:getString("unlockTitle") .. I18N:getString(tblData.l)
                params.numID = tblData.i
                params.numPriceUnlock = tblData.o * 5000

                local options = {
                    isModal = true,
                    effect = "fade",
                    params = params,
                    time = 0
                }
                Composer.showOverlay("classes.phoenix.controller.scenes.Alert", options)
                Jukebox:dispatchEvent({name="playSound", id="negation"})
                return false
            end

            local numPrice = tblData.p

            if numPrice > Controller:getData():getCash() then
                Jukebox:dispatchEvent({name="playSound", id="negation"})
                bntBuyRelease()
                return false
            end

            if tblData.v == tblData.t then
                Jukebox:dispatchEvent({name="playSound", id="negation"})
                return false
            end

            if txtCash.tmrCancel ~= nil then timer.cancel(txtCash.tmrCancel) end
            txtCash.text = Controller:getData():getCash()
            Controller:getData():addCash(-numPrice)

            local numValue = tblData.v + tblData.m
            numValue = numValue > tblData.t and tblData.t or numValue
            if numValue == tblData.t then
                self:setFillColor(.3)
                self.sptFx:setFillColor(0)
            end
            
            tblData.v = numValue
            if tblData.n == 1 then
                tblData.n = 0
                self.sptNew.isVisible = false
                self.txtNew.isVisible = false
            end
            Controller:getData():setStore(tblData.i.."", tblData)

            self.txtItemValue.text = " "..numValue
            self.txtItemValue.anchorX = .5
            self.txtItemValue.x = 0

            Jukebox:dispatchEvent({name="playSoundCoins"})

            local sptItemFx = self.sptItemFx
            if sptItemFx ~= nil then
                if sptItemFx.trtCancel ~= nil then transition.cancel(sptItemFx.trtCancel) end
                sptItemFx.xScale, sptItemFx.yScale, sptItemFx.alpha = NUM_ITEM_ICON_SCALE, NUM_ITEM_ICON_SCALE, 1
                sptItemFx.trtCancel = transition.to(sptItemFx, {alpha=0, xScale=2, yScale=2, time=1000})
            end
            
            _animCoins(1)
            _animeCounter(txtCash, Controller:getData():getCash(), 1500, _animCoins)
        end
        return false
    end
    for i = 0, numRows - 1 do
        for j = 1, numCols do
            local pos = i * numCols + j + 4

            if tblStore[pos] == nil then
                break
            end

            local tblData = Controller:getData():getStore(tblStore[pos].i.."")
            local tblDescription = Controller:getData():getStoreDescribeMission(tblData.i)

            local grpItem = display.newGroup()
            grpStore:insert(grpItem)

            local bntItem = display.newSprite(shtButtons, {{name="s", start=20, count=1}})
            bntItem.touch = bntItemRenewRelease
            bntItem.active = bntItemRenewActive
            bntItem:addEventListener("touch", bntItem)
            bntItem.anchorX, bntItem.anchorY = .5, .5
            bntItem.x, bntItem.y = 0, 0
            local numRandom = random(4)
            local numRot = numRandom == 1 and 0 or (numRandom == 2 and 90 or (numRandom == 3 and 180 or 270))
            bntItem:rotate(numRot, numRot)
            local numScaleX, numScaleY = random(2) == 1 and 1 or -1, random(2) == 1 and 1 or -1 
            bntItem:scale(numScaleX, numScaleY)
            bntItem.tblData = tblData
            bntItem.tblDescription = tblDescription
            grpItem:insert(bntItem)

            local sptFx = display.newSprite(shtButtons, {{name="s", start=20, count=1}})
            bntItem.sptFx = sptFx
            local numRandom = random(4)
            local numRot = numRandom == 1 and 0 or (numRandom == 2 and 90 or (numRandom == 3 and 180 or 270))
            sptFx:rotate(numRot, numRot)
            local numScaleX, numScaleY = random(2) == 1 and 1 or -1, random(2) == 1 and 1 or -1 
            sptFx:scale(numScaleX, numScaleY)
            sptFx.alpha = .6
            grpItem:insert(sptFx)

            if tblData.v == tblData.t then
                bntItem:setFillColor(.3)
                sptFx:setFillColor(0)
            else
                bntItem:setFillColor(.15)
                sptFx:setFillColor(0)
            end

            if tblData.n == 1 then
                local sptNew = display.newSprite(shtUtilUi, { {name="s", start=12, count=1} })
                bntItem.sptNew = sptNew
                sptNew.x, sptNew.y = bntItem.height*.5 - 4, -bntItem.width*.5 + 9
                grpItem:insert(sptNew)

                local txtNew = display.newText(grpItem, " !", 0, 0, "Maassslicer", 9)
                bntItem.txtNew = txtNew
                txtNew.anchorX, txtNew.anchorY = .5, .5
                txtNew.x, txtNew.y = sptNew.x, sptNew.y + 1
            end

            local sptItem = 0
            local sptItemFx = 0
            if tblData.i == 5 then
                local numFrame = random(42, 45)
                sptItem = display.newSprite(shtUtilGameplay, { {name="s", frames={numFrame} }})
                sptItem:rotate(random(360))
                sptItemFx = display.newSprite(shtUtilGameplay, { {name="s", frames={numFrame}} })
            elseif tblData.i == 6 then
                sptItem = display.newSprite(shtUtilGameplay, { {name="s", start=35, count=1} })
                sptItem:rotate(random(360))
                sptItemFx = display.newSprite(shtUtilGameplay, { {name="s", start=35, count=1} })
            elseif tblData.i == 7 then
                sptItem = display.newSprite(shtUtilGameplay, { {name="s", start=31, count=1} })
                sptItemFx = display.newSprite(shtUtilGameplay, { {name="s", start=31, count=1} })
            else
                local tblFrames = {nil,nil,nil,nil,nil,nil,nil,21,34,35,36,37,38,39,40,41,42,43}
                sptItem = display.newSprite(shtButtons, { {name="s", start=tblFrames[tblData.i], count=1} })
                sptItemFx = display.newSprite(shtButtons, { {name="s", start=tblFrames[tblData.i], count=1} })
            end
            sptItem.anchorX, sptItem.anchorY = .5, .5
            sptItem.xScale, sptItem.yScale = NUM_ITEM_ICON_SCALE, NUM_ITEM_ICON_SCALE
            sptItem.y = -7
            sptItem:setFillColor(tblData.k == 1 and .2 or 1)
            grpItem:insert(sptItem)

            sptItemFx.alpha, sptItemFx.rotation, sptItemFx.y = 0, sptItem.rotation, sptItem.y
            bntItem.sptItemFx = sptItemFx
            grpItem:insert(sptItemFx)

            local numScaleTo = 1
            if tblData.i == 5 then
                sptItem:setFillColor(Powerup.tblColors[5][1], Powerup.tblColors[5][2], Powerup.tblColors[5][3])
                sptItemFx:setFillColor(Powerup.tblColors[5][1], Powerup.tblColors[5][2], Powerup.tblColors[5][3])
            end

            local txtItemValue = display.newText(grpItem, " "..tblData.v, 0, 0, "Maassslicer", 8)
            txtItemValue.anchorX, txtItemValue.anchorY = .5, .5
            txtItemValue.x, txtItemValue.y = 0, 13
            if tblData.k == 1 then
                txtItemValue.isVisible = false
            end
            bntItem.txtItemValue = txtItemValue

            local grpItemValue = display.newGroup()
            grpItem:insert(grpItemValue)
            if tblData.k == 1 then
                local sptLocked = display.newSprite(shtButtons, { {name="standard", start=28, count=1} })
                sptLocked:setFillColor(1)
                sptLocked:scale(.9, .9)
                grpItemValue:insert(sptLocked)
                grpItemValue.anchorX, grpItemValue.anchorY = .5, .5
                grpItemValue.x, grpItemValue.y = 0, 7

                local txtItemLocked = display.newText(grpItemValue, " "..tblDescription.numToGo, 0, 0, "Maassslicer", 10)
                txtItemLocked:setFillColor(.4)
                txtItemLocked.anchorX, txtItemLocked.anchorY = .5, .5
                txtItemLocked.x, txtItemLocked.y = sptLocked.x, sptLocked.y + 4
            else
                local imgCoin = display.newSprite(shtUtilUi, {{name="s", start=10, count=1}})
                imgCoin.anchorX, imgCoin.anchorY = 0, .5
                imgCoin.x, imgCoin.y = 0, -1
                grpItemValue:insert(imgCoin)
                bntItem.imgCoin = imgCoin

                local txtItemPrice = display.newText(grpItemValue, " "..tblData.p, 0, 0, "Maassslicer", 9)
                txtItemPrice:setFillColor(1, 1, .2)
                txtItemPrice.anchorX, txtItemPrice.anchorY = 1, .5
                txtItemPrice.x, txtItemPrice.y = 0, 0
                bntItem.txtItemPrice = txtItemPrice

                grpItemValue.anchorChildren = true
                grpItemValue.anchorX, grpItemValue.anchorY = .5, 1
                grpItemValue.x, grpItemValue.y = 0, 35
            end

            local strLabel = (tblData.m > 1 and tblData.m.."x" or "")..I18N:getString(tblData.l)
            local txtItemLabel = display.newText(grpItem, " "..strLabel, 0, 0, "Maassslicer", 8)
            txtItemLabel.anchorX, txtItemLabel.anchorY = .5, 1
            txtItemLabel.alpha = tblData.k == 1 and .4 or 1
            txtItemLabel.x, txtItemLabel.y = 0, -23

            grpItem.anchorX, grpItem.anchorY = .5, 0
            grpItem.x, grpItem.y = j * (bntItem.width + 30) - 6, (i + 1) * (bntItem.height + 25) + 65 + (i > 0 and 30 or 0)
        end
    end


    -- PADDING BOTTOM
    local rctPaddingBottom = display.newRect(grpStore, 100, grpStore.height + 5, 1, 1)
    rctPaddingBottom.alpha = .01


    -- LABEL UPDATABLE
    local numX = grpStore.width * .5 + 40
    local numY = 0

    local rctAssistsBg = display.newRect(grpStore, 0, 0, scrView.width, 25)
    rctAssistsBg:setFillColor(0, .15)
    rctAssistsBg.anchorX, rctAssistsBg.anchorY = .5, 0
    rctAssistsBg.x, rctAssistsBg.y = numX, numY

    local txtAssists = display.newText(grpStore, I18N:getString("updates"), 0, 0, "Maassslicer", 14)
    txtAssists.anchorX, txtAssists.anchorY = .5, 0
    txtAssists.x, txtAssists.y = numX, numY + 5


    -- LABEL ASSISTS
    local numY = 182

    local rctAssistsBg = display.newRect(grpStore, 0, 0, scrView.width, 25)
    rctAssistsBg:setFillColor(0, .15)
    rctAssistsBg.anchorX, rctAssistsBg.anchorY = .5, 0
    rctAssistsBg.x, rctAssistsBg.y = numX, numY

    local txtAssists = display.newText(grpStore, I18N:getString("assists"), 0, 0, "Maassslicer", 14)
    txtAssists.anchorX, txtAssists.anchorY = .5, 0
    txtAssists.x, txtAssists.y = numX, numY + 5


    rctScroll.numHeightProp = scrView.height / grpStore.height
    rctScroll.height = rctScroll.numHeightProp * scrView.height
    rctScroll.anchorX, rctScroll.anchorY = 1, 0
    rctScroll:setFillColor(1)
    rctScroll.x, rctScroll.y = scrView.width, 0
    scrView:insert(rctScroll)


    scrView:insert(grpStore)
    grpStore.anchorChildren = true
    grpStore.anchorX, grpStore.anchorY = .5, 0
    grpStore.x, grpStore.y = scrView.width * .5, 0


    scrView.anchorX, scrView.anchorY = .5, .5
    scrView.x, scrView.y = display.contentCenterX, display.contentCenterY + 5


    local bntMenu = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 16,
        overFrame = 16,
        onRelease = globals_bntBackRelease
    }


    local bntBuy = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 26,
        overFrame = 26,
        onRelease = bntBuyRelease
    }


    local function bntPlayRelease(event)
        local options = {
            effect = "fade",
            time = 0,
            params = {isReload=true}
        }
        Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)

        return true
    end
    local bntPlay = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 1,
        overFrame = 1,
        onRelease = bntPlayRelease
    }
    transition.blink(bntPlay[2], {time=2000})


    local grpAd = display.newGroup()
    grpHud:insert(grpAd)

    local txtAd = {}
    local txtAdPlus = {}

    local function bntAdRelease(event)
        txtAd.alpha, txtAdPlus.alpha = 0, 0

        globals_adCallbackListener = function(params)
            phase = params.phase
            if phase == "hidden" then
                Controller:getData():addCash(Constants.NUM_COINS_REWARDED_VIDEO_AD)

                local scene = Composer.getScene(Composer.getSceneName("current"))
                if Composer.getSceneName("current") == "classes.phoenix.controller.scenes.Store" and scene.overlayEnded then
                    scene:overlayEnded()
                end
            end
            if phase == "hidden" or phase == "bug" or phase == "validationExceededQuota" then
                globals_adCallbackListener = function() end
            end
        end

        if txtAd.TRT_CANCEL ~= nil then
            transition.cancel(txtAd.TRT_CANCEL)
        end
        txtAd.TRT_CANCEL = nil
        if txtAdPlus.TRT_CANCEL ~= nil then
            transition.cancel(txtAdPlus.TRT_CANCEL)
        end
        txtAdPlus.TRT_CANCEL= nil
        txtAd.TRT_CANCEL = transition.to(txtAd, {alpha=1, delay=200, time=300})
        txtAdPlus.TRT_CANCEL = transition.to(txtAdPlus, {alpha=1, delay=200, time=300})
       
        local AdsGame = require "classes.phoenix.business.AdsGame"
        AdsGame:showRewarded()
        return true
    end
    local grpBntAd = display.newGroup()
    grpAd:insert(grpBntAd)
    local bntAd = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 47,
        overFrame = 47,
        onRelease = bntAdRelease
    }
    grpBntAd:insert(bntAd)
    grpBntAd.anchorX, grpBntAd.anchorY = 0, .5
    grpBntAd.x, grpBntAd.y = 0, 0
    grpBntAd:scale(.6, .6)

    local tblTxtAd = {
        parent = grpAd,
        text = " "..Util:formatNumber(Constants.NUM_COINS_REWARDED_VIDEO_AD),
        font = "Maassslicer",
        fontSize = 7,
        align = "left"
    }
    txtAd = display.newText(tblTxtAd)
    txtAd:setFillColor(1, 1, .2)
    txtAd.anchorX, txtAd.anchorY = .5, .5
    txtAd.x, txtAd.y = 2, 8

    local tblTxtPlus = {
        parent = grpAd,
        text = " +",
        font = "Maassslicer",
        fontSize = 13,
        align = "left"
    }
    txtAdPlus = display.newText(tblTxtPlus)
    txtAdPlus:setFillColor(1, 1, .2)
    txtAdPlus.anchorX, txtAdPlus.anchorY = 1, .5
    txtAdPlus.x, txtAdPlus.y = -txtAd.width * .5 + 7, 9

    grpAd.anchorChildren = true
    grpAd.anchorX, grpAd.anchorY = 1, .5
    grpAd.x, grpAd.y = grpCash.x - grpCash.width, grpCash.y + grpCash.height * .5

    Util:generateFrame(grpFrame, bntBuy, sptCashBG, bntPlay, bntMenu)


    grpFrame:toFront()
end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase

    if phase == "will" then
        
        Composer.stage.alpha = 1

        globals_bntBackRelease = bntBackRelease

    elseif phase == "did" then

        --Controller:setStatus(0)

        Jukebox:dispatchEvent({name="stopSoundCoins"})
        
        local function _callback()
            if #helpTblID > 0 then
                timer.performWithDelay(50, function()
                    local options = {
                        effect = "fade",
                        time = 0,
                        params = {tblID=helpTblID, isObrigatory=true, helpType=2},
                        isModal = true
                    }
                    Composer.showOverlay("classes.phoenix.controller.scenes.Help", options)
                end, 1)
            end
        end

        if not Controller:getData():getProfile("isSeenHelpStore") then

            Jukebox:dispatchEvent({name="playSound", id="stage"})
            
            Controller:getData():setProfile("isSeenHelpStore", true) 
            local options = {
                effect = "fade",
                time = 0,
                params = {tblID={3}, callback=_callback},
                isModal = true
            }
            Composer.showOverlay("classes.phoenix.controller.scenes.Help", options)
        else
            _callback()
        end

    end

end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase

    if phase == "did" then

        globals_bntBackRelease = bntBackRelease

        Jukebox:dispatchEvent({name="stopSoundCoins"})
        
    end
end


function objScene:overlayEnded()
    local strCash = " "..Util:formatNumber(Controller:getData():getCash())
    if strCash ~= txtCash.text then
        local str = string.gsub(txtCash.text, ",", "")
        local numCashCurrent = tonumber(str)
        local numCashTarget = Controller:getData():getCash()
        local dir = numCashCurrent > numCashTarget and 1 or -1
        _animCoins(dir)
        _animeCounter(txtCash, Controller:getData():getCash(), 1500, _animCoins)
    end

    if Composer.getSceneName("current") == "classes.phoenix.controller.scenes.Store" then
        globals_bntBackRelease = bntBackRelease
    end
end 


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene