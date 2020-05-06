local Composer = require "composer"
local json = require "json"


local Trt = require "lib.Trt"
local I18N = require "lib.I18N"


local Particle = require "classes.phoenix.entities.Particle"
local Spaceship = require "classes.phoenix.entities.Spaceship"
local Untouchable = require "classes.phoenix.entities.Untouchable"
local Powerup = require "classes.phoenix.entities.Powerup"
local Persistence = require "classes.phoenix.persistence.Persistence"
local AI = require "classes.phoenix.business.AI"
local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"
local Message = require "classes.phoenix.business.Message"


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random
local floor = math.floor
local round = math.round

local Controller = {}

local tblLevels
local rctEmpty


Controller.NUM_MAX_STAGES = 4 -- CHANGE TO 4 FOR PRODUCTION
Controller.NUM_MAX_WAVELETS = 3 -- CHANGE TO 3 FOR PRODUCTION

Controller.numCurrentNebula = 1
Controller.isPassThrough = false
Controller.status = 0
Controller.isActiveLaunch = false
Controller.numCountCleanWavelets = 0
Controller.tblWaveletStats = nil
Controller.ai = AI:new()

--[[
STATUS
    0 - menu
    1 - playing
    2 - paused
    3 - results
    4 - challenge
    5 - bonus
    6 - superphoenix
    7 - help
    8 - untouchable
    9 - tutorial
    10 - continue
    11 - assist
]]--
local _TBL_STATUS_FLOW = {
    {1, 7, 9}, -- 0
    {2, 3, 4, 5, 6, 7, 8, 10, 11}, -- 1
    {0, 1, 7}, -- 2
    {0, 1}, -- 3
    {1, 2, 3, 10}, -- 4
    {1, 2}, -- 5
    {1, 9}, -- 6
    {0, 1, 2}, -- 7
    {1}, -- 8
    {1, 6}, -- 9
    {1, 3, 4}, -- 10
    {0, 1}, -- 11
}
local _TBL_SCENES = {
    "classes.phoenix.controller.scenes.GamePlay",  -- 1
    "classes.phoenix.controller.scenes.GamePlayPause", -- 2
    "classes.phoenix.controller.scenes.GamePlayResults", -- 3
    "classes.phoenix.controller.scenes.Challenge", -- 4
    "classes.phoenix.controller.scenes.Bonus", -- 5
    "classes.phoenix.controller.scenes.SuperPhoenix", -- 6
    "classes.phoenix.controller.scenes.Help", -- 7,
    "classes.phoenix.controller.scenes.Untouchable", -- 8
    "classes.phoenix.controller.scenes.GamePlay",  -- 9
    "classes.phoenix.controller.scenes.Continue",  -- 10
    "classes.phoenix.controller.scenes.Assist",  -- 11
}

local function _init(self)
    local path = system.pathForFile("data/waves_gameplay.json")
    local fh = io.open(path, "r")
    local contents = fh:read("*a")
    tblLevels = json.decode(contents)
    rctEmpty = display.newRect(-1, -1, 1, 1)

    self.data = Persistence:new()
end

local function _copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[_copy(k, s)] = _copy(v, s) end
    return res
end

local function getData(self)
    return self.data
end

local function validateNextStatus(self, status)
    local tblStatus = _TBL_STATUS_FLOW[self.status + 1]
    if status ~= self.status then
        for i=1, #tblStatus do
            if status == tblStatus[i] then
                return true
            end
        end
    end
    --print(self.status, status, false)
    return false
end

local function setStatus(self, status, isForced)
    --print(self.status, "-- >", status)
    if status ~= self.status then
        if not isForced and not self:validateNextStatus(status) then
            return false
        end
        --if isForced then print(self.status, status, true) end
        if (status ~= 2 and status ~= 6 and status ~= 7 and status ~= 8 and status ~= 11) and 
            not (status == 1 and (self.status == 6 or self.status == 8)) and 
            not (status == 0 and self.status == 9) then

            local statusTemp = status == 9 and 2 or status + 1
            Jukebox:dispatchEvent({name="playMusic", id=statusTemp})

        end
    end

    self.status = status
    return true
end

local function getStatus(self)
    return self.status
end

local function showSceneOverlay(self, sceneStatus, params, isForced)
    if isForced or self:validateNextStatus(sceneStatus) then
        local options = {
            isModal = true,
            effect = "fade",
            time = 0,
            params = params
        }
        Composer.showOverlay(_TBL_SCENES[sceneStatus], options)
        return true
    end
    return false
end

local function resetWaveletStats(self)
    self.isHittedStar = false
end

local function setActiveLaunch(self, isActiveLaunch)
    self.isActiveLaunch = isActiveLaunch
end

local function _getCountObstacles()
    return Spaceship.count + Particle.count + Untouchable.count + Powerup.count
end

local function verifyIsUnlockedStore(self)
    local tblStores = {}
    local helpTblID = {}
    -- UNLOCK STORE
    local countUnlocks = self.data:getProfile("countUnlocks")
    for i=1, countUnlocks do
        local storeID = Persistence.TBL_UNLOCKS_STORE[i..""]
        if storeID ~= nil then
            local tblDataStore = self.data:getStore(""..storeID)
            if tblDataStore.k == 1 then
                tblDataStore.k = 0
                tblDataStore.n = 1

                -- SETTING
                tblStores[#tblStores+1] = tblDataStore
                helpTblID[#helpTblID+1] = tblDataStore.i + 3
            end
        end
    end

    -- SAVING IF NECESSARY
    self.data:setStores(tblStores)
    return helpTblID
end

local function verifyIsCompletedMissions(self)
    local tblMissionsCurrent = self.data:getProfile("tblMissionsCurrent")
    local tblAchievementsUpdated = {}

    for i=1, #tblMissionsCurrent do
        local tblAchievement = self.data:getAchievement(""..tblMissionsCurrent[i])

        if tblAchievement.t == 2 then
            --- LAST DATE PLAYED
            local tblLastPlayedH = self.data:getStatProfile("dLastPlayedH")
            local dNow = os.date("*t") 
            dNow.hour, dNow.min, dNow.sec = 0, 0, 0
            dNow = os.time(dNow)
            local dDifference = floor((dNow - tblLastPlayedH.v) / (24 * 60 * 60))
            if dDifference > 0 then
                if dDifference == 1 then
                    self.data:addStatValue("nDaysPlayedConsecutiveZ", 1)
                elseif dDifference > 1 then
                    self.data:setStatValue("nDaysPlayedConsecutiveZ", 1)
                end
                tblLastPlayedH.v = dNow
                self.data:setStatProfile("dLastPlayedH", tblLastPlayedH)
            end
        end

        if tblAchievement.k == 1 and self.data:getStat(tblAchievement.u).v >= tblAchievement.v then
            tblAchievement.k = 0

            -- REWARD
            self.data:addCash(30 + tblAchievement.i * 2)

            -- SETTING
            tblAchievementsUpdated[#tblAchievementsUpdated + 1] = tblAchievement

            local tblAchievementDescribe = self.data:getDescribeMission(tblMissionsCurrent[i])
            Message:addMessage({text=tblAchievementDescribe.strResume, numReward=tblAchievementDescribe.numReward, a="teste"})
        end
    end

    -- SAVING IF NECESSARY
    self.data:setAchievements(tblAchievementsUpdated)
end

local function startHowToPlay(self, camera)
    -- INIT
    self:setStatus(9)
    self:resetWaveletStats()

    Spaceship:reset()
    Particle:reset()
    Untouchable:reset()
    Powerup:reset()

    local nCurrentHowToPlayID = self.data:getProfile("nCurrentHowToPlayID")
    camera:showCurrentHowToPlay(nCurrentHowToPlayID)

    local HowToPlay = require "classes.phoenix.business.HowToPlay"
    HowToPlay.showHow({numID=nCurrentHowToPlayID, camera=camera, onComplete=function()

        -- SHOW MESSAGE
        local strText = ""
        local numDelay = 0
        if nCurrentHowToPlayID == 5 then
            strText = I18N:getString("howToPlayDone")
            numDelay = 2500
        end
        Message:addMessage({text=strText, numDelay=numDelay, onComplete=function()

            -- RESTARTING
            local nNextHowToPlayID = nCurrentHowToPlayID + 1
            self.data:setProfile("nCurrentHowToPlayID", nNextHowToPlayID)

            -- RESETING STORE IF ENDING HOW TO PLAY
            if nNextHowToPlayID == 6 then
                local tblStore = self.data:getStore("5")
                tblStore.v = 5
                self.data:setStore("5", tblStore)
                local tblStore = self.data:getStore("6")
                tblStore.v = 250
                self.data:setStore("6", tblStore)

                Jukebox:dispatchEvent({name="stopMusic"})
                self:setStatus(0, true)
                timer.performWithDelay(1700, function() 
                    Jukebox:dispatchEvent({name="playMusic", id=1})
                end)

                Composer.stage.alpha = 0
                local options = {
                    effect = "fade",
                    time = 200,
                }
                Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
            else
                Composer.stage.alpha = 0
                local options = {
                    effect = "fade",
                    time = 0,
                    params = {isReload=true}
                }
                Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
            end
            
        end})

    end})
end

local function _getConvertedWavelet(tblWavelets, numCurrentWavelet)
    return #tblWavelets[numCurrentWavelet] > 0 and numCurrentWavelet or _getConvertedWavelet(tblWavelets, numCurrentWavelet - 1)
end

local function _getDirection(numChoosedNebula, numCurrentWavelet)
    return random(2) == 1 and 1 or -1
end

local _onCompleteLaunch = function() end

local function doSuperPhoenix(self)
    if self.trtLaunch ~= nil then
        Trt.cancel(self.trtLaunch)
        self.trtLaunch = nil
    end
    Trt.to(rctEmpty, {time=2500, isLocked=true, onComplete=function()
        _onCompleteLaunch()
    end})
end

local function start(self, camera)
    -- COMMENT ON PRODUCTION
    --[[]
    local tblTxtOptions = {
        parent = camera,
        text = "",
        font = "Maassslicer",
        fontSize = 9,
        align = "right"
    }
    local txtLevel = display.newText(tblTxtOptions)
    txtLevel:setFillColor(1, .1)
    txtLevel.anchorX, txtLevel.anchorY = 1, 1
    txtLevel.x, txtLevel.y = Constants.RIGHT, Constants.BOTTOM - 47
    --]]

    -- INIT
    self:setStatus(1)
    self:setActiveLaunch(false)
    self.numCountCleanWavelets = 0
    self.numCurrentNebula = 1
    self.isPassThrough = false
    self.ai:init()

    Spaceship:reset()
    Particle:reset()
    Untouchable:reset()
    Powerup:reset()

    local numCurrentStage = 1
    local numCurrentWave = 1
    local numCountWavelets = 0
    local haveNewStage = true

    local function _doPick()
        local numCurrentWave = (self.numCurrentNebula - 1) * (Controller.NUM_MAX_STAGES * Controller.NUM_MAX_WAVELETS) + numCountWavelets
        local numGroup = self.ai:chooseGroup(self.isHittedStar)
        local numIdCurrentNebula = self.numCurrentNebula % 5
        numIdCurrentNebula = numIdCurrentNebula == 0 and 5 or numIdCurrentNebula
        local numChoosedNebula = numGroup == 1 and 1 or self.ai:chooseNebulaObstacles(numIdCurrentNebula)
        local numCurrentWavelet = numGroup == 1 and 1 or random(1, #tblLevels[numChoosedNebula])

        local tblWavelets = tblLevels[numChoosedNebula]
        
        local numTimeGroup = -2000 -300 * numGroup - numCurrentWave * 10
        local numTimeVariation = random(-5, 0) * 100
        local numTimeDelayFactor = random(numGroup * .5 - 12, (numGroup - 12) * .5) * 27 -- 25
        local numDirection = _getDirection(numChoosedNebula, numCurrentWavelet)
        local numGravityAsteroid = -(numTimeGroup * .00015 + 1.3)
        local numDirectionAsteroid = random(2) == 1 and 1 or -1

        -- COMMENT ON PRODUCTION
        --[[ 
        --local strPrint = " DIF:"..numGroup--.." FRM:"..numCurrentWavelet
        --txtLevel.text = strPrint
        --]]

        -- RESET STATS FOR NEW WAVELET
        self:resetWaveletStats()

        local tblObjects = tblWavelets[_getConvertedWavelet(tblWavelets, numCurrentWavelet)]
        local numQttObjects = 0
        for key,value in pairs(tblObjects) do numQttObjects = numQttObjects + 1 end

        local numCurrentObject = numDirection == 1 and 1 or numQttObjects
        local posLaunched = 0
        local particle = {}

        -- COUNT WAVELETS
        numCountWavelets = numCountWavelets + 1

        local function _doLaunch()
            local tblDelay = numDirection == 1 and _copy(tblObjects[numCurrentObject][2]) or (numCurrentObject == 1 and _copy(tblObjects[numQttObjects][2]) or (numCurrentObject == numQttObjects and _copy(tblObjects[1][2]) or _copy(tblObjects[numCurrentObject][2])))
            local tblParams = _copy(tblObjects[numCurrentObject])
            tblParams.camera = camera
            local tblParamsOld = tblObjects[(numCurrentObject-numDirection)]
            tblParams.pOld = tblParamsOld and tblParamsOld[5]
            tblParams.pOldLaunched = posLaunched
            tblParams.currentGroup = numGroup

            -- ADJUSTING TIME (FOR ASTEROID)
            numTimeGroup = tblParams[1] == 1 and numTimeGroup * 1.1 or numTimeGroup

            -- ADJUSTING TIME TO COLLISION
            tblParams[3] = ("table" == type(tblParams[3])) and ({tblParams[3][1] * 100 + numTimeVariation + numTimeGroup, tblParams[3][2] * 100 + numTimeVariation + numTimeGroup}) or (tblParams[3] * 100 + numTimeVariation + numTimeGroup)

            -- INSTANCIATE PARTICLE
            if tblParams[1] == 2 then
                particle = Spaceship:new(tblParams)
            else
                -- TO ASTEROID
                if tblParams[1] == 1 then
                    -- ADJUSTING GRAVITY
                    if tblParams[6] then
                        tblParams[6] = ("table" == type(tblParams[6])) and {tblParams[6][1] + numGravityAsteroid, tblParams[6][2] + numGravityAsteroid} or tblParams[6] + numGravityAsteroid
                    end
                    -- ADJUSTING DIRECTION
                    if tblParams[7] then
                        tblParams[7] = ("table" == type(tblParams[7])) and tblParams[7] or tblParams[7] * numDirectionAsteroid
                    end
                end
                particle = Particle:new(tblParams)
            end

            -- SAVING POS REFERENCE
            if particle then
                posLaunched = particle.posLaunched
            end

            _onCompleteLaunch = numCurrentObject == (numDirection == 1 and numQttObjects or 1) and _doPick or _doLaunch
            numCurrentObject = numCurrentObject + numDirection
            local delay = ("table" == type(tblDelay) and random(tblDelay[1], tblDelay[2]) or tblDelay) * (camera.isFrozen and 25 or 100) 
            delay =  numCurrentObject == numQttObjects and 0 or delay + numTimeDelayFactor
            self.trtLaunch = Trt.to(rctEmpty, {isLocked=true, time=delay, onComplete=_onCompleteLaunch})

            if numCountWavelets == Controller.NUM_MAX_WAVELETS then
                numCountWavelets = 0

                -- NEXT STAGE
                numCurrentStage = numCurrentStage + 1
                if numCurrentStage > Controller.NUM_MAX_STAGES then
                    numCurrentStage = 1
                    self.numCurrentNebula = self.numCurrentNebula + 1
                end

                self:setActiveLaunch(false)
                haveNewStage = true
            end

        end

        local _verifyIfCanLaunch = function() end
        _verifyIfCanLaunch = function()
            if not haveNewStage or (_getCountObstacles() < 1 and haveNewStage) then
    
                Trt.cancel(self.trtLaunch)

                local numPos = camera:getTargetPos()--5********************

                if haveNewStage and camera and camera.showCurrentStage then
                    haveNewStage = false
                    numPos = (self.numCurrentNebula == 1 and numCurrentStage == 1) and random(4) or self.ai:chooseJumpPos()--5*********
                    camera:showCurrentStage(self.numCurrentNebula, numCurrentStage, numPos, self.isPassThrough)
                end

                if self.isActiveLaunch then
                    if numPos == 5 then
                        local numFactor = camera.codAssist == 12 and 30 or 20
                        for i = 1, self.ai:chooseNumMaxUntouchables() do
                            if random(numFactor - numGroup) == 1 then
                                Untouchable:new({camera=camera, currentGroup=numGroup})
                            end
                        end
                    end
                    
                    _doLaunch()
                else
                    self.trtLaunch = Trt.to(rctEmpty, {isLocked=true, time=200, onComplete=_verifyIfCanLaunch})
                end

            else
                self.trtLaunch = Trt.to(rctEmpty, {isLocked=true, time=200, onComplete=_verifyIfCanLaunch})
            end
        end
        _verifyIfCanLaunch()
        
    end

    self.trtLaunch = Trt.to(rctEmpty, {isLocked=true, time=100, onComplete=_doPick})

end


Controller.init = _init
Controller.getData = getData
Controller.validateNextStatus = validateNextStatus
Controller.setStatus = setStatus
Controller.getStatus = getStatus
Controller.showSceneOverlay = showSceneOverlay
Controller.resetWaveletStats = resetWaveletStats
Controller.setActiveLaunch = setActiveLaunch
Controller.verifyIsCompletedMissions = verifyIsCompletedMissions
Controller.verifyIsUnlockedStore = verifyIsUnlockedStore
Controller.doSuperPhoenix = doSuperPhoenix
Controller.startHowToPlay = startHowToPlay
Controller.start = start


return Controller