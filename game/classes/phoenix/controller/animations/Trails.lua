local sqrt = math.sqrt
local atan2 = math.atan2

local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())


local Trails = {}

Trails.isActive = false


local tblSprites = {{},{}}
for i=1, 5 do
	tblSprites[1][i] = display.newSprite(shtUtilUi, { {name="s", start=52, count=1} })
	tblSprites[1][i].xScale = .001
	tblSprites[1][i].anchorX = .7
end

local tblSpritesUsed = {}
local tblSpritesAvailable = {}

local function _onTouchListener(event)
	local x = event.x
	local y = event.y
	local id = tostring(event.id)
	local phase = event.phase

	if phase == "moved" then
		if tblSpritesUsed[id] then
			tblSpritesUsed[id][10] = x
			tblSpritesUsed[id][11] = y
		end

	elseif phase == "began" then
		local idAvailable = #tblSpritesAvailable
		tblSpritesUsed[id] = {}

		for i=1, 7, 2 do
			tblSpritesUsed[id][i] = x
			tblSpritesUsed[id][i + 1] = y
		end

		if idAvailable > 0 then
			tblSpritesUsed[id][9] = tblSpritesAvailable[idAvailable]
			tblSpritesUsed[id][9].alpha = 1
			tblSpritesUsed[id][9].xScale = .001
			table.remove(tblSpritesAvailable, idAvailable)
		else
			tblSpritesUsed[id][9] = {empty=true}
		end

		tblSpritesUsed[id][10] = x
		tblSpritesUsed[id][11] = y

	elseif phase == "ended" or  phase == "cancelled" then
		if tblSpritesUsed[id] then
			if not tblSpritesUsed[id][9].empty then
				tblSpritesAvailable[#tblSpritesAvailable + 1] = tblSpritesUsed[id][9]
			end
			tblSpritesUsed[id][9].alpha = .001
			tblSpritesUsed[id][9] = nil
			tblSpritesUsed[id] = nil
		end
	end 
end

local function _onEnterFrameUpdateTrails(event)	
	for key,trail in pairs(tblSpritesUsed) do
		for i = 1, 5, 2 do
			trail[i] = trail[i+2]
			trail[i+1] = trail[i+3]
		end
		
		trail[7] = trail[10]
		trail[8] = trail[11]
	
		trail[9].x = trail[7]
		trail[9].y = trail[8]
				
		local deltaX = trail[7] - trail[5]
		local deltaY = trail[8] - trail[6]
		local distance = sqrt(deltaX * deltaX + deltaY * deltaY)
		local xScale = distance * .018
		if xScale > 0 then
			trail[9].xScale = xScale
		end

		local rotation = atan2(deltaY, deltaX)
		if rotation ~= 0 and rotation ~= 360 then
			trail[9].rotation = rotation * 57.32484076433121 -- (rotation / 6.28) * 360 = rotation * 57.32484076433121
		end
	end
end 

local _activate = function(self, isActivate)
	if Trails.isActive ~= isActivate then
		if isActivate then
			Runtime:addEventListener("touch", _onTouchListener)
			Runtime:addEventListener("enterFrame", _onEnterFrameUpdateTrails)
		else
			Runtime:removeEventListener("touch", _onTouchListener)
			Runtime:removeEventListener("enterFrame", _onEnterFrameUpdateTrails)

			for key,trail in pairs(tblSpritesUsed) do
				trail[9].alpha = .001
				if not trail[9].empty then
					tblSpritesAvailable[#tblSpritesAvailable + 1] = trail[9]
				end
			end
			for key,trail in pairs(tblSpritesUsed) do
				tblSpritesUsed[key] = nil
			end
		end
		Trails.isActive = isActivate
	end
end

local _setTrailType = function(self, trailType)
	for i=1, 5 do
		tblSpritesAvailable[i] = tblSprites[trailType][i]
	end
end


Trails.activate = _activate
Trails.setTrailType = _setTrailType


Trails:setTrailType(1)


return Trails