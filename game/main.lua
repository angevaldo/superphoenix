-- hidden bar
local Util = require "classes.phoenix.business.Util"
Util:hideStatusbar()

-- global functions
globals_bntBackRelease = function(event) end

-- prepare screen
display.setDefault("background", 0)
system.activate("multitouch")

-- init ads
globals_adCallbackListener = function(params) end
local AdsGame = require "classes.phoenix.business.AdsGame"
AdsGame:init()


-- load first scene
local Composer = require "composer"
Composer.gotoScene("classes.phoenix.controller.scenes.LoadingGameIn")

-- clean memory
local function _onMemoryWarning( event )
	Composer:removeHidden(false)
end
Runtime:addEventListener("memoryWarning", _onMemoryWarning)

-- FACEBOOK CAMPAINS REGISTRATION
local facebook = require "plugin.facebook.v4"
facebook.publishInstall()

-------------------------------------

-- DEBUGS (DESACTIVATE ON PRODUCTION)
--[[]
-- MEMORY
local Constants = require "classes.phoenix.business.Constants"
local performance = require "lib.Performance"
performance:newPerformanceMeter()
performance.text.anchorX, performance.text.anchorY = 1, 1
performance.text.x, performance.text.y = Constants.RIGHT, Constants.BOTTOM - 60
performance.text.alpha = .3
--]]
--[[]
-- GLOBALS
local _TBL_RESERVED = {"_G","_network_pathForFile","mime","ltn12","socket","_VERSION","al","assert","audio","collectgarbage","coronabaselib","coroutine","debug","display","dofile","easing","error","gcinfo","getfenv","getmetatable","graphics","io","ipairs","lfs","load","loadfile","loadstring","lpeg","math","media","metatable","module","native","network","newproxy","next","os","package","pairs","pcall","physics","print","rawequal","rawget","rawset","require","Runtime","select","setfenv","setmetatable","string","system","table","timer","tonumber","tostring","transition","type","unpack","xpcall"}
for k, v in pairs( _G ) do
	local isReserved = false
	for i, j in pairs( _TBL_RESERVED ) do
		if k == j then
			isReserved = true
			break
		end
	end
	if not isReserved then
	   print( k .. " => ", v )
	end
end
--]]