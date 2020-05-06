local Composer = require "composer"
local objScene = Composer.newScene()


local Controller = require "classes.phoenix.business.Controller"
local Jukebox = require "classes.phoenix.business.Jukebox"


local infScenario = require("classes.infoScenario")
local shtScenario = graphics.newImageSheet("images/ui/bkgScenario.jpg", infScenario:getSheet())


local _rct_background = display.newRect(0, 0, 500, 350)
_rct_background:toBack()


local function go(event)
    -- verify integrity data
    local isInit = Controller:getData():updateDatabase()

    -- init jukebox
    Jukebox:activateMusics(Controller:getData():getProfile("isMusicActive"))
    Jukebox:activateSounds(Controller:getData():getProfile("isSoundActive"))

    -- clean memory
    Composer:removeHidden(false)
    collectgarbage("collect")

    -- loading scene
    if Controller:getData():getProfile("nCurrentHowToPlayID") < 6 then
        local options = {
            effect = "fade",
            time = 0,
            params = {isReload=true}
        }
        Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
        transition.to(_rct_background, {time=1000, onComplete=function() 
            Jukebox:dispatchEvent({name="playMusic", id=2})
        end})
    else
        Composer.gotoScene("classes.phoenix.controller.scenes.GamePlay", {params = {}})
        transition.to(_rct_background, {time=1000, onComplete=function() 
            Jukebox:dispatchEvent({name="playMusic", id=1})
        end})
    end
end


function objScene:create(event)
    local grpView = self.view

    --[[] EXPIRE COMMENT ON PRODUCTION
    local tblTime = os.date("*t")
    if tblTime.year > 2015 or tblTime.month > 9 then
        os.exit()
    end
    --]]

    local imgBkgLogo = display.newSprite(shtScenario, { {name="s", frames={1}} })
    imgBkgLogo.anchorX, imgBkgLogo.anchorY = .5, .5
    imgBkgLogo.x, imgBkgLogo.y, imgBkgLogo.alpha = display.contentCenterX, display.contentCenterY - 20, 0
    grpView:insert(imgBkgLogo)

    local tblProperties = {name="standard", frames={16}, time=800, loopCount=1}
    local sptShadow = display.newSprite(graphics.newImageSheet("images/ui/aniLogoAj.png", {width=128, height=128, numFrames=16, sheetContentWidth=512, sheetContentHeight=512}), tblProperties)
    sptShadow.anchorX, sptShadow.anchorY = .5, .5
    sptShadow:setFillColor(0, .15)
    sptShadow.x, sptShadow.y = display.contentCenterX, display.contentCenterY
    sptShadow:scale(.5, .5)
    grpView:insert(sptShadow)

    local tblProperties = {name="standard", frames={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}, time=800, loopCount=1}--850
    local aniLogo = display.newSprite(graphics.newImageSheet("images/ui/aniLogoAj.png", {width=128, height=128, numFrames=16, sheetContentWidth=512, sheetContentHeight=512}), tblProperties)
    aniLogo.anchorX, aniLogo.anchorY = .5, .5
    aniLogo.x, aniLogo.y = display.contentCenterX, display.contentCenterY
    aniLogo:scale(.5, .5)
    local evt = event
    local function onSprite(event)
        if event.phase == "ended" then

            grpView[2].isVisible = false

            transition.to(grpView[1], {y=display.contentCenterY, alpha=1, time=400, transition=easing.outBack, onComplete=function()

                _rct_background:setFillColor(0)

            end})
            
            transition.to(grpView[3], {yScale=1, xScale=1, time=800, transition=easing.outElastic, onComplete=function()

                go(evt)

            end})

        end
    end
    aniLogo:addEventListener("sprite", onSprite)
    aniLogo:pause()
    grpView:insert(aniLogo)
end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase

    if phase == "will" then

        _rct_background.anchorX, _rct_background.anchorY = 0, 0
        _rct_background:setFillColor(1)
        
        Composer.stage.alpha = 1
        Jukebox:dispatchEvent({name="stopMusic"})

        globals_bntBackRelease = nil


    elseif phase == "did" then

        Controller:init()
        if Controller:getData():getProfile("userName") == nil then
            Controller:getData():clear()
        end

        transition.to(grpView, {time=500, onComplete=function()

            if Controller:getData():getProfile("userName") == "" then
                grpView[3]:pause()

                local options = {
                    isModal = true,
                    effect = "fade",
                    time = 0
                }
                Composer.showOverlay("classes.phoenix.controller.scenes.Profile", options)
            else
                grpView[3]:play()
            end

        end})

    end
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase


    if phase == "did" then

        Composer:removeScene("classes.phoenix.controller.scenes.LoadingGameIn")

    end
end


function objScene:overlayEnded(event)
    local grpView = self.view

    grpView[3]:play()
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene