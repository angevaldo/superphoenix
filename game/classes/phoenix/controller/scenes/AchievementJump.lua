local Composer = require "composer"
local objScene = Composer.newScene()


local I18N = require "lib.I18N"


local Wgt = require "classes.phoenix.business.Wgt"
local Util = require "classes.phoenix.business.Util"
local Controller = require "classes.phoenix.business.Controller"
local Constants = require "classes.phoenix.business.Constants"
local Message = require "classes.phoenix.business.Message"


local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())
local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())


local bntBackRelease = function(event)
    Composer.hideOverlay(false, "fade", 200)
    return false
end


function objScene:create(event)
    local grpView = self.view


    globals_bntBackRelease = bntBackRelease


    local params = event.params
    
    
    local NUM_PRICE = params.numPriceBuy


    local rctOverlay = display.newRect(grpView, -10, -10, 500, 350)
    rctOverlay.anchorX, rctOverlay.anchorY = 0, 0
    rctOverlay:setFillColor(0, .95)


    -- CASH
    local grpCash = display.newGroup()
    grpView:insert(grpCash)

    local tblTxtBuy = {
        parent = grpCash,
        text = " "..Util:formatNumber(Controller:getData():getCash()),
        width = 150,
        height = 40,
        font = "Maassslicer",
        fontSize = 26,
        align = "right"
    }
    txtCash = display.newText(tblTxtBuy)
    txtCash:setFillColor(1, 1, .2)
    txtCash.anchorX, txtCash.anchorY = 1, .5
    txtCash.x, txtCash.y = 0, 2

    local imgCashCoin = display.newSprite(shtUtilUi, { {name="standard", start=9, count=1} })
    imgCashCoin.anchorX, imgCashCoin.anchorY = 0, .5
    imgCashCoin.x, imgCashCoin.y = 0, -5
    grpCash:insert(imgCashCoin)

    grpCash.anchorChildren = true
    grpCash.anchorX, grpCash.anchorY = 1, 0
    grpCash.x, grpCash.y = Constants.RIGHT, Constants.TOP


    local grpQuestion = display.newGroup()
    grpView:insert(grpQuestion)

    local tblTxtOptions = {
        parent = grpQuestion,
        font = "Maassslicer",
        align = "left"
    }

    tblTxtOptions.text = I18N:getString("achievementJumpDescription")
    tblTxtOptions.fontSize = 20
    local txtQuestion = display.newText(tblTxtOptions)
    txtQuestion.anchorX, txtQuestion.anchorY = 0, .5
    txtQuestion.x, txtQuestion.y = 0, 0

    tblTxtOptions.text = " "..Util:formatNumber(NUM_PRICE)
    tblTxtOptions.fontSize = 22
    local txtPrice = display.newText(tblTxtOptions)
    txtPrice:setFillColor(1, 1, .2)
    txtPrice.anchorX, txtPrice.anchorY = 0, .5
    txtPrice.x, txtPrice.y = txtQuestion.x + txtQuestion.width - 5, 0

    local imgCoin = display.newSprite(shtUtilUi, { {name="standard", start=9, count=1} })
    imgCoin:scale(.6, .6)
    imgCoin.anchorX, imgCoin.anchorY = 0, .5
    imgCoin.x, imgCoin.y = txtPrice.x + txtPrice.width, -1
    grpQuestion:insert(imgCoin)

    tblTxtOptions.text = " ?"
    tblTxtOptions.fontSize = 16
    local txtInterr = display.newText(tblTxtOptions)
    txtInterr.anchorX, txtInterr.anchorY = 0, .5
    txtInterr.x, txtInterr.y = imgCoin.x + imgCoin.width - 10, 0

    grpQuestion.anchorChildren = true
    grpQuestion.anchorX, grpQuestion.anchorY = .5, .5
    grpQuestion.x, grpQuestion.y = display.contentCenterX, display.contentCenterY - 15


    local grpYes = display.newGroup()
    grpView:insert(grpYes)
    local function bntYesRelease(event)

        local tblData = Controller:getData():getAchievement(""..params.id)
        tblData.k = 0
        Controller:getData():setAchievement(tblData)
        Controller:getData():addCash(-NUM_PRICE)

        local strResume = I18N:getString("achievementDescription"..tblData.t)
        strResume = string.gsub(strResume, "xx", ""..tblData.v)
        Message:addMessage({text=strResume})

        Composer.stage.alpha = 0
        local options = {
            effect = "fade",
            time = 0,
            params = {scene="classes.phoenix.controller.scenes.Achievement"}
        }
        Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)

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

        globals_bntBackRelease = bntBackRelease

        if parent.overlayBegan then
            parent:overlayBegan()
        end

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