local Widget = require "widget"


local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"


local infObstacles = require("classes.infoObstacles")
local shtObstacles = graphics.newImageSheet("images/gameplay/aniObstacles.png", infObstacles:getSheet())


local Wgt = {}
Wgt.isAnimating = false

local _tblFramesExplosion = {{61, 10}, {84, 12}}

math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random

function newButton(args)

	local obj = display.newGroup()

    local _onSpriteExplode = function(self, event)
        if event.phase == "ended" then					
			local bnt = self.parent.parent[2]
			bnt.isVisible = true

			local sptTop = self.parent.parent[1][2]
			sptTop.isVisible = true

			local sptParticle = self
            sptParticle.xScale, sptParticle.yScale = 1, 1
            sptParticle:setSequence("s")

            obj.alpha = 0
            transition.to(obj, {alpha=1, delay=100, time=500, onComplete=function()
                if obj.trtBreathCancel ~= nil then
                    transition.cancel(obj.trtBreathCancel)
                    obj.trtBreathCancel = nil
                end
                if obj and obj.breath then
                    obj:breath()
                end
            end})
        end
    end

    local _breath = function(self)
        obj.trtBreathCancel = transition.to(self, {xScale=self.tblTo[1], yScale=self.tblTo[2], rotation=self.tblTo[3], time=self.tblTo[4], onComplete=function()
            obj.trtBreathCancel = transition.to(self, {xScale=self.tblFrom[1], yScale=self.tblFrom[2], rotation=self.tblFrom[3], time=self.tblFrom[4], onComplete=function()
                self:breath()
            end})
        end})
    end

	function onPress(event)
		if not Wgt.isAnimating and obj.isActive then
            if obj.trtBreathCancel ~= nil then
    			transition.cancel(obj.trtBreathCancel)
                obj.trtBreathCancel = nil
            end

	        Jukebox:dispatchEvent({name="playSound", id="ice"})

			Wgt.isAnimating = true

			obj.event = event

			local bnt = event.target
			bnt.isVisible = false

			local sptTop = event.target.parent[1][2]
			sptTop.isVisible = false

			local sptParticle = event.target.parent[1][1]
            if random(2) == 1 then
                sptParticle.xScale = -1.3
            else
                sptParticle.xScale = 1.3
            end
            if random(2) == 1 then
                sptParticle.yScale = -1.3
            else
                sptParticle.yScale = 1.3
            end
            sptParticle:setSequence("e")
            sptParticle:play()
            sptParticle:addEventListener("sprite", sptParticle)

			timer.performWithDelay(300, function()
				Wgt.isAnimating = false
			end, 1)
			timer.performWithDelay(100, function()
				if args.onRelease then
					args.onRelease(event)
				end
			end, 1)
		end
	end

	local grpParticle = display.newGroup()
	obj:insert(grpParticle)

    local numFrameDefault = random(58, 60)
    local numFrameTop = random(58, 60)
    local i = random(2)

	local sptParticle = display.newSprite(shtObstacles, {
        {name="s", start=numFrameDefault, count=1},
        {name="e", start=_tblFramesExplosion[i][1], count=_tblFramesExplosion[i][2], time=200, loopCount=1},
    })
	sptParticle.rotation = random(360)
    sptParticle.sprite = _onSpriteExplode
	grpParticle:insert(sptParticle)

	local sptTop = display.newSprite(shtObstacles, {
        {name="s", start=numFrameTop, count=1}
    })
	sptTop.rotation = random(360)
    sptTop.alpha = random(4, 8) * .1
    grpParticle:insert(sptTop)

	local bnt = Widget.newButton{
	    sheet = args.sheet,
	    defaultFrame = args.defaultFrame,
        id = args.id,
	    onPress = onPress
	}
	bnt.anchorX, bnt.anchorY = .5, .5
	local dir = random(2) == 1 and 1 or -1
	bnt:rotate(random(10)*dir)
	bnt.x, bnt.y = 0, 0
	obj:insert(bnt)

    obj.anchorChildren = true
    obj.isActive = true
    obj.breath = _breath

    local tblAleatory = {random(2), random(2), random(5)}
    obj.tblFrom = {tblAleatory[1] == 1 and 1 or .97, tblAleatory[1] == 1 and 1 or .97, tblAleatory[2] == 1 and -2 or 2, 3000 + 200 * tblAleatory[3]}
    obj.tblTo = {tblAleatory[1] == 2 and 1 or .97, tblAleatory[1] == 2 and 1 or .97, tblAleatory[2] == 2 and -2 or 2, 3000 + 200 * tblAleatory[3]}
    obj:breath()

	return obj
end

Wgt.newButton = newButton

return Wgt