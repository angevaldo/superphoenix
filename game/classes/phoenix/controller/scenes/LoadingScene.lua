local Composer = require "composer"
local objScene = Composer.newScene()


local Controller = require "classes.phoenix.business.Controller"
local Util = require "classes.phoenix.business.Util"


local Trt = require "lib.Trt"


function objScene:show(event)
    local grpView = self.view
    local phase = event.phase

    if phase == "will" then

        globals_bntBackRelease = nil

    elseif phase == "did" then

        -- REMOVE STATUS BAR
        Util:hideStatusbar()

        -- clean memory
        Composer:removeHidden(false) -- clean textures and variables/tables
        Composer:removeScene("classes.phoenix.controller.scenes.GamePlay") -- force clean gameplay
        Trt.cancelAll() -- clean animes transitions
        collectgarbage()

        -- setting default
        local params = event.params
        if (params == nil) then
            params = {}
        end
        if (params.scene == nil) then
            params.scene = "classes.phoenix.controller.scenes.GamePlay"
        end

        local options = {
            effect = "crossFade",
            time = 500,
            params = params
        }
        transition.to(grpView, {time=100, onComplete=function()
            Composer.gotoScene(params.scene, options)
        end})


    end
end


objScene:addEventListener("show", objScene)


return objScene