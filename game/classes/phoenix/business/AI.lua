math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random
local round = math.round

local AI = {}

local TBL_NEBULA_GROUP = {}
TBL_NEBULA_GROUP[1] = {1}
TBL_NEBULA_GROUP[2] = {1,1,1,1,1,1,1,1,2}
TBL_NEBULA_GROUP[3] = {1,1,1,1,1,1,2}
TBL_NEBULA_GROUP[4] = {1,1,1,1,1,1,2,2,2,2,2,3}
TBL_NEBULA_GROUP[5] = {1,1,1,1,1,1,2,2,2,3}
TBL_NEBULA_GROUP[6] = {1,1,1,1,1,1,2,2,2,2,3,3,4}
TBL_NEBULA_GROUP[7] = {1,1,1,1,1,2,2,2,3,4}
TBL_NEBULA_GROUP[8] = {1,1,1,1,1,1,1,1,2,2,2,2,3,3,4,4,5}
TBL_NEBULA_GROUP[9] = {1,1,1,1,1,1,1,2,2,2,3,4,5}
TBL_NEBULA_GROUP[10] = {1,1,1,1,2,2,2,3,4,5}

local TENDENCY_OLD = -1
local TENDENCY_SAME_COUNT = 0
local TENDENCY_SAME_COUNT_MAX = 0

function AI:new()
    local object = {
    	group = 1,
    }

    return setmetatable(object, {__index = AI})
end

function AI:init()
    self.group = 1
    TENDENCY_OLD = -1
    TENDENCY_SAME_COUNT = 0
    TENDENCY_SAME_COUNT_MAX = 0
end

function AI:getGroup()
    return self.group
end

function AI:addGroup(dif)
    local group = self:getGroup() + dif
    if group > 10 then
        group = 10
    end

    self.group = group
end

function AI:chooseGroup(currentGroup, isHittedStar)
    local tendency = isHittedStar and 0 or 1

    if TENDENCY_OLD == tendency then
        TENDENCY_SAME_COUNT = TENDENCY_SAME_COUNT + 1
    end
    if TENDENCY_SAME_COUNT > TENDENCY_SAME_COUNT_MAX then
        self:addGroup(tendency)
        TENDENCY_SAME_COUNT = 0
        TENDENCY_SAME_COUNT_MAX = 1--random(0, 1)
    end
            
    TENDENCY_OLD = tendency

    return self:getGroup()
end

function AI:chooseNebulaObstacles(numCurrentNebula)
    local choosed = 1
    local id = round(self:getGroup() * .9) + numCurrentNebula
    id = id > 10 and 10 or id
    choosed = TBL_NEBULA_GROUP[id][random(#TBL_NEBULA_GROUP[id])]
    return choosed
end

function AI:chooseNumMaxUntouchables()
    return self:getGroup() * .5
end

function AI:chooseJumpPos()
    local numResult = self:getGroup()
    if numResult < 5 then
        return random(5) == 1 and (random(2) == 1 and 3 or 4) or (random(2) == 1 and 1 or 2)
    elseif numResult < 8 then
        return random(5) == 1 and (random(2) == 1 and 1 or 2) or (random(2) == 1 and 3 or 4)
    end
    return random(6) == 1 and random(4) or 5
end

return AI