local Composer = require "composer"
local objScene = Composer.newScene()


local Wgt = require "classes.phoenix.business.Wgt"
local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"
local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"


local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())


local view


local bntBackRelease = function(event)

    view.isVisible = false

    local scnCurrent = Composer.getScene(Composer.getSceneName("current"))
    scnCurrent:doCountDown()

    Util:hideStatusbar()
    
    return true
end


function objScene:create()
    local grpView = self.view
    grpView.isVisible = false


    view = grpView


    local grpMenu = display.newGroup()
    local numButtonDistance = 60


    local function bntEffectsRelease(event)
        local isSoundActive = not Controller:getData():getProfile("isSoundActive")
        Controller:getData():setProfile("isSoundActive", isSoundActive)
        event.target:setFillColor(isSoundActive and 1 or .3)
        Jukebox:activateSounds(isSoundActive)
        return false
    end
    local bntEffects = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 12,
        onRelease = bntEffectsRelease
    }
    bntEffects.x, bntEffects.y = numButtonDistance * 0, 0
    grpMenu:insert(bntEffects)


    local function bntSoundRelease(event)
        local isMusicActive = not Controller:getData():getProfile("isMusicActive")
        Controller:getData():setProfile("isMusicActive", isMusicActive)
        event.target:setFillColor(isMusicActive and 1 or .3)
        Jukebox:activateMusics(isMusicActive)
        return false
    end
    local bntSound = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 13,
        onRelease = bntSoundRelease
    }
    bntSound.x, bntSound.y = numButtonDistance * 1, 0
    grpMenu:insert(bntSound)


    local function bntHelpRelease(event)
        Controller:showSceneOverlay(7)
        return true
    end
    local bntHelp = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 24,
        onRelease = bntHelpRelease
   }
    bntHelp.x, bntHelp.y = numButtonDistance * 2, 0
    grpMenu:insert(bntHelp)


    local function bntResetRelease(event)
        Composer.stage.alpha = 0

        local options = {
            effect = "fade",
            time = 0,
            params = {isReload=true}
        }
        Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
        return false
    end
    local bntReset = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 15,
        onRelease = bntResetRelease
   }
    bntReset.x, bntReset.y = numButtonDistance * 3, 0
    grpMenu:insert(bntReset)


    grpMenu.anchorChildren = true
    grpMenu.anchorX, grpMenu.anchorY = .5, .5
    grpMenu.x, grpMenu.y = display.contentCenterX, display.contentCenterY


    grpView:insert(grpMenu)


    local function bntMenuRelease(event)
        Composer.stage.alpha = 0

        local options = {
            effect = "fade",
            time = 0
        }
        Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
        return true
    end
    local bntMenu = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 16,
        onRelease = bntMenuRelease
    }


    globals_bntBackRelease = bntBackRelease
    local bntPlay = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 1,
        onRelease = globals_bntBackRelease
    }
    transition.blink(bntPlay[2], {time=2000})


    Util:generateFrame(grpView, nil, nil, bntPlay, bntMenu)


end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        if grpView and grpView[1] and grpView[1][1][2] then
            grpView[1][1][2]:setFillColor(Controller:getData():getProfile("isSoundActive") and 1 or .4)
            grpView[1][2][2]:setFillColor(Controller:getData():getProfile("isMusicActive") and 1 or .4)
        end

        globals_bntBackRelease = bntBackRelease

        Jukebox:dispatchEvent({name="stopMusic"})

        parent:overlayBegan()

    elseif phase == "did" then

        Controller:setStatus(2)

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