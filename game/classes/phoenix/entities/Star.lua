local Composer = require "composer"


local Trt = require "lib.Trt"


local Jukebox = require "classes.phoenix.business.Jukebox"
local Controller = require "classes.phoenix.business.Controller"


local Powerup = require "classes.phoenix.entities.Powerup"


local infStar = require("classes.infoStar")
local shtStar = graphics.newImageSheet("images/gameplay/aniStar.png", infStar:getSheet())
local infUtilGameplay = require("classes.infoUtilGameplay")
local shtUtilGameplay = graphics.newImageSheet("images/gameplay/scnUtilGameplay.png", infUtilGameplay:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random
local sqrt = math.sqrt
local round = math.round

local Star = {}
Star.TBL_POSITIONS = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}}
Star.HEALTH_LIMIT = 30

local NUM_INDEX_SHIELD = -1     -- SHIELD
local NUM_INDEX_STAR = -1       -- ANIM STAR
local NUM_INDEX_MAGMA = -1      -- ANIM MAGMA
local NUM_INDEX_BRIGHT = -1     -- BRIGHT
local NUM_INDEX_FIRE = -1       -- ANIM FIRE
local NUM_INDEX_FLAME = -1      -- ANIM FLAME
local NUM_INDEX_ICING = -1      -- ICING
local NUM_INDEX_HEALTH = -1     -- HEALTH
local NUM_INDEX_TOUCH_AREA = -1 -- TOUCH AREA

Star.TBL_COLORS = {
    {nil},
    {"filter.monotone", .7,1,0, .4},
    {"filter.monotone", 1,.7,0, .4},
    {"filter.monotone", 1,.5,.7, .4},
    {"filter.monotone", .5,.4,1, .4},
}

local function _showHealth(obj, value)
    local grpHealth = obj[NUM_INDEX_HEALTH]
    if grpHealth then
        obj.numHealthAccumlated = obj.numHealthAccumlated + value

        local txtHealth = obj.txtHealth

        local txtHealthAnim = obj.txtHealthAnim
        local strSign = obj.numHealthAccumlated < 0 and " " or " +"
        txtHealthAnim.text = strSign .. obj.numHealthAccumlated .. "% "

        if grpHealth.trtAlphaCancel ~= nil then 
            transition.cancel(grpHealth.trtAlphaCancel) 
            grpHealth.trtAlphaCancel = nil
        end
        grpHealth.alpha = 1

        if txtHealthAnim.trtAlphaCancel ~= nil then 
            transition.cancel(txtHealthAnim.trtAlphaCancel) 
            txtHealthAnim.trtAlphaCancel = nil
        end
        txtHealthAnim.y = txtHealthAnim.y > 48 and txtHealth.y or txtHealthAnim.y
        txtHealthAnim.trtAlphaCancel = transition.to(txtHealthAnim, {y=48, alpha=1, time=200, onComplete=function()
            txtHealthAnim.trtAlphaCancel = transition.to(txtHealthAnim, {alpha=0, delay=300, y=60, time=400, onComplete=function()
                txtHealthAnim.alpha, txtHealthAnim.y = 0, txtHealth.y
                obj.numHealthAccumlated = 0
            end})
        end})

        txtHealth.text = " " .. obj.health .. "% "
        local numFrame = 48 - round(obj.health * .48) + 1
        grpHealth[2]:setFrame(numFrame)
        local numAlpha = obj.health > Star.HEALTH_LIMIT and 0 or .3
        grpHealth.trtAlphaCancel = transition.to(grpHealth, {alpha=numAlpha, delay=2000, time=400})
    end
end

local function _destroy(self)

    self:removeEventListener("touchOn", self)
    self:removeEventListener("touchOff", self)
    self[NUM_INDEX_TOUCH_AREA]:removeEventListener("tap", self[NUM_INDEX_TOUCH_AREA])
    self._functionListeners = nil
    self._tableListeners = nil

    if self.parent and self.parent.remove then
        self.parent:remove(self)
    end

    self = nil
end

local function _onStarExplodeHowToPlay(self, event)
    if event.phase == "ended" then
        Composer.stage.alpha = 0
        local options = {
            effect = "fade",
            time = 0,
            params = {isReload=true}
        }
        Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
    end
end

local function _onStarExplode(self, event)
    if event.phase == "ended" then
        if self.sequence == "e" then
            self:doCallback() 
        elseif self.sequence == "i" then
            local obj = self.parent

            obj:reset(self.numIdNebulaCurrent)
            obj:flame()
        end

        if self.removeEventListener then
            self:removeEventListener("sprite", self)
        end
    end
end

local function _onFlameEnded(self, event)
    if event.phase == "ended" then
        transition.to(self, {alpha=0, time=500, onComplete=function(self)
            if self.removeEventListener then
                self.isVisible = false
                self.alpha = 1
                self.rotation = random(360)
                self:setFrame(1)
                self:removeEventListener("sprite", self)
            end
        end})
    end
end

local function _shot(self, params)
    local numShots = self.transientShots.v

    if not self.isActive then
        return numShots
    end

    if numShots > 0 then
        self.transientShots.v = numShots - 1
        Controller:getData():setStore("6", self.transientShots)

        local shot = display.newSprite(shtUtilGameplay, {{name="standard", start=35, count=1}})
        self.camera:add(shot, 3)
        shot.x, shot.y = self.x, self.y
        local numRGB = self.health * .02
        numRGB = numRGB > 1 and 1 or numRGB
        shot:setFillColor(numRGB, numRGB, numRGB)

        transition.to(shot, {x=params.x, y=params.y, time=100, transition=easing.outQuad, onComplete=function()
            if shot then
                self.camera:add(shot, 7)
                transition.to(shot, {time=500, xScale=.3, yScale=.3, onComplete=function()
                    if self.camera and self.camera.rem then
                        self.camera:rem(shot, 7)
                    end
                end})
            end
        end})

        -- DESTROY
        local other
        if self.camera then
            for i=1, #self.camera.tblStashTap do
                other = self.camera.tblStashTap[1]
                if other then
                    other:hit(2)
                    table.remove(self.camera.tblStashTap, 1)
                end
            end
        end
    end
    return numShots
end

local function _activeShield(self, isActive)
    local isActive = isActive == nil and true or isActive
    if isActive then
        for i=1, self.numQttShieldsMax do
            local sptShield = self[NUM_INDEX_SHIELD + i - 1]
            local numScale = .5 + (i * .025)
            sptShield.isVisible = true
            if sptShield.cnlTransition ~= nil then
                transition.cancel(sptShield.cnlTransition)
                sptShield.cnlTransition = nil
            end
            local numTime = 150*i
            sptShield.cnlTransition = transition.to(sptShield, {xScale=numScale, transition=easing.outBack, yScale=numScale, time=numTime, alpha=1})
        end

        self.numQttShieldsActive = self.numQttShieldsMax
    else
        for i=1, self.numQttShieldsMax do
            local sptShield = self[NUM_INDEX_SHIELD + i - 1]
            sptShield.alpha = 0
            sptShield.isVisible = false
        end
        self.numQttShieldsActive = 0
    end
end

local function _addSuperPhoenix(self, value)
    local limit = value > 0 and self.transientSuperPhoenix.t or 0
    local numT = self.transientSuperPhoenix.v + value
    if self.canDoSuperPhoenix then
        if ((value < 0 and numT >= limit) or (value > 0 and numT <= limit)) then
            self.transientSuperPhoenix.v = numT

            Controller:getData():setStore("5", self.transientSuperPhoenix)

            self.canDoSuperPhoenix = false
            timer.performWithDelay(3000, function() self.canDoSuperPhoenix = true end, 1)
            return true
        else
            if self.CANCEL_NEGATION ~= nil then
                Trt.cancel(self.CANCEL_NEGATION)
                self.CANCEL_NEGATION = nil
            end
            self.CANCEL_NEGATION = Trt.to(self, {time=100, onComplete=function()
                Jukebox:dispatchEvent({name="playSound", id="negation"})
            end})
        end
    end

    return false
end

local function _adjustAppereance(obj)
    local numAlpha = obj.health * .01
    numAlpha = numAlpha > 1 and 1 or numAlpha

    obj[NUM_INDEX_FIRE].alpha = numAlpha
    obj[NUM_INDEX_MAGMA].alpha = numAlpha

    --[[
    local numShields = obj.numQttShieldsActive
    for i = NUM_INDEX_SHIELD + numShields, NUM_INDEX_SHIELD + 4 do
        local sptShield = obj[i]
        sptShield.isVisible = false
    end
    ]]
end

local function _onCollision(self, params)
    if self:addHealth(params.element.damage) then

        -- ADDING STATS
        self.isPerfectDefense = false
        Controller:getData().isHittedStar = true

        return true
    end
    return false
end

local function _recoveryHealth(self)
    local sptMagma = self[NUM_INDEX_MAGMA]
    if sptMagma.sequence == "s" then
        self:addHealth(self.numHealthRecovery)
        self:flame()
    end
end

local function _addHealth(self, value, hideHealth)
    if value < 0 then

        -- HAVE SHIELD
        if self.numQttShieldsActive > 0 then
            Jukebox:dispatchEvent({name="playSound", id="shield"})

            local numIndex = NUM_INDEX_SHIELD + self.numQttShieldsActive - 1
            local sptShield = self[numIndex]
            if sptShield.cnlTransition ~= nil then
                transition.cancel(sptShield.cnlTransition)
                sptShield.cnlTransition = nil
            end
            sptShield.cnlTransition = transition.to(sptShield, {xScale=1, yScale=1, time=600, alpha=0, onComplete=function()
                sptShield.isVisible = false
            end})
            self.numQttShieldsActive = self.numQttShieldsActive - 1

            return false
        end

        -- DO NOT HAVE SHIELD
        local id = value > -26 and 1 or (value > -51 and 2 or 3)
        Jukebox:dispatchEvent({name="playSound", id="starCollision"..id})

    end

    local numValue = self.camera.codAssist == 10 and round(value * .5) or value

    local health = self.health + numValue
    health = health > 100 and 100 or (health < 0 and 0 or health)
    self.health = health

    _adjustAppereance(self)

    if not hideHealth then
        _showHealth(self, numValue)
    else
        self.numHealthAccumlated = 0
        self.txtHealth.text = " ".. health .."%"
        self.txtHealthAnim.text = " 0%"
    end

    return true
end

local function _addHealthHowToPlay(self, value, hideHealth)
    if value == 100 then
        self.health = 100
    else
        value = value == -7 and -7 or -100
        Jukebox:dispatchEvent({name="playSound", id="starCollision3"})
        self.health = self.health + value
    end

    _adjustAppereance(self)
    if not hideHealth then
        _showHealth(self, value)
    else
        self.numHealthAccumlated = 0
        self.txtHealth.text = " ".. self.health .."%"
        self.txtHealthAnim.text = " 0%"
    end

    return true
end

local function _flame(self)
    local sptFlame = self[NUM_INDEX_FLAME]
    sptFlame.rotation = random(360)
    sptFlame:addEventListener("sprite", sptFlame)
    sptFlame.isVisible = true
    sptFlame:play()

    Jukebox:dispatchEvent({name="playSound", id="flame"})
end

local function _setActive(self, isActive)
    self.isActive = isActive
    local sptFire = self[NUM_INDEX_FIRE]
    local sptMagma = self[NUM_INDEX_MAGMA]

    if self and self.addEventListener then
        if isActive then
            if sptFire ~= nil and sptFire[2] ~= nil and sptFire[2].play ~= nil then
                sptFire[2]:play()
            end
            if sptMagma ~= nil and sptMagma.play ~= nil then
                sptMagma:play()
            end

            self:addEventListener("touchOn", self)
            self:addEventListener("touchOff", self)
            self[NUM_INDEX_TOUCH_AREA]:addEventListener("tap", self[NUM_INDEX_TOUCH_AREA])
        else
            self:removeEventListener("touchOn", self)
            self:removeEventListener("touchOff", self)
            self[NUM_INDEX_TOUCH_AREA]:removeEventListener("tap", self[NUM_INDEX_TOUCH_AREA])
        end
    end
end

local function _start(self)
    self.isVisible = true
    self:setActive(true)
    self:flame()
    self[NUM_INDEX_MAGMA]:play()
    self[NUM_INDEX_FIRE][2]:play()
    self[NUM_INDEX_FIRE][3]:play()
    self.rotation = 360
    transition.to(self, {rotation=0, transition=easing.outExpo, time=1000})
end

local function _onTouchOn(self, event)
    --[[
    if event.phase == "began" then
        self.tblTouchX[event.id], self.tblTouchY[event.id] = 2000, 2000
        if self.transientShots.v > 0 then
            return
        end
    elseif self.tblTouchX[event.id] == nil then
        self.tblTouchX[event.id], self.tblTouchY[event.id] = 2000, 2000
    end

    local dx, dy = self.tblTouchX[event.id] - event.x, self.tblTouchY[event.id] - event.y
    self.tblDist[event.id] = sqrt(dx*dx + dy*dy)
    if self.tblDist[event.id] > 100 or self.camera.tblStashTouch[1] then -- self.tblDist[event.id] > 90 or then

        local shot = display.newCircle(0, 0, 2)--display.newSprite(shtUtilGameplay, {{name="standard", start=35, count=1}})
        local x, y = event.x, event.y
        self.camera:add(shot, 3)
        shot.x, shot.y = self.x, self.y
        local numRGB = self.health * .01
        numRGB = numRGB > 1 and 1 or numRGB
        shot:setFillColor(numRGB * 1.3, numRGB * 1.2, numRGB)
        
        transition.to(shot, {x=x, y=y, time=300, transition=easing.outQuad, onComplete=function()
            self.camera:add(shot, 7)
            transition.to(shot, {time=300, xScale=.3, yScale=.3, onComplete=function()
                if self.camera and self.camera.rem then
                    self.camera:rem(shot, 7)
                end
            end})
        end})

        self.tblTouchX[event.id], self.tblTouchY[event.id] = x, y
    end
    ]]

    -- DESTROY
    local other
    for i=1, #self.camera.tblStashTouch do
        other = self.camera.tblStashTouch[1]
        if other then
            other:hit(.8)
            table.remove(self.camera.tblStashTouch, 1)
        end
    end
end

local function _onTouchOff(self, event)
    if self.tblDist[event.id] then
        self.tblDist[event.id], self.tblTouchX[event.id], self.tblTouchY[event.id] = nil, nil, nil
    end
end

local function _onTap(self, event)
    local obj = self.parent
    if event.numTaps >= 2 and obj.isActive and obj[NUM_INDEX_MAGMA].sequence ~= "e" and obj:addSuperPhoenix(-1) then
        -- UNDO IF CAN'T SHOW PHOENIX
        if not obj.camera:doSuperPhoenix() then
            obj:addSuperPhoenix(1)
        end
    end

    return true
end

local function _getCurrentPos(self)
    return self.currentPos
end

local function _jump(self, params)
    if params.numPos ~= self.currentPos then

        local numX = Star.TBL_POSITIONS[params.numPos][1]
        local numY = params.numPos == 6 and self.y or Star.TBL_POSITIONS[params.numPos][2]
        Trt.to(self, {x=numX, y=numY, time=params.numTime, transition=params.easing, onComplete=params.onComplete})

        if params.numPos ~= 6 then
            Jukebox:dispatchEvent({name="playSound", id="jump"})
            self.currentPos = params.numPos
        end

    elseif params.onComplete then
        params.onComplete()
    end
end

local function _reposition(self, numPos)
    self.currentPos = numPos
    self.x = Star.TBL_POSITIONS[self.currentPos][1]
    self.y = Star.TBL_POSITIONS[self.currentPos][2]
end

local function _explode(self, callBack)
    local sptMagma = self[NUM_INDEX_MAGMA]
    if not sptMagma.sequence ~= "e" then
        
        Jukebox:dispatchEvent({name="playSound", id="starExplosion"})

        for i=1, self.numQttShieldsMax do
            local sptShield = self[NUM_INDEX_SHIELD + i - 1]
            sptShield.isVisible = false
        end
        self[NUM_INDEX_FIRE].isVisible = false
        self[NUM_INDEX_FLAME].isVisible = false
        self[NUM_INDEX_ICING].isVisible = false
        self[NUM_INDEX_HEALTH].isVisible = false
        sptMagma:setSequence("e")
        sptMagma.xScale, sptMagma.yScale = 1, 1
        sptMagma:setFillColor(1, 1, 1)
        sptMagma:play()
        sptMagma.alpha = 1
        self.camera:add(self, 7)
        transition.to(self, {xScale=26, yScale=26, time=500})
        sptMagma:addEventListener("sprite", sptMagma)

        sptMagma.doCallback = callBack
    end
end

local function _reset(self, numIdNebula)
    local sptMagma = self[NUM_INDEX_MAGMA]
    sptMagma:setFillColor(1, 1, 1)
    sptMagma.alpha = 1
    sptMagma:setSequence("s")
    sptMagma:play()
    sptMagma.numIdNebulaCurrent = numIdNebula

    self.xScale, self.yScale = .1, .1
    if self.CANCEL_TRANSITION_RESIZE ~= nil then
        transition.cancel(self.CANCEL_TRANSITION_RESIZE)
        self.CANCEL_TRANSITION_RESIZE = nil
    end
    self.CANCEL_TRANSITION_RESIZE = transition.to(self, {xScale=1, yScale=1, time=400, transition=easing.outBack})

    self:addHealth(100, true)
    self:activeShield(false)

    local grpHealth = self[NUM_INDEX_HEALTH]
    if grpHealth.trtAlphaCancel ~= nil then
        transition.cancel(grpHealth.trtAlphaCancel)
        grpHealth.trtAlphaCancel = nil
        grpHealth.alpha = 0
    end

    self[NUM_INDEX_FIRE].isVisible = true
    self[NUM_INDEX_ICING].isVisible = true
    self[NUM_INDEX_HEALTH].isVisible = true
    self[NUM_INDEX_HEALTH].alpha = 0
    self.camera:add(self, 4)
            
    local numIdCurrentNebula = numIdNebula % 5
    numIdCurrentNebula = numIdCurrentNebula == 0 and 5 or numIdCurrentNebula
    local tblObject = {self[NUM_INDEX_FIRE][1], self[NUM_INDEX_FIRE][2], self[NUM_INDEX_FIRE][3], self[NUM_INDEX_MAGMA], self[NUM_INDEX_FLAME]}
    for i=1, #tblObject do
        local obj = tblObject[i]
        obj.fill.effect = Star.TBL_COLORS[numIdCurrentNebula][1]
        if Star.TBL_COLORS[numIdCurrentNebula][1] ~= nil then
            obj.fill.effect.r = Star.TBL_COLORS[numIdCurrentNebula][2]
            obj.fill.effect.g = Star.TBL_COLORS[numIdCurrentNebula][3]
            obj.fill.effect.b = Star.TBL_COLORS[numIdCurrentNebula][4]
            obj.fill.effect.a = Star.TBL_COLORS[numIdCurrentNebula][5]
        end
    end
end

local function _rebirth(self, numIdNebula)
    local sptMagma = self[NUM_INDEX_MAGMA]
    sptMagma:setSequence("i")
    sptMagma:setFillColor(1, 1, 1)
    sptMagma.alpha = 1
    sptMagma:addEventListener("sprite", sptMagma)
    sptMagma:play()
    sptMagma.numIdNebulaCurrent = numIdNebula

    self.xScale, self.yScale = 10, 10

    if self.CANCEL_TRANSITION_RESIZE ~= nil then
        transition.cancel(self.CANCEL_TRANSITION_RESIZE)
        self.CANCEL_TRANSITION_RESIZE = nil
    end
    self.CANCEL_TRANSITION_RESIZE = transition.to(self, {xScale=.1, yScale=.1, time=200})
end

