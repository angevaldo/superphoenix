-- FALSE ON PRODUCTION
local showRuntimeErrors = false

-- DYNAMIC FPS
local sysAdjustedFPS = 30

-- APPLE
local infoApple = system.getInfo("architectureInfo")
local tblApplesMin = {}
tblApplesMin["iPhone"] = 5.3
tblApplesMin["iPad"] = 4.1
tblApplesMin["iPod"] = 5.1
for k, v in pairs(tblApplesMin) do
	local pos = infoApple:find(k)
	if pos ~= nil then
    	local version, numReplaced = string.gsub(infoApple:sub(#k+1, #infoApple), ",", ".")
		if tonumber(version) >= v then
			sysAdjustedFPS = 60
			break
		end
	end
end

-- ANDROID
local infoAndroid = system.getInfo("androidDisplayApproximateDpi")
if infoAndroid ~= nil and infoAndroid >= 480 then
	sysAdjustedFPS = 60
end

--[[] COMMENT FOR PRODUCTION
local strInfo = "InfoApple: "..(infoApple or "nil").."\nInfoAndroid: "..(infoAndroid or "nil").."\nSysAdjustedFPS: "..sysAdjustedFPS
native.showAlert("", strInfo, {"OK"})
--]]

-- CONFIG
application = {
    showRuntimeErrors = showRuntimeErrors,
	content = {
		width = 320,
		height = 480,
		fps = sysAdjustedFPS,
        antialias = false,
		scale = "zoomEven",
		audioPlayFrequency = 22050,
        imageSuffix = {
		    ["@2x"] = 1.5,
		    ["@4x"] = 3.0,
		}
	},
	license = {
        google = {
            key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAshTQ/EXjh7g355ztvMPRNJTEVUqI6vLGlH6bT/BwkRmZXFHJq6gBAuRjfcjnf3+NMvVby3EOJctRw86j2UGZgyuBxSY0+r1IfjPDUgq+E7BWhdwBzhL0SK20YQp4maHW6NvfSo1vjTcvPUv8sWE+TxHrY1Vd4+7PBlS8NN/+IsoLpm5KE/EHNTJX+Q2CUrS1WeH+cjQeVP+KhuMJw63j1DMoyzO4iqHEEB6ygMq0pYLYlZ8aumq1bRqdv0KsDlnjhGTcp3SFlvUjmUc+m3vnl86mRVYQpuifvOxLol4RzCXIFiSXB3UjuZsHPiobAemEvfJboF1lSFCKAZ6U2bOe6wIDAQAB",
        },
    },
}