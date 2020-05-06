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


function objScene:goNextScene()
    if Composer.getSceneName("current") == "classes.phoenix.controller.scenes.RateIt" then
        local options = {
            effect = "fade",
            time = 300,
            params = self.params
        }
        Composer.gotoScene(self.params.scene, options)
    end
end


local bntBackRelease = function(event)
    objScene:goNextScene()

    return true
end


function objScene:create(event)
    local grpView = self.view
    self.params = event.params
    
    grpView.isVisible = false


    local NUM_PRICE = 250


    globals_bntBackRelease = bntBackRelease


    local rctOverlay = display.newRect(grpView, -10, -10, 500, 350)
    rctOverlay.anchorX, rctOverlay.anchorY = 0, 0
    rctOverlay:setFillColor(0, 1)


    local tblTxtOptions = {
        font = "Maassslicer",
        align = "center"
    }

    tblTxtOptions.text = I18N:getString("rateTitle")
    tblTxtOptions.fontSize = 16
    local txtTitle = display.newText(tblTxtOptions)
    grpView:insert(txtTitle)
    txtTitle.anchorX, txtTitle.anchorY = .5, 0
    txtTitle.x, txtTitle.y = display.contentCenterX, Constants.TOP

    local grpMsg = display.newGroup()
    grpView:insert(grpMsg)

    tblTxtOptions.text = I18N:getString("rateitMessage")
    tblTxtOptions.fontSize = 20
    local txtMsg = display.newText(tblTxtOptions)
    grpMsg:insert(txtMsg)
    txtMsg:setFillColor(1)
    txtMsg.anchorX, txtMsg.anchorY = 0, .5
    txtMsg.x, txtMsg.y = 0, 0

    tblTxtOptions.text = " "..Util:formatNumber(NUM_PRICE)
    tblTxtOptions.fontSize = 22
    local txtPrice = display.newText(tblTxtOptions)
    grpMsg:insert(txtPrice)
    txtPrice:setFillColor(1, 1, .2)
    txtPrice.anchorX, txtPrice.anchorY = 0, .5
    txtPrice.x, txtPrice.y = txtMsg.x + txtMsg.width, 0

    local imgCoin = display.newSprite(shtUtilUi, { {name="standard", start=9, count=1} })
    grpMsg:insert(imgCoin)
    imgCoin:scale(.6, .6)
    imgCoin.anchorX, imgCoin.anchorY = 0, .5
    imgCoin.x, imgCoin.y = txtPrice.x + txtPrice.width, -1

    grpMsg.anchorChildren = true
    grpMsg.anchorX, grpMsg.anchorY = .5, .5
    grpMsg.x, grpMsg.y = display.contentCenterX, display.contentCenterY - 15


    local grpYes = display.newGroup()
    grpView:insert(grpYes)
    local function bntYesRelease(event)
        Controller:getData():setProfile("isBeenRated", true)
        Controller:getData():addCash(NUM_PRICE)

        local options = {
           iOSAppId = "872827927",
           supportedAndroidStores = { "google" },
        }
        native.showPopup("rateApp", options)

        self:goNextScene()

        return true
    end
    local bntYes = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 11,
        onRelease = bntYesRelease
    }
    grpYes:insert(bntYes)
    grpYes.anchorX, grpYes.anchorY = .5, .5
    grpYes.rotation = 180
    grpYes.x, grpYes.y = display.contentCenterX - 50, display.contentCenterY + 40


    local bntNo = Wgt.newButton {
        sheet = shtButtons,
        defaultFrame = 4,
        onRelease = globals_bntBackRelease
    }
    bntNo.anchorX, bntNo.anchorY = .5, .5
    bntNo.x, bntNo.y = display.contentCenterX + 50, display.contentCenterY + 40
    grpView:insert(bntNo)

end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        grpView.isVisible = true
        Composer.stage.alpha = 1

        globals_bntBackRelease = bntBackRelease

    end
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "did" then

        if parent and parent.overlayEnded then
            parent:overlayEnded()
        end

    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene