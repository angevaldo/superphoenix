local HowToPlay = {}

HowToPlay.imgFocus = {}
HowToPlay.imgHand = {}

HowToPlay.TRT_CANCEL = nil
HowToPlay.RCT_EMPTY = display.newRect(-1, -1, 1, 1)
HowToPlay.NUM_TIME_STARTED = 0

local Vector2D = require "lib.Vector2D"
local Trt = require "lib.Trt"
local Constants = require "classes.phoenix.business.Constants"

local Particle = require "classes.phoenix.entities.Particle"
local Spaceship = require "classes.phoenix.entities.Spaceship"
local Untouchable = require "classes.phoenix.entities.Untouchable"
local Powerup = require "classes.phoenix.entities.Powerup"

local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())

math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random

local STR_EASING = "outSine"

local function _getCountObstacles()
    return Spaceship.count + Particle.count + Untouchable.count + Powerup.count
end

local _verifyIfCanContinue = function() end
_verifyIfCanContinue = function(params)
	local numTime = os.time()
	if _getCountObstacles() > 0 then
		if numTime - HowToPlay.NUM_TIME_STARTED > 90 then
    		params.camera:doGameOver()
    	else
        	Trt.to(HowToPlay.RCT_EMPTY, {isLocked=true, time=30, onComplete=function()
    			_verifyIfCanContinue(params)
    		end})
        end
    else
    	HowToPlay.NUM_TIME_STARTED = os.time()
    	params.onComplete()
    end
end

local function _initFocus(params)
	HowToPlay.imgFocus = display.newSprite(shtUtilUi, {{name="s", start=17, count=1}})
	HowToPlay.imgFocus.xScale, HowToPlay.imgFocus.yScale = 10, 10
	HowToPlay.imgFocus.anchorX, HowToPlay.imgFocus.anchorY = .5, .5
	HowToPlay.imgFocus.alpha = 0
	params.camera:add(HowToPlay.imgFocus, 7)
end

local function _initHandTouch(params)
	HowToPlay.imgHand = display.newSprite(shtUtilUi, {{name="s", start=14, count=2, time=1500}})
	HowToPlay.imgHand.alpha = 0
	params.camera:add(HowToPlay.imgHand, 7)
end

local function _initHandUntouch(params)
	HowToPlay.imgHand = display.newGroup()
	HowToPlay.imgHand:insert(display.newSprite(shtUtilUi, {{name="s", start=14, count=2, time=1500}}))
	HowToPlay.imgHand:insert(display.newSprite(shtUtilUi, {{name="s", start=16, count=1}}))
	HowToPlay.imgHand.alpha = 0
	params.camera:add(HowToPlay.imgHand, 7)
end

local function _initHandTap(params)
	HowToPlay.imgHand = display.newSprite(shtUtilUi, {{name="s", start=14, count=2, time=400}})
	HowToPlay.imgHand.alpha = 0
	params.camera:add(HowToPlay.imgHand, 7)
end

local function _initHandDoubleTap(params)
	HowToPlay.imgHand = display.newSprite(shtUtilUi, {{name="s", frames={14,15,14,15,14,14,14,14,14,14,14,14,14}, time=1700}})
	HowToPlay.imgHand.alpha = 0
	params.camera:add(HowToPlay.imgHand, 7)
end

local function _initHandDrag(params)
	HowToPlay.imgHand = display.newSprite(shtUtilUi, {{name="s", start=14, count=2, time=700, loopCount=1}})
	HowToPlay.imgHand.alpha = 0
	params.camera:add(HowToPlay.imgHand, 7)
end


-- 1 - DRAG SIMPLE
local function _showHow1(params)
	-- INIT
	_initHandDrag(params)

	local tblParticles = {}
	local tblPositions = {{},{},{},{},{},{}}
	local numPos = 17
	for i=1, 4 do
	    local tblParams = {0,3000,3000,2,numPos}
	    tblParams.camera = params.camera
	    tblParams.pOld, tblParams.pOldLaunched, tblParams.currentGroup, tblParams.isPowerup, tblParams.easing = 1, 1, 1, false, STR_EASING
	    tblParticles[i] = Particle:new(tblParams)
	    tblParticles[i].isTouchable = false
	    numPos = numPos + 2
	end

	HowToPlay.TRT_CANCEL = Trt.to(tblParticles[1], {time=950, onComplete=function()

		Trt:pauseAll()

		for i=1, 4 do
			tblPositions[i+1].x, tblPositions[i+1].y, tblPositions[i+1].time = tblParticles[i].x, tblParticles[i].y, 80
		end
		local numFactor = 2
		local vec = Vector2D:new(tblPositions[2].x - tblPositions[3].x, tblPositions[2].y - tblPositions[3].y)
		vec:mult(numFactor)
		tblPositions[1].x, tblPositions[1].y, tblPositions[1].time = vec.x + tblPositions[2].x, vec.y + tblPositions[2].y, tblPositions[2].time * numFactor
		local vec = Vector2D:new(tblPositions[5].x - tblPositions[4].x, tblPositions[5].y - tblPositions[4].y)
		vec:mult(numFactor)
		tblPositions[6].x, tblPositions[6].y, tblPositions[6].time = vec.x + tblPositions[5].x, vec.y + tblPositions[5].y, tblPositions[2].time * numFactor

		local sptTrail = display.newSprite(shtUtilUi, {{name="s", start=18, count=10, time=tblPositions[1].time*4+tblPositions[2].time*5, loopCount=1}})
		sptTrail.anchorX, sptTrail.anchorY, sptTrail.alpha = 0, 0, .8
		sptTrail.x, sptTrail.y = tblPositions[1].x, tblPositions[1].y
		local numRot = Vector2D:Vec2deg(Vector2D:new(tblPositions[6].x - tblPositions[1].x, tblPositions[6].y - tblPositions[1].y))
		sptTrail.rotation = numRot
		params.camera:add(sptTrail, 7)

		-- TOUCH
		local xFrom, yFrom = tblPositions[1].x + 21, tblPositions[1].y + 19
		HowToPlay.imgHand.x, HowToPlay.imgHand.y = xFrom, yFrom
		local numIndex = 6
		local function _moveNext()
			if tblPositions[numIndex].x then
				if numIndex == 1 then
					sptTrail:setFrame(1)
					sptTrail:play()
				end
				HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=tblPositions[numIndex].time, x=tblPositions[numIndex].x + 21, y=tblPositions[numIndex].y + 19, onComplete=function()
					if trtCancelTrail ~= nil then 
						Trt.cancel(trtCancelTrail)
						trtCancelTrail = nil
					end
					if _getCountObstacles() > 0 then
						if numIndex == 7 then
							numIndex = 1

							HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=300, onComplete=function()
								HowToPlay.imgHand:setFrame(1)
								HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=200, delay=300, alpha=0, onComplete=function()
									HowToPlay.imgHand:pause()
									HowToPlay.imgHand:setFrame(1)
									if HowToPlay.imgHand.x then
										HowToPlay.imgHand.x, HowToPlay.imgHand.y = xFrom, yFrom
										HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=200, delay=200, alpha=1, onComplete=function()
											sptTrail:pause()
											HowToPlay.imgHand:play()
											HowToPlay.TRT_CANCEL = Trt.to(sptTrail, {time=500, onComplete=function()
												_moveNext()
											end})
										end})
									end
								end})
							end})

						else
							_moveNext()
						end
					else
						sptTrail.alpha = 0
						HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=300, alpha=0})
					end
				end})
				numIndex = numIndex + 1
			end
		end

		_moveNext()
		HowToPlay.TRT_CANCEL = Trt.to(tblParticles[1], {time=1500, onComplete=function()
			params.camera:listeningTouchEvents(true, true, true)
			for i=1, 4 do tblParticles[i].isTouchable = true end
		end})
			

		_verifyIfCanContinue({camera=params.camera, onComplete=function()
			if trtCancelTrail ~= nil then 
				Trt.cancel(trtCancelTrail)
				trtCancelTrail = nil
			end
			if HowToPlay.TRT_CANCEL ~= nil then 
				Trt.cancel(HowToPlay.TRT_CANCEL)
				HowToPlay.TRT_CANCEL = nil
			end
			sptTrail.alpha = 0
			HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=300, alpha=0})
			Trt:resumeAll()

			_verifyIfCanContinue({camera=params.camera, onComplete=params.onComplete})
		end})

	end})
end


-- 2 - DRAG DOBLE
local function _showHow2(params)
	-- INIT
	_initHandDrag(params)

	local tblParticles = {}
	local tblPositions = {{},{},{},{},{},{},{},{},{},{}}
	local numPos = 12
	for i=1, 4 do
	    local tblParams = {0,3000,3000,2,numPos}
	    tblParams.camera = params.camera
	    tblParams.pOld, tblParams.pOldLaunched, tblParams.currentGroup, tblParams.isPowerup, tblParams.easing = 1, 1, 1, false, STR_EASING
	    tblParticles[i] = Particle:new(tblParams)
	    tblParticles[i].isTouchable = false
	    numPos = numPos + 4
	end
	numPos = numPos - 3
	for i=5, 7 do
	    local tblParams = {0,3000,3000 + i * 400,2,numPos}
	    tblParams.camera = params.camera
	    tblParams.pOld, tblParams.pOldLaunched, tblParams.currentGroup, tblParams.isPowerup, tblParams.easing = 1, 1, 1, false, STR_EASING
	    tblParticles[i] = Particle:new(tblParams)
	    tblParticles[i].isTouchable = false
	    numPos = numPos - 1
	end

	HowToPlay.TRT_CANCEL = Trt.to(tblParticles[1], {time=1200, onComplete=function()

		Trt:pauseAll()

		for i=1, 4 do
			tblPositions[i+1].x, tblPositions[i+1].y, tblPositions[i+1].time = tblParticles[i].x, tblParticles[i].y, 80
		end
		for i=5, 7 do
			tblPositions[i+2].x, tblPositions[i+2].y, tblPositions[i+2].time = tblParticles[i].x, tblParticles[i].y, 80
		end
		local numFactor = 2
		local vec = Vector2D:new(tblPositions[2].x - tblPositions[3].x, tblPositions[2].y - tblPositions[3].y)
		vec:mult(numFactor)
		tblPositions[1].x, tblPositions[1].y, tblPositions[1].time = vec.x + tblPositions[2].x, vec.y + tblPositions[2].y, tblPositions[2].time * numFactor
		local vec = Vector2D:new(tblPositions[5].x - tblPositions[4].x, tblPositions[5].y - tblPositions[4].y)
		vec:mult(numFactor * .8)
		tblPositions[6].x, tblPositions[6].y, tblPositions[6].time = vec.x + tblPositions[5].x, vec.y + tblPositions[5].y, tblPositions[2].time * numFactor
		local vec = Vector2D:new(tblPositions[9].x - tblPositions[8].x, tblPositions[9].y - tblPositions[8].y)
		tblPositions[10].x, tblPositions[10].y, tblPositions[10].time = vec.x + tblPositions[9].x, vec.y + tblPositions[9].y, tblPositions[2].time

		local sptTrail = display.newSprite(shtUtilUi, {{name="s", start=28, count=16, time=tblPositions[1].time*4+tblPositions[2].time*7.5, loopCount=1}})
		sptTrail.anchorX, sptTrail.anchorY, sptTrail.alpha = .5, .5, .8
		sptTrail.x, sptTrail.y = tblPositions[5].x, tblPositions[5].y
		params.camera:add(sptTrail, 7)

		-- TOUCH
		local xFrom, yFrom = tblPositions[1].x + 21, tblPositions[1].y + 19
		HowToPlay.imgHand.x, HowToPlay.imgHand.y = xFrom, yFrom
		local numIndex = 10
		local function _moveNext()
			if tblPositions[numIndex].x then
				if numIndex == 1 then
					sptTrail:setFrame(1)
					sptTrail:play()
				end
				HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=tblPositions[numIndex].time, x=tblPositions[numIndex].x + 21, y=tblPositions[numIndex].y + 19, onComplete=function()
					if trtCancelTrail ~= nil then 
						Trt.cancel(trtCancelTrail)
						trtCancelTrail = nil
					end
					if _getCountObstacles() > 0 then
						if numIndex == 11 then
							numIndex = 1

							HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=200, delay=200, alpha=0, onComplete=function()
								HowToPlay.imgHand:pause()
								HowToPlay.imgHand:setFrame(1)
								if HowToPlay.imgHand.x then
									HowToPlay.imgHand.x, HowToPlay.imgHand.y = xFrom, yFrom
									HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=200, delay=0, alpha=1, onComplete=function()
										sptTrail:pause()
										HowToPlay.imgHand:play()
										HowToPlay.TRT_CANCEL = Trt.to(sptTrail, {time=500, onComplete=function()
											_moveNext()
										end})
									end})
								end
							end})

						else
							_moveNext()
						end
					else
						sptTrail.alpha = 0
						HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=300, alpha=0})
					end
				end})
				numIndex = numIndex + 1
			end
		end

		_moveNext()
		HowToPlay.TRT_CANCEL = Trt.to(tblParticles[1], {time=1700, onComplete=function()
			params.camera:listeningTouchEvents(true, true, true)
			for i=1, 7 do tblParticles[i].isTouchable = true end
		end})
			

		_verifyIfCanContinue({camera=params.camera, onComplete=function()
			if trtCancelTrail ~= nil then 
				Trt.cancel(trtCancelTrail)
				trtCancelTrail = nil
			end
			if HowToPlay.TRT_CANCEL ~= nil then 
				Trt.cancel(HowToPlay.TRT_CANCEL)
				HowToPlay.TRT_CANCEL = nil
			end
			sptTrail.alpha = 0
			HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=300, alpha=0})
			Trt:resumeAll()

			_verifyIfCanContinue({camera=params.camera, onComplete=params.onComplete})
		end})

	end})
end


-- 3 - ESPECIAL SHOT / SPACESHIP
local function _showHow3(params)
	-- INIT
	_initFocus(params)
	_initHandTap(params)

	-- FOCUS
	HowToPlay.imgFocus.x, HowToPlay.imgFocus.y = Constants.LEFT + 72, Constants.TOP + 7

	HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgFocus, {time=500, delay=500, xScale=4, yScale=4, alpha=.8, transition="outExpo", onComplete=function()
		HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgFocus, {time=200, delay=300, alpha=0, onComplete=function()
				
		    local tblParams = {0,3000,25000,3,6}
		    tblParams.camera, tblParams.isTouchable, tblParams.currentGroup = params.camera, false, 1
		    local spaceship = Spaceship:new(tblParams)

			HowToPlay.TRT_CANCEL = Trt.to(spaceship, {time=1000, onComplete=function()

				Trt:pauseAll()

				spaceship:startShot()

				-- TOUCH
				HowToPlay.imgHand.x, HowToPlay.imgHand.y = spaceship.x + 20, spaceship.y + 19
				HowToPlay.imgHand:play()

				HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=200, alpha=1, onComplete=function()

					spaceship.isTouchable = true
					params.camera:listeningTouchEvents(true, false, true)
					
					_verifyIfCanContinue({camera=params.camera, onComplete=function()
						HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=300, alpha=0})
						Trt:resumeAll()

						_verifyIfCanContinue({camera=params.camera, onComplete=params.onComplete})
					end})

				end})

			end})

		end})
	end})
end


-- 4 - PLANET PHOENIX / UNTOUCHABLE
local function _showHow4(params)
	-- INIT
	_initFocus(params)
	_initHandUntouch(params)

    local untouchable = Untouchable:new({pos=10, camera=params.camera, isTouchable=false, timeToTarget=2000, numDelay=0, currentGroup=1})

	HowToPlay.TRT_CANCEL = Trt.to(untouchable, {time=2000, onComplete=function()

		Trt:pauseAll()

		-- FOCUS
		HowToPlay.imgFocus.x, HowToPlay.imgFocus.y = Constants.RIGHT - 42, Constants.TOP + 10

		HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgFocus, {time=500, xScale=6, yScale=6, alpha=.8, transition="outExpo", onComplete=function()
			HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgFocus, {time=200, delay=300, alpha=0, onComplete=function()
				
				-- FOCUS
				HowToPlay.imgFocus.x, HowToPlay.imgFocus.y = untouchable.x, untouchable.y
				HowToPlay.imgFocus.xScale, HowToPlay.imgFocus.yScale = 10, 10

				HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgFocus, {time=500, delay=100, xScale=4, yScale=4, alpha=.8, transition="outExpo", onComplete=function()
					HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgFocus, {time=200, delay=300, alpha=0, onComplete=function()
						
						-- TOUCH
						HowToPlay.imgHand.x, HowToPlay.imgHand.y = untouchable.x + 21, untouchable.y + 19
						HowToPlay.imgHand[1]:play()

						HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=200, alpha=1, onComplete=function()

							HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=1000, onComplete=function()
								untouchable.isTouchable = true
								HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=300, alpha=0})
								Trt:resumeAll()
								params.camera:listeningTouchEvents(true, true, false)

								Untouchable:new({camera=params.camera, timeToTarget=3000, numDelay=2000, currentGroup=1})

								for j=1, 3 do
									local numPos = random(11,24)
									for i=1, 3 do
										numPos = numPos + 1
									    local tblParams = {0,3000,5000,2,numPos}
									    tblParams.camera = params.camera
						    			tblParams.pOld, tblParams.pOldLaunched, tblParams.currentGroup, tblParams.isPowerup, tblParams.easing = 1, 1, 1, false, STR_EASING
						    			tblParams.numDelay = (j - 1) * 1500 + (i - 1) * 20
									    Particle:new(tblParams)
									end
								end

								_verifyIfCanContinue({camera=params.camera, onComplete=params.onComplete})
							end})	

						end})

					end})
				end})

			end})
		end})

	end})
end


-- 5 - SUPER PHOENIX
local function _showHow5(params)
	-- INIT
	_initFocus(params)
	_initHandDoubleTap(params)

	params.camera:setActiveStar(false)

	-- FOCUS
	HowToPlay.imgFocus.x, HowToPlay.imgFocus.y = Constants.LEFT + 18, Constants.TOP + 10

	HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgFocus, {time=500, delay=500, xScale=4, yScale=4, alpha=.8, transition="outExpo", onComplete=function()
		
		params.camera:setActiveStar(false)

		HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgFocus, {time=200, delay=300, alpha=0, onComplete=function()
				
			params.camera:setActiveStar(false)
			
			for i=1, 15 do
			    local tblParams = {0,3000,3000,2,{11,24}}
			    tblParams.camera = params.camera
				tblParams.pOld, tblParams.pOldLaunched, tblParams.currentGroup, tblParams.isPowerup, tblParams.easing = 1, 1, 1, false, STR_EASING
				tblParams.isTouchable = false
				tblParams.numDelay = 50 * (i - 1)
			    Particle:new(tblParams)
			end

		    local tblParams = {0,3000,25000,2,{1,20}}
		    tblParams.camera, tblParams.isTouchable, tblParams.currentGroup = params.camera, false, 1
		    local spaceship = Spaceship:new(tblParams)

			HowToPlay.TRT_CANCEL = Trt.to(spaceship, {time=1000, onComplete=function()

				params.camera:setActiveStar(false)
				
				Trt:pauseAll()

				-- TOUCH
				HowToPlay.imgHand.x, HowToPlay.imgHand.y = display.contentCenterX + 19, display.contentCenterY + 19
				HowToPlay.imgHand:play()

				HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=200, alpha=1, onComplete=function()

					--params.camera:listeningTouchEvents(true, true, true)
					params.camera:setActiveStar(true)
					
					_verifyIfCanContinue({camera=params.camera, onComplete=function()
						HowToPlay.TRT_CANCEL = Trt.to(HowToPlay.imgHand, {time=300, alpha=0})
						Trt:resumeAll()

						for i=1, 15 do
						    local tblParams = {0,3000,11000,2,{11,24}}
						    tblParams.camera = params.camera
							tblParams.pOld, tblParams.pOldLaunched, tblParams.currentGroup, tblParams.isPowerup, tblParams.easing = 1, 1, 1, false, STR_EASING
							tblParams.isTouchable = false
							tblParams.numDelay = 100 * (i - 1)
						    Particle:new(tblParams)
						end

						for i=1, 5 do
						    local tblParams = {0,3000,25000,1,{1,20}}
						    tblParams.camera, tblParams.isTouchable, tblParams.currentGroup = params.camera, false, 1
						    tblParams.numDelay = 1000 * i
						    local spaceship = Spaceship:new(tblParams)
						end

						_verifyIfCanContinue({camera=params.camera, onComplete=function()
							params.camera:setActiveStar(false)
							params.onComplete()
						end})
					end})

				end})

			end})

		end})
	end})
end

local function _showHow(params)
	if HowToPlay.TRT_CANCEL ~= nil then
		Trt.cancel(HowToPlay.TRT_CANCEL)
		HowToPlay.TRT_CANCEL = nil
	end

	HowToPlay.NUM_TIME_STARTED = os.time()

	local fName = "showHow"..params.numID
	HowToPlay[fName](params)
end

HowToPlay.showHow = _showHow
HowToPlay.showHow1 = _showHow1
HowToPlay.showHow2 = _showHow2
HowToPlay.showHow3 = _showHow3
HowToPlay.showHow4 = _showHow4
HowToPlay.showHow5 = _showHow5

return HowToPlay