local Composer = require "composer"
local objScene = Composer.newScene()


local Scroll = require "lib.Scroll"
local I18N = require "lib.I18N"
local Countries = require "lib.Countries"


local Wgt = require "classes.phoenix.business.Wgt"
local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"
local Constants = require "classes.phoenix.business.Constants"


local infButtons = require("classes.infoButtons")
local shtButtons = graphics.newImageSheet("images/ui/scnButtons.png", infButtons:getSheet())
local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())
local infScenario = require("classes.infoScenario")
local shtScenario = graphics.newImageSheet("images/ui/bkgScenario.jpg", infScenario:getSheet())


math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
local random = math.random
local abs = math.abs

local _hideRanking = function() end
local numCurrentTypeRanking = 1
local grpDetails = {}

local bntBackRelease = function(event)
    local options = {
        effect = "fade",
        time = 0
    }
    Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)
    return true
end

local function _getSeparator(txt1, txtName)
    local numWidthSeparator = txtName.x - txt1.x - (txt1.width + txtName.width)
    local strSeparator = ""
    for i=1, numWidthSeparator * .165 do
        strSeparator = strSeparator .. ". "
    end
    return strSeparator
end

local function _onTapItem(self)
	if self.tblDetails[1] ~= "0º" then
	    if grpDetails.trtCancel ~= nil then transition.cancel(grpDetails.trtCancel) end

	    if grpDetails.x == -100 then
	        grpDetails[1].text = self.tblDetails[1]
	        grpDetails[2].text = self.tblDetails[2]
	        grpDetails[3].text = self.tblDetails[3]
	        grpDetails[4].text = self.tblDetails[4]
	        grpDetails[5].text = self.tblDetails[5]
	        for i=2, 5 do grpDetails[i].y = grpDetails[i-1].y + grpDetails[i-1].height + (i==2 and 10 or 5) end
	        grpDetails.anchorX, grpDetails.anchorY = 0, .5
	        grpDetails.y = display.contentCenterY - grpDetails.height * .5

	        grpDetails.trtCancel = transition.to(grpDetails, {time=500, x=Constants.LEFT, transition=easing.outBack, onComplete=function()
	            if grpDetails then
	                grpDetails.trtCancel = transition.to(grpDetails, {time=300, x=-100, transition=easing.outBack, delay=15000})
	            end
	        end})
	    else
	        grpDetails.trtCancel = transition.to(grpDetails, {time=300, x=-100, transition=easing.outBack, onComplete=function()
		        grpDetails[1].text = self.tblDetails[1]
		        grpDetails[2].text = self.tblDetails[2]
		        grpDetails[3].text = self.tblDetails[3]
		        grpDetails[4].text = self.tblDetails[4]
		        grpDetails[5].text = self.tblDetails[5]
		        for i=2, 5 do grpDetails[i].y = grpDetails[i-1].y + grpDetails[i-1].height + (i==2 and 10 or 5) end
	            grpDetails.anchorX, grpDetails.anchorY = 0, .5
	            grpDetails.y = display.contentCenterY - grpDetails.height * .5
	            
	            grpDetails.trtCancel = transition.to(grpDetails, {time=500, x=Constants.LEFT, transition=easing.outBack, onComplete=function()
	                if grpDetails then
	                    grpDetails.trtCancel = transition.to(grpDetails, {time=300, x=-100, transition=easing.outBack, delay=15000})
	                end
	            end})
	        end})
	    end
	end
end

local function _addItem(grpRanking, numRank, strName, strValue, count, codCountry, strDate, codAssist)
    local y = 21 * (count - 1)

    local country = Countries:getCountry(codCountry)
    local strCountry = country.name
    if country.code == 'Z4' then
        strCountry = I18N:getString(country.name)
    end
    local strRank = Util:formatNumber(numRank).."º"
    local strName = strName
    local strValue = Util:formatNumber(strValue)
    local strDate = strDate
    local tblDetails = {strRank, strName, strValue, strDate, strCountry}

    if numRank > 0 then
        local txt1 = display.newText(grpRanking, " "..strRank..".", 0, 0, "Maassslicer", 11)
        txt1.tblDetails = tblDetails
        txt1.tap = _onTapItem
        txt1:addEventListener("tap", txt1)
        txt1.anchorX, txt1.anchorY = 1, 0
        txt1.x, txt1.y = -95, y
        
        local imgFlag = country.image
        grpRanking:insert(imgFlag)
        imgFlag.tblDetails = tblDetails
        imgFlag.tap = _onTapItem
        imgFlag:addEventListener("tap", imgFlag)
        imgFlag.anchorX, imgFlag.anchorY = 0, 0
        imgFlag.x, imgFlag.y = -98, y - 4
    end

    local txtName = display.newText(grpRanking, " "..strName, 0, 0, "Maassslicer", 11)
    txtName.tblDetails = tblDetails
    txtName.tap = _onTapItem
    txtName:addEventListener("tap", txtName)
    txtName.anchorX, txtName.anchorY = 0, 0
    txtName.x, txtName.y = -78, y

    local txtValue = display.newText(grpRanking, " "..strValue, 0, 0, "Maassslicer", 11)
    txtValue.tblDetails = tblDetails
    txtValue.tap = _onTapItem
    txtValue:addEventListener("tap", txtValue)
    txtValue.anchorX, txtValue.anchorY = 1, 0
    txtValue:setFillColor(1, 1, .2)
    txtValue.x, txtValue.y = 130, y

    if codAssist > 0 then
        local tblFrames = {nil,nil,nil,nil,nil,nil,nil,21,34,35,36,37,38,39,40,41,42,43}
        local imgAssist = display.newSprite(shtButtons, { {name="s", start=tblFrames[codAssist], count=1} })
        grpRanking:insert(imgAssist)
        imgAssist.tblDetails = tblDetails
        imgAssist.tap = _onTapItem
        imgAssist:addEventListener("tap", imgAssist)
        imgAssist.anchorX, imgAssist.anchorY = .5, 0
        imgAssist.x, imgAssist.y = 140, y - 1
        imgAssist:scale(.3, .3)
    end

    local strSeparator = numRank > 0 and _getSeparator(txtName, txtValue) or ". . ."
    local txtSeparator = display.newText(grpRanking, strSeparator, 0, 0, "Maassslicer", 10)
    txtSeparator.anchorX, txtSeparator.anchorY = 0, 0
    txtSeparator.x, txtSeparator.y, txtSeparator.alpha = txtName.x + txtName.width + 6, y - 1, .4
end


