local Composer = require "composer"


local Controller = require "classes.phoenix.business.Controller"
local Constants = require "classes.phoenix.business.Constants"
local Trt = require "lib.Trt"


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random


local Util = {}


-- INTERFACE

local tblCornersAngles = {0, -270, -180, -90}
local tblCornersPositionsFrom = {{Constants.LEFT - 100, Constants.TOP - 100}, {Constants.RIGHT + 100, Constants.TOP - 100}, {Constants.RIGHT + 100, Constants.BOTTOM + 100} , {Constants.LEFT - 100, Constants.BOTTOM + 100}}
local tblCornersPositionsTo = {{Constants.LEFT - 10, Constants.TOP - 15}, {Constants.RIGHT + 10, Constants.TOP - 15}, {Constants.RIGHT + 10, Constants.BOTTOM + 15} , {Constants.LEFT - 10, Constants.BOTTOM + 15}}
local function generateFrame(self, grp, bntTL, bntTR, bntBR, bntBL, numDelay)
    local numDelay = numDelay and numDelay or 0

    local tblCornersButtons = {bntTL, bntTR, bntBR, bntBL}

    for i = 1, 4 do
        if tblCornersButtons[i] then
            local grpCorner = display.newGroup( )
            grp:insert(grpCorner)

            tblCornersButtons[i].anchorX, tblCornersButtons[i].anchorY = 0, 0
            grpCorner:insert(tblCornersButtons[i])

            grpCorner.anchorX, grpCorner.anchorY = 0, 0
            grpCorner.x, grpCorner.y = tblCornersPositionsFrom[i][1], tblCornersPositionsFrom[i][2]
            grpCorner.rotation = tblCornersAngles[i]

            tblCornersButtons[i].isActive = false
            grpCorner.xFrom, grpCorner.yFrom = grpCorner.x, grpCorner.y 
            grpCorner.trtCancel = transition.to(grpCorner, {x=tblCornersPositionsTo[i][1], delay=numDelay + 300, y=tblCornersPositionsTo[i][2], transition=easing.outBack, time=400, onComplete=function()
                if tblCornersButtons[i] then
                    tblCornersButtons[i].isActive = true
                end
            end})
        end
    end
end

local function hideStatusbar()
    display.setStatusBar(display.HiddenStatusBar)
    if ( system.getInfo("platformName") == "Android" ) then
        local androidVersion = string.sub( system.getInfo( "platformVersion" ), 1, 3)
        if( androidVersion and tonumber(androidVersion) >= 4.4 ) then
            native.setProperty( "androidSystemUiVisibility", "immersiveSticky" )
        elseif( androidVersion ) then
            native.setProperty( "androidSystemUiVisibility", "lowProfile" )
        end
    end
end

-- GENERAL

local function formatNumber(self, amount)
    --return string.format("%07d", amount)
    --[
    local formatted = amount
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then break end
    end
    return formatted
    --]]
end

local masterVolume = audio.getVolume()

-- CONTROL HARD BUTTONS

local downPress = false
--[[]
function _onBackKeyButtonPressed(e)
    if (e.phase == "down" and e.keyName == "back") then
        downPress = true
        return true
    else
        if (e.phase == "up" and e.keyName == "back" and downPress) then
            downPress = false
            if globals_bntBackRelease then
                globals_bntBackRelease()
            elseif Controller:getStatus() == 0 then
                local options = {
                    isModal = true,
                    effect = "fade",
                    time = 0
                }
                Composer.showOverlay("classes.phoenix.controller.scenes.Quit", options)
            end
        end
    end
    if keyName == "volumeUp" or keyName == "volumeDown" then
        return false
    end
    return true; 
end
--]]
local function _getMasterVolume(self)
    return masterVolume
end
--[
local tmrKeyCancel
local function _updateVolume(keyName, qtd)
    if keyName == "volumeUp" then
        masterVolume = audio.getVolume()
        if masterVolume < 1 then
            masterVolume = masterVolume + qtd
            audio.setVolume(masterVolume)
            media.setSoundVolume(masterVolume)
        else
            audio.setVolume(1)
            media.setSoundVolume(1)
        end
    elseif keyName == "volumeDown" then
        masterVolume = audio.getVolume()
        if masterVolume > .1 then
            masterVolume = masterVolume - qtd
            audio.setVolume(masterVolume)
            media.setSoundVolume(masterVolume)
        else
            audio.setVolume(0)
            media.setSoundVolume(0)
        end
    elseif keyName == "back" then
        downPress = true
    end
    tmrKeyCancel = timer.performWithDelay(30, function()
        _updateVolume(keyName, .05)
    end, 1)
end
local function _onBackKeyButtonPressed(event)
    local phase = event.phase
    local keyName = event.keyName

    if phase == "down" then
        _updateVolume(keyName, .1)
    elseif phase == "up" then
        if keyName == "back" and downPress then
            downPress = false
            if globals_bntBackRelease then
                globals_bntBackRelease()
            elseif Controller:getStatus() == 0 then
                local options = {
                    isModal = true,
                    effect = "fade",
                    time = 0
                }
                Composer.showOverlay("classes.phoenix.controller.scenes.Quit", options)
            end
        elseif tmrKeyCancel ~= nil then
            timer.cancel(tmrKeyCancel)
        end
    end

    if keyName == "volumeUp" or keyName == "volumeDown" then
        return false
    end

    return true
end
--]]
Runtime:addEventListener("key", _onBackKeyButtonPressed)

local function _onSuspendResume(event)
    if event.type == "applicationSuspend" then
        if Controller:getStatus() == 1 then
            TIME_PAUSED = os.time()
            local options = {
                isModal = true,
                effect = "fade",
                time = 0
            }
            Composer.showOverlay("classes.phoenix.controller.scenes.GamePlayPause", options)
        end
    elseif event.type == "applicationResume" then
        hideStatusbar()
        Trt.timeScaleAll(1)
    end
end
Runtime:addEventListener("system", _onSuspendResume)


Util.generateFrame = generateFrame
Util.formatNumber = formatNumber
Util.hideStatusbar = hideStatusbar


return Util