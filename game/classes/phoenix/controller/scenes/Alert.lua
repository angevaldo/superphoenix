local Composer = require "composer"
local objScene = Composer.newScene()


local I18N = require "lib.I18N"


local Wgt = require "classes.phoenix.business.Wgt"
local Util = require "classes.phoenix.business.Util"
local Constants = require "classes.phoenix.business.Constants"
local Controller = require "classes.phoenix.business.Controller"


local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())
local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())


local bntBackRelease = function(event)
    Composer.hideOverlay(false, "fade", 200)
    return true
end


function objScene:create(event)
    local grpView = self.view
    
    grpView.isVisible = false


    globals_bntBackRelease = bntBackRelease


    local rctOverlay = display.newRect(grpView, -10, -10, 500, 350)
    rctOverlay.anchorX, rctOverlay.anchorY = 0, 0
    rctOverlay:setFillColor(0, .95)


    local grpFrame = display.newGroup()
    grpView:insert(grpFrame)


    local params = event.params


    local tblTxtOptions = {
        parent = grpView,
        text = params.strTitle,
        width = Constants.RIGHT - 100,
        font = "Maassslicer",
        fontSize = 18,
        align = "center"
    }

    local txtTitle = display.newText(tblTxtOptions)
    txtTitle.anchorX, txtTitle.anchorY = .5, 0
    txtTitle.x, txtTitle.y = display.contentCenterX, Constants.TOP


    tblTxtOptions.text = params.strMsg.." !  "..I18N:getString("or")
    tblTxtOptions.fontSize = 16

    local txtMsg = display.newText(tblTxtOptions)
    txtMsg:setFillColor(1)
    txtMsg.anchorX, txtMsg.anchorY = .5, 1
    txtMsg.x, txtMsg.y = display.contentCenterX, display.contentCenterY - 5

    local tblTxtOptions = {
        font = "Maassslicer",
        align = "left"
    }

    local grpQuestion = display.newGroup()
    grpView:insert(grpQuestion)

    tblTxtOptions.text = " "..Util:formatNumber(params.numPriceUnlock)
    tblTxtOptions.fontSize = 22
    tblTxtOptions.parent = grpQuestion
    local txtPrice = display.newText(tblTxtOptions)
    txtPrice:setFillColor(1, 1, .2)
    txtPrice.anchorX, txtPrice.anchorY = 1, .5
    txtPrice.x, txtPrice.y = 0, 0

    local imgCoin = display.newSprite(shtUtilUi, { {name="standard", start=9, count=1} })
    imgCoin:scale(.6, .6)
    imgCoin.anchorX, imgCoin.anchorY = 0, .5
    imgCoin.x, imgCoin.y = 0, -1
    grpQuestion:insert(imgCoin)

    local bntBuyRelease = function(event)
        local numPriceBuy = event.target.id
        if Controller:getData():getCash() < params.numPriceUnlock then
            local options = {
                isModal = true,
                effect = "fade",
                time = 0,
            }
            Composer.showOverlay("classes.phoenix.controller.scenes.Buy", options)
        else
            Controller:getData():addCash(-params.numPriceUnlock)
            local tblData = Controller:getData():getStore(params.numID.."")
            tblData.k = 0
            Controller:getData():setStore(tblData)
            Composer.stage.alpha = 0
            local options = {
                effect = "fade",
                time = 0,
                params = {scene="classes.phoenix.controller.scenes.Store"}
            }
            Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
        end
        return true
    end

    local grpBnt = display.newGroup()
    grpQuestion:insert(grpBnt)
    local bntBuy = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 46,
        onRelease = bntBuyRelease
    } 
    grpBnt:insert(bntBuy)
    grpBnt.anchorX, grpBnt.anchorY = 0, .5
    grpBnt.x, grpBnt.y = imgCoin.x + imgCoin.width + 25, 0

    grpQuestion.anchorChildren = true
    grpQuestion.anchorX, grpQuestion.anchorY = .5, 0
    grpQuestion.x, grpQuestion.y = display.contentCenterX, display.contentCenterY - 5


    local bntBack = Wgt.newButton {
        sheet = shtButtons,
        defaultFrame = 14,
        onRelease = globals_bntBackRelease
    }


    Util:generateFrame(grpFrame, bntBack, nil, nil, nil)


end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        globals_bntBackRelease = bntBackRelease

    end
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

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