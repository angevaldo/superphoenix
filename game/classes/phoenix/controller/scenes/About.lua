local Composer = require "composer"
local objScene = Composer.newScene()


local Wgt = require "classes.phoenix.business.Wgt"
local Util = require "classes.phoenix.business.Util"
local Constants = require "classes.phoenix.business.Constants"
local Controller = require "classes.phoenix.business.Controller"
local Trt = require "lib.Trt"
local I18N = require "lib.I18N"


local infObstacles = require("classes.infoObstacles")
local shtObstacles = graphics.newImageSheet("images/gameplay/aniObstacles.png", infObstacles:getSheet())
local infObstacles = require("classes.infoObstacles")
local shtObstacles = graphics.newImageSheet("images/gameplay/aniObstacles.png", infObstacles:getSheet())
local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())
local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())


local source = ""

local bntBackRelease = function(event)
    if source == "classes.phoenix.controller.scenes.Options" then
        local options = {
            isModal = true,
            effect = "fade",
            time = 0,
        }
        Composer.showOverlay(source, options)
    else
        Composer.hideOverlay(false, "fade", 200)
    end
    return true
end

function objScene:create(event)
    local grpView = self.view
    grpView.isVisible = false

    source = event.params.source

    local rctBg = display.newRect(grpView, 0,0, 500, 300)
    rctBg.anchorX, rctBg.anchorY = 0, 0
    rctBg.alpha = .01

    local grpCredits = display.newGroup()

    local function _addText(str, typeText, dist)
        local y = grpCredits.numChildren == 0 and 0 or grpCredits[grpCredits.numChildren].y + dist
        local tblColor = {1, 1, 1}
        local size = 10
        tblColor = {.5, .5, .5}
        if typeText == 2 then
            tblColor = {1, 1, 1}
            size = 13
        elseif typeText == 3 then
            tblColor = {1, .9, .3}
            size = 10
        end
        local txt = display.newText(grpCredits, str, 0, 0, "Maassslicer", size)
        txt:setFillColor(tblColor[1], tblColor[2], tblColor[3])
        txt.anchorX, txt.anchorY = .5, 0
        txt.x, txt.y = 0, y
    end

    _addText(" ", 1, 0)
    _addText(I18N:getString("aboutVersion").." "..Controller:getData():getProfile("gameVersion"), 1, 115)
    _addText(I18N:getString("aboutCode"), 3, 60)
    _addText(" Angevaldo Rocha Jr ", 2, 20)
    _addText(I18N:getString("aboutDesign"), 3, 50)
    _addText(" Angevaldo Rocha Jr ", 2, 20)
    _addText(" Fábio Rocha ", 2, 20)
    _addText(I18N:getString("aboutTools"), 3, 50)
    _addText(" Audacity ", 2, 20)
    _addText(" Corona SDK", 2, 20)
    _addText(" ImageOptim ", 2, 20)
    _addText(" Sublime Text ", 2, 20)
    _addText(" TexturePacker ", 2, 20)
    _addText(I18N:getString("aboutSpecialThanks"), 3, 50)
    _addText(" All Our Family and Friends ", 2, 20)
    _addText(I18N:getString("aboutVerySpecialThanks"), 3, 50)
    _addText(" Bruno Barros ", 2, 20)
    _addText(" Luiz F Rocha ", 2, 20)
    _addText(" Gabriel Rocha ", 2, 20)
    _addText(" Neto Correia ", 2, 20)
    _addText(" Thalma B Rocha ", 2, 20)
    _addText(I18N:getString("aboutThankYou"), 2, Constants.BOTTOM)
    _addText(I18N:getString("aboutMore"), 1, Constants.BOTTOM)
    _addText(" ajtechlabs.com ", 2, 20)

    local sptLogo = display.newSprite(shtUtilUi, {{name="s", start=2, count=1}})
    grpCredits:insert(sptLogo)
    sptLogo:scale(.5, .5)
    sptLogo.anchorY = 0
    sptLogo.x, sptLogo.y = 0, -10
    
    local sptBrand = display.newSprite(shtUtilUi, {{name="s", start=1, count=1}})
    grpCredits:insert(sptBrand)
    sptBrand:scale(.7, .7)
    sptBrand.anchorY = 0
    sptBrand.x, sptBrand.y = 0, 60

    --[[
    local sptAsteroid1 = display.newSprite(shtObstacles, {{name="s", start=7, count=1}})
    grpCredits:insert(sptAsteroid1)
    sptAsteroid1.x, sptAsteroid1.y = 110, 190

    local sptIce2 = display.newSprite(shtObstacles, {{name="s", start=59, count=1}})
    grpCredits:insert(sptIce2)
    sptIce2.x, sptIce2.y = -100, 400

    local sptIce3 = display.newSprite(shtObstacles, {{name="s", start=60, count=1}})
    grpCredits:insert(sptIce3)
    sptIce3.x, sptIce3.y = 100, 620
    --]]

    grpCredits.anchorX, grpCredits.anchorY = .5, 0
    grpCredits.x, grpCredits.y = display.contentCenterX, Constants.BOTTOM - 10
    grpView:insert(grpCredits)

    local ds = - grpCredits.height - grpCredits.y
    local v =  50000 / ds
    local function _addAnim()
        if grpCredits and grpCredits.height then
            local dt = (- grpCredits.height - grpCredits.y) * v
            grpView.trtCancel = Trt.to(grpCredits, {type=9, y=-grpCredits.height, time=dt, onComplete=function()
                if grpCredits and grpCredits.y then
                    grpCredits.y = Constants.BOTTOM + 30
                    _addAnim()
                end
            end})
        end
    end
    _addAnim()

    local function _onTouch(self, event)
        local phase = event.phase
        if phase == "began" or phase == "moved" then
            Trt.timeScaleAll(6)
        else
            Trt.timeScaleAll(1)
        end
    end
    grpView.touch = _onTouch
    grpView:addEventListener("touch", grpView)


    local function bntPrivacyRelease(event)
        system.openURL("http://www.ajtechlabs.com/privacy-policy")
        return true
    end
    local bntPrivacy = Wgt.newButton {
        sheet = shtButtons,
        defaultFrame = 28,
        onRelease = bntPrivacyRelease
    }
    bntPrivacy[2].rotation = 90


    globals_bntBackRelease = bntBackRelease
    local bntBack = Wgt.newButton {
        sheet = shtButtons,
        defaultFrame = 11,
        onRelease = globals_bntBackRelease
    }


    Util:generateFrame(grpView, nil, nil, bntBack, bntPrivacy)


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

        Trt.resumeType(9)

    end
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "did" then

        Trt.timeScaleAll(1)

        if parent.overlayEnded then
            parent:overlayEnded()
        end

    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene