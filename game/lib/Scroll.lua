local Constants = require "classes.phoenix.business.Constants"

local Scroll = {}

local abs = math.abs
local huge = math.huge

local function _showScrollbar(self)
    if self.objTarget.height == nil then
        self:stopanimation()
        return 
    end
    if self.objTarget.height > display.actualContentHeight - 40 then
        self.viewableRatio = self.visibleHeight / self.objTarget.height
        self.rctScroll.height = self.visibleHeight * self.viewableRatio
        --[[
        if self.viewableRatio < 1 then
            transition.to(self.rctScroll, {alpha=.5, time=400})
        end
        --]]
    end
end

local function _moveScrollbar(self)
    if self.viewableRatio ~= huge and self.rctScroll.height ~= nil then
        self.rctScroll.y = -self.objTarget.y * self.viewableRatio + self.border + self.rctScroll.height * .5 - self.bottomDistance
    end
end

local function _hideScrollbar(self)
    transition.to(self.rctScroll, {alpha=0, time=400})
end

local function _stopanimation(self)
    if self.animationtimer ~= nil then timer.cancel(self.animationtimer) end
    self.animationtimer = nil
    --self:hideScrollbar()
end

local function _updatescrollview(self)
    if self.objTarget.y == nil then
        self:stopanimation()
    else
        self.position = self.objTarget.y - self.topDistance
    end

    -- If mouse is still down, just scroll instantly to point
    if (self.mousedownpoint) then
        -- First assume not beyond limits
        local displacement = self.currentmousepoint - self.translatedmousedownpoint
        self.velocity = displacement / self.animationtimestep
        self.translatedmousedownpoint = self.currentmousepoint

        -- If scrolled beyond top or bottom, dampen velocity to prevent going
        -- beyond bounce height
        if ((self.position > 0 and self.velocity > 0) or (self.position < -self.scrollrange and self.velocity < 0)) then
            local displace = (self.position > 0 and self.position or self.position + self.scrollrange)
            self.velocity = self.velocity * (1 - abs(displace) / self.bounceheight)
        end
    else
        if (self.position > 0) then
            -- If reach the top bound, bounce back
            if (self.velocity <= 0) then
                -- Return to 0 self.position
                self.velocity = -1 * self.returntobaseconst * abs(self.position)
            else
                -- Slow down in order to turn around
                local change = self.bouncedecelerationconst * self.animationtimestep
                self.velocity = self.velocity - change
            end
            --self:hideScrollbar()
        elseif (self.position < -self.scrollrange) then
            -- If reach bottom bound, bounce back
            if (self.velocity >= 0) then
                -- Return to bottom self.position
                self.velocity = self.returntobaseconst * abs(self.position + self.scrollrange)
            else
                -- Slow down
                local change = self.bouncedecelerationconst * self.animationtimestep
                self.velocity = self.velocity + change
            end
            --self:hideScrollbar()
        else
            -- Free scrolling. Decelerate gradually.
            local changevelocity = self.decelerationconst * self.animationtimestep
            if (changevelocity > abs(self.velocity)) then
                self.velocity = 0
                self:stopanimation()
            else
                self.velocity = self.velocity - (self.velocity > 0 and 1 or -1) * changevelocity
            end
        end

    end

    self:showScrollbar()

    -- Update self.position
    self.position = self.position + self.velocity * self.animationtimestep

    -- Update view
    self.objTarget.y = self.position + self.topDistance
    if self.isWithMask then
        self.objTarget.maskY = -self.objTarget.y + self.maskHeight * .5 + self.displayfactor + 61 -- + Constants.TOP --+ self.topDistance
    end

    -- Update scroll
    self:moveScrollbar()
end

local function _updaterange(self)
    if self.objTarget then
        self.scrollrange = abs(self.objTarget.height - self.visibleHeight)
    end
end

local function _scrollviewdown(self, e)
    if self.animationtimer ~= nil then self:stopanimation() end
    self:updaterange()
    self.mousedownpoint = e.y
    self.translatedmousedownpoint = self.mousedownpoint
    self.currentmousepoint = self.mousedownpoint
    self.animationtimer = timer.performWithDelay(self.animationtimestep, function() self:updatescrollview() end, 0)
end

local function _scrollviewup(self)
    self.mousedownpoint = nil
    self.currentmousepoint = nil
    self.translatedmousedownpoint = nil
end

local function _scrollviewmove(self, e)
    if not self.mousedownpoint then return end
    self.currentmousepoint = e.y
end

local function _turnOff(self, isOff)
	self.isActive = not isOff
    if isOff ~= nil and not isOff and self.objTarget.height > display.actualContentHeight - 60 then
        self.objSource:addEventListener("touch", self.objSource)
        if self.rctScroll.trtCancel ~= nil then
            transition.cancel(self.rctScroll.trtCancel)
            self.rctScroll.trtCancel = nil
        end
        self.rctScroll.trtCancel = transition.to(self.rctScroll, {alpha=1, delay=1000, time=500})
    else
        self.objSource:removeEventListener("touch", self.objSource)
        if self.rctScroll.trtCancel ~= nil then
            transition.cancel(self.rctScroll.trtCancel)
            self.rctScroll.trtCancel = nil
        end
        self.rctScroll.alpha = 0
    end
    self:scrollviewdown({})
end

function Scroll:new(params)
    local tbl = {}
    if (params ~= nil) then tbl = params end

    if tbl.objSource == nil then tbl.objSource = tbl.objTarget end
    if tbl.numScrollX == nil then tbl.numScrollX = display.actualContentWidth + (display.contentWidth - display.actualContentWidth) * .5 end
    if tbl.isWithMask == nil then tbl.isWithMask = true end

    local object = {}
    object.isWithMask = tbl.isWithMask
    object.displayfactor = (display.contentHeight - display.actualContentHeight) * .5
    object.objSource = tbl.objSource
    object.objTarget = tbl.objTarget
    object.position = 0
    object.topDistance = tbl.isWithMask and 60 + object.displayfactor or object.displayfactor
    object.bottomDistance = tbl.isWithMask and 5 + object.displayfactor or 25 - object.displayfactor
    object.maskHeight = tbl.isWithMask and 300 or display.actualContentHeight

    object.border = object.topDistance + object.bottomDistance
    object.visibleHeight = object.maskHeight - object.border

    object.scrollrange = nil
    object.bounceheight = 50
    object.animationtimestep = 1/15
    object.mousedownpoint = nil
    object.translatedmousedownpoint = nil
    object.currentmousepoint = nil
    object.animationtimer = nil
    object.velocity = 0
    object.returntobaseconst = 5
    object.decelerationconst = 100
    object.bouncedecelerationconst = 2000

    if tbl.isWithMask then
        local mask = graphics.newMask("images/ui/scnListMask.png")
        object.objTarget:setMask(mask)
    end

    local rctScroll = display.newRect(0,0, 2,1)
    rctScroll.anchorX, rctScroll.anchorY = 1, 0
    rctScroll:setFillColor(1, 1, 1)
    rctScroll.x = tbl.numScrollX
    --rctScroll.alpha = 0
    object.rctScroll = rctScroll
    object.objSource:insert(object.rctScroll)
    object.isActive = false

    object.viewableRatio = 0

    object.showScrollbar = _showScrollbar
    object.moveScrollbar = _moveScrollbar
    object.hideScrollbar = _hideScrollbar
    object.stopanimation = _stopanimation
    object.updaterange = _updaterange
    object.updatescrollview = _updatescrollview
    object.scrollviewdown = _scrollviewdown
    object.scrollviewup = _scrollviewup
    object.scrollviewmove = _scrollviewmove
    object.turnOff = _turnOff

    local function _onTouch(self, event)
        local phase = event.phase
        if phase == "began" then
            object:scrollviewdown(event)
        elseif phase == "moved" then
            object:scrollviewmove(event)
        else
            object:scrollviewup()
        end
        return true
    end
    object.objSource.touch = _onTouch
    object.objSource:addEventListener("touch", object.objSource)

    object:updaterange()
    object:turnOff()

    return object
end

return Scroll