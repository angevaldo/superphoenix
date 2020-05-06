local Composer = require "composer"
local objScene = Composer.newScene()
local Store = require "store" 
if system.getInfo("platformName") == "Android" then
    Store = require "plugin.google.iap.v3" 
end

local I18N = require "lib.I18N"


local Wgt = require "classes.phoenix.business.Wgt"
local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"
local Constants = require "classes.phoenix.business.Constants"
local Jukebox = require "classes.phoenix.business.Jukebox"


local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())
local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())


local abs = math.abs


local TIMER_LOAD
local TBL_PRODUCTS_DETAIL_LOADED = {}
local TBL_PRODUCTS_VALUES = {}
TBL_PRODUCTS_VALUES["com.ajtechlabs.support.game.remove_ads_01"] = 0
TBL_PRODUCTS_VALUES["com.ajtechlabs.support.game.pack_01"] = 1000
TBL_PRODUCTS_VALUES["com.ajtechlabs.support.game.pack_02"] = 5000
TBL_PRODUCTS_VALUES["com.ajtechlabs.support.game.pack_03"] = 10000
TBL_PRODUCTS_VALUES["com.ajtechlabs.support.game.pack_04"] = 50000
TBL_PRODUCTS_VALUES["com.ajtechlabs.support.game.unlock_store_01"] = 0
local TBL_PRODUCTS_PRICES = {}
TBL_PRODUCTS_PRICES[1] = .99
TBL_PRODUCTS_PRICES[2] = 1.99
TBL_PRODUCTS_PRICES[3] = 2.99
TBL_PRODUCTS_PRICES[4] = 4.99
TBL_PRODUCTS_PRICES[5] = 19.99
TBL_PRODUCTS_PRICES[6] = 49.99
local TBL_PRODUCTS_ID = {
    --[
    "com.ajtechlabs.support.game.remove_ads_01",
    "com.ajtechlabs.support.game.pack_01",
    "com.ajtechlabs.support.game.pack_02",
    "com.ajtechlabs.support.game.pack_03",
    "com.ajtechlabs.support.game.pack_04",
    "com.ajtechlabs.support.game.unlock_store_01",
    --]]
    --[[]
    "android.test.purchased",
    "android.test.purchased",
    "android.test.canceled",
    "android.test.refunded",
    "android.test.item_unavailable",
    --]]
}


-- LOCAL FUNCTIONS
local function _quicksort(t, start, endi)
    start, endi = start or 1, endi or #t
    if(endi - start < 1) then return t end
    local pivot = start
    for i = start + 1, endi do
        if t[i].price < t[pivot].price then -- <=
            local temp = t[pivot + 1]
            t[pivot + 1] = t[pivot]
            if(i == pivot + 1) then
                t[pivot] = temp
            else
                t[pivot] = t[i]
                t[i] = temp
            end
            pivot = pivot + 1
        end
    end
    t = _quicksort(t, start, pivot - 1)
    return _quicksort(t, pivot + 1, endi)
end


local bntBackRelease = function(event)
    Composer.hideOverlay(false, "fade", 200)
    return false
end


local function _getSeparator(x1, x2, width)
    local numWidthSeparator = abs(x2 - x1) - width
    local strSeparator = ""
    for i=1, numWidthSeparator * .165 do
        strSeparator = strSeparator .. ". "
    end
    return strSeparator
end


local function _addItem(grp, id, strLabel, strPrice, numValue, x, y, xFrom)
    y = numValue > 0 and y or (y + 7)

    local txt1 = display.newText(grp, " "..strLabel, 0, 0, "Maassslicer", 8)
    txt1.anchorX, txt1.anchorY = 0, .5
    txt1.x, txt1.y = xFrom, y - 7

    str2 = tonumber(numValue) > 0 and " "..Util:formatNumber(numValue) or ""
    local txt2 = display.newText(grp, " "..str2, 0, 0, "Maassslicer", 14)
    txt2.anchorX, txt2.anchorY = 0, .5
    txt2:setFillColor(1, 1, .2)
    txt2.x, txt2.y = txt1.x + 5, y + 7

    local txtReference = numValue > 0 and txt2 or txt1

    local txt3 = display.newText(grp, " "..strPrice, 0, 0, "Maassslicer", 12)
    txt3.anchorX, txt3.anchorY = 1, .5
    txt3:setFillColor(1, 0, 0)
    txt3.x, txt3.y = x - 17, txtReference.y - 1

    local txtSeparator = display.newText(grp, _getSeparator(txtReference.x, x - txt3.width, txtReference.width), 0, 0, "Maassslicer", 9)
    txtSeparator.anchorX, txtSeparator.anchorY = 0, .5
    txtSeparator.x, txtSeparator.y, txtSeparator.alpha = txtReference.x + txtReference.width + 6, txtReference.y - 2, .2

    if numValue > 0 then
        local imgCoin = display.newSprite(shtUtilUi, { {name="standard", start=10, count=1} })
        imgCoin.anchorX, imgCoin.anchorY = 0, .5
        imgCoin.x, imgCoin.y = txt2.x + txt2.width, txt2.y
        grp:insert(imgCoin)
    end
end


