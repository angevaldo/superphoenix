local round = math.round


local Composer = require "composer"
local objScene = Composer.newScene()


local I18N = require "lib.I18N"


local Wgt = require "classes.phoenix.business.Wgt"
local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"
local Constants = require "classes.phoenix.business.Constants"


local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())
local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())
local infAchievements = require("classes.infoAchievements")
local shtAchievements = graphics.newImageSheet("images/ui/scnAchievements.png", infAchievements:getSheet())
local infScenario = require("classes.infoScenario")
local shtScenario = graphics.newImageSheet("images/ui/bkgScenario.jpg", infScenario:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random


local bntBackRelease = function(event)
    local options = {
        effect = "fade",
        time = 0
   }
    Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
    return true
end


function objScene:create()
    local grpView = self.view
    grpView.isVisible = false


    globals_bntBackRelease = bntBackRelease


    local NUM_PRICE = 500


    local imgBkg = display.newSprite(shtScenario, { {name="s", frames={2}} })
    imgBkg.anchorX, imgBkg.anchorY = .5, .5
    imgBkg.x, imgBkg.y = display.contentCenterX, display.contentCenterY
    grpView:insert(imgBkg)


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


    local grpFrame = display.newGroup()
    grpView:insert(grpFrame)

    local numLineHeight = 42
    local tblDescribe = {}
    local tblMissionsCurrent = Controller:getData():getProfile("tblMissionsCurrent")

    if #tblMissionsCurrent > 0 then

        local tblProgress = Controller:getData():getAchievementsProgress()


        local txtTitle = display.newText(grpView, I18N:getString("achievements")..": "..tblProgress.numQttUnlocked.. " / " .. tblProgress.numQttT, 0, 0, "Maassslicer", 15)
        txtTitle.anchorX, txtTitle.anchorY = .5, 0
        txtTitle.x, txtTitle.y = display.contentCenterX, Constants.TOP


        local grpStats = display.newGroup()
        grpView:insert(grpStats)

        local rctBar = display.newRect(grpStats, 0, -10, 80, 8)
        rctBar.anchorX, rctBar.anchorY = 0, .5
        rctBar.x, rctBar.y = 0, 0
        rctBar:setFillColor(1, .3)
        local rctProgress = display.newRect(grpStats, 1, -10, 80, 8)
        rctProgress.anchorX, rctProgress.anchorY = 0, .5
        rctProgress.x, rctProgress.y = rctBar.x, 0
        rctProgress.xScale = (tblProgress.numProgress / 100) + .001

        local tblTxtOptionsHud = {
            parent = grpStats,
            font = "Maassslicer",
            fontSize = 9,
            align = "left",
        }

        tblTxtOptionsHud.text = " "..tblProgress.numProgress.."% "

        local txtProgress = display.newText(tblTxtOptionsHud)
        txtProgress.anchorX, txtProgress.anchorY = 0, .5
        txtProgress.x, txtProgress.y = rctBar.x + rctBar.width + 2, 1

        grpStats.anchorChildren = true
        grpStats.anchorX, grpStats.anchorY = .5, 0
        grpStats.x, grpStats.y = display.contentCenterX, txtTitle.y + txtTitle.height + 2


        local grpAchievements = display.newGroup()
        grpView:insert(grpAchievements)

        local rctOverlayAchievement = display.newRect(-10, -10, 500, numLineHeight * 3 + 15)
        rctOverlayAchievement.anchorX, rctOverlayAchievement.anchorY = .5, 0
        rctOverlayAchievement.x, rctOverlayAchievement.y = 0, 0
        rctOverlayAchievement:setFillColor(0, .7)
        grpAchievements:insert(rctOverlayAchievement)

        local tblTxtOptions = {
            parent = grpAchievements,
            font = "Maassslicer",
        }

        for i=1, #tblMissionsCurrent do
            tblDescribe = Controller:getData():getDescribeMission(tblMissionsCurrent[i])
            
            tblTxtOptions.text = " "..tblDescribe.strLabel
            tblTxtOptions.align = "left"
            tblTxtOptions.fontSize = 9

            local txtLabel = display.newText(tblTxtOptions)
            txtLabel:setFillColor(1, .4)
            txtLabel.anchorX, txtLabel.anchorY = 0, 0
            txtLabel.x, txtLabel.y = -140, (numLineHeight + 2) * (i-1) + 13

            local grpCoins = display.newGroup()
            grpAchievements:insert(grpCoins)

            tblTxtOptions.text = " "..tblDescribe.numReward
            tblTxtOptions.align = "righ"
            tblTxtOptions.fontSize = 16

            local txtCoins = display.newText(tblTxtOptions)
            txtCoins:setFillColor(1, 1, .2)
            txtCoins.anchorX, txtCoins.anchorY = 1, .5
            txtCoins.x, txtCoins.y = -1, 0
            grpCoins:insert(txtCoins)

            local imgCoin = display.newSprite(shtUtilUi, { {name="standard", start=10, count=1} })
            imgCoin.anchorX, imgCoin.anchorY = 0, .5
            imgCoin.x, imgCoin.y = 0, -1
            grpCoins:insert(imgCoin)

            grpCoins.anchorChildren = true
            grpCoins.anchorX, grpCoins.anchorY = 0, .5
            grpCoins.x, grpCoins.y = txtLabel.x + txtLabel.width + 7, txtLabel.y + numLineHeight * .5 - 13

            local sptIcon = display.newSprite(shtAchievements, { {name="s", start=tblDescribe.numType, count=1} })
            grpAchievements:insert(sptIcon)
            sptIcon.anchorX, sptIcon.anchorY = .5, .5
            sptIcon.x, sptIcon.y = -155, txtLabel.y + numLineHeight * .5 - 6

            tblTxtOptions.text = " "..tblDescribe.strDescription
            tblTxtOptions.align = "left"
            tblTxtOptions.fontSize = 11

            local txtDescription = display.newText(tblTxtOptions)
            txtDescription:setFillColor(1)
            txtDescription.anchorX, txtDescription.anchorY = 0, 0
            txtDescription.x, txtDescription.y = txtLabel.x, txtLabel.y + txtLabel.height + 6

            if i ~= #tblMissionsCurrent then
                local linSeparator = display.newLine(grpAchievements, 0, 0, 600, 0)
                linSeparator:setStrokeColor(1, .07)
                linSeparator.anchorX, linSeparator.anchorY = 0, .5
                linSeparator.x, linSeparator.y = -300, txtLabel.y + numLineHeight - 6
            end

            local bntBuyRelease = function(event)
                local numPriceBuy = event.target.id
                local scene = Controller:getData():getCash() < numPriceBuy and "classes.phoenix.controller.scenes.Buy" or "classes.phoenix.controller.scenes.AchievementJump"

                local options = {
                    isModal = true,
                    effect = "fade",
                    time = 0,
                    params = {id=tblMissionsCurrent[i], numPriceBuy=numPriceBuy}
                }
                Composer.showOverlay(scene, options)
                return false
            end

            local numPriceBuy = round(tblDescribe.numReward * .025) * 100

            local grpBnt = display.newGroup()
            grpAchievements:insert(grpBnt)
            local bntBuy = Wgt.newButton{
                sheet = shtButtons,
                defaultFrame = 45,
                id = numPriceBuy,
                onRelease = bntBuyRelease
            } 
            grpBnt:insert(bntBuy)
            grpBnt:scale(.6, .6)
            grpBnt.anchorX, grpBnt.anchorY = 0, 0
            grpBnt.x, grpBnt.y = 150, txtDescription.y - 2


            tblTxtOptions.text = " "..numPriceBuy
            tblTxtOptions.align = "left"
            tblTxtOptions.fontSize = 11

            local txtBuyCoins = display.newText(tblTxtOptions)
            txtBuyCoins:setFillColor(1, 1, .2)
            txtBuyCoins.anchorX, txtBuyCoins.anchorY = 0, .5
            txtBuyCoins.x, txtBuyCoins.y = grpBnt.x + 20, grpBnt.y
            grpAchievements:insert(txtBuyCoins)

            local imgBuyCoin = display.newSprite(shtUtilUi, { {name="standard", start=10, count=1} })
            imgBuyCoin.anchorX, imgBuyCoin.anchorY = 0, .5
            imgBuyCoin.x, imgBuyCoin.y = txtBuyCoins.x + txtBuyCoins.width, txtBuyCoins.y
            imgBuyCoin:scale(.8, .8)
            grpAchievements:insert(imgBuyCoin)
        end

        grpAchievements.anchorChildren = true
        grpAchievements.anchorX, grpAchievements.anchorY = .5, .5
        grpAchievements.x, grpAchievements.y = display.contentCenterX, display.contentCenterY

    else

        local tblTxt = {
            parent = grpView,
            font = "Maassslicer",
            align = "center"
        }


        tblTxt.text = I18N:getString("achievementsCompletedTitle")
        tblTxt.fontSize = 25

        local txtTitle = display.newText(tblTxt)
        transition.blink(txtTitle, {time=2000})
        txtTitle:setFillColor(1, 1, .2)
        txtTitle.anchorX, txtTitle.anchorY = .5, .5
        txtTitle.x, txtTitle.y = display.contentCenterX, display.contentCenterY - 20

        tblTxt.text = I18N:getString("achievementsCompletedDescription")
        tblTxt.fontSize = 14

        local txtDescription = display.newText(tblTxt)
        txtDescription.anchorX, txtDescription.anchorY = .5, .5
        txtDescription.x, txtDescription.y = display.contentCenterX, display.contentCenterY + 20

    end


    local bntMenu = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 16,
        onRelease = globals_bntBackRelease
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
        onRelease = bntPlayRelease
    }
    transition.blink(bntPlay[2], {time=2000})


    Util:generateFrame(grpFrame, nil, nil, bntPlay, bntMenu)


    grpFrame:toFront()
end

function objScene:show(event)
    local grpView = self.view
    local phase = event.phase

    if phase == "will" then

        Composer.stage.alpha = 1

        globals_bntBackRelease = bntBackRelease

    elseif phase == "did" then

        Controller:setStatus(0, true)

    end
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase

    if phase == "did" then

        globals_bntBackRelease = bntBackRelease

    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene