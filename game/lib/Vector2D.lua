local Vector2D = {}

local round = math.round
local cos = math.cos
local sin = math.sin
local abs = math.abs
local acos = math.acos
local atan2 = math.atan2
local sqrt = math.sqrt

function Vector2D:new(x, y)
    local object = {x = x, y = y}
    setmetatable(object, {__index = Vector2D})
    return object
end

function Vector2D:copy()
    return Vector2D:new(self.x, self.y)
end

function Vector2D:copyTo(otherVector)
    otherVector.x = self.x
    otherVector.y = self.y
end

function Vector2D:magnitude()
    return sqrt(self.x*self.x + self.y*self.y)
end

function Vector2D:normalize()
    local temp
    temp = self:magnitude()
    if temp > 0 then
        self.x = self.x / temp
        self.y = self.y / temp
    end
end

function Vector2D:limit(l)
    if self.x > l then
        self.x = l
    end

    if self.y > l then
        self.y = l
    end
end

function Vector2D:equals(vec)
    if self.x == vec.x and self.y == vec.y then
        return true
    else
        return false
    end
end

function Vector2D:add(vec)
    self.x = self.x + vec.x
    self.y = self.y + vec.y
end

function Vector2D:sub(vec)
    self.x = self.x - vec.x
    self.y = self.y - vec.y
end

function Vector2D:subScalar(sx, sy)
    self.x = self.x < 0 and (self.x + sx) or (self.x - sx)
    self.y = self.y < 0 and (self.y + sy) or (self.y - sy)
end

function Vector2D:mult(s)
    self.x = self.x * s
    self.y = self.y * s
end

function Vector2D:div(s)
    self.x = self.x / s
    self.y = self.y / s
end

function Vector2D:dot(vec)
    return self.x * vec.x + self.y * vec.y
end

function Vector2D:dist(vec2)
    local x = (vec2.x - self.x)
    local y = (vec2.y - self.y)
    return sqrt(x*x + y*y)
end

function Vector2D:rotateVector(angle)
    angle = angle * 0.017453292519943295769236907684886
    local s = sin(angle)
    local c = cos(angle)
    self.x = (self.x * c - self.y * s)--round
    self.y = (self.x * s + self.y * c)--round
end

-- Class Methods

function Vector2D:Normalize(vec)
    local tempVec = Vector2D:new(vec.x,vec.y)
    local temp = tempVec:magnitude()
    if temp > 0 then
        tempVec.x = tempVec.x / temp
        tempVec.y = tempVec.y / temp
    end
    return tempVec
end

function Vector2D:Limit(vec,l)
    local tempVec = Vector2D:new(vec.x,vec.y)

    if tempVec.x > l then
        tempVec.x = l
    end

    if tempVec.y > l then
        tempVec.y = l
    end

    return tempVec
end

function Vector2D:Add(vec1, vec2)
    return Vector2D:new(vec1.x + vec2.x, vec1.y + vec2.y)
end

function Vector2D:Sub(vec1, vec2)
    return Vector2D:new(vec1.x - vec2.x, vec1.y - vec2.y)
end

function Vector2D:Mult(vec, s)
    return Vector2D:new(vec.x * s, vec.y * s)
end

function Vector2D:ProdScalar(vec1, vec2)
    return vec1.x * vec2.x + vec1.y * vec2.y
end

function Vector2D:Deg(vec1, vec2)
    local mag1 = vec1:magnitude()
    local mag2 = vec2:magnitude()
    if (mag1 < 1 or mag2 < 1) then
        return 0
    end
    local prod = Vector2D:ProdScalar(vec1, vec2)/(mag1 * mag2)
    return acos(prod) * 57.295779513082320876798154814105
end

function Vector2D:Div(vec, s)
    return Vector2D:new(vec.x / s, vec.y / s)
end

function Vector2D:Dist(vec1, vec2)
    local x = vec2.x - vec1.x
    local y = vec2.y - vec1.y
    return sqrt(x*x + y*y)
end

function Vector2D:Rad2vec(r, m)
    -- if not m then m = 1 end
    local v = Vector2D:new(cos(r), sin(r))
    v:normalize()
    v:mult(m)
    return v
end

function Vector2D:Deg2vec(r, m)
    -- if not m then m = 1 end
    return Vector2D:Rad2vec(r * 0.017453292519943295769236907684886, m)
end

function Vector2D:Vec2rad(vec)
    return atan2(vec.y, vec.x)
end

function Vector2D:Vec2deg(vec)
    return Vector2D:Vec2rad(vec) * 57.295779513082320876798154814105
end

function Vector2D:RotateVector(vec, angle)
    angle = angle * 0.017453292519943295769236907684886
    local s = sin(angle)
    local c = cos(angle)
    return Vector2D:new((vec.x * c - vec.y * s), (vec.x * s + vec.y * c))--Vector2D:new(round(vec.x * c - vec.y * s), round(vec.x * s + vec.y * c))
end

function Vector2D:RotateAddVector(vec, a, s)
    return Vector2D:Add(vec, Vector2D:Deg2vec(a, s))
end

--[[
function Vector2D:GetNormalPoint(p, a, b)
    local ap = Vector2D:Sub(p, a)
    local ab = Vector2D:Sub(b, a)
    ab:normalize()
    ab:mult(ap:dot(ab))
    return Vector2D:Add(a, ab)
end
--]]

return Vector2D