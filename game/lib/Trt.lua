local Trt = {}
Trt.timeScale = 1

local stack = {}

local sin = math.sin
local asin = math.asin
local cos = math.cos
local sqrt = math.sqrt
local abs = math.abs
local PI = math.pi
local pow = math.pow

local transitFunc

local cancel,pause,resume,cancelAll,pauseAll,resumeAll,to,timeScaleAll

local eas = {}

eas["linear"] = function(t,b,c,d)
    return c*t/d+b
end

eas["inQuad"] = function(t,b,c,d)
    t=t/d
    return c*t*t + b
end

eas["outQuad"] = function(t,b,c,d)
    t=t/d
    return (-c)*t*(t-2) + b
end

eas["inOutQuad"] = function(t,b,c,d)
    t=2*t/d
    if t < 1 then
        return c*0.5*t*t + b
    end
    t=t-1
    return (-c)*0.5*((t)*(t-2)-1) + b
end

eas["inCubic"] = function(t,b,c,d)
    return c*((t/d)^3) + b
end

eas["outCubic"] = function(t,b,c,d)
    return c*(((t/d-1)^3)+1) + b
end

eas["inOutCubic"] = function(t,b,c,d)
    t=2*t/d
    if t<1 then
        return c*0.5*(t^3) + b;
    end
    return c*0.5*(((t-2)^3)+2) + b;
end

eas["inQuart"] = function(t,b,c,d)
    t=t/d
    return c*(t^4) + b;
end

eas["outQuart"] = function(t,b,c,d)
    return -c*(((t/d-1)^4)-1) + b
end

eas["inOutQuart"] = function(t,b,c,d)
    t=2*t/d
    if t < 1 then
        return c*0.5*(t^4) + b
    end
    return -c*0.5*(((t-2)^4)-2) + b
end

eas["inQuint"] = function(t,b,c,d)
    return c*((t/d)^5) + b
end

eas["outQuint"] = function(t,b,c,d)
    return c*((t/d-1)^5+1) + b
end

eas["inOutQuint"] = function(t,b,c,d)
    t=2*t/d
    if t<1 then
        return c*0.5*(t^5) + b
    end
    return c*0.5*((t-2)^5+2) + b
end

eas["inExpo"] = function(t,b,c,d)
    if t == 0 then
        return b
    else
        return c*(2^(10*(t/d-1))) + b
    end
end

eas["outExpo"] = function(t,b,c,d)
    if t==d then
        return b+c
    else
        return c*(-2^(-10*t/d)+1) + b
    end
end

eas["inOutExpo"] = function(t,b,c,d)
    if t==0 then return b end
    if t==d then return b+c end

    t=2*t/d
    if t<1 then
        return c*0.5*(2^(10*(t-1))) + b
    end
    t=t-1
    return c*0.5*(2-(2^(-10*t))) + b;
end

eas["inSine"] = function(t,b,c,d)
    return -c*cos(t/d*PI*0.5) + c + b
end

eas["outSine"] = function(t,b,c,d)
    return c*sin(t/d*PI*0.5) + b
end

eas["inOutSine"] = function(t,b,c,d)
    return -c*0.5*(cos(PI*t/d)-1) + b
end

eas["inCirc"] = function(t,b,c,d)
    t=t/d
    return -c*(sqrt(1-t*t)-1) + b
end

eas["outCirc"] = function(t,b,c,d)
    t=t/d-1
    return c*sqrt(1-t*t) + b;
end

eas["inOutCirc"] = function(t,b,c,d)
    t=2*t/d
    if t<1 then
        return -c*0.5*(sqrt(1 - t*t)-1) + b
    end
    t=t-2
    return c*0.5*(sqrt(1-t*t)+1) + b
end

eas["inBack"] = function(t,b,c,d)
    local s = 1.70158

    t=t/d
    return c*t*t*((s+1)*t-s) + b
end

eas["outBack"] = function(t,b,c,d)
    local s = 1.70158

    t=t/d-1
    return c*(t*t*((s+1)*t+s)+1) + b
end

eas["inOutBack"] = function(t,b,c,d)
    local s = 1.70158

    t=2*t/d
    if t<1 then
        s=s*1.525
        return c*0.5*(t*t*((s+1)*t-s)) + b
    end

    t=t-2
    s=s*1.525
    return c*0.5*(t*t*((s+1)*t+s) +2) + b
end

eas["outBounce"] = function(t,b,c,d)
    t=t/d
    if t<(1/2.75) then
        return c*(7.5625*t*t) + b
    elseif t < (2/2.75) then
        t=t-(1.5/2.75)
        return c*(7.5625*t*t+0.75) + b
    elseif t < (2.5/2.75) then
        t=t-(2.25/2.75)
        return c*(7.5625*t*t+0.9375) + b
    else
        t=t-(2.625/2.75)
        return c*(7.5625*t*t+0.984375) + b
    end
end

eas["inBounce"] = function(t,b,c,d)
    return c-eas["outBounce"](d-t,0,c,d) + b
end

eas["inOutBounce"] = function(t,b,c,d)
    if t < d/2 then
        return eas["inBounce"](t*2, 0, c, d)*0.5 + b
    end

    return eas["outBounce"](t*2-d,0,c,d)*0.5+c*0.5 + b
end

local function cancel(th)
    local index =  #stack

    while stack[index] ~= th and index > 0 do
        index = index - 1
    end

    Runtime:removeEventListener("enterFrame", th)

    table.remove(stack, index)
    th = nil
end

local function pause(th)
    if th then
        th.isActive = false
    end
end

local function resume(th)
    if th then
        th.isActive = true
    end
end

local transitFunc = function(self,e)
    local eTime = e.time

    -- only carry out animation when unpaused
    if self.isActive then
        local deltaTime = eTime - self.prevTime
        local obj = self.obj

        -- execute onStart Listener if assigned
        if self.onStart then
            self.onStart(obj)
            self.onStart = nil
        end

        deltaTime = deltaTime * self.timeScale          -- timeScale parameter allows slowing and increasing speed of animation on the fly
        self.timePassed = self.timePassed + deltaTime

        -- check if object has been removed
        if obj.x then
            -- make sure delay has passed
            if self.timePassed-self.delay > 0 then
                local timePassed = self.timePassed - self.delay
                -- check if end point reached, ensure object is at required position
                if timePassed >= self.time then
                    if self.x then
                        obj:translate(self.endX-obj.x,0)
                    end

                    if self.y then
                        obj:translate(0,self.endY-obj.y)
                    end

                    if self.width then
                        obj.width = self.endWidth
                    end

                    if self.height then
                        obj.height = self.endHeight
                    end

                    if self.xScale then
                        obj.xScale = self.endxS
                    end

                    if self.yScale then
                        obj.yScale = self.endyS
                    end

                    if self.alpha then
                        obj.alpha = self.endAlpha
                    end

                    if self.rotation then
                        obj:rotate(self.endRot-obj.rotation)
                    end

                    --[[
                    if self.maskX then
                        obj.maskX = self.endmX
                    end

                    if self.maskY then
                        obj.maskY = self.endmY
                    end

                    if self.maskScaleX then
                        obj.maskScaleX = self.endmxS
                    end

                    if self.maskScaleY then
                        obj.maskScaleY = self.endmyS
                    end

                    if self.maskRotation then
                        obj.maskRotation = self.endmRot
                    end

                    if self.onFrac then
                        if self.onFrac.fraction <= 1 then           -- makes sure fractional listener is executed in cases whereby framerate drops, if it's within animation time
                            self.onFrac.listener(obj)
                        end
                    end
                    --]]

                    if self.onComplete then
                        self.onComplete(obj)
                    end

                    cancel(self)
                    self=nil
                else
                    --[[
                    -- check for fractional listener
                    if self.onFrac then
                        if timePassed/self.time >= self.onFrac.fractionTotal then
                            self.onFrac.listener(obj)
                            self.onFrac.fractionTotal = self.onFrac.fractionTotal + self.onFrac.fraction
                            --self.onFrac = nil
                        end
                    end
                    --]]

                    -- change parameters if assigned
                    if self.x then
                        obj:translate(self.transition(timePassed,self.x,self.dX,self.time)-obj.x,0)
                    end

                    if self.y then
                        obj:translate(0,self.transition(timePassed,self.y,self.dY,self.time)-obj.y)
                    end

                    if self.width then
                        obj.width = self.transition(timePassed,self.width,self.dWidth,self.time)
                    end

                    if self.height then
                        obj.height = self.transition(timePassed,self.height,self.dHeight,self.time)
                    end

                    if self.xScale then
                        obj.xScale = self.transition(timePassed,self.xScale,self.dxS,self.time)
                    end

                    if self.yScale then
                        obj.yScale = self.transition(timePassed,self.yScale,self.dyS,self.time)
                    end

                    if self.alpha then
                        obj.alpha = self.transition(timePassed,self.alpha,self.dA,self.time)
                    end

                    if self.rotation then
                        obj:rotate(self.transition(timePassed,self.rotation,self.dRot,self.time)-obj.rotation)
                    end

                    --[[
                    if self.maskX then
                        obj.maskX = self.transition(timePassed,self.maskX,self.dmX,self.time)
                    end

                    if self.maskY then
                        obj.maskY = self.transition(timePassed,self.maskY,self.dmY,self.time)
                    end

                    if self.maskScaleX then
                        obj.maskScaleX = self.transition(timePassed,self.maskScaleX,self.dmxS,self.time)
                    end

                    if self.maskScaleY then
                        obj.maskScaleY = self.transition(timePassed,self.maskScaleY,self.dmyS,self.time)
                    end

                    if self.maskRotation then
                        obj.maskRotation = self.transition(timePassed,self.maskRotation,self.dmRot,self.time)
                    end
                    --]]
                end
            end
        else
            -- kill enterFrame listener ie. transition if object has been removed
            --print("Transition Warning: Object Missing. Cancelling transition.")
            cancel(self)
            self=nil
        end
    end

    if self then
        self.prevTime = eTime
    end
end

-- replacing the transition.to function
local function to(obj,p)
    local th = {}

    -- setting up flags for required changes
    -- check for delta parameter
    if p.delta then
        if p.x then th.x = obj.x; th.endX = p.x + obj.x; th.dX = p.x; end
        if p.y then th.y = obj.y; th.endY = p.y + obj.y; th.dY = p.y; end
        if p.width then th.width = obj.width; th.endWidth = p.width + obj.width; th.dWidth = p.width; end
        if p.height then th.height = obj.height; th.endHeight = p.height + obj.height; th.dHeight = p.height; end
        if p.xScale then th.xScale = obj.xScale; th.endxS = p.xScale + obj.xScale; th.dxS = p.xScale; end
        if p.yScale then th.yScale = obj.yScale; th.endyS = p.yScale + obj.yScale; th.dyS = p.yScale; end
        if p.alpha then th.alpha = obj.alpha; th.endAlpha = p.alpha + obj.alpha; th.dA = p.alpha; end
        if p.rotation then th.rotation = obj.rotation; th.endRot = p.rotation + obj.rotation; th.dRot = p.rotation; end
        --[[
        if p.maskX then th.maskX = obj.maskX; th.endmX = p.maskX + obj.maskX; th.dmX = p.maskX; end
        if p.maskY then th.maskY = obj.maskY; th.endmY = p.maskY + obj.maskY; th.dmY = p.maskY; end
        if p.maskScaleX then th.maskScaleX = obj.maskScaleX; th.endmxS = p.maskScaleX + obj.maskScaleX; th.dmxS = p.maskScaleX; end
        if p.maskScaleY then th.maskScaleY = obj.maskScaleY; th.endmyS = p.maskScaleY + obj.maskScaleY; th.dmyS = p.maskScaleY; end
        if p.maskRotation then th.maskRotation = obj.maskRotation; th.endmRot = p.maskRotation + obj.maskRotation; th.dmRot = p.maskRotation; end
        --]]
    else
        if p.x then th.x = obj.x; th.endX = p.x; th.dX = p.x - obj.x; end
        if p.y then th.y = obj.y; th.endY = p.y; th.dY = p.y - obj.y; end
        if p.width then th.width = obj.width; th.endWidth = p.width; th.dWidth = p.width - obj.width; end
        if p.height then th.height = obj.height; th.endHeight = p.height; th.dHeight = p.height - obj.height; end
        if p.xScale then th.xScale = obj.xScale; th.endxS = p.xScale; th.dxS = p.xScale - obj.xScale; end
        if p.yScale then th.yScale = obj.yScale; th.endyS = p.yScale; th.dyS = p.yScale - obj.yScale; end
        if p.alpha then th.alpha = obj.alpha; th.endAlpha = p.alpha; th.dA = p.alpha - obj.alpha; end
        if p.rotation then th.rotation = obj.rotation; th.endRot = p.rotation; th.dRot = p.rotation - obj.rotation; end
        --[[
        if p.maskX then th.maskX = obj.maskX; th.endmX = p.maskX; th.dmX = p.maskX - obj.maskX; end
        if p.maskY then th.maskY = obj.maskY; th.endmY = p.maskY; th.dmY = p.maskY - obj.maskY; end
        if p.maskScaleX then th.maskScaleX = obj.maskScaleX; th.endmxS = p.maskScaleX; th.dmxS = p.maskScaleX - obj.maskScaleX; end
        if p.maskScaleY then th.maskScaleY = obj.maskScaleY; th.endmyS = p.maskScaleY; th.dmyS = p.maskScaleY - obj.maskScaleY; end
        if p.maskRotation then th.maskRotation = obj.maskRotation; th.endmRot = p.maskRotation; th.dmRot = p.maskRotation - obj.maskRotation; end
        --]]
    end

    -- animation parameters
    th.transition = eas[p.transition] or eas["linear"]
    th.isLocked = p.isLocked or false
    th.type = p.type or nil
    th.time = p.time or 500
    th.delay = p.delay or 0
    th.onStart = p.onStart or false
    th.onComplete = p.onComplete or false
    --[[
    if p.onFrac then
        th.onFrac = p.onFrac
        th.onFrac.fractionTotal = th.onFrac.fraction
    else
        th.onFrac = false
    end
    --]]
    th.timeScale = Trt.timeScale
    th.prevTime = system.getTimer()
    th.timePassed = 0

    -- control parameters
    th.isActive = true
    th.obj = obj

    -- start enterFrame listener
    th.enterFrame = transitFunc
    Runtime:addEventListener("enterFrame", th)

    -- add to stack
    stack[#stack+1] = th

    -- return handle
    return th
end

local function cancelType(type)
    if #stack > 0 then
        for i=#stack,1,-1 do
            if stack[i] and stack[i].type == type then
                cancel(stack[i])
                stack[i] = nil
            end
        end
    end
end

local function pauseType(type)
    if #stack > 0 then
        for i=#stack,1,-1 do
            if stack[i] and stack[i].type == type then
                pause(stack[i])
            end
        end
    end
end

local function resumeType(type)
    if #stack > 0 then
        for i=#stack,1,-1 do
            if stack[i] and stack[i].type == type then
                resume(stack[i])
            end
        end
    end
end

local function pauseAll()
    if #stack > 0 then
        for i=#stack,1,-1 do
            if stack[i] then
                pause(stack[i])
            end
        end
    end
end

local function resumeAll()
    if #stack > 0 then
        for i=#stack,1,-1 do
            if stack[i] then
                resume(stack[i])
            end
        end
    end
end

local function cancelUnlocked()
    if #stack > 0 then
        for i=#stack,1,-1 do
            if stack[i] and not stack[i].isLocked then
                cancel(stack[i])
                stack[i] = nil
            end
        end
    end
end

local function cancelAll()
    if #stack > 0 then
        for i=#stack,1,-1 do
            if stack[i] then
                cancel(stack[i])
                stack[i] = nil
            end
        end
        stack = {}
    end
end

local function timeScaleAll(timeScale)
    Trt.timeScale = timeScale
    if #stack > 0 then
        for i=#stack,1,-1 do
            if stack[i] then
                stack[i].timeScale = timeScale
            end
        end
    end
end

Trt.cancel = cancel
Trt.pause = pause
Trt.resume = resume
Trt.to = to
Trt.cancelType = cancelType
Trt.pauseType = pauseType
Trt.resumeType = resumeType
Trt.cancelUnlocked = cancelUnlocked
Trt.cancelAll = cancelAll
Trt.pauseAll = pauseAll
Trt.resumeAll = resumeAll
Trt.timeScaleAll = timeScaleAll

return Trt