function objScene:create(event)
    local grpView = self.view


    globals_bntBackRelease = bntBackRelease


    if event.params and event.params.helpTblID then
        local options = {
            effect = "fade",
            time = 0,
            params = {tblID=event.params.helpTblID, helpType=2},
            isModal = true
        }
        Composer.showOverlay("classes.phoenix.controller.scenes.Help", options)
    end


    local isLoadingRanking = false


    local imgBkg = display.newSprite(shtScenario, { {name="s", frames={2}} })
    imgBkg.anchorX, imgBkg.anchorY = .5, .5
    imgBkg.x, imgBkg.y = display.contentCenterX, display.contentCenterY
    grpView:insert(imgBkg)


    local rctOverlay = display.newRect(-10, -10, 500, 350)
    rctOverlay.anchorX, rctOverlay.anchorY = 0, 0
    rctOverlay.x, rctOverlay.y = 0, Constants.TOP + 40
    rctOverlay.alpha = 0
    rctOverlay:setFillColor(0, .5)
    grpView:insert(rctOverlay)


    local sptShadowTop = display.newSprite(shtUtilUi, { {name="s", start=44, count=1} })
    sptShadowTop.anchorX, sptShadowTop.anchorY = 0, 0
    sptShadowTop.x, sptShadowTop.y = 0, Constants.TOP + 40
    sptShadowTop.yScale = 2
    sptShadowTop.alpha = 0
    sptShadowTop.width = 500
    grpView:insert(sptShadowTop)


    local grpRanking = display.newGroup()
    grpRanking.alpha = 0
    grpView:insert(grpRanking)


    local grpFrame = display.newGroup()
    grpView:insert(grpFrame)


    grpDetails = display.newGroup()
    grpDetails.x = -100
    grpView:insert(grpDetails)

    local tblTxtOptions = {
        parent = grpDetails,
        text = "",
        width = 70,
        font = "Maassslicer",
        fontSize = 14,
        align = "center"
    }
    local txtRank = display.newText(tblTxtOptions)
    txtRank:setFillColor(1)
    txtRank.anchorX, txtRank.anchorY = 0, 0
    txtRank.x, txtRank.y = 0, 0

    local tblTxtOptions = {
        parent = grpDetails,
        text = "",
        width = 70,
        font = "Maassslicer",
        fontSize = 9,
        align = "center"
    }
    local txtName = display.newText(tblTxtOptions)
    txtName:setFillColor(1)
    txtName.anchorX, txtName.anchorY = 0, 0
    txtName.x, txtName.y = 0, 0

    local tblTxtOptions = {
        parent = grpDetails,
        text = "",
        width = 70,
        font = "Maassslicer",
        fontSize = 9,
        align = "center"
    }
    local txtScore = display.newText(tblTxtOptions)
    txtScore:setFillColor(1, 1, .2)
    txtScore.anchorX, txtScore.anchorY = 0, 0
    txtScore.x, txtScore.y = 0, 0

    local tblTxtOptions = {
        parent = grpDetails,
        text = "",
        width = 70,
        font = "Maassslicer",
        fontSize = 9,
        align = "center"
    }
    local txtDate = display.newText(tblTxtOptions)
    txtDate:setFillColor(1)
    txtDate.anchorX, txtDate.anchorY = 0, 0
    txtDate.x, txtDate.y = 0, 0

    local tblTxtOptions = {
        parent = grpDetails,
        text = "",
        width = 70,
        font = "Maassslicer",
        fontSize = 9,
        align = "center"
    }
    local txtFlag = display.newText(tblTxtOptions)
    txtFlag:setFillColor(1)
    txtFlag.anchorX, txtFlag.anchorY = 0, 0
    txtFlag.x, txtFlag.y = 0, 0


    local txtTitle = display.newText(grpView, "", 0, 0, "Maassslicer", 15)
    txtTitle.anchorX, txtTitle.anchorY = .5, 0
    txtTitle.x, txtTitle.y = display.contentCenterX, Constants.TOP

    local txtSubtitle = display.newText(grpView, "", 0, 0, "Maassslicer", 11)
    txtSubtitle.anchorX, txtSubtitle.anchorY = .5, 0
    txtSubtitle.x, txtSubtitle.y = display.contentCenterX, Constants.TOP + txtTitle.height + 4
    txtSubtitle:setFillColor(1)


    local scroll = Scroll:new({objSource=grpView, objTarget=grpRanking})

    local imgLoader = display.newSprite(shtButtons, {
        {name="s", start=2, count=1}
    })
    grpView:insert(imgLoader)
    imgLoader.anchorX, imgLoader.anchorY = .5, .5
    imgLoader.x, imgLoader.y, imgLoader.alpha = display.contentCenterX, display.contentCenterY, 0


    local _hideLoader = {}
    local _onNetwork = {}


    _hideLoader = function(isHide)
        if imgLoader.trtCancel ~= nil then 
            transition.cancel(imgLoader.trtCancel) 
            imgLoader.trtCancel = nil
        end
        if imgLoader.trtCancelRotate ~= nil then 
            transition.cancel(imgLoader.trtCancelRotate) 
            imgLoader.trtCancelRotate = nil
        end

        if isHide == nil or isHide then
            imgLoader.trtCancel = transition.to(imgLoader, {alpha=0, time=300})
        else
            imgLoader.trtCancel = transition.to(imgLoader, {delay=200, alpha=1, time=300})
            imgLoader.trtCancelRotate = transition.to(imgLoader, {rotation=72000, time=200000})
        end
    end


    _hideRanking = function(isHide, typeRank)
        if typeRank then
            numCurrentTypeRanking = typeRank
        end

        if txtTitle.trtCancel ~= nil then 
            transition.cancel(txtTitle.trtCancel) 
            txtTitle.trtCancel = nil
        end
        if txtSubtitle.trtCancel ~= nil then 
            transition.cancel(txtSubtitle.trtCancel) 
            txtSubtitle.trtCancel = nil
        end
        if sptShadowTop.trtCancel ~= nil then 
            transition.cancel(sptShadowTop.trtCancel) 
            sptShadowTop.trtCancel = nil
        end
        if rctOverlay.trtCancel ~= nil then 
            transition.cancel(rctOverlay.trtCancel) 
            rctOverlay.trtCancel = nil
        end
        if grpRanking.trtCancel ~= nil then 
            transition.cancel(grpRanking.trtCancel) 
            grpRanking.trtCancel = nil
        end
        _hideLoader(not isHide)

        if isHide == nil or isHide then
            isLoadingRanking = true
            txtTitle.trtCancel = transition.to(txtTitle, {alpha=0, time=300})
            txtSubtitle.trtCancel = transition.to(txtSubtitle, {alpha=0, time=300})
            sptShadowTop.trtCancel = transition.to(sptShadowTop, {alpha=0, time=300})
            rctOverlay.trtCancel = transition.to(rctOverlay, {alpha=0, delay=100, time=300})
            grpRanking.trtCancel = transition.to(grpRanking, {alpha=0, delay=100, time=300, onComplete=function()
                if grpRanking and grpRanking.numChildren then
                    for i=1, grpRanking.numChildren do
                        grpRanking:remove(grpRanking[1])
                    end
                    scroll:turnOff()
                    if typeRank then
                        Controller:getData():getRanking(_onNetwork, {r=typeRank})
                    end
                end
            end})
        else
            grpRanking.trtCancel = transition.to(grpRanking, {delay=600, alpha=1, time=300, onComplete=function()
                isLoadingRanking = false
            end})
            grpRanking.x  = display.contentCenterX
            if grpRanking and grpRanking.numChildren and grpRanking.numChildren  > 1 then
                txtTitle.trtCancel = transition.to(txtTitle, {delay=400, alpha=1, time=300})
                txtSubtitle.trtCancel = transition.to(txtSubtitle, {delay=400, alpha=1, time=300})
                sptShadowTop.trtCancel = transition.to(sptShadowTop, {delay=200, alpha=.5, time=400})
                rctOverlay.trtCancel = transition.to(rctOverlay, {delay=200, alpha=1, time=300})
            end
        end
    end
    _hideRanking = _hideRanking


    _onNetwork = function(event)
        _hideRanking(true)

        if (event.isError) then

            local msg = display.newText(grpRanking, I18N:getString("entfal"), 0, 0, "Maassslicer", 15)
            msg.anchorX, msg.anchorY = .5, .5
            msg.x, msg.y = 0, display.contentCenterY
            grpRanking.x, grpRanking.y = display.contentCenterX, 0

        elseif event.response == nil and json.decode(event.response) ~= nil then

            local msg = display.newText(grpRanking, I18N:getString("edbnav"), 0, 0, "Maassslicer", 15)
            msg.anchorX, msg.anchorY = .5, .5
            msg.x, msg.y = 0, display.contentCenterY
            grpRanking.x, grpRanking.y = display.contentCenterX, 0

        else

            local json = require "json"
            local response = json.decode(event.response)
            local i = 1

            if response == nil then

                local msg = display.newText(grpRanking, I18N:getString("edbnav"), 0, 0, "Maassslicer", 15)
                msg.anchorX, msg.anchorY = .5, .5
                msg.x, msg.y = 0, display.contentCenterY
                grpRanking.x, grpRanking.y = display.contentCenterX, 0
                
            elseif grpRanking.insert then

                if response.e then

                    if response.e == "edbuni" then
                        Controller:getData():setProfile("userID", 0)
                        Controller:getData():setProfile("isSyncProfile", false)
                    end
                    local msg = display.newText(grpRanking, I18N:getString(response.e), 0, 0, "Maassslicer", 15)
                    msg.anchorX, msg.anchorY = .5, .5
                    msg.x, msg.y = 0, display.contentCenterY
                    grpRanking.x, grpRanking.y = display.contentCenterX, 0

                elseif tonumber(response[1].a) == 0 then
                    local msg = display.newText(grpRanking, I18N:getString("noRanking"), 0, 0, "Maassslicer", 15)
                    msg.anchorX, msg.anchorY = .5, .5
                    msg.x, msg.y = 0, display.contentCenterY
                    grpRanking.x, grpRanking.y = display.contentCenterX, 0

                else
                    local numTRanking = tonumber(response[1].a)
                    local strTRanking = I18N:getString("of")..Util:formatNumber(numTRanking)..I18N:getString(numTRanking > 1 and "players" or "player")

                    txtTitle.text = I18N:getString("rank"..response[1].t)
                    txtSubtitle.text = (tonumber(response[1].r) > 0 and I18N:getString("ure").." "..Util:formatNumber(response[1].r).."º" or I18N:getString("urenot"))..strTRanking

                    local rctFocus = {}
                    if tonumber(response[1].r) > 0 then
                        rctFocus = display.newRect(-100, -100, 1, 1)
                        grpRanking:insert(rctFocus)
                        rctFocus:setFillColor(1, .5)
                        rctFocus.anchorX, rctFocus.anchorY = .5, 0
                        rctFocus.x = 0
                    end

                    local numUserID = Controller:getData():getProfile("userID")

                    local numID = "0"
                    local numRank = 0
                    local strName = ""
                    local strValue = ""
                    local codCountry = ""
                    for key in pairs(response) do
                        if response[key].t == nil then
                            numID = response[key].i
                            numRank = tonumber(response[key].r)
                            strName = response[key].n
                            strValue = response[key].p
                            codCountry = response[key].c
                            strDate = response[key].d
                            codAssist = tonumber(response[key].a)

                            _addItem(grpRanking, numRank, strName, strValue, i, codCountry, strDate, codAssist)

                            if numID == numUserID then
                                rctFocus.height, rctFocus.width, rctFocus.y, rctFocus.alpha = grpRanking[grpRanking.numChildren].height + 4, 600, grpRanking[grpRanking.numChildren].y - 2, .4
                                rctFocus:toBack()
                            end

                            if i == 10 and #response > 10 then
                                local y = grpRanking[grpRanking.numChildren].y + grpRanking[grpRanking.numChildren].height + 5
                                local linSeparator10 = display.newLine(grpRanking, -250, y, 250, y)
                                linSeparator10:setStrokeColor(1, .1)
                            end

                            i = i + 1
                        end
                    end
                    if numTRanking > numRank then
                        _addItem(grpRanking, 0, "", "", i, "", "", 0)
                    end
                    grpRanking.anchorX, grpRanking.anchorY = .5, 0
                    grpRanking.x, grpRanking.y = display.contentCenterX, grpRanking.height > Constants.BOTTOM - 50 and (Constants.BOTTOM * .5 - (rctFocus.y or 0)) or 150
                    transition.blink(rctFocus, {time=2000})
                    scroll:turnOff(false)
                end

            end
        end

        _hideRanking(false)
    end


    local NUM_BUTTONS_DIST_Y = 40
    local NUM_BUTTONS_POS_Y = 27
    local NUM_BUTTONS_SCALE = .7


    local grpDay = display.newGroup()
    grpView:insert(grpDay)
    local function bntDayRelease()
        if not isLoadingRanking then
            _hideRanking(true, 1)
        end
        return true
    end
    local bntDay = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 32,
        onRelease = bntDayRelease
    }
    grpDay:insert(bntDay)
    grpDay.anchorX, grpDay.anchorY = 1, 0
    grpDay.x, grpDay.y = Constants.RIGHT + 100, Constants.TOP + 15
    grpDay:scale(NUM_BUTTONS_SCALE, NUM_BUTTONS_SCALE)


    local grpMonth = display.newGroup()
    grpView:insert(grpMonth)
    local function bntMonthRelease()
        if not isLoadingRanking then
            _hideRanking(true, 2)
        end
        return true
    end
    local bntMonth = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 30,
        onRelease = bntMonthRelease
    }
    grpMonth:insert(bntMonth)
    grpMonth.anchorX, grpMonth.anchorY = 1, 0
    grpMonth.x, grpMonth.y = Constants.RIGHT + 100, grpDay.y + NUM_BUTTONS_DIST_Y
    grpMonth:scale(NUM_BUTTONS_SCALE, NUM_BUTTONS_SCALE)


    local grpAllTime = display.newGroup()
    grpView:insert(grpAllTime)
    local function bntAllTimeRelease()
        if not isLoadingRanking then
            _hideRanking(true, 3)
        end
        return true
    end
    local bntAllTime = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 31,
        onRelease = bntAllTimeRelease
    }
    grpAllTime:insert(bntAllTime)
    grpAllTime.anchorX, grpAllTime.anchorY = 1, 0
    grpAllTime.x, grpAllTime.y = Constants.RIGHT + 100, grpMonth.y + NUM_BUTTONS_DIST_Y
    grpAllTime:scale(NUM_BUTTONS_SCALE, NUM_BUTTONS_SCALE)


    local grpCountry = display.newGroup()
    grpView:insert(grpCountry)
    local function bntCountryRelease()
        if not isLoadingRanking then
            _hideRanking(true, 4)
        end
        return true
    end
    local bntCountry = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 33,
        onRelease = bntCountryRelease
    }
    grpCountry:insert(bntCountry)
    grpCountry.anchorX, grpCountry.anchorY = 1, 0
    grpCountry.x, grpCountry.y = Constants.RIGHT + 100, grpAllTime.y + NUM_BUTTONS_DIST_Y
    grpCountry:scale(NUM_BUTTONS_SCALE, NUM_BUTTONS_SCALE)


    local x = Constants.RIGHT - NUM_BUTTONS_POS_Y
    transition.to(grpDay, {x=x, delay=500, time=200, transition=easing.outBack, onComplete=function()
        transition.to(grpMonth, {x=x, time=200, transition=easing.outBack, onComplete=function()
            transition.to(grpAllTime, {x=x, time=200, transition=easing.outBack, onComplete=function()
                transition.to(grpCountry, {x=x, time=200, transition=easing.outBack})
            end})
        end})
    end})


    local bntMenu = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 16,
        onRelease = globals_bntBackRelease
    }


    local function bntProfileRelease()
        local options = {
            isModal = true,
            effect = "fade",
            time = 200
        }
        Composer.showOverlay("classes.phoenix.controller.scenes.Profile", options)
        return true
    end
    local bntProfile = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 17,
        onRelease = bntProfileRelease
    }


    local function bntPlayRelease(event)
        local options = {
            effect = "fade",
            time = 0,
            params = {isReload=true}
        }
        Composer.gotoScene("classes.phoenix.controller.scenes.LoadingScene", options)

        return true
    end
    local bntPlay = Wgt.newButton{
        sheet = shtButtons,
        defaultFrame = 1,
        onRelease = bntPlayRelease
    }
    transition.blink(bntPlay[2], {time=2000})


    if event.params and event.params.numTypeRanking then
        numCurrentTypeRanking = event.params.numTypeRanking
    end
    _hideRanking(true, numCurrentTypeRanking)


    Util:generateFrame(grpFrame, bntProfile, nil, bntPlay, bntMenu)


    grpFrame:toFront()
    grpDay:toFront()
    grpMonth:toFront()
    grpAllTime:toFront()
    grpCountry:toFront()
end


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase

    if phase == "will" then

        Composer.stage.alpha = 1

        globals_bntBackRelease = bntBackRelease

    elseif phase == "did" then

        Controller:setStatus(0)

    end
end


function objScene:hide(event)
    local grpView = self.view
    local phase = event.phase

    if phase == "did" then

        globals_bntBackRelease = bntBackRelease

    end
end


objScene:addEventListener("create", objScene)
objScene:addEventListener("show", objScene)
objScene:addEventListener("hide", objScene)


return objScene