function objScene:create(event)
    local grpView = self.view


    globals_bntBackRelease = bntBackRelease


    local rctOverlay = display.newRect(grpView, -10, -10, 500, 350)
    rctOverlay.anchorX, rctOverlay.anchorY = 0, 0
    rctOverlay:setFillColor(0, .95)


    local grpFrame = display.newGroup()
    grpView:insert(grpFrame)


    local txtTitle = display.newText(grpView, I18N:getString("buy"), 0, 0, "Maassslicer", 18)
    txtTitle.anchorX, txtTitle.anchorY = .5, 0
    txtTitle.x, txtTitle.y = display.contentCenterX, Constants.TOP


    local imgLoader = display.newSprite(shtButtons, { {name="s", start=2, count=1} })
    grpView:insert(imgLoader)
    imgLoader.anchorX, imgLoader.anchorY = .5, .5
    imgLoader.x, imgLoader.y, imgLoader.alpha = display.contentCenterX, display.contentCenterY, 0

    local grpListProducts = display.newGroup()
    grpView:insert(grpListProducts)

    local txtError = display.newText(grpView, I18N:getString("entfal"), 0, 0, "Maassslicer", 15)
    txtError.anchorX, txtError.anchorY = .5, .5
    txtError.x, txtError.y = display.contentCenterX, display.contentCenterY
    txtError.alpha = 0
    grpView:insert(txtError)

    local _internetError = function()
        if txtError.trtCancel ~= nil then 
            transition.cancel(txtError.trtCancel) 
            txtError.trtCancel = nil
        end
        if imgLoader.trtCancel ~= nil then 
            transition.cancel(imgLoader.trtCancel) 
            imgLoader.trtCancel = nil
        end
        if imgLoader.trtCancelRotate ~= nil then 
            transition.cancel(imgLoader.trtCancelRotate) 
            imgLoader.trtCancelRotate = nil
        end
        imgLoader.trtCancel = transition.to(imgLoader, {alpha=0, time=300})
        txtError.trtCancel = transition.to(txtError, {alpha=1, time=300})
    end

    local _hideLoader = function(isHide)
        if imgLoader.trtCancel ~= nil then 
            transition.cancel(imgLoader.trtCancel) 
            imgLoader.trtCancel = nil
        end
        if imgLoader.trtCancelRotate ~= nil then 
            transition.cancel(imgLoader.trtCancelRotate) 
            imgLoader.trtCancelRotate = nil
        end
        if grpListProducts.trtCancelRotate ~= nil then 
            transition.cancel(grpListProducts.trtCancelRotate) 
            grpListProducts.trtCancelRotate = nil
        end
        if txtError.trtCancel ~= nil then 
            transition.cancel(txtError.trtCancel) 
            txtError.trtCancel = nil
        end
        txtError.alpha = 0

        if isHide == nil or isHide then
            imgLoader.trtCancel = transition.to(imgLoader, {alpha=0, time=300})
            txtError.trtCancel = transition.to(txtError, {alpha=0, time=300})
            grpListProducts.trtCancel = transition.to(grpListProducts, {alpha=1, time=300})
        else
            imgLoader.trtCancel = transition.to(imgLoader, {delay=200, alpha=.6, time=300})
            imgLoader.trtCancelRotate = transition.to(imgLoader, {rotation=72000, time=200000})
            grpListProducts.trtCancel = transition.to(grpListProducts, {alpha=0, time=300})

            txtError.trtCancel = transition.to(txtError, {time=30000, onComplete=function()
                if imgLoader.alpha == 1 then
                    _internetError()
                end
            end})
        end
    end


    local transactionCallback = function(event) end
    transactionCallback = function(event)
        local transaction = event.transaction
        local tstate = transaction.state
        local productIdentifier = transaction.productIdentifier
        --
        --Google does not return a "restored" state when you call Store.restore()
        --You're only going to get "purchased" with Google. This is a work around
        --to the problem.
        --
        --The assumption here is that any real purchase should happen reasonably
        --quick while restores will have a transaction date sometime in the past.
        --5 minutes seems sufficient to separate a purchase from a restore.
        --

        _hideLoader()

        local numValue = TBL_PRODUCTS_VALUES[productIdentifier]

        if tstate == "purchased" or tstate == "restored" then
            -- FOR APPLE STORE
            Store.finishTransaction(transaction)

            -- UNMANAGED ITEMS
            if Store.target == "google" then
                if numValue ~= nil and numValue > 0 then
                    timer.performWithDelay(1, function()
                        Store.consumePurchase({productIdentifier}, transactionCallback)
                    end, 1)
                end
            end

            -- UPDATE DATA
            if numValue ~= nil and numValue > 0 then
                Controller:getData():addCash(numValue)
            elseif productIdentifier == "com.ajtechlabs.support.game.remove_ads_01" then
                Controller:getData():setProfile("ads", false)
            elseif productIdentifier == "com.ajtechlabs.support.game.unlock_store_01" then 
                Controller:getData():setStoreUnlocked(true)

                Composer.stage.alpha = 0
                local options = {
                    effect = "fade",
                    time = 0,
                    params = {scene="classes.phoenix.controller.scenes.Store"}
                }
                Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
            end

            -- ALERT USER
            if tstate == "restored" then 
                native.showAlert(I18N:getString("buttonRestored"), I18N:getString("restoredDescription"), {I18N:getString("buttonOk")})
            elseif Store.target == "google" then
                native.showAlert(I18N:getString("buttonPurchased"), I18N:getString("purchasedDescription"), {I18N:getString("buttonOk")})
            end


        -- FOR GOOGLE PLAY V3
        elseif tstate == "consumed" then


        elseif tstate == "refunded" then
            -- FOR APPLE STORE
            Store.finishTransaction(transaction)

            if Store.target == "google" then
                native.showAlert(I18N:getString("refunded"), I18N:getString("refundedDescription"), {I18N:getString("buttonOk")})
            end
            if numValue ~= nil and numValue > 0 then
                Controller:getData():addCash(-numValue)
            elseif productIdentifier == "com.ajtechlabs.support.game.remove_ads_01" then
                Controller:getData():setProfile("ads", true)
            elseif productIdentifier == "com.ajtechlabs.support.game.unlock_store_01" then
                Controller:getData():setStoreUnlocked(false)
                
                Composer.stage.alpha = 0
                local options = {
                    effect = "fade",
                    time = 0,
                    params = {scene="classes.phoenix.controller.scenes.Store"}
                }
                Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
            end


        elseif tstate == "revoked" then -- Amazon feature
            native.showAlert(I18N:getString("revoked"), I18N:getString("revokedDescription"), {I18N:getString("buttonOk")})
            if numValue ~= nil and numValue > 0 then
                Controller:getData():addCash(-numValue)
            elseif productIdentifier == "com.ajtechlabs.support.game.remove_ads_01" then
                Controller:getData():setProfile("ads", true)
            elseif productIdentifier == "com.ajtechlabs.support.game.unlock_store_01" then
                Controller:getData():setStoreUnlocked(false)
                
                Composer.stage.alpha = 0
                local options = {
                    effect = "fade",
                    time = 0,
                    params = {scene="classes.phoenix.controller.scenes.Store"}
                }
                Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
            end


        elseif tstate == "cancelled" then
            -- FOR APPLE STORE
            Store.finishTransaction(transaction)


        elseif tstate == "failed" then
            -- FOR APPLE STORE
            Store.finishTransaction(transaction)

            native.showAlert(I18N:getString("failed"), I18N:getString("failedDescription"), {I18N:getString("buttonOk")}) --.." "..transaction.errorString


        else
            -- FOR APPLE STORE
            Store.finishTransaction(transaction)


        end

        Util:hideStatusbar()
    end


    -- INIT STORE
    Store.init(transactionCallback)


    local bntBack = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 14,
        onRelease = globals_bntBackRelease
    } 

    local bntRestore
    if Store.isActive and not Controller:getData():getProfile("unlockStorePurchased") then
        local function bntRestoreRelease(event)
            if not Controller:getData():getProfile("unlockStorePurchased") then
                _hideLoader(false)

                Store.restore()
            end
            return false
        end
        bntRestore = Wgt.newButton{
            sheet = shtButtons,
            defaultFrame = 15,
            onRelease = bntRestoreRelease
        }
        bntRestore[2].xScale = -1
    end


    Util:generateFrame(grpFrame, bntBack, bntRestore, nil, nil)


    --[
    -- HIDDING IF NOT AVALIABLE
    if not Store.isActive or (not Store.canMakePurchases and Store.target == "apple") then --1==2 then--
        local grpMsg = display.newGroup()
        grpView:insert(grpMsg)

        local tblTxtOptions = {
            parent = grpMsg,
            text = I18N:getString("cantMakePurchases"),
            width = Constants.RIGHT - 100,
            font = "Maassslicer",
            fontSize = 20,
            align = "center"
        }

        local txtMsg = display.newText(tblTxtOptions)
        txtMsg:setFillColor(1, 1, .2)
        txtMsg.anchorX, txtMsg.anchorY = .5, .5
        txtMsg.x, txtMsg.y = 0, 40

        grpMsg.anchorChildren = true
        grpMsg.anchorX, grpMsg.anchorY = .5, .5
        grpMsg.x, grpMsg.y = display.contentCenterX, display.contentCenterY
        return
    end
    --]]


    local function showProducts()
        _hideLoader()

        if grpListProducts and grpListProducts.insert then

            local bntBuyRelease = function(event)
                if Store.target == "apple" then
                    _hideLoader(false)
                    Store.purchase({TBL_PRODUCTS_ID[event.target.id]})
                elseif Store.target == "google" then
                    _hideLoader(false)
                    Store.purchase(TBL_PRODUCTS_ID[event.target.id])
                end
            end
            local numMaxWidth = 0
            for i = 1, #TBL_PRODUCTS_DETAIL_LOADED do
                if not (TBL_PRODUCTS_VALUES[i] == 0 and not Controller:getData():isStoreLocked()) then
                    local y = i * 37
                    local strPrice = TBL_PRODUCTS_DETAIL_LOADED[i].localizedPrice
                    if #strPrice > numMaxWidth then
                        numMaxWidth = #strPrice
                    end
                end
            end
            for i = 1, #TBL_PRODUCTS_DETAIL_LOADED do
                if not (TBL_PRODUCTS_VALUES[i] == 0 and not Controller:getData():isStoreLocked()) then
                    local y = i * 35
                    local strPrice = TBL_PRODUCTS_DETAIL_LOADED[i].localizedPrice
                    local x = -40 - numMaxWidth * 7

                    local sptIcon = display.newSprite(shtUtilUi, { {name="s", start=44+i, count=1} })
                    sptIcon.anchorX, sptIcon.anchorY = 1, .5
                    sptIcon.x, sptIcon.y = x, y
                    grpListProducts:insert(sptIcon)

                    local grpBnt = display.newGroup()
                    grpListProducts:insert(grpBnt)

                    local bntBuy = Wgt.newButton{
                        sheet = shtButtons,
                        defaultFrame = 26,
                        id = i,
                        onRelease = bntBuyRelease
                    } 
                    grpBnt:insert(bntBuy)

                    if (TBL_PRODUCTS_ID[i] == "com.ajtechlabs.support.game.unlock_store_01" and Controller:getData():getProfile("unlockStorePurchased")) or (TBL_PRODUCTS_ID[i] == "com.ajtechlabs.support.game.remove_ads_01" and not Controller:getData():getProfile("ads")) then
                        bntBuy.isActive = false
                        bntBuy.alpha = .2
                    end
                    
                    grpBnt:scale(.6, .6)
                    grpBnt.anchorX, grpBnt.anchorY = 0, .3
                    grpBnt.x, grpBnt.y = 100, y

                    _addItem(grpListProducts, i, I18N:getString("iapLabel"..i), strPrice, TBL_PRODUCTS_VALUES[TBL_PRODUCTS_DETAIL_LOADED[i].productIdentifier], grpBnt.x, y, x)

                    grpBnt:toFront()
                end
            end

            grpListProducts.anchorChildren = true
            grpListProducts.anchorX, grpListProducts.anchorY = .5, .5
            grpListProducts.x, grpListProducts.y = display.contentCenterX, display.contentCenterY + 15

        end
    end


    local function loadProductsCallback(event)
        --[[
        for i=1, #event.products do
            print( event.products[i].title )
            print( event.products[i].description )
            print( event.products[i].price )
            print( event.products[i].localizedPrice )
            print( event.products[i].priceLocale )
            print( event.products[i].productIdentifier )
        end
        --]]

        local tblProducts = {}
        tblProducts = event.products
        TBL_PRODUCTS_DETAIL_LOADED = _quicksort(tblProducts, 1)

        showProducts()
    end


    -- LOAD PRODUCTS
    if TIMER_LOAD ~= nil then 
        timer.cancel(TIMER_LOAD) 
        TIMER_LOAD = nil
    end
    TIMER_LOAD = timer.performWithDelay(1, function()
        if Store.target == "google" then --1==1 then--
            _hideLoader(false)

            local event = {}
            event.products = {}
            for i=1, #TBL_PRODUCTS_PRICES do
                event.products[i] = {}
                event.products[i].price = TBL_PRODUCTS_PRICES[i]
                event.products[i].localizedPrice = "US$"..  event.products[i].price
                event.products[i].productIdentifier = TBL_PRODUCTS_ID[i]
            end
            loadProductsCallback(event)

        else
            if Store.canLoadProducts then
                _hideLoader(false)

                Store.loadProducts(TBL_PRODUCTS_ID, loadProductsCallback)

            else
                local grpMsg = display.newGroup()
                grpView:insert(grpMsg)

                local tblTxtOptions = {
                    parent = grpMsg,
                    text = I18N:getString("iapCantLoadProducts"),
                    width = Constants.RIGHT - 100,
                    font = "Maassslicer",
                    fontSize = 20,
                    align = "center"
                }

                local txtMsg = display.newText(tblTxtOptions)
                txtMsg:setFillColor(1, 1, .2)
                txtMsg.anchorX, txtMsg.anchorY = .5, .5
                txtMsg.x, txtMsg.y = 0, 40

                grpMsg.anchorChildren = true
                grpMsg.anchorX, grpMsg.anchorY = .5, .5
                grpMsg.x, grpMsg.y = display.contentCenterX, display.contentCenterY
            end
        end
    end)


end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase

    parent = event.parent

    if phase == "will" then

        globals_bntBackRelease = bntBackRelease

    end
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase
    
    if phase == "did" then

        if parent.overlayEnded then
            parent:overlayEnded()
        end

    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene