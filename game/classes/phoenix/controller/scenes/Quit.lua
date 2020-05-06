local Composer = require "composer"
local objScene = Composer.newScene()


local I18N = require "lib.I18N"


local Wgt = require "classes.phoenix.business.Wgt"


local bntBackRelease = function(event)
    Composer.hideOverlay(false, "fade", 200)
    return false
end


function objScene:create()
    local grpView = self.view


    globals_bntBackRelease = bntBackRelease


    local infButtons = require("classes.infoButtons")
    local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())


    local txtQuestion = display.newText(I18N:getString("quit"), 0, 0, "Maassslicer", 16)
    txtQuestion.anchorX, txtQuestion.anchorY = .5, .5
    txtQuestion.x, txtQuestion.y = display.contentCenterX, display.contentCenterY - 15
    grpView:insert(txtQuestion)


    local grpYes = display.newGroup()
    grpView:insert(grpYes)
    local function bntYesRelease(event)
        os.exit()
        return true
    end
    local bntYes = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 11,
        onRelease = bntYesRelease
    }
    grpYes:insert(bntYes)
    grpYes.anchorX, bntYes.anchorY = .5, .5
    grpYes.rotation = 180
    grpYes.x, grpYes.y = display.contentCenterX - 50, display.contentCenterY + 40


    local bntNo = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 4,
        onRelease = bntBackRelease
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

        globals_bntBackRelease = function() end

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