local Composer = require "composer"
local objScene = Composer.newScene()


local Controller = require "classes.phoenix.business.Controller"
local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"


local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())

local NUM_STATUS_OLD = 1

function objScene:create(event)
    local grpView = self.view

    local params = event.params

    grpView.camera = params.camera

    local rctOverlay = display.newRect(grpView, 0, 0, 900, 450)
    rctOverlay.anchorX, rctOverlay.anchorY = .5, .5
    rctOverlay.x, rctOverlay.y = grpView.camera:getTarget().x, grpView.camera:getTarget().y
    rctOverlay.fill.effect = "generator.radialGradient"
    rctOverlay.fill.effect.color1 = {1, .8, .5}
    rctOverlay.fill.effect.color2 = {1, .2, 0}
    rctOverlay.fill.effect.center_and_radiuses  =  {0.5, 0.5, 0.4, .9}
    rctOverlay.fill.effect.aspectRatio  = 1
    rctOverlay.alpha = 0

    local sptLogoFx = display.newSprite(shtUtilUi, { {name="s", start=2, count=1} })
    grpView:insert(sptLogoFx)
    sptLogoFx.anchorX, sptLogoFx.anchorY = .5, .5
    sptLogoFx.rotation = 90
    sptLogoFx.alpha = 0
    sptLogoFx.x, sptLogoFx.y = grpView.camera:getTarget().x, grpView.camera:getTarget().y
    sptLogoFx:scale(.1, .1)

    local sptLogoFx = display.newSprite(shtUtilUi, { {name="s", start=2, count=1} })
    grpView:insert(sptLogoFx)
    sptLogoFx.anchorX, sptLogoFx.anchorY = .5, .5
    sptLogoFx.rotation = 90
    sptLogoFx.alpha = 0
    sptLogoFx.x, sptLogoFx.y = grpView.camera:getTarget().x, grpView.camera:getTarget().y
    sptLogoFx:scale(.1, .1)

    local grpLogo = display.newGroup()
    grpView:insert(grpLogo)
    local sptLogo = display.newSprite(shtUtilUi, { {name="s", start=2, count=1} })
    grpLogo:insert(sptLogo)
    local sptLogoEye = display.newSprite(shtUtilUi, { {name="s", frames={6,3,3,3,3,4,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6}, time=1300} })
    sptLogoEye.x, sptLogoEye.y = -16, -60
    grpLogo:insert(sptLogoEye)
    grpLogo.anchorX, grpLogo.anchorY = .5, .5
    grpLogo.x, grpLogo.y = grpView.camera:getTarget().x, grpView.camera:getTarget().y
    grpLogo.rotation = 90
    grpLogo.alpha = 0
    grpLogo:scale(.1, .1)

    local txtScore = display.newText(grpView, " +"..params.numScore, 0, 0, "Maassslicer", 60)
    txtScore.numScore = params.numScore
    txtScore:setFillColor(0)
    txtScore.anchorX, txtScore.anchorY = .5, .5
    txtScore.alpha = 0
    txtScore.x, txtScore.y = Constants.LEFT + txtScore.width * .5, Constants.BOTTOM - txtScore.height * .5
    txtScore:scale(.1, .1)
end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        if parent.overlayBegan then
            parent:overlayBegan(true)
        end

    elseif phase == "did" then

        NUM_STATUS_OLD = Controller:getStatus()
        Controller:setStatus(6, true)

        local rctOverlay = grpView[1]
        transition.to(rctOverlay, {time=600, alpha=1})

        if grpView.numChildren then

        	local txtScore = grpView[grpView.numChildren]
            transition.to(txtScore, {transition=easing.outElastic, delay=500, alpha=1, time=400, xScale=1, yScale=1})

            local sptLogoFx1 = grpView[grpView.numChildren - 3]
            sptLogoFx1.trtCancel = transition.to(sptLogoFx1, {alpha=.25, rotation=-360, time=500, transition=easing.outInQuad, xScale=.3, yScale=.3, onComplete=function()
                sptLogoFx1.trtCancel = transition.to(sptLogoFx1, {rotation=-720, transition=easing.outExpo, time=800, xScale=1, yScale=1})
            end})

            local sptLogoFx2 = grpView[grpView.numChildren - 2]
            sptLogoFx2.trtCancel = transition.to(sptLogoFx2, {alpha=.5, rotation=-360, time=400, transition=easing.outInQuad, xScale=.3, yScale=.3, onComplete=function()
                sptLogoFx2.trtCancel = transition.to(sptLogoFx2, {rotation=-720, transition=easing.outExpo, time=800, xScale=1, yScale=1})
            end})

            local grpLogo = grpView[grpView.numChildren - 1]
            grpLogo.trtCancel = transition.to(grpLogo, {alpha=1, rotation=-360, time=300, transition=easing.outInQuad, xScale=.3, yScale=.3, onComplete=function()
                Jukebox:dispatchEvent({name="playSound", id="phoenix"})
                Jukebox:dispatchEvent({name="playSound", id="phoenixExplosions"})
                grpLogo.trtCancel = transition.to(grpLogo, {rotation=-720, transition=easing.outExpo, time=800, xScale=1, yScale=1, onComplete=function()

                    if grpLogo[2] and grpLogo[2].play then
                        grpLogo[2]:play()
                    end

                    transition.cancel(sptLogoFx1.trtCancel)
                    transition.cancel(sptLogoFx2.trtCancel)
                    transition.cancel(grpLogo.trtCancel)
                    sptLogoFx1.rotation = 0
                    sptLogoFx2.rotation = 0
                    grpLogo.rotation = 0
                    sptLogoFx1.trtCancel = transition.to(sptLogoFx1, {delay=100, time=700, xScale=.125, yScale=.125, rotation=-720, transition=easing.inExpo, onComplete=function()
                        transition.to(sptLogoFx1, {delay=80, time=500, rotation=-1440, transition=easing.outExpo})
                    end})
                    sptLogoFx2.trtCancel = transition.to(sptLogoFx2, {delay=50, time=700, xScale=.125, yScale=.125, rotation=-720, transition=easing.inExpo, onComplete=function()
                        transition.to(sptLogoFx2, {delay=160, time=500, rotation=-1440, transition=easing.outExpo})
                    end})
                    grpLogo.trtCancel = transition.to(grpLogo, {delay=0, time=700, xScale=.125, yScale=.125, rotation=-720, transition=easing.inExpo, onComplete=function()
                        transition.to(grpLogo, {delay=0, time=500, rotation=-1440, transition=easing.outExpo})

                        Composer.hideOverlay(false, "fade", 500)
                        timer.performWithDelay(700, function()

                            Controller:setStatus(NUM_STATUS_OLD, true)
                            grpView.camera:addScore(txtScore.numScore)

                        end, 1)
                        
                        grpView.camera:flame()

                    end})

                end})
            end})

        end

    end
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        if parent.overlayEnded then
            parent:overlayEnded()
        end

    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene