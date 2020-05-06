local Jukebox = require "classes.phoenix.business.Jukebox"
local Constants = require "classes.phoenix.business.Constants"


local infUtilUi = require("classes.infoUtilUi")
local shtUtilUi = graphics.newImageSheet("images/ui/scnUtilUi.png", infUtilUi:getSheet())


local Message = {}

local _tblMessagesStash = {}

local _grpMessage = display.newGroup()
_grpMessage.isVisible = false

local _txtMessage = display.newText(_grpMessage, "", 0, 0, "Maassslicer", 11)
_txtMessage:setFillColor(1, 1, 1)
_txtMessage.anchorX, _txtMessage.anchorY = .5, .5
_txtMessage.x, _txtMessage.y = 0, -1

local _imgCheck = display.newSprite(shtUtilUi, {{name="standard", start=7, count=2}})
_imgCheck:setFillColor(1, 1, 1)
_imgCheck.anchorX, _imgCheck.anchorY = .5, .5
_imgCheck.x, _imgCheck.y = 0, 0
_grpMessage:insert(_imgCheck)

local _grpCoins = display.newGroup()
_grpMessage:insert(_grpCoins)

local _txtCoins = display.newText({parent = _grpCoins, text = "", font = "Maassslicer", fontSize = 13, align = "right"})
_txtCoins:setFillColor(1, 1, .2)
_txtCoins.anchorX, _txtCoins.anchorY = 1, .5
_txtCoins.x, _txtCoins.y = 0, -1
_grpCoins:insert(_txtCoins)

local _imgCoin = display.newSprite(shtUtilUi, {{name="standard", start=10, count=1}})
_imgCoin.anchorX, _imgCoin.anchorY = 0, .5
_imgCoin.x, _imgCoin.y = 0, -2
_grpCoins:insert(_imgCoin)
_grpCoins.anchorChildren = true
_grpCoins.anchorX, _grpCoins.anchorY = .5, .5
_grpCoins.x, _grpCoins.y = 0, -2
_grpCoins.isVisible = false
_grpMessage.anchorX, _grpMessage.anchorY = .5, 1
_grpMessage.x, _grpMessage.y = display.contentCenterX, Constants.BOTTOM + 25

local function _showNextMessage()
    if not _grpMessage.isVisible then
        local numReward = _tblMessagesStash[1].numReward or 0
        local numDelay = _tblMessagesStash[1].numDelay or 2000

        _txtMessage.text = _tblMessagesStash[1].text
        _txtCoins.text = " +"..numReward

        _grpMessage.onComplete = _tblMessagesStash[1].onComplete

        _imgCheck:setFrame(#_txtMessage.text > 0 and 2 or 1)
        _imgCheck.isVisible = false
        _grpMessage.y, _grpMessage.isVisible = Constants.BOTTOM + 30, true

        Jukebox:dispatchEvent({name="playSound", id="achievement"})

        local _yTo = #_txtMessage.text > 0 and (Constants.BOTTOM - 5) or (Constants.BOTTOM - 12)
        transition.to(_grpMessage, {y=_yTo, alpha=1, time=200, transition=easing.outBack})

        _grpCoins.x, _grpCoins.xScale, _grpCoins.yScale, _grpCoins.isVisible, _grpCoins.alpha = _txtMessage.x - _txtMessage.width * .5 - _grpCoins.width * .5 - 10, .1, .1, numReward > 0, 0
        local numTime = numReward > 0 and 1000 or 1
        transition.to(_grpCoins, {alpha=1, xScale=1, yScale=1, delay=50, transition=easing.outElastic, time=numTime, onComplete=function()

	        Jukebox:dispatchEvent({name="playSound", id="ok"})

            _imgCheck.x, _imgCheck.xScale, _imgCheck.yScale, _imgCheck.isVisible = #_txtMessage.text > 0 and (_txtMessage.x + _txtMessage.width * .5 + 20) or 0, .1, .1, true
            transition.to(_imgCheck, {xScale=1, yScale=1, transition=easing.outElastic, time=700, onComplete=function()
                transition.to(_grpMessage, {delay=numDelay, time=250, y=Constants.BOTTOM + 30, transition=easing.inBack, onComplete=function()

                    _grpCoins.xScale, _grpCoins.yScale, _grpCoins.isVisible = .1, .1, false
                    _imgCheck.xScale, _imgCheck.yScale, _imgCheck.isVisible = .1, .1, false
                    _grpMessage.isVisible = false

                    if _grpMessage.onComplete then
                        _grpMessage.onComplete()
                    end

                end})
            end})

        end})

        table.remove (_tblMessagesStash, 1)
    end

    if #_tblMessagesStash > 0 then
        timer.performWithDelay(1000, _showNextMessage, 1)
    end
end

local function addMessage(self, params)
    _tblMessagesStash[#_tblMessagesStash+1] = params
    _showNextMessage()
end


Message.addMessage = addMessage


--[[]
-- TESTING MESSAGES
for i=1, 25 do Message:addMessage({text="TESTING MSG "..(300*i), numReward=300*i}) end
--]]


return Message