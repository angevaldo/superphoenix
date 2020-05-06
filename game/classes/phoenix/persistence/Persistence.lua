local GGData = require "lib.GGData"
local I18N = require "lib.I18N"

local OpenSSL = require "plugin.openssl"
local Cipher = OpenSSL.get_cipher("aes-256-cbc")
local MIME = require "mime"

local Persistence = {}

-- CONSTANTS
local CRYPTO_NORMAL_KEY = "5&BoAVKn3r6rA84z12TK"
local CRYPTO_NORMAL_0 = "LNuUxgLIgKI0tT/m9RLijg=="
local CRYPTO_CASH_KEY = "r@nOIhS414gflWZYALho"
local CRYPTO_CASH_0 = "yEX2UNcdkk473s+PgfwegA=="
--local CRYPTO_CASH_1000000 = "NX3Cqaav+Xx2UuR5meuv7Q==" -- COMMENT FOR PRODUCTION
local NUM_ACHIEVEMENTS_TOTAL = 250
local TBL_LIMIT_STORE = {nil,nil,nil,nil,9,9999,9,3,99,99,99,99,99,99,99,99,99,99}
Persistence.TBL_UNLOCKS_STORE = {2,4,6,12,0,0,25,50,15,20,30,35,40,45,60,90,120,150}
for i=1, 18 do
    Persistence.TBL_UNLOCKS_STORE[(Persistence.TBL_UNLOCKS_STORE[i])..""] = i -- PRODUCTION: Persistence.TBL_UNLOCKS_STORE[i] OR TEST: i
end

-- LOCAL FUNCTIONS
local function _quicksort(t, start, endi)
    start, endi = start or 1, endi or #t
    if(endi - start < 1) then return t end
    local pivot = start
    for i = start + 1, endi do
        if t[i].o < t[pivot].o then -- <=
            local temp = t[pivot + 1]
            t[pivot + 1] = t[pivot]
            if(i == pivot + 1) then
                t[pivot] = temp
            else
                t[pivot] = t[i]
                t[i] = temp
            end
            pivot = pivot + 1
        end
    end
    t = _quicksort(t, start, pivot - 1)
    return _quicksort(t, pivot + 1, endi)
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

local function _urlencode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
        str = string.gsub (str, " ", "+")
    end
    return str
end

local function _serviceConsume(url, networkListener, params)
    local headers = {}
    headers["Content-Type"] = "application/x-www-form-urlencoded"

    local options = {}
    options.headers = headers

    if params then
        local strParams = ""
        for key, value in pairs(params) do
            strParams = strParams .. key .. "=" .. _urlencode(value.."") .. "&"
        end
        options.body = strParams
    end

    --[
    --print(url.."?"..options.body)
    --]]
    network.request(url, "POST", networkListener, options)
end

local function _updateCountUnlocks(db)
    local countUnlocks = 0
    for key in pairs(db.achievement) do
        if db.achievement[key].k == 0 then
            countUnlocks = countUnlocks + 1
        end
    end
    if db.profile["countUnlocks"] ~= countUnlocks then
        db:setProfile("countUnlocks", countUnlocks)
    end
end

local function _canAddTableUniqueValue(t, v)
    for i=1, #t do
        if v == t[i] then
            return false
        end
    end
    return true
end

local function _removeStatsList(db, id)
    local strAchievement = db.achievement[id..""].u
    local strKey = string.sub(strAchievement, #strAchievement, #strAchievement)
    strAchievement = (strKey == "Z" or strKey == "H") and string.sub(strAchievement, 1, #strAchievement - 1) or strAchievement

    db.stats[strAchievement] = nil
    db.stats[strAchievement.."H"] = nil
    db.stats[strAchievement.."Z"] = nil
    db.stats:save()
end

local function _addStatsList(db, id)
    local strAchievement = db.achievement[id..""].u
    local strKey = string.sub(strAchievement, #strAchievement, #strAchievement)
    strAchievement = (strKey == "Z" or strKey == "H") and string.sub(strAchievement, 1, #strAchievement - 1) or strAchievement

    for key in pairs(db.stats) do
        local strKeyTemp = string.sub(key, #key, #key)
        local strAchievementTemp = (strKeyTemp == "Z" or strKeyTemp == "H") and string.sub(key, 1, #key - 1) or key
        if strAchievementTemp == strAchievement then
            return false
        end
    end

    db.stats[strAchievement] = _copy(db.definitionStats[strAchievement])
    if strKey == "H" then
        db.stats[strAchievement.."H"] = _copy(db.definitionStats[strAchievement.."H"])
    end
    if strKey == "Z" then
        db.stats[strAchievement.."Z"] = _copy(db.definitionStats[strAchievement.."Z"])
    end
    db.stats:save()

    return true
end

local function _addAchievementsAvaliable(tm, db, id) end
_addAchievementsAvaliable = function(tm, db, id)
    id = id or 1

    if _canAddTableUniqueValue(tm, id) and db.achievement[""..id].k == 1 and _addStatsList(db, id) then
        tm[#tm + 1] = id
    end

    if #tm < 3 and id < NUM_ACHIEVEMENTS_TOTAL then
        _addAchievementsAvaliable(tm, db, id + 1)
    end
end

local function _verifyMissions(db)
    local isModified = false
    local tm = db.profile["tblMissionsCurrent"]
    for i=3, 1, -1 do
        local id = tm[i]
        if id ~= nil then
            if db.achievement[""..id].k ~= 1 then
                table.remove(tm, i)
                _removeStatsList(db, id)
                isModified = true
            end
        end
    end
    if #tm < 3 then
        _addAchievementsAvaliable(tm, db)
        isModified = true
    end
    if isModified then
        db.profile["tblMissionsCurrent"] = tm

        db.profile:save()
    end
end

local function _updateStatsTables(tbl, dbTbl)
    local strKey = nil
    local tblValue = nil
    local tblValueOld = nil
    local tblValueParent = nil
    local value = nil

    for key in pairs(tbl) do
        strKey = key..""
        tblValue = tbl[strKey]

        if tblValue.t == 1 then
            dbTbl:set(strKey, tblValue)

        elseif tblValue.t == 2 then
            tblValueOld = dbTbl[strKey]
            tblValueParent = dbTbl[tblValueOld.p]
            value = tblValueParent.v
            if value > tblValueOld.v then
                tblValue.b = 1
                tblValue.v = value
            else
                tblValue.b = nil
                tblValue.v = tblValueOld.v
            end
            dbTbl:set(strKey, tblValue)
            tbl[key] = tblValue

        else
            tblValueOld = dbTbl[strKey]
            tblValueParent = dbTbl[tblValueOld.p]
            value = tblValueOld.v + tblValueParent.v
            if value ~= tblValueOld.v then
                tblValue.b = 1
                tblValue.v = value
            else
                tblValue.b = nil
                tblValue.v = tblValueOld.v
            end
            dbTbl:set(strKey, tblValue)
            tbl[strKey] = tblValue
        end
    end
end

local function _decrypt(value)
    local decryptedData = Cipher:decrypt(MIME.unb64(value), CRYPTO_NORMAL_KEY)
    return decryptedData
end

local function _encrypt(value)
    local encryptedData = MIME.b64(Cipher:encrypt(value, CRYPTO_NORMAL_KEY))
    return encryptedData
end

local function _decryptCash(value)
    local decryptedData = Cipher:decrypt(MIME.unb64(value), CRYPTO_CASH_KEY)
    return decryptedData
end

local function _encryptCash(value)
    local encryptedData = MIME.b64(Cipher:encrypt(value, CRYPTO_CASH_KEY))
    return encryptedData
end

--[[]
local sqlite3 = require "sqlite3"
local nameGenerator = require "nameGenerator"
math.randomseed(os.time());
local random = math.random
nameGenerator:open();
local function _createVirtualRanking()
    local p = {
        i = 0,
        n = nameGenerator:generateName(),
        c = tblCountries[random(#tblCountries)].code,
        h = _encrypt(random(1, 30000)),
        t = random(5) == 1 and random(8,18) or 0, 
        s = _encrypt(random(1, 15000)),
        a = random(5) == 1 and random(8,18) or 0, 
        f = 1
    }
    _serviceConsume("https://phoenix-ajtechlabs.rhcloud.com/profile.php", function() end, p)
end
timer.performWithDelay(10, _createVirtualRanking, 100000)
--]]


function Persistence:new()
    local object = {
        profile = GGData:new("profile"),
        store = GGData:new("store"),
        achievement = GGData:new("achievement"),
        definitionStats = GGData:new("definitionStats"),
        stats = GGData:new("stats"),
        statsProfile = GGData:new("statsProfile")
   }

    return setmetatable(object, {__index = Persistence})
end

function Persistence:getProfile(name)
    return self.profile[name]
end

function Persistence:setProfile(name, value, callback)
    self.profile[name] = value
    self.profile:saveNewThread(callback)
end

function Persistence:getDecryptedScore()
    return tonumber(_decrypt(self.profile["nScore"]))
end

function Persistence:getDecryptedScoreLast()
    return tonumber(_decrypt(self.profile["nScoreLast"]))
end

function Persistence:getCash(value)
    return tonumber(_decryptCash(self.profile["nCash"]))
end

function Persistence:addCash(value)
    local numValue = self:getCash() + value
    self.profile["nCash"] = _encryptCash(numValue)
    self.profile:save()
end

function Persistence:getStoresSorted()
    local tblStores = {}
    local count = 0
    for key in pairs(self.store) do
        if tonumber(key) then
            tblStores[#tblStores + 1] = self.store[key]
            count = count + 1
        end
    end
    return _quicksort(tblStores, 1, count)
end

function Persistence:getStore(name)
    return self.store[name]
end

function Persistence:getStoreQttNew()
    local count = 0
    for key, v in pairs(self.store) do
        if v.n == 1 then
            count = count + 1
        end
    end
    return count
end

function Persistence:setStore(name, value, callback)
    self.store[name] = value
    self.store:saveNewThread(callback)
end

function Persistence:setStores(tblStores)
    local isEntry = false
    for i=1, #tblStores do
        self.store[tblStores[i].i..""] = tblStores[i]
        isEntry = true
    end
    if isEntry then
        self.store:save()
    end
end

function Persistence:setStoreUnlocked(isUnlock)
    local tblStores = {}
    local tblStore = {}
    local k = isUnlock and {0,1} or {1,0}
    for key in pairs(self.store) do
        tblStore = self.store[key]
        if tblStore.k == k[2] then
            tblStore.k = k[1]
            if isUnlock then
                tblStore.n = 1
            end
            tblStores[#tblStores+1] = tblStore
        end
    end
    self:setStores(tblStores)
    self:setProfile("unlockStorePurchased", isUnlock)
end

function Persistence:isStoreLocked()
    local tblStore = {}
    local isStoreLocked = false
    for key in pairs(self.store) do
        tblStore = self.store[key]
        if tblStore.k == 1 then
            isStoreLocked = true
            break
        end
    end
    return isStoreLocked
end

function Persistence:getAchievement(name)
    return self.achievement[name]
end

function Persistence:setAchievement(name, value)
    self.achievement[name] = value

    self.achievement:save()

    _updateCountUnlocks(self)
    _verifyMissions(self)
end

function Persistence:setAchievements(tblAchievements)
    local isModified = false
    for i=1, #tblAchievements do
        self.achievement[tblAchievements[i].i..""] = tblAchievements[i]
        isModified = true
    end

    self.achievement:save()

    _updateCountUnlocks(self)
    _verifyMissions(self)
end

function Persistence:getStat(name)
    return self.stats[name]
end

function Persistence:getStatProfile(name)
    return self.statsProfile[name]
end

function Persistence:getStats()
    local tblStats = {}
    for key in pairs(self.stats) do
        if key ~= "path" and key ~= "id" then
            tblStats[key] = self.stats[key]
        end
    end
    return tblStats
end

function Persistence:getStatsClean()
    local tblStats = {}
    local tblStat = {}
    for key in pairs(self.stats) do
        if key ~= "path" and key ~= "id" then
            tblStat = self.stats[key]
            if tblStat.t == 1 then --string.find(key, "Z") == nil and string.find(key, "H") == nil then
                tblStat.v = 0
            end
            tblStats[key] = tblStat
        end
    end
    return tblStats
end

function Persistence:getStatsProfileClean()
    local tblStats = {}
    local tblStat = {}
    for key in pairs(self.statsProfile) do
        if key ~= "path" and key ~= "id" then
            tblStat = self.statsProfile[key]
            if tblStat.t == 1 then --string.find(key, "Z") == nil and string.find(key, "H") == nil then
                tblStat.v = 0
            end
            tblStats[key] = tblStat
        end
    end
    return tblStats
end

function Persistence:setStat(name, value, callback)
    self.stat[name] = value
    self.stat:saveNewThread(callback)
end

function Persistence:setStatProfile(name, value, callback)
    self.statsProfile[name] = value
    self.statsProfile:saveNewThread(callback)
end

function Persistence:setStatValue(name, value, callback)
    local tblStat = self.stats[name]
    if tblStat then
        tblStat.v = value
        self.stats:saveNewThread(callback)
    elseif callback then
        callback()
    end

end

function Persistence:addStatValue(name, value, callback)
    local tblStat = self.stats[name]
    if tblStat then
        tblStat.v = tblStat.v + value
        self.stats:saveNewThread(callback)
    elseif callback then
        callback()
    end

end

function Persistence:updateResults(params)
    -- INIT
    local stats = params.stats
    local statsProfile = params.statsProfile
    local strScore = params.strScore
    local codAssist = params.codAssist
    local numCashFactor = codAssist == 11 and 2 or 1
    local numTime = params.numTime > 1800 and 1800 or params.numTime
    local numScore = params.numScore


    -- SETTING PROFILE STATS RECORDS
    statsProfile.nScore.v = numScore
    statsProfile.nScoreBonus.v = math.floor(numScore * .01)
    statsProfile.nTime.v = numTime
    statsProfile.nTimeBonus.v = math.floor(statsProfile.nTime.v * .5)
    statsProfile.nCombosBonus.v = statsProfile.nCombos.v * 5
    -- UPDATE TABLES PROFILE STATS RECORDS
    _updateStatsTables(statsProfile, self.statsProfile)


    -- ADJUST CASH
    local numCash = (statsProfile.nScoreBonus.v + statsProfile.nTimeBonus.v + statsProfile.nCombosBonus.v) * numCashFactor
    self:addCash(numCash)


    -- SETTING STATS
    if stats.nScore then
        stats.nScore.v = numScore
    end
    if stats.nQttPlayed then
        stats.nQttPlayed.v = 1
    end
    if stats.nTime then
        stats.nTime.v = numTime
    end
    -- UPDATE TABLES STATS
    _updateStatsTables(stats, self.stats)


    -- SAVING SCORES
    local numScoreEncrypted = _encrypt(numScore)
    self.profile:set("nScoreLast", numScoreEncrypted)
    if statsProfile.nScoreH.b == 1 then
        self.profile:set("nScore", numScoreEncrypted)
        self.profile:set("nScoreAssist", codAssist)
    end
    if numScore > tonumber(_decrypt(self.profile["nScoreNotSync"])) then
        self.profile:set("nScoreNotSync", numScoreEncrypted)
        self.profile:set("nScoreNotSyncAssist", codAssist)
    end
    self:setProfile("isSyncProfile", false)

    -- SAVING DATA
    local function _callback()
        self.statsProfile:saveNewThread()
    end
    self.stats:saveNewThread(_callback)
end

--[[]
function Persistence:sendProfile(params, callback, callbackListener, callbackParams)
    local userNameOld = self.profile["userName"]
    local countryOld = self.profile["country"]

    if params then
        self:setProfile("userName", params.userName)
        self:setProfile("country", params.country)
    end

    if self.profile["isSyncProfile"] == false then

        

        local p = {
            i = self.profile["userID"],
            n = self.profile["userName"],
            c = self.profile["country"],
        }

        local function _onSend(event)
            if event.isError then
                if callbackListener then
                    callbackListener(event)
                end
            else
                local json = require "json"
                local response = json.decode(event.response)

                if response["e"] then
                    if callbackListener then
                        callbackListener(event)
                    end
                else
                    self:setProfile("userID", response["i"])
                    self:setProfile("isSyncProfile", true)

                    if type(callback) == "function" then
                        callback(callbackListener, callbackParams)
                    end
                end
            end
        end

        _serviceConsume("https://phoenix-ajtechlabs.rhcloud.com/profile.php", _onSend, p)
    else

        if type(callback) == "function" then
            callback(callbackListener, callbackParams)
        end

    end
end
--]]

function Persistence:sendScore(callback)
    if not self.profile["isSyncProfile"] then

        local p = {
            i = self.profile["userID"],
            n = self.profile["userName"],
            c = self.profile["country"],
            h = self.profile["nScore"],
            t = self.profile["nScoreAssist"], 
            s = self.profile["nScoreNotSync"],
            a = self.profile["nScoreNotSyncAssist"],
            f = self.profile["isForceSync"]
        }

        local function _onSend(event)

            if not event.isError then
                local json = require "json"
                local response = json.decode(event.response)

                if response ~= nil and response["e"] == nil then

                    self:setProfile("nScoreNotSync", CRYPTO_NORMAL_0)
                    self:setProfile("nScoreNotSyncAssist", CRYPTO_NORMAL_0)
                    self:setProfile("isSyncProfile", true)
                    self:setProfile("isForceSync", 0)
                    self:setProfile("userID", response["i"])

                    if callback then
                        callback()
                    end

                elseif callback then
                    callback()
                end

            elseif callback then
                callback()
            end
        end

        _serviceConsume("https://phoenix-ajtechlabs.rhcloud.com/profile.php", _onSend, p)

    elseif callback then
        callback()
    end
end

local _getRanking = function() end
local countCalls = 0
_getRanking = function(self, networkListener, params)
    countCalls = countCalls + 1
    if self and self.profile then
        local userID = self.profile["userID"]
        params.i = userID

        if not self.profile["isSyncProfile"] and countCalls < 10 then
            local callback = function()
                _getRanking(self, networkListener, params)
            end
            self:sendScore(callback, networkListener, params)
        else
            countCalls = 0
            _serviceConsume("https://phoenix-ajtechlabs.rhcloud.com/ranking.php", networkListener, params)
        end
    end
end
Persistence.getRanking = _getRanking

function Persistence:haveAssist()
    for key in pairs(self.store) do
        if tonumber(key) ~= nil and tonumber(key) > 8 and self.store[key].v > 0 then
            return true
        end
    end
    return false
end

function Persistence:getDescribeMissions()
    local tblReturn = {}
    local tblMissionsCurrent = self.profile["tblMissionsCurrent"]
    for i=1, #tblMissionsCurrent do
        tblReturn[i] = self:getDescribeMission(tblMissionsCurrent[i])
    end
    return tblReturn
end

function Persistence:getDescribeMission(id)
    local tblAchievement = self.achievement[""..id]
    local tblStat = self.stats[tblAchievement.u]
    local numToGo = tblAchievement.v - tblStat.v
    numToGo = numToGo > 0 and numToGo or 0

    local tblReturn = {}

    local strLabel = I18N:getString("achievementLabel"..tblAchievement.t)

    local strToGo = (tblAchievement.k == 1 and (tblStat.t == 3 or tblStat.g == 1)) and (string.gsub(I18N:getString(numToGo > 1 and "toGoN" or "toGo1"), "xx", ""..numToGo)) or ""
    local numIdDescription = tblAchievement.t
    local strResume = I18N:getString("achievementDescription"..numIdDescription)
    strResume = string.gsub(strResume, "xx", ""..tblAchievement.v)

    tblReturn.id = tblAchievement.i
    tblReturn.isLocked = tblAchievement.k == 1
    tblReturn.strLabel = strLabel
    tblReturn.numType = tblAchievement.t
    tblReturn.numReward = 30 + tblAchievement.i * 2
    tblReturn.strDescription = strResume..strToGo
    tblReturn.strResume = strResume
    tblReturn.numToGo = (tblAchievement.k == 1 and (tblStat.t == 3 or tblStat.g == 1)) and numToGo or nil
    tblReturn.numTotal = tblAchievement.v

    return tblReturn
end

function Persistence:getStoreDescribeMission(id)
    local tblReturn = {}

    local numToGo = Persistence.TBL_UNLOCKS_STORE[id] - self.profile["countUnlocks"]
    numToGo = numToGo > 0 and numToGo or 0
    local strToGo = string.gsub(I18N:getString(numToGo > 1 and "toGoN" or "toGo1"), "xx", ""..numToGo)
    local strResume = I18N:getString("achievementDescription99")
    strResume = string.gsub(strResume, "xx", ""..Persistence.TBL_UNLOCKS_STORE[id])

    tblReturn.strDescription = strResume..strToGo
    tblReturn.numToGo = numToGo

    return tblReturn
end

function Persistence:adsCanShow()
    local dNow = os.time(os.date("*t"))
    local dShowed = self.profile["dAdsShowed"]
     or 0
    local dDif = (dNow - dShowed) / (24 * 60 * 60)
    local nAdsShowedCount = self.profile["nAdsShowedCount"] or 0
    if dDif > 1 or dDif < 0 then
        self.profile:set("dAdsShowed", dNow)
        nAdsShowedCount = 0
        self.profile:set("nAdsShowedCount", nAdsShowedCount)
    end
    local canShow = nAdsShowedCount < 11

    --[[] COMMENT IN PRODUCTION
    native.showAlert("can show", "can show "..nAdsShowedCount, {"ok"})
    --]]

    return canShow
end

function Persistence:adsShowed()
    local nAdsShowedCount = self.profile["nAdsShowedCount"] or 0
    self.profile:set("nAdsShowedCount", nAdsShowedCount + 1)
    self.profile:save()

    --[[] COMMENT IN PRODUCTION
    native.showAlert("showed", "showed "..nAdsShowedCount, {"ok"})
    --]]
end

function Persistence:getAchievementsProgress()    
    local numQttUnlocked = 0
    for i=1, NUM_ACHIEVEMENTS_TOTAL do
        if self.achievement[""..i].k == 0 then
            numQttUnlocked = numQttUnlocked + 1
        end
    end

    local numProgress = math.round((numQttUnlocked / NUM_ACHIEVEMENTS_TOTAL) * 100)

    local tblReturn = {}
    tblReturn.numProgress = numProgress
    tblReturn.numQttUnlocked = numQttUnlocked
    tblReturn.numQttT = NUM_ACHIEVEMENTS_TOTAL

    return tblReturn
end

function Persistence:updateDatabase()
    -- SETTING LIMITS STORE
    local isChanged = false
    for i=5,#TBL_LIMIT_STORE do
        local store = self.store:get(i.."")
        if store.t > TBL_LIMIT_STORE[i] then
            store.t, isChanged = TBL_LIMIT_STORE[i], true
        end
        if store.v > TBL_LIMIT_STORE[i] then
            store.v, isChanged = TBL_LIMIT_STORE[i], true
        end
    end
    if isChanged then
        self.store:save()
    end

    local numGameVersion = self.profile["gameVersion"]

    -- ADDED TO DATABASE AFTER FIRST RELEASE
    
    -- 1.19
    if numGameVersion < 1.19 then
        self.profile:set("gameVersion", 1.19)
        self.profile:save()

        local reg = self.store:get("1")
        reg.p = {40, 80, 250, 1000, 5000}
        self.store:set("1", reg)
        local reg = self.store:get("2")
        reg.p = {100, 200, 400, 1000, 2000, 4000, 8000, 16000, 30000, 60000}
        self.store:set("2", reg)
        local reg = self.store:get("3")
        reg.p = {80, 160, 320, 800, 1700, 3500, 7000, 14500, 28000, 55000}
        self.store:set("3", reg)
        local reg = self.store:get("4")
        reg.p = {65, 130, 300, 600, 1500, 3000, 6000, 12000, 24000, 50000}
        self.store:set("4", reg)
        self.store:save()
    end

    -- 1.20
    if numGameVersion < 1.20 then
        self.profile:set("gameVersion", 1.20)
        self.profile:save()

        local reg = self.store:get("6")
        reg.p = 80
        self.store:set("6", reg)
        self.store:save()
    end

    -- 1.21
    if numGameVersion < 1.21 then
        self.profile:set("gameVersion", 1.21)
        self.profile:set("ads", true) 
        self.profile:save()

        local reg = self.store:get("1")
        reg.p = {50, 500, 1000, 5000, 10000}
        self.store:set("1", reg)
        local reg = self.store:get("2")
        reg.p = {100, 1000, 4000, 6000, 8000, 10000, 15000, 30000, 40000, 60000}
        self.store:set("2", reg)
        local reg = self.store:get("3")
        reg.p = {150, 1500, 6000, 7000, 9000, 12000, 20000, 40000, 50000, 70000}
        self.store:set("3", reg)
        local reg = self.store:get("4")
        reg.p = {200, 2000, 7000, 9000, 12000, 20000, 40000, 50000, 70000, 80000}
        self.store:set("4", reg)
        local reg = self.store:get("5")
        reg.p = 1000
        self.store:set("5", reg)
        local reg = self.store:get("6")
        reg.p = 100
        self.store:set("6", reg)
        local reg = self.store:get("7")
        reg.p = 500
        self.store:set("7", reg)
        local reg = self.store:get("9")
        reg.p = 1000
        self.store:set("9", reg)
        self.store:save()
    end

    -- 1.22
    if numGameVersion < 1.22 then
        self.profile:set("gameVersion", 1.22)
        self.profile:save()
    end

    -- 1.23
    if numGameVersion < 1.23 then
        self.profile:set("gameVersion", 1.23)
        self.profile:save()
    end

    -- 1.24
    if numGameVersion < 1.24 then
        self.profile:set("gameVersion", 1.24)
        self.profile:set("language", system.getPreference("locale", "language"))
        self.profile:save()
    end

    -- 1.25
    if numGameVersion < 1.25 then
        self.profile:set("gameVersion", 1.25)
        self.profile:save()
    end

    -- 1.27
    if numGameVersion < 1.27 then
        self.profile:set("gameVersion", 1.27)
        self.profile:set("nAdsShowedCount", 0)
        self.profile:save()
    end

    -- 1.28
    if numGameVersion < 1.28 then
        self.store:setSync(false)
        self.store:save()
        self.achievement:setSync(false)
        self.achievement:save()
        self.definitionStats:setSync(false)
        self.definitionStats:save()
        self.statsProfile:setSync(false)
        self.statsProfile:save()
        self.stats:setSync(false)
        self.stats:save()

        self.profile:set("gameVersion", 1.28)
        self.profile:setSync(false)
        self.profile:save()
    end

    --[[
    -- 1.29
    if numGameVersion < 1.29 then
        self.profile:set("gameVersion", 1.29)
        self.profile:save()
    end

    -- 1.30
    if numGameVersion < 1.30 then
        self.profile:set("gameVersion", 1.30)
        self.profile:save()
    end

    -- 1.31
    if numGameVersion < 1.31 then
        self.profile:set("gameVersion", 1.31)
        self.profile:save()
    end

    -- 1.32
    if numGameVersion < 1.32 then
        self.profile:set("gameVersion", 1.32)
        self.profile:save()
    end

    -- 1.33
    if numGameVersion < 1.33 then
        self.profile:set("gameVersion", 1.33)
        self.profile:save()
    end

    -- 1.34
    if numGameVersion < 1.34 then
        self.profile:set("gameVersion", 1.34)
        self.profile:save()
    end

    -- 1.36
    if numGameVersion < 1.36 then
        self.profile:set("gameVersion", 1.36)
        self.profile:save()
    end
    --]]

    -- 1.41
    if numGameVersion < 1.41 then
        self.profile:set("gameVersion", 1.41)
        self.profile:save()
    end
end

function Persistence:clear()
    local userID = self.profile["userID"]
    local tblMissions = {1, 2, 3}
    local dNow = os.date("*t") 
    dNow.hour, dNow.min, dNow.sec = 0, 0, 0
    dNow = os.time(dNow)


    self.store:delete()
    self.store = GGData:new("store")
    self.achievement:delete()
    self.achievement = GGData:new("achievement")
    self.definitionStats:delete()
    self.definitionStats = GGData:new("definitionStats")
    self.profile:delete()
    self.profile = GGData:new("profile")
    self.statsProfile:delete()
    self.statsProfile = GGData:new("statsProfile")
    self.stats:delete()
    self.stats = GGData:new("stats")


    self.store:set("1", {i=1, o=1, l="shield", n=0, k=1, v=1, s={1, 2, 3, 4, 5}, p={50, 500, 1000, 5000, 10000}})
    self.store:set("2", {i=2, o=2, l="health", n=0, k=1, v=5, s={5, 10, 15, 20, 25, 30, 35, 40, 45, 50}, p={100, 1000, 4000, 6000, 8000, 10000, 15000, 30000, 40000, 60000}})
    self.store:set("3", {i=3, o=3, l="hole", n=0, k=1, v=80, s={80, 95, 115, 130, 150, 165, 185, 200, 300, 400}, p={150, 1500, 6000, 7000, 9000, 12000, 20000, 40000, 50000, 70000}})
    self.store:set("4", {i=4, o=4, l="slow", n=0, k=1, v=1000, s={1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000}, p={200, 2000, 7000, 9000, 12000, 20000, 40000, 50000, 70000, 80000}})
    self.store:set("5", {i=5, o=5, l="superPhoenix", n=0, k=0, m=1, t=TBL_LIMIT_STORE[5], v=0, p=1000})
    self.store:set("6", {i=6, o=6, l="shot", n=0, k=0, m=10, t=TBL_LIMIT_STORE[6], v=0, p=100})
    self.store:set("7", {i=7, o=7, l="planet", n=0, k=1, m=1, t=TBL_LIMIT_STORE[7], v=0, p=500})
    self.store:set("8", {i=8, o=8, l="continue", n=0, k=1, m=1, t=TBL_LIMIT_STORE[8], v=0, p=1500})
    self.store:set("9", {i=9, o=9, l="doublePowerup", n=0, k=1, m=1, t=TBL_LIMIT_STORE[9], v=0, p=1000})
    self.store:set("10", {i=10, o=10, l="doubleResistence", n=0, k=1, m=1, t=TBL_LIMIT_STORE[10], v=0, p=1500})
    self.store:set("11", {i=11, o=11, l="doubleCoins", n=0, k=1, m=1, t=TBL_LIMIT_STORE[11], v=0, p=1000})
    self.store:set("12", {i=12, o=12, l="halfPlanet", n=0, k=1, m=1, t=TBL_LIMIT_STORE[12], v=0, p=1000})
    self.store:set("13", {i=13, o=13, l="multiplier2", n=0, k=1, m=1, t=TBL_LIMIT_STORE[13], v=0, p=500})
    self.store:set("14", {i=14, o=14, l="multiplier4", n=0, k=1, m=1, t=TBL_LIMIT_STORE[14], v=0, p=1000})
    self.store:set("15", {i=15, o=15, l="jump2", n=0, k=1, m=1, t=TBL_LIMIT_STORE[15], v=0, p=500})
    self.store:set("16", {i=16, o=16, l="jump3", n=0, k=1, m=1, t=TBL_LIMIT_STORE[16], v=0, p=600})
    self.store:set("17", {i=17, o=17, l="jump4", n=0, k=1, m=1, t=TBL_LIMIT_STORE[17], v=0, p=800})
    self.store:set("18", {i=18, o=18, l="jump5", n=0, k=1, m=1, t=TBL_LIMIT_STORE[18], v=0, p=1000})
    self.store:setSync(false)
    self.store:save()


    -- type, id, value, increment, difficulty
    local TBL_MISSIONS = {
        {1, "nTimeZ", 0, 180, 1},
        {4, "nQttPlayedZ", 0, 4, 1},
        {15, "nDoSuperPhoenixZ", 0, 2, 1},
        {5, "nScoreZ", 0, 20000, 1},
        {14, "nIcesDestroyedZ", 10, 200, 1},
        {6, "nAsteroidsDestroyedZ", 0, 100, 1},
        {13, "nSpaceshipsDestroyedZ", 0, 20, 1},
        {1, "nTime", 0, 50, 1},
        {5, "nScore", 0, 8000, 1},
        {2, "nDaysPlayedConsecutiveZ", 0, 1, 1},
        {16, "nIdNebulaH", 1, 1, 1},
        {15, "nDoSuperPhoenix", 0, 1, 2},
        {7, "nGetPowerupsZ", 0, 30, 2},
        {12, "nBlackHoleZ", 0, 2, 3},
        {8, "nCombosSimpleZ", 0, 20, 3},
        {9, "nCombosDoubleZ", 0, 15, 3},
        {10, "nCombosTripleZ", 0, 10, 3},
        {11, "nCombosQuadZ", 0, 7, 3},
        {14, "nIcesDestroyed", 10, 100, 3},
        {6, "nAsteroidsDestroyed", 0, 50, 3},
        {13, "nSpaceshipsDestroyed", 0, 10, 3},
        {7, "nGetPowerups", 0, 4, 3},
        {8, "nCombosSimple", 0, 5, 3},
        {9, "nCombosDouble", 0, 3, 3},
        {10, "nCombosTriple", 0, 2, 3},
        {11, "nCombosQuad", 0, 1, 3},
        {12, "nBlackHole", 0, 1, 4},
        {3, "nPerfectDefenseZ", 0, 1, 4},
    }
    local currentIndex = 1
    local currentDifficulty = 1
    local countAchievements = 0
    repeat
        local mission = TBL_MISSIONS[currentIndex]
        if currentDifficulty == mission[5] then
            mission[3] = mission[3] + mission[4]
            mission[5] = mission[5] + 1
            --print(i, mission[1], 1, mission[2], mission[3])
            countAchievements = countAchievements + 1
            self.achievement:set(countAchievements.."", {i=countAchievements, t=mission[1], k=1, u=mission[2], v=mission[3]})
        end
        if currentIndex == #TBL_MISSIONS then
            currentIndex = 1
            currentDifficulty = currentDifficulty + 1
        else
            currentIndex = currentIndex + 1
        end
    until (countAchievements == NUM_ACHIEVEMENTS_TOTAL)
    self.achievement:setSync(false)
    self.achievement:save()


    --[[
        NAMES: statName-normal, statNameH-high, statNameZ-cumulative
        v: value
        t: type stat (1=last/current, 2=high, 3=total,cumulative)
        b: is record beaten (1=yes)
        p: parent statistic for calculation
    --]]
    self.definitionStats:set("nScore", {v=0, t=1})
    self.definitionStats:set("nQttPlayed", {v=0, t=1})
    self.definitionStats:set("nTime", {v=0, t=1})
    self.definitionStats:set("nCombos", {v=0, t=1})
    self.definitionStats:set("nCombosSimple", {v=0, t=1})
    self.definitionStats:set("nCombosDouble", {v=0, t=1})
    self.definitionStats:set("nCombosTriple", {v=0, t=1})
    self.definitionStats:set("nCombosQuad", {v=0, t=1})
    self.definitionStats:set("nIdNebula", {v=0, t=1})
    self.definitionStats:set("nIcesDestroyed", {v=0, t=1})
    self.definitionStats:set("nAsteroidsDestroyed", {v=0, t=1})
    self.definitionStats:set("nSpaceshipsDestroyed", {v=0, t=1})
    self.definitionStats:set("nPerfectDefense", {v=0, t=1})
    self.definitionStats:set("nGetPowerups", {v=0, t=1})
    self.definitionStats:set("nBlackHole", {v=0, t=1})
    self.definitionStats:set("nDoSuperPhoenix", {v=0, t=1})
    self.definitionStats:set("nDaysPlayedConsecutive", {v=0, t=1})

    -- ADD TABLES HIGH AND TOTAL
    local tblH = {}
    local tblZ = {}
    for key in pairs(self.definitionStats) do
        if key ~= "path" and key ~= "id" then
            tblH[key.."H"] = {v=0, t=2, p=key}
            tblZ[key.."Z"] = {v=0, t=3, p=key}
        end
    end
    for key in pairs(tblH) do
        self.definitionStats:set(key, tblH[key])
    end
    for key in pairs(tblZ) do
        self.definitionStats:set(key, tblZ[key])
    end

    self.definitionStats:setSync(false)
    self.definitionStats:save()


    self.profile:set("gameVersion", 1.41)
    self.profile:set("userID", userID or CRYPTO_NORMAL_0)
    self.profile:set("userName", "")
    self.profile:set("country", "")
    self.profile:set("nScoreLast", CRYPTO_NORMAL_0)
    self.profile:set("nScore", CRYPTO_NORMAL_0)
    self.profile:set("nScoreAssist", 0)
    self.profile:set("nScoreNotSync", CRYPTO_NORMAL_0)
    self.profile:set("nScoreNotSyncAssist", 0)
    self.profile:set("isSyncProfile", false)
    self.profile:set("isForceSync", 1)
    self.profile:set("isSoundActive", true)
    self.profile:set("isMusicActive", true)
    self.profile:set("nCurrentHowToPlayID", 1) -- CHANGE TO 1 FOR PRODUCTION
    self.profile:set("isSeenHelpStore", false)
    self.profile:set("nPlayedCount", 0)
    self.profile:set("isBeenRated", false)
    self.profile:set("tblMissionsCurrent", tblMissions)
    self.profile:set("countUnlocks", 0) 
    self.profile:set("unlockStorePurchased", false) 
    self.profile:set("ads", true) 
    self.profile:set("language", system.getPreference("locale", "language")) 
    self.profile:set("nCash", CRYPTO_CASH_0) -- CHANGE TO CRYPTO_CASH_0 FOR PRODUCTION
    self.profile:setSync(false)
    self.profile:save()


    self.statsProfile:set("nScore", {v=0, t=1})
    self.statsProfile:set("nScoreH", {v=0, t=2, p="nScore"})
    self.statsProfile:set("nScoreBonus", {v=0, t=1})
    self.statsProfile:set("nScoreBonusH", {v=0, t=2, p="nScoreBonus"})
    self.statsProfile:set("nTime", {v=0, t=1})
    self.statsProfile:set("nTimeH", {v=0, t=2, p="nTime"})
    self.statsProfile:set("nTimeBonus", {v=0, t=1})
    self.statsProfile:set("nTimeBonusH", {v=0, t=2, p="nTimeBonus"})
    self.statsProfile:set("nCombos", {v=0, t=1})
    self.statsProfile:set("nCombosH", {v=0, t=2, p="nCombos"})
    self.statsProfile:set("nCombosBonus", {v=0, t=1})
    self.statsProfile:set("nCombosBonusH", {v=0, t=2, p="nCombosBonus"})
    self.statsProfile:set("nCombosBonusH", {v=0, t=2, p="nCombosBonus"})
    self.statsProfile:set("dLastPlayedH", {v=dNow, t=2, p="dLastPlayedH"})
    self.statsProfile:setSync(false)
    self.statsProfile:save()


    for i=1, #tblMissions do
        _addStatsList(self, tblMissions[i])
    end
    self.stats:setSync(false)
    self.stats:save()
end

return Persistence