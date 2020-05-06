local Composer = require "composer"
local objScene = Composer.newScene()


local Widget = require "widget"
local I18N = require "lib.I18N"


local Wgt = require "classes.phoenix.business.Wgt"
local Controller = require "classes.phoenix.business.Controller"
local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"
local Util = require "classes.phoenix.business.Util"


local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())
local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random

local NUM_ITEM_SCALE_DEFAULT = .7
local camera = {}

local bntBackRelease = function(event)
    local rctOverlay = display.newRect(-10, -10, 500, 350)
    rctOverlay.anchorX, rctOverlay.anchorY, rctOverlay.alpha = 0, 0, 0
    rctOverlay:setFillColor(0)

    camera:blink(true)

    transition.to(rctOverlay, {alpha=1, time=250, onComplete=function()
        transition.to(rctOverlay, {time=150, onComplete=function()
            rctOverlay:removeSelf()
            rctOverlay = nil
            local options = {
                effect = "fade",
                time = 0
            }
            Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
        end})
    end})
    return true
end


function objScene:create(event)
    local grpView = self.view


    local rctOverlay = display.newRect(grpView, -10, -10, 500, 350)
    rctOverlay.anchorX, rctOverlay.anchorY, rctOverlay.alpha = 0, 0, 0
    rctOverlay:setFillColor(0, .3)


    -- GLOBALS
    local TBL_IMG_PICKED = {}
    local TBL_TXT_AVALIABLES = {}
    local TBL_BUTTONS = {}
    local NUM_ID_PICKED = 0


    camera = event.params.camera


    local grpMiddle = display.newGroup()
    grpView:insert(grpMiddle)
    local grpBottom = display.newGroup()
    grpView:insert(grpBottom)
    local grpTop = display.newGroup()
    grpView:insert(grpTop)
    local grpFrame = display.newGroup()
    grpView:insert(grpFrame)


    local txtTitle = {}

    local txtLabel = display.newText(grpMiddle, "", 0, 0, "Maassslicer", 20)
    txtLabel.anchorX, txtLabel.anchorY = 0, .5
    txtLabel.x, txtLabel.y = 0, 0

    local imgPickedNone = display.newSprite(shtButtons, { {name="s", start=4, count=1} })
    imgPickedNone.anchorX, imgPickedNone.anchorY = .5, .5
    imgPickedNone.x, imgPickedNone.y = 0, 0
    imgPickedNone:setFillColor(.2)
    grpMiddle:insert(imgPickedNone)

    local tblTxtOptions = {
        parent = grpMiddle,
        text = "",
        font = "Maassslicer",
        fontSize = 11,
        width = 130,
        align = "right"
    }
    local txtDescription = display.newText(tblTxtOptions)
    txtDescription.anchorX, txtDescription.anchorY = 1, .5
    txtDescription.x, txtDescription.y = 0, 0
        
    local function _uncolorized()
        for i=1, #TBL_BUTTONS do
            local obj = TBL_BUTTONS[i]
            obj:setFillColor(.15)
            obj.sptFx:setFillColor(0)
        end
    end

    local function _unselect()
        Jukebox:dispatchEvent({name="playSound", id="negation"})

        if NUM_ID_PICKED > 0 then

            _uncolorized()

            local txtItemValue = TBL_TXT_AVALIABLES[NUM_ID_PICKED..""]
            txtItemValue.text = " "..(tonumber(txtItemValue.text) + 1)
            txtItemValue.anchorX = .5
            txtItemValue.x = 0

            if txtLabel.trtCancel ~= nil then 
                transition.cancel(txtLabel.trtCancel) 
                txtLabel.trtCancel = nil
            end
            txtLabel.trtCancel = transition.to(txtLabel, {alpha=0, x=150, time=500, transition=easing.outExpo})

            if txtDescription.trtCancel ~= nil then 
                transition.cancel(txtDescription.trtCancel) 
                txtDescription.trtCancel = nil
            end
            txtDescription.trtCancel = transition.to(txtDescription, {alpha=0, x=-150, time=500, transition=easing.outExpo})

            local imgPicked = TBL_IMG_PICKED[NUM_ID_PICKED..""]
            if imgPicked.trtCancel ~= nil then 
                transition.cancel(imgPicked.trtCancel) 
                imgPicked.trtCancel = nil
            end
            imgPicked.trtCancel = transition.to(imgPicked, {alpha=0, xScale=.1, yScale=.1, time=500, transition=easing.outExpo})

            if imgPickedNone.trtCancel ~= nil then 
                transition.cancel(imgPickedNone.trtCancel) 
                imgPickedNone.trtCancel = nil
            end
            imgPickedNone.trtCancel = transition.to(imgPickedNone, {alpha=1, xScale=1, yScale=1, time=500, transition=easing.outElastic})

            if txtTitle.trtCancel ~= nil then 
                transition.cancel(txtTitle.trtCancel) 
                txtTitle.trtCancel = nil
            end
            txtTitle.trtCancel = transition.to(txtTitle, {alpha=1, time=500})

            NUM_ID_PICKED = 0
        end
    end

    local function bntPickedRelease(event)
        local phase = event.phase
        local obj = event.target
        if phase == "ended" then
            _unselect()
        end
        return true
    end
    local bntPicked = Widget.newButton{ sheet = shtButtons, defaultFrame = 20, onEvent = bntPickedRelease } 
    grpMiddle:insert(bntPicked)
    bntPicked.anchorX, bntPicked.anchorY = .5, .5
    bntPicked.x, bntPicked.y = 0, 0
    local sptShadow = display.newSprite(shtButtons, { {name="s", start=20, count=1} })
    grpMiddle:insert(sptShadow)
    local numRandom = random(4)
    local numRot = numRandom == 1 and 0 or (numRandom == 2 and 90 or (numRandom == 3 and 180 or 270))
    sptShadow:rotate(numRot, numRot)
    local numScaleX, numScaleY = random(2) == 1 and 1 or -1, random(2) == 1 and 1 or -1 
    sptShadow:scale(numScaleX, numScaleY)
    sptShadow.alpha = .5
    sptShadow.anchorX, sptShadow.anchorY = .5, .5
    sptShadow.x, sptShadow.y = 0, 0

    bntPicked:setFillColor(.15)
    sptShadow:setFillColor(0)

    grpMiddle.anchorX, grpMiddle.anchorY = .5, .5
    grpMiddle.x, grpMiddle.y = -Constants.RIGHT, display.contentCenterY

    local function bntPlayRelease(event)
        if NUM_ID_PICKED > 0 then
            local tblData = Controller:getData():getStore(NUM_ID_PICKED.."")
            tblData.v = tblData.v - 1
            Controller:getData():setStore(NUM_ID_PICKED.."", tblData)
            camera.codAssist = NUM_ID_PICKED
        end

        Controller:setStatus(1)

        transition.to(grpTop, {delay=0, time=400, y=-200, transition=easing.inQuad})
        transition.to(txtLabel, {delay=0, time=300, alpha=0})
        transition.to(txtDescription, {delay=0, time=200, alpha=0})
        transition.to(grpMiddle, {delay=200, time=400, x=1000, transition=easing.inQuad, onComplete=function()
            Composer.hideOverlay(false, "fade", 0)
        end})
        transition.to(grpBottom, {alpha=0, time=400})
        transition.to(rctOverlay, {delay=100, time=500, alpha=0})
        transition.to(grpFrame[1], {delay=100, time=100, alpha=0})

        -- HIDE FRAME
        for i=1, grpFrame.numChildren do
            local obj = grpFrame[i]
            if obj.trtCancel ~= nil then 
                transition.cancel(obj.trtCancel)
                obj.trtCancel = nil 
            end
            if i ~= 1 then
                obj.trtCancel = transition.to(obj, {x=obj.xFrom, y=obj.yFrom, time=300})
            end
        end
    end
    local bntPlay = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 1,
        onRelease = bntPlayRelease
    }
    transition.blink(bntPlay[2], {time=2000})

    imgPickedNone:toFront()

    transition.to(grpMiddle, {delay=0, time=600, x=display.contentCenterX, transition=easing.outBack})
    transition.to(rctOverlay, {delay=200, time=500, alpha=1})


    local rctBGBottom = display.newRect(grpBottom, -10, -10, 500, 140)
    rctBGBottom.anchorX, rctBGBottom.anchorY = .5, .5
    rctBGBottom.x, rctBGBottom.y = 0, 0
    rctBGBottom.isVisible = false

    txtTitle = display.newText(grpBottom, I18N:getString("assist"), 0, 0, "Maassslicer", 13)
    txtTitle.anchorX, txtTitle.anchorY = .5, 0
    txtTitle.x, txtTitle.y = 0, -rctBGBottom.height * .5 - 10

    grpBottom.anchorX, grpBottom.anchorY = .5, 0
    grpBottom.x, grpBottom.y = display.contentCenterX, Constants.BOTTOM + grpBottom.height
    local numY = display.contentCenterY + 40 + rctBGBottom.height * .5
    transition.to(grpBottom, {delay=800, time=800, y=numY, transition=easing.outExpo})


    local scrView = {}
    local NUM_HEIGHT_SCRVIEW = 140

    local grpItens = display.newGroup()

    -- ITENS ASSIST
    local function bntItemEvent(event)
        local phase = event.phase
        local obj = event.target
        
        if phase == "began" then

        elseif phase == "moved" then

            if grpItens.width > scrView.width then
                scrView:takeFocus(event)
            end

        elseif phase == "ended" then

            _uncolorized()

            local tblData = obj.tblData

            if tblData.v == 0 then
                Jukebox:dispatchEvent({name="playSound", id="negation"})
                return true
            else
                Jukebox:dispatchEvent({name="playSound", id="button"})
            end

            if tblData.i == NUM_ID_PICKED then
                _unselect()
                return true
            end

            obj:setFillColor(.3)
            obj.sptFx:setFillColor(.3)

            txtLabel.text = I18N:getString(tblData.l)
            if txtLabel.trtCancel ~= nil then 
                transition.cancel(txtLabel.trtCancel) 
                txtLabel.trtCancel = nil
            end
            txtLabel.x, txtLabel.alpha = -150, 0
            txtLabel.trtCancel = transition.to(txtLabel, {alpha=1, x=30, time=500, transition=easing.outBack})

            txtDescription.text = I18N:getString(tblData.l.."Description")
            if txtDescription.trtCancel ~= nil then 
                transition.cancel(txtDescription.trtCancel) 
                txtDescription.trtCancel = nil
            end
            txtDescription.x, txtDescription.alpha = 150, 0
            txtDescription.trtCancel = transition.to(txtDescription, {alpha=1, x=-30, time=500, transition=easing.outBack})

            if txtTitle.trtCancel ~= nil then 
                transition.cancel(txtTitle.trtCancel) 
                txtTitle.trtCancel = nil
            end
            txtTitle.trtCancel = transition.to(txtTitle, {alpha=0, time=500})

            obj.txtItemValue.text = " "..tblData.v - 1
            obj.txtItemValue.anchorX = .5
            obj.txtItemValue.x = 0
            if NUM_ID_PICKED > 0 then
                local txtItemValue = TBL_TXT_AVALIABLES[NUM_ID_PICKED..""]
                txtItemValue.text = " "..(tonumber(txtItemValue.text) + 1)
                txtItemValue.anchorX = .5
                txtItemValue.x = 0
            end
            NUM_ID_PICKED = tblData.i

            for k, imgPicked in pairs(TBL_IMG_PICKED) do
                if imgPicked.trtCancel ~= nil then 
                    transition.cancel(imgPicked.trtCancel) 
                    imgPicked.trtCancel = nil
                end
                imgPicked.trtCancel = transition.to(imgPicked, {alpha=0, xScale=.1, yScale=.1, time=500})
            end


            if imgPickedNone.trtCancel ~= nil then 
                transition.cancel(imgPickedNone.trtCancel) 
                imgPickedNone.trtCancel = nil
            end
            imgPickedNone.trtCancel = transition.to(imgPickedNone, {alpha=0, xScale=.1, yScale=.1, time=1000})

            local imgPicked = TBL_IMG_PICKED[tblData.i..""]
            if imgPicked.trtCancel ~= nil then 
                transition.cancel(imgPicked.trtCancel) 
                imgPicked.trtCancel = nil
            end
            imgPicked.xScale, imgPicked.yScale, imgPicked.alpha = .1, .1, 0
            imgPicked.trtCancel = transition.to(imgPicked, {alpha=1, xScale=1, yScale=1, time=1000, transition=easing.outElastic})
        else

            obj.parent.xScale, obj.parent.yScale = NUM_ITEM_SCALE_DEFAULT, NUM_ITEM_SCALE_DEFAULT
            obj:setFillColor(.15)
            obj.sptFx:setFillColor(0)

        end
        return true
    end
    local numCount = 1
    local tblStore = Controller:getData():getStoresSorted()
    for i=9, #tblStore do
        local tblData = Controller:getData():getStore(tblStore[i].i.."")

        if tblData.k ~= 1 and tblData.v ~= 0 then

            local grpItem = display.newGroup()
            grpItens:insert(grpItem)

            local bntItem = Widget.newButton{ sheet = shtButtons, defaultFrame = 20, onEvent = bntItemEvent } 
            bntItem.anchorX, bntItem.anchorY = .5, .5
            bntItem.x, bntItem.y = 0, 0
            local numRandom = random(4)
            local numRot = numRandom == 1 and 0 or (numRandom == 2 and 90 or (numRandom == 3 and 180 or 270))
            bntItem:rotate(numRot, numRot)
            local numScaleX, numScaleY = random(2) == 1 and 1 or -1, random(2) == 1 and 1 or -1 
            bntItem:scale(numScaleX, numScaleY)
            if tblData.v == tblData.t then
                bntItem:setFillColor(1, 1, .2)
            end
            bntItem.tblData = tblData
            grpItem:insert(bntItem)
            TBL_BUTTONS[#TBL_BUTTONS+1] = bntItem

            local sptItem = display.newSprite(shtButtons, { {name="s", start=20, count=1} })
            bntItem.sptFx = sptItem
            local numRandom = random(4)
            local numRot = numRandom == 1 and 0 or (numRandom == 2 and 90 or (numRandom == 3 and 180 or 270))
            sptItem:rotate(numRot, numRot)
            local numScaleX, numScaleY = random(2) == 1 and 1 or -1, random(2) == 1 and 1 or -1 
            sptItem:scale(numScaleX, numScaleY)
            sptItem.alpha = .5
            grpItem:insert(sptItem)

            bntItem:setFillColor(.15)
            sptItem:setFillColor(0)

            local tblFrames = {nil,nil,nil,nil,nil,nil,nil,21,34,35,36,37,38,39,40,41,42,43}

            local imgItem = display.newSprite(shtButtons, { {name="s", start=tblFrames[tblData.i], count=1} })
            imgItem.anchorX, imgItem.anchorY = .5, .5
            imgItem.xScale, imgItem.yScale, imgItem.alpha = .7, .7, 1
            imgItem.y = -6
            grpItem:insert(imgItem)

            local imgPicked = display.newSprite(shtButtons, { {name="s", start=tblFrames[tblData.i], count=1} })
            imgPicked.alpha, imgPicked.rotation, imgPicked.x, imgPicked.y = 0, imgItem.rotation, 0, 0
            imgPicked:scale(.1, .1)
            grpMiddle:insert(imgPicked)
            TBL_IMG_PICKED[tblData.i..""] = imgPicked

            local txtItemValue = display.newText(grpItem, " "..tblData.v, 0, 0, "Maassslicer", 9)
            txtItemValue.anchorX, txtItemValue.anchorY = .5, .5
            txtItemValue.x, txtItemValue.y, txtItemValue.alpha = 0, 14, 1
            if tblData.k == 1 then
                txtItemValue.isVisible = false
            end
            bntItem.txtItemValue = txtItemValue
            TBL_TXT_AVALIABLES[tblData.i..""] = txtItemValue

            grpItem.anchorX, grpItem.anchorY = 0, 1
            local numWidth = bntItem.width - 8
            grpItem.x, grpItem.y = numCount * numWidth - numWidth * .5 + 4, NUM_HEIGHT_SCRVIEW
            grpItem:scale(NUM_ITEM_SCALE_DEFAULT, NUM_ITEM_SCALE_DEFAULT)

            numCount = numCount + 1

        end
    end


    local rctBg = display.newRect(grpTop, -10, -10, 500, 46)
    rctBg.anchorX, rctBg.anchorY = .5, .5
    rctBg.x, rctBg.y = 0, 42
    rctBg:setFillColor(0, .5)

    -- SCROLL
    scrView = Widget.newScrollView{
        width = Constants.RIGHT + 10,
        height = NUM_HEIGHT_SCRVIEW,
        horizontalScrollDisabled = true,--grpItens.width < Constants.RIGHT + 10,
        verticalScrollDisabled = true,
        hideBackground = true,
        hideScrollBar = false,
        isBounceEnabled = true,
        autoHideScrollBar = false,
        keepPositionOnInsert = false,
    }
    grpTop:insert(scrView)
    scrView:insert(grpItens)

    --[[
    local txtAvaliable = display.newText(grpTop, I18N:getString("assistAvaliable"), 0, 0, "Maassslicer", 9)
    txtAvaliable.anchorX, txtAvaliable.anchorY, txtAvaliable.alpha = .5, 1, 1
    txtAvaliable.x, txtAvaliable.y = 0,  15
    --]]

    grpItens.anchorX, grpItens.anchorY = 0, 0
    if grpItens.width > scrView.width then
        -- PADDING RIGHT
        local rctPaddingRight = display.newRect(scrView:getView().width + 15, 0, 10, 10)
        rctPaddingRight.alpha = .01
        scrView:insert(rctPaddingRight)
        grpItens.x, grpItens.y = 0, -28
    else
        grpItens.x, grpItens.y = (scrView.width - grpItens.width) * .5 - 15 * .5, -28
    end


    scrView.anchorX, scrView.anchorY = .5, .5
    scrView.x, scrView.y = 0, 0


    grpTop.anchorX, grpTop.anchorY = .5, 1
    grpTop.x, grpTop.y = display.contentCenterX, - scrView.height
    local numY = display.contentCenterY - 40 - scrView.height * .5
    transition.to(grpTop, {delay=500, time=800, y=numY, transition=easing.outExpo})


    globals_bntBackRelease = bntBackRelease
    local bntPrevious = Wgt.newButton {
        sheet = shtButtons,
        defaultFrame = 14,
        onRelease = globals_bntBackRelease
    }
    bntPrevious[2].rotation = 90


    Util:generateFrame(grpFrame, nil, nil, bntPlay, bntPrevious)
end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        globals_bntBackRelease = bntBackRelease

        Jukebox:dispatchEvent({name="stopMusic"})

        parent:overlayBegan(true)

    elseif phase == "did" then

        Controller:setStatus(11)

    end
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        globals_bntBackRelease = nil

    elseif phase == "did" then

        parent:overlayEnded()

    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene