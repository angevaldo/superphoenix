local Composer = require "composer"
local objScene = Composer.newScene()
local Widget = require "widget"


local Wgt = require "classes.phoenix.business.Wgt"
local Jukebox = require "classes.phoenix.business.Jukebox"
local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"
local Constants = require "classes.phoenix.business.Constants"


local I18N = require "lib.I18N"


local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())


local bntBackRelease = function()
    Composer.hideOverlay(false, "fade", 200)
    return true
end


function objScene:create()
    local grpView = self.view
    grpView.isVisible = false


    globals_bntBackRelease = bntBackRelease


    local data = Controller:getData()
    
    local grpMenu = display.newGroup()
    local numButtonDistance = 60


    local function bntEffectsRelease(event)
        local isSoundActive = not data:getProfile("isSoundActive")
        data:setProfile("isSoundActive", isSoundActive)
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
        local isMusicActive = not data:getProfile("isMusicActive")
        data:setProfile("isMusicActive", isMusicActive)
        event.target:setFillColor(isMusicActive and 1 or .3)

        Jukebox:activateMusics(isMusicActive)
        if isMusicActive then
            Jukebox:dispatchEvent({name="playMusic", id=1})
        end
        return false
    end
    local bntSound = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 13,
        onRelease = bntSoundRelease
    }
    bntSound.x, bntSound.y = numButtonDistance * 1, 0
    grpMenu:insert(bntSound)


    local function bntHelpRelease()
        local options = {
            isModal = true,
            effect = "fade",
            time = 0
        }
        Composer.showOverlay("classes.phoenix.controller.scenes.Help", options)
        return true
    end
    local bntHelp = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 24,
        onRelease = bntHelpRelease
    }
    bntHelp.x, bntHelp.y = numButtonDistance * 2, 0
    grpMenu:insert(bntHelp)


    local function bntAboutRelease()
        local options = {
            isModal = true,
            effect = "fade",
            time = 0,
            params = {source="classes.phoenix.controller.scenes.Options"}
        }
        Composer.showOverlay("classes.phoenix.controller.scenes.About", options)
        return true
    end
    local bntAbout = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 10,
        onRelease = bntAboutRelease
    }
    bntAbout.x, bntAbout.y = numButtonDistance * 3, 0
    grpMenu:insert(bntAbout)


    local function bntResetRelease()
        local options = {
            isModal = true,
            effect = "fade",
            time = 0
        }
        Composer.showOverlay("classes.phoenix.controller.scenes.Reset", options)
        return false
    end
    local bntReset = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 15,
        onRelease = bntResetRelease
    } 
    bntReset.x, bntReset.y = numButtonDistance * 4, 0
    grpMenu:insert(bntReset)


    grpMenu.anchorChildren = true
    grpMenu.anchorX, grpMenu.anchorY = .5, .5
    grpMenu.x, grpMenu.y = display.contentCenterX, display.contentCenterY


    grpView:insert(grpMenu)


    local function bntRankingRelease()
        Composer.stage.alpha = 0
        local options = {
            effect = "fade",
            time = 0,
            params = {scene="classes.phoenix.controller.scenes.Ranking"}
        }
        Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
        return true
    end
    local bntRanking = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 25,
        onRelease = bntRankingRelease
    }


    local function bntAchievementsRelease()
        Composer.stage.alpha = 0
        local options = {
            effect = "fade",
            time = 0,
            params = {scene="classes.phoenix.controller.scenes.Achievement"}
        }
        Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
        return true
    end
    local bntAchievements = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 29,
        onRelease = bntAchievementsRelease
    }


    local grpLanguages = display.newGroup()
    grpView:insert(grpLanguages)

    local TBL_LANGUAGES_INDEX = {"pt", "en", "es", "ja", "zh", "de", "ru", "fr"}
    local strLanguage = data:getProfile("language")
    strLanguage = strLanguage == nil and "en" or strLanguage

    local function bntLanguagesRelease(self, event)
        local phase = event.phase
        if phase == "began" then
            self[2].xScale, self[2].yScale = .5, .5

        elseif phase == "ended" then
            self[2].xScale, self[2].yScale = 1, 1

            local strLanguage = TBL_LANGUAGES_INDEX[self.id]
            I18N:reloadLanguage(strLanguage)
            data:setProfile("language", strLanguage)

            Composer.stage.alpha = 0

            local params = {}
            params.scene = "classes.phoenix.controller.scenes.LoadingGameIn"

            local options = {
                effect = "fade",
                time = 0,
                params = params
            }
            Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
        else
            self[2].xScale, self[2].yScale = 1, 1
        end
    end
    for i=1, 8 do
        local grpLanguage = display.newGroup()
        grpLanguages:insert(grpLanguage)

        local rctLanguage = display.newRect(grpLanguage, 0,0, 25,50)
        rctLanguage.anchorX, rctLanguage.anchorY = .5, .5
        rctLanguage.x, rctLanguage.y, rctLanguage.alpha = 0, -10, .01

        local sptLanguage = display.newSprite(shtButtons, { {name="standard", frames={56+i}} })
        sptLanguage.anchorX, sptLanguage.anchorY = .5, .5
        sptLanguage.x, sptLanguage.y = 0, 0
        grpLanguage:insert(sptLanguage)

        grpLanguage.id = i
        grpLanguage.x, grpLanguage.y = i * 30, 0

        if strLanguage == TBL_LANGUAGES_INDEX[i] then
            sptLanguage:setFillColor(.2)
        else
            grpLanguage.touch = bntLanguagesRelease
            grpLanguage:addEventListener("touch", grpLanguage)
        end
    end

    local txtLanguage = display.newText(I18N:getString("language"), 0, 0, "Maassslicer", 8)
    txtLanguage:setFillColor(1)
    txtLanguage.anchorX, txtLanguage.anchorY = .5, .5
    txtLanguage.x, txtLanguage.y = 135, -20
    grpLanguages:insert(txtLanguage)

    grpLanguages.anchorChildren = true
    grpLanguages.anchorX, grpLanguages.anchorY = .5, 1
    grpLanguages.x, grpLanguages.y, grpLanguages.alpha = display.contentCenterX, Constants.BOTTOM, 1


    local bntBack = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 27,
        onRelease = globals_bntBackRelease
    }


    Util:generateFrame(grpView, bntAchievements, bntRanking, nil, bntBack)


end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        local data = Controller:getData()

        grpView[1][1][2]:setFillColor(data:getProfile("isSoundActive") and 1 or .3)
        grpView[1][2][2]:setFillColor(data:getProfile("isMusicActive") and 1 or .3)

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