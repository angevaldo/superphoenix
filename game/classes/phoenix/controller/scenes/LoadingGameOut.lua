local Composer = require "composer"
local objScene = Composer.newScene()


local infScenario = require("classes.infoScenario")
local shtScenario = graphics.newImageSheet("images/ui/bkgScenario.jpg", infScenario:getSheet())


function objScene:create()
    local grpView = self.view

    local rctOverlay = display.newRect(grpView, -10, -10, 500, 350)
    rctOverlay.anchorX, rctOverlay.anchorY = 0, 0
    rctOverlay:setFillColor(1, 1, 1)

    local imgBkgLogo = display.newSprite(shtScenario, { {name="s", frames={1}} })
    imgBkgLogo.anchorX, imgBkgLogo.anchorY = .5, .5
    imgBkgLogo.x, imgBkgLogo.y = display.contentCenterX, display.contentCenterY
    grpView:insert(imgBkgLogo)

    local tblProperties = {name="standard", frames={16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1}, time=600, loopCount=1}--700
    local aniLogo = display.newSprite(graphics.newImageSheet("images/ui/aniLogoAj.png", {width=128, height=128, numFrames=16, sheetContentWidth=512, sheetContentHeight=512}), tblProperties)
    aniLogo.anchorX, aniLogo.anchorY = .5, .5
    aniLogo.x, aniLogo.y = display.contentCenterX, display.contentCenterY
    local function onSprite(event)
        if (event.phase == "ended") then
            timer.performWithDelay(1, function()
                Composer.hideOverlay(false, "fade", 500)
            end, 1)
        end
    end
    aniLogo:addEventListener("sprite", onSprite)
    grpView:insert(aniLogo)
end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase

    if phase == "did" then
        
        timer.performWithDelay(1, function()

            grpView[grpView.numChildren]:play()

            transition.to(grpView[grpView.numChildren-1], {alpha=0, time=400})

        end, 1)

    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)


return objScene