function Star:new(params)
    local tbl = {}
    if (params ~= nil) then tbl = params end

    -- IMAGE GROUP
    local img = display.newGroup()
    img.camera = tbl.camera
    img.camera:add(img, 4)

    local numIndexCount = 0

    -- HEALTH GROUP
    numIndexCount = numIndexCount + 1
    NUM_INDEX_HEALTH = numIndexCount
    local grpHealth = display.newGroup()
    grpHealth.alpha = 0
    img:insert(grpHealth)

    -- HEALTH BAR
    local sptHealthBar = display.newSprite(shtUtilGameplay, {{name="s", start=49, count=1}})
    sptHealthBar:setFillColor(1, 1, 1, 0.3)
    grpHealth:insert(sptHealthBar)

    -- HEALTH
    local sptHealth = display.newSprite(shtUtilGameplay, {{name="s", start=49, count=49}})
    sptHealth:setFillColor(.9, 0, 0)
    grpHealth:insert(sptHealth)

    -- TEXT HEALTH
    local tblTxtOptions = {
        text = " 100% ",
        width = 128,
        font = "Maassslicer",
        fontSize = 13,
        align = "center"
    }
    local txtHealth = display.newText(tblTxtOptions)
    grpHealth:insert(txtHealth)
    txtHealth:setFillColor(0, .7)
    txtHealth.anchorX, txtHealth.anchorY = .5, 0
    txtHealth.x, txtHealth.y = 0, 32
    img.txtHealth = txtHealth

    -- TEXT HEALTH ANIM
    local tblTxtOptions = {
        text = " 0% ",
        width = 128,
        font = "Maassslicer",
        fontSize = 10,
        align = "center"
    }
    local txtHealthAnim = display.newText(tblTxtOptions)
    grpHealth:insert(txtHealthAnim)
    txtHealthAnim:setFillColor(0, .4)
    txtHealthAnim.anchorX, txtHealthAnim.anchorY = .5, 0
    txtHealthAnim.x, txtHealthAnim.y = 0, txtHealth.y
    img.txtHealthAnim = txtHealthAnim

    -- ANIM SHIELD
    local numQttShieldsMax = Controller:getData():getStore("1").v
    numIndexCount = numIndexCount + 1
    NUM_INDEX_SHIELD = numIndexCount
    local numDiff = 0
    for i=1, numQttShieldsMax do
        local sptShield = display.newSprite(shtUtilGameplay, {{name="s", start=34, count=1}})
        sptShield.alpha = 0
        sptShield:setFillColor(Powerup.tblColors[1][1], Powerup.tblColors[1][2], Powerup.tblColors[1][3], 1)
        sptShield:rotate(random(360))
        img:insert(sptShield)

        numIndexCount = numIndexCount + 1
    end
    numIndexCount = numIndexCount - 1

    -- ANIM FIRE
    numIndexCount = numIndexCount + 1
    NUM_INDEX_FIRE = numIndexCount
    local grpFire = display.newGroup()
    local sptBright = display.newSprite(shtUtilGameplay, {
        {name="s", start=100, count=1},
    })
    sptBright:scale(2, 2)
    grpFire:insert(sptBright)
    local numTimeSpt = random(10) * 100
    local sptFire = display.newSprite(shtStar, {
        {name="s", start=13, count=24, time=3000 + numTimeSpt},
    })
    sptFire:setFrame(random(sptFire.numFrames))
    local numScaleX = random(2) == 1 and 1 or -1
    local numScaleY = random(2) == 1 and 1 or -1
    sptFire:scale(numScaleX, numScaleY)
    sptFire.rotation = random(360)
    grpFire:insert(sptFire)
    local numTimeSpt = random(10) * 100
    local sptFire = display.newSprite(shtStar, {
        {name="s", frames={36,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13}, time=3000 + numTimeSpt},
    })
    sptFire:setFrame(random(sptFire.numFrames))
    local numScaleX = random(2) == 1 and 1 or -1
    local numScaleY = random(2) == 1 and 1 or -1
    sptFire:scale(numScaleX, numScaleY)
    sptFire.rotation = random(360)
    grpFire:insert(sptFire)
    img:insert(grpFire)

    -- ANIM ICING
    numIndexCount = numIndexCount + 1
    NUM_INDEX_ICING = numIndexCount
    local sptIcing = display.newSprite(shtUtilGameplay, {{name="s", start=33, count=1}})
    sptIcing:scale(.95, .95)
    img:insert(sptIcing)

    -- ANIM MAGMA
    numIndexCount = numIndexCount + 1
    NUM_INDEX_MAGMA = numIndexCount
    local sptMagma = display.newSprite(shtStar, {
        {name="s", start=43, count=110, time=14000},
        {name="e", start=37, count=5, time=600, loopCount=1},
        {name="i", frames={39,38}, time=250, loopCount=1}
    })
    sptMagma:setFrame(random(60))
    sptMagma.rotation = random(360)
    sptMagma.sprite = tbl.isHowToPlay and _onStarExplodeHowToPlay or _onStarExplode
    img:insert(sptMagma)

    -- ANIM FLAME
    numIndexCount = numIndexCount + 1
    NUM_INDEX_FLAME = numIndexCount
    local sptFlame = display.newSprite(shtStar, {
        {name="s", start=1, count=12,  time=1000, loopCount=1},
    })
    sptFlame.isVisible = false
    sptFlame.sprite = _onFlameEnded
    local numDirX = random(2) == 1 and 1 or -1
    local numDirY = random(2) == 1 and 1 or -1
    sptFlame:scale(numDirX, numDirX)
    img:insert(sptFlame)

    -- TOUCH AREA SUPER PHOENIX
    numIndexCount = numIndexCount + 1
    NUM_INDEX_TOUCH_AREA = numIndexCount
    local cirTouch = display.newCircle(0, 0, 35)
    cirTouch.alpha = .01
    img:insert(cirTouch)

    -- STORE
    local transientShots = Controller:getData():getStore("6")
    local transientSuperPhoenix = Controller:getData():getStore("5")

    if tbl.isHowToPlay then
        transientShots.v = tbl.currentHowToPlay == 3 and 20 or 0
        Controller:getData():setStore("6", transientShots)

        transientSuperPhoenix.v = tbl.currentHowToPlay == 5 and 5 or 0
        Controller:getData():setStore("5", transientSuperPhoenix)
    end

    -- ATT
    img.isVisible = false
    img.canDoSuperPhoenix = true
    img.numHealthAccumlated = 0
    img.x, img.y = tbl.x, tbl.y
    img.currentPos = 5
    Star.TBL_POSITIONS = {{img.x,img.y - 50}, {img.x,img.y + 50}, {img.x + 130,img.y}, {img.x - 130,img.y}, {img.x,img.y}, {img.x - 140,img.y}}
    img.health = 100
    img.isActive = false
    img.isPerfectDefense = true
    img.numQttShieldsActive = 0
    img.numHealthRecovery = Controller:getData():getStore("2").v
    img.numQttShieldsMax = numQttShieldsMax
    img.transientShots = transientShots
    img.transientSuperPhoenix = transientSuperPhoenix
    img.tblDist = {}
    img.tblTouchX = {}
    img.tblTouchY = {}
    img.tblTouchTarget = {}

    -- METHODS / EVENTS
    img.touchOn = _onTouchOn
    img.touchOff = _onTouchOff
    img[NUM_INDEX_TOUCH_AREA].tap = _onTap
    img.collision = _onCollision
    img.activeShield = _activeShield
    img.flame = _flame
    img.addSuperPhoenix = _addSuperPhoenix
    img.setActive = _setActive
    img.start = _start
    img.shot = _shot
    img.recoveryHealth = _recoveryHealth
    img.destroy = _destroy
    img.explode = _explode
    img.addHealth = tbl.isHowToPlay and _addHealthHowToPlay or _addHealth
    img.jump = _jump
    img.reposition = _reposition
    img.getCurrentPos = _getCurrentPos
    img.reset = _reset
    img.rebirth = _rebirth

    img:reset(1)

    return img
end

return Star