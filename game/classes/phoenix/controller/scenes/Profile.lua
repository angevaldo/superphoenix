local Composer = require "composer"
local objScene = Composer.newScene()


local I18N = require "lib.I18N"
local Countries = require "lib.Countries"


local Wgt = require "classes.phoenix.business.Wgt"
local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"
local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"


local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())


local strUserName = ""
local grp = display.newGroup()
local countryCurrent = {}
local isShowingSelector = false
local cnlSelector = nil
local tflUserName


local function _showCountry(grpCountry)
    for i=grpCountry.numChildren, 1, -1 do
        grpCountry:remove(grpCountry[i])
    end

    -- GENERATING INTERFACE
    local rctBg = display.newRect(grpCountry, 0, 0, 250, 80)
    rctBg.alpha = .01
    rctBg.anchorX, rctBg.anchorY = .5, .5
    rctBg.x, rctBg.y = 0, -10

    local imgFlag = countryCurrent.image
    imgFlag.anchorX, imgFlag.anchorY = .5, .5
    imgFlag.x, imgFlag.y = 0, -1
    grpCountry:insert(imgFlag)

    grpCountry.anchorX, grpCountry.anchorY = .5, .5
    grpCountry.x, grpCountry.y = display.contentCenterX, display.contentCenterY + 65

    local txtTitleCountry = display.newText(grpCountry, I18N:getString("countryInformation"), 0, 0, "Maassslicer", 18)
    txtTitleCountry.anchorX, txtTitleCountry.anchorY = .5, 1
    txtTitleCountry.x, txtTitleCountry.y = 0, -10

    local txtName = display.newText(grpCountry, " "..countryCurrent.name, 0, 0, "Maassslicer", 10)
    txtName.anchorX, txtName.anchorY = 1, .5
    txtName.x, txtName.y = -9, 0

    local txtNameOriginal = display.newText(grpCountry, " "..countryCurrent.nameOriginal, 0, 0, "Maassslicer", 10)
    txtNameOriginal.anchorX, txtNameOriginal.anchorY = 0, .5
    txtNameOriginal.x, txtNameOriginal.y = 9, 0

    if countryCurrent.code == 'Z4' then
        txtName.text = " "..I18N:getString(countryCurrent.name)
        txtNameOriginal.text = " "..I18N:getString(countryCurrent.name)
    end

    -- COLORS
    if Composer.getSceneName("current") == "classes.phoenix.controller.scenes.LoadingGameIn" then
        txtTitleCountry:setFillColor(.8)
        txtName:setFillColor(.4)
        txtNameOriginal:setFillColor(.4)
    else
        txtTitleCountry:setFillColor(.3)
        txtName:setFillColor(.6)
        txtNameOriginal:setFillColor(.6)
    end
end

local function _createSelector(grpView, grpCountry)
    local numLineHeight = 28
    local isTapped = false

    local grpSelector = display.newGroup()
    grpView:insert(grpSelector)

    local tblCountries = Countries:getAllCountries()

    local Scroll = require "lib.Scroll"
    local scroll = Scroll:new({objSource=grpView, objTarget=grpSelector, isWithMask=false, numScrollX=Constants.RIGHT - 5})

    local function _onTap(self, event)
        if scroll.velocity == 0 and not isTapped then

            isTapped = true

            local rctBg = display.newRect(grpSelector, 0, 0, 500, numLineHeight)
            rctBg.anchorX, rctBg.anchorY = .5, .5
            rctBg.x, rctBg.y = self.x, self.y
            -- COLORS
            if Composer.getSceneName("current") == "classes.phoenix.controller.scenes.LoadingGameIn" then
                rctBg:setFillColor(0, .3)
            else
                rctBg:setFillColor(1, .3)
            end
            transition.blink(rctBg, {time=200})

            if cnlSelector ~= nil then timer.cancel(cnlSelector) end
            cnlSelector = timer.performWithDelay(500, function()
                if grpSelector then
                    countryCurrent = self.country
                    _showCountry(grpCountry)
                    grpView:remove(grpSelector)
                    grpView:remove(rctOverlay)

                    scroll:turnOff()
                    
                    grpSelector = nil 
                    rctOverlay = nil
                    scroll = nil

                    isShowingSelector = false
                    for i=1, grpView.numChildren do
                        grpView[i].isVisible = true
                    end
                end
            end, 1)
        end
        return false
    end

    for i=1, #tblCountries do
        local country = tblCountries[i]

        local grpItem = display.newGroup()
        grpSelector:insert(grpItem)
        grpItem.country = country
        grpItem.tap = _onTap
        grpItem:addEventListener("tap", grpItem)

        if countryCurrent.code == country.code then
            local rctFocus = display.newRect(grpItem, 0, 0, 500, numLineHeight)
            -- COLORS
            if Composer.getSceneName("current") == "classes.phoenix.controller.scenes.LoadingGameIn" then
                rctFocus:setFillColor(0, .3)
            else
                rctFocus:setFillColor(1, .3)
            end
            rctFocus.anchorX, rctFocus.anchorY = .5, .5
            rctFocus.x, rctFocus.y = 0, 0
            transition.blink(rctFocus, {time=2000})
        end

        local imgFlag = country.image
        imgFlag.anchorX, imgFlag.anchorY = .5, .5
        imgFlag.x, imgFlag.y = 0, 0
        grpItem:insert(imgFlag)

        local txtName = display.newText(grpItem, " "..country.name, 0, 0, "Maassslicer", 10)
        txtName.anchorX, txtName.anchorY = 1, .5
        txtName.x, txtName.y = -9, 0

        local txtNameOriginal = display.newText(grpItem, " "..country.nameOriginal, 0, 0, "Maassslicer", 10)
        txtNameOriginal.anchorX, txtNameOriginal.anchorY = 0, .5
        txtNameOriginal.x, txtNameOriginal.y = 9, 0

        if country.name == country.nameOriginal then
            if country.code == 'Z4' then
                txtName.text = " "..I18N:getString(country.name)
                txtNameOriginal.text = " "..I18N:getString(country.name)
            end
        end 

        -- COLORS
        txtName:setFillColor(.5)
        txtNameOriginal:setFillColor(.5)

        grpItem.anchorX, grpItem.anchorY = .5, .5
        grpItem.x, grpItem.y = 0, numLineHeight * i
    end

    grpSelector.anchorX, grpSelector.anchorY = .5, 0
    grpSelector.x, grpSelector.y = display.contentCenterX, -numLineHeight * Countries:anIndexOf(countryCurrent.code) + display.contentCenterY

    scroll:turnOff(false)

    grpView[2].isVisible = false
    grpView[3].isVisible = false
    grpView[4].isVisible = false
    --grpView[5].isVisible = false
end

local function _sendProfile()
    native.setKeyboardFocus(nil)

    if grp and grp[6] then
        isShowingSelector = false
    end

    strUserName = #strUserName < 3 and "pnx"..os.time() or strUserName
    strUserName = strUserName == I18N:getString("wru") and "pnx"..os.time() or strUserName
    if strUserName ~= Controller:getData():getProfile("userName") or countryCurrent.code ~= Controller:getData():getProfile("country") then
        for i=2, grp.numChildren do grp[i].isVisible = false end

        local userNameOld = Controller:getData():getProfile("userName")
        local countryOld = Controller:getData():getProfile("country")

        local _callback = function()
        end

        if userNameOld ~= strUserName or countryOld ~= countryCurrent.code then
            Controller:getData():setProfile("userName", strUserName)
            Controller:getData():setProfile("country", countryCurrent.code)
            Controller:getData():setProfile("isSyncProfile", false)
        end

        if Composer.getSceneName("current") == "classes.phoenix.controller.scenes.LoadingGameIn" then
            Composer.hideOverlay(true, "fade", 0)
        else
            Composer.stage.alpha = 0
            local options = {
                effect = "fade",
                time = 0,
                params = {scene="classes.phoenix.controller.scenes.Ranking"}
            }
            Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
        end

    else
        grp[2].alpha = 0
        Composer.hideOverlay(true, "fade", 250)
    end
    return true
end

local function _removeCharSpecial(varString)
    local varRes = ""
    for i = 1, #varString do
        local cString = string.sub(varString, i, i)
        if string.find("`~!#$%ˆ&*()+={[}]|\\\":;'?/><,", cString, 1, true) ~= nil then cString = " " end
        varRes = varRes..cString
    end
    return varRes:gsub("^%s*(.-)%s*$", "%1")
end

local bntBackRelease = function(event)
    return _sendProfile()
end


function objScene:create()
    local grpView = self.view
    grp = grpView


    globals_bntBackRelease = bntBackRelease


    -- GET STORED COUNTRY
    if Controller:getData():getProfile("country") == "" then
        countryCurrent = Countries:getCountryDefault()
        Controller:getData():setProfile("country", countryCurrent.code)
    else
        countryCurrent = Countries:getCountry(Controller:getData():getProfile("country"))
    end


    local rctOverlay = display.newRect(grpView, -10, -10, 500, 350)
    rctOverlay.anchorX, rctOverlay.anchorY = 0, 0


    local grpFrame = display.newGroup()
    grpView:insert(grpFrame)


    -- COUNTRY
    local grpCountry = display.newGroup()
    grpView:insert(grpCountry)
    local function _selectCountry(self, event)
        local phase = event.phase
        if phase == "began" then
            self.xScale, self.yScale = .85, .85
        else
            self.xScale, self.yScale = 1, 1
        end
        if phase == "ended" and not isShowingSelector then
            isShowingSelector = true
            if cnlSelector ~= nil then timer.cancel(cnlSelector) end
            cnlSelector = timer.performWithDelay(1, function()
                _createSelector(grpView, grpCountry)
            end, 1)
        end
        return true
    end
    grpCountry.touch = _selectCountry
    grpCountry:addEventListener("touch", grpCountry)
    _showCountry(grpCountry)


    local function _onTflUserName(self, event)
        strUserName = self.text
        if "began" == event.phase then
            self.y = display.contentCenterY - 60
            strUserName = self.text
        elseif "editing" == event.phase then
            if #strUserName > 15 then
                strUserName = string.sub(strUserName, 1, 15)
            end
            self.text = strUserName
        elseif "ended" == event.phase then
            self.text = _removeCharSpecial(self.text)
            self.y = display.contentCenterY
            strUserName = self.text
        elseif "submitted" == event.phase then
            self.text = _removeCharSpecial(self.text)
            strUserName = self.text
            native.setKeyboardFocus(nil)
        end
    end
    local isAndroid = "Android" == system.getInfo("platformName")
    local numFontSize = 18
    local numHeight = 25
    if (isAndroid) then
        numFontSize = numFontSize - 4
        numHeight = numHeight + 10
    end
    tflUserName = native.newTextField(-100, -100, 200, numHeight)
    tflUserName.userInput = _onTflUserName
    tflUserName:addEventListener("userInput", tflUserName)
    tflUserName.font = native.newFont("Maassslicer", numFontSize)
    tflUserName.isEditable = true
    tflUserName.align = "center"
    tflUserName.placeholder = I18N:getString("wru")
    tflUserName.text =  Controller:getData():getProfile("userName")
    tflUserName:setTextColor(0)
    tflUserName.anchorX, tflUserName.anchorY = .5, .5
    tflUserName.x, tflUserName.y = display.contentCenterX, display.contentCenterY
    grpView:insert(tflUserName)
    

    -- COLORS
    if Composer.getSceneName("current") == "classes.phoenix.controller.scenes.LoadingGameIn" then
        rctOverlay:setFillColor(1)
    else
        rctOverlay:setFillColor(0, .9)
    end


    local bntOk = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 11,
        onRelease = globals_bntBackRelease
    }


    Util:generateFrame(grpFrame, nil, nil, bntOk, nil)


end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase

    if phase == "will" then

        globals_bntBackRelease = bntBackRelease

        strUserName = Controller:getData():getProfile("userName")

    elseif phase == "did" then

        if Composer.getSceneName("current") == "classes.phoenix.controller.scenes.LoadingGameIn" then
            native.setKeyboardFocus(tflUserName)
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

    elseif phase == "did" then

        grp:removeSelf()
        grp = nil

        Util:hideStatusbar()
        
    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene