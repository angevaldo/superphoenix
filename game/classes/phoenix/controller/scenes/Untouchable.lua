local Composer = require "composer"
local objScene = Composer.newScene()


local I18N = require "lib.I18N"
local Controller = require "classes.phoenix.business.Controller"
local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"


local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())
local infObstacles = require("classes.infoObstacles")
local shtObstacles = graphics.newImageSheet("images/gameplay/aniObstacles.png", infObstacles:getSheet())
local infStar = require("classes.infoStar")
local shtStar = graphics.newImageSheet("images/gameplay/aniStar.png", infStar:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random


local NUM_STATUS_OLD = 1


function objScene:create(event)
    local grpView = self.view

    local params = event.params

    grpView.camera = params.camera
    grpView.isNotCleanScreen = params.isNotCleanScreen

    if not params.isNotCleanScreen then

        local grpCinematic = display.newGroup()
        grpView:insert(grpCinematic)

        local imgExplosion = display.newSprite(shtObstacles, { {name="e", start=118, count=1} })
        imgExplosion:scale(.7, .7)
        imgExplosion:rotate(random(360))
        imgExplosion:setFillColor(1, .7, .4)
        transition.to(imgExplosion, {transition=easing.outQuad, xScale=1.5, yScale=1.5, time=2000})
        grpCinematic:insert(imgExplosion)

        local tblPos = {{{0,0},{-30,0}}, {{0,-5},{0,-40}}, {{0,0},{-30,-50}}, {{-10,0},{-40,20}}, {{0,0},{-50,-20}}, {{5,0},{60,20}}, {{5,-5},{40,-40}}, {{0,0},{40,0}}, {{0,5},{0,30}}, {{0,15},{30,70}}}
        local grpParticles = display.newGroup()
        grpCinematic:insert(grpParticles)

        for i=1, #tblPos do
            local imgParticle = display.newSprite(shtStar, { {name="s", start=random(153,156), count=1} })
            imgParticle:rotate(random(-360, 360))
            imgParticle.x, imgParticle.y = tblPos[i][1][1], tblPos[i][1][2]
            grpParticles:insert(imgParticle)

            local numScaleFromX, numScaleFromY = random(1, 3) * .1, random(1, 3) * .1
            local numScaleToX, numScaleToY = random(4, 10) * .1, random(5, 10) * .1
            if random(5) == 1 then
                local numTempX = numScaleFromX
                local numTempY = numScaleFromY
                numScaleFromX = numScaleToX
                numScaleFromY = numScaleToY
                numScaleToX = numTempX
                numScaleToY = numTempY
            end
            local easingTemp = random(2) == 1 and easing.outQuad or easing.outExpo
            local numAlpha = random(0, 10) * .1

            imgParticle:scale(numScaleFromX, numScaleFromY)
            transition.to(imgParticle, {transition=easingTemp, alpha=numAlpha, rotation=random(-100, 100), xScale=numScaleToX, yScale=numScaleToY, x=tblPos[i][2][1], y=tblPos[i][2][2], time=2000})
        end
        grpParticles:rotate(random(360))

        grpCinematic.anchorChildren = true
        grpCinematic.anchorX, grpCinematic.anchorY = .5, .5
        grpCinematic.x, grpCinematic.y = params.x, params.y


        local txtScore = display.newText(grpView, " -"..500, 0, 0, "Maassslicer", 60)
        txtScore:setFillColor(1)
        txtScore.anchorX, txtScore.anchorY = .5, .5
        txtScore.alpha = 0
        txtScore.x, txtScore.y = Constants.LEFT + txtScore.width * .5, Constants.BOTTOM - txtScore.height * .5
        txtScore:scale(.1, .1)


        local strLeft = I18N:getString("leftN")
        if params.numLeft == 0 then
            strLeft = I18N:getString("leftOver")
        elseif params.numLeft == 1 then
            strLeft = I18N:getString("left")
        end
        strLeft = string.gsub(strLeft, "xx", ""..params.numLeft)
        local txtTitle = display.newText(grpView, strLeft, 0, 0, "Maassslicer", 35)
        txtTitle:setFillColor(1)
        txtTitle.anchorX, txtTitle.anchorY = .5, 0
        txtTitle.x, txtTitle.y = display.contentCenterX, Constants.TOP - txtTitle.height * 2

        Jukebox:dispatchEvent({name="playSound", id="untouchable"})

    else

        params.vecDir:mult(100)
        local xTo, yTo = params.vecDir.x + params.x, params.vecDir.y + params.y
        local sptReflect = display.newSprite(shtStar, {{name="s", start=42, count=1}})
        sptReflect.x, sptReflect.y, sptReflect.rotation = params.x, params.y, params.rotation
        grpView:insert(sptReflect)
        transition.to(sptReflect, {x=xTo, y=yTo, time=3000})


        for i=1, 10 do
            local sptStar = display.newSprite(shtUtilUi, { {name="standard", start=13, count=1} })
            sptStar:setFillColor(1)
            grpView:insert(sptStar)
            sptStar.rotation = random(90)
            sptStar.x, sptStar.y = params.x + random(-10, 10), params.y + random(-10, 10)
            transition.to(sptStar, {alpha=0, rotation=random(90), time=random(8) * 100})
        end


        local strLeft = I18N:getString("leftPlanetN")
        if params.numLeft == 0 then
            strLeft = I18N:getString("leftPlanetOver")
        elseif params.numLeft == 1 then
            strLeft = I18N:getString("leftPlanet")
        end
        strLeft = string.gsub(strLeft, "xx", ""..params.numLeft)
        local txtTitle = display.newText(grpView, strLeft, 0, 0, "Maassslicer", 25)
        txtTitle:setFillColor(1)
        txtTitle.anchorX, txtTitle.anchorY = .5, 0
        txtTitle.x, txtTitle.y = display.contentCenterX, Constants.TOP - txtTitle.height * 2

        Jukebox:dispatchEvent({name="playSound", id="reflect"})

    end
end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase
    local parent = event.parent

    if phase == "will" then

        if parent.overlayBegan then
            parent:overlayBegan()
        end

    elseif phase == "did" then

        NUM_STATUS_OLD = Controller:getStatus()
        Controller:setStatus(8, true)

        if grpView.numChildren then

            if not grpView.isNotCleanScreen then
                local txtScore = grpView[grpView.numChildren - 1]
                transition.to(txtScore, {transition=easing.outBack, delay=100, alpha=1, time=400, xScale=1, yScale=1})
            end

            local txtTitle = grpView[grpView.numChildren]
            transition.to(txtTitle, {transition=easing.outElastic, delay=100, alpha=1, time=600, y=Constants.TOP + 5, onComplete=function()
                transition.to(txtTitle, {time=300, onComplete=function()

                    if not grpView.isNotCleanScreen then
                        grpView.camera:addScore(-500)
                    end
                    grpView.camera:untouchableEnded()
                    Controller:setStatus(NUM_STATUS_OLD, true)
                    Composer.hideOverlay(false, "fade", 500)

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