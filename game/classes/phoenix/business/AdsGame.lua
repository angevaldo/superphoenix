local Toast = require "plugin.toast"

local I18N = require "lib.I18N"

local Constants = require "classes.phoenix.business.Constants"
local Controller = require "classes.phoenix.business.Controller"

local Ads

local AdsGame = display.newGroup()

local _EXPIRATION_TIMER_CANCEL

local function _stopPlayExpiration()
    if _EXPIRATION_TIMER_CANCEL ~= nil then
        timer.cancel(_EXPIRATION_TIMER_CANCEL)
    end
    _EXPIRATION_TIMER_CANCEL = nil
end

local function adListener(event) 
    local phase = event.phase
    local eType = event.type or ""

    if phase == "hidden" or phase == "init" then
        if eType == "" or eType == "interstitial" then
            Ads.load()            
        end
        if eType == "" or eType == "incentivizedInterstitial" then
            Ads.load(true)
        end

    elseif phase == "validationExceededQuota" then
        Toast.show(I18N:getString("adsLimit"), {duration="long"})

    elseif phase == "displayed" or phase == "playbackBegan" then
        _stopPlayExpiration()
    end

    globals_adCallbackListener(event)

    -- HIDE STATUS BAR
    display.setStatusBar(display.HiddenStatusBar)
    if system.getInfo("platformName") == "Android" then
        local androidVersion = string.sub(system.getInfo("platformVersion"), 1, 3)
        if androidVersion and tonumber(androidVersion) >= 4.4 then
            native.setProperty("androidSystemUiVisibility", "immersiveSticky")
        elseif androidVersion then
            native.setProperty("androidSystemUiVisibility", "lowProfile")
        end
    end

end

local function _startPlayExpiration()
    _EXPIRATION_TIMER_CANCEL = timer.performWithDelay(Constants.NUM_WAIT_MILLISECONDS_TO_HIDE_AD_IF_NOT_SHOW, function()
        if adListener then
            Toast.show(I18N:getString("adsCantShow"), {duration="long"})
            adListener({name="adListener", phase="bug"})
        end
    end)
end

local function _init()
    Ads = require "plugin.applovin"
    if Ads then
        Ads.init(adListener, {sdkKey=Constants.STR_KEY_APPLOVIN_AD, verboseLogging=false})
    end
end

local function _show()
    Ads = AdsGame:isActive() and require "plugin.applovin" or nil
    if Ads then
        if Ads.isLoaded() then 
            _startPlayExpiration()
            Ads.show()
            return true
        else
            Ads.load()
        end
    end
    return false
end

local function _showRewarded()
    Ads = require "plugin.applovin"
    if Ads then 
        if Ads.isLoaded(true) then
            _startPlayExpiration()
            Ads.show(true)
            return true
        else
            Ads.load(true)
            Toast.show(I18N:getString("adsCantShow"), {duration="long"})
        end
    else
        Toast.show(I18N:getString("adsNotSupported"), {duration="long"})
    end
    return false
end

local function _showContinue()
    Ads = require "plugin.applovin"
    if Ads then 
        if Ads.isLoaded(true) then
            _startPlayExpiration()
            Ads.show(true)
            return true
        else
            Ads.load(true)
            Toast.show(I18N:getString("adsNotReady"), {duration="long"})
        end
    else
        Toast.show(I18N:getString("adsNotReady"), {duration="long"})
    end
    return false
end

local function _isActive()
    return Controller:getData():getProfile("ads")
end


AdsGame.init = _init
AdsGame.show = _show
AdsGame.isActive = _isActive
AdsGame.show = _show
AdsGame.showRewarded = _showRewarded
AdsGame.showContinue = _showContinue


return AdsGame