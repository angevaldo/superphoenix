local Jukebox = display.newRect(0, 0, 1, 1)
Jukebox.isVisible = false

audio.reserveChannels(1)

local ID_CURRENT_BACKGROUND_MUSIC = 0
local CHANNEL_BACKGROUND_MUSIC = 1
local HANDLE_BACKGROUND_MUSIC = 0
local IS_PLAY_COINS = false
local TBL_MUSICS_STASH = {}
local TBL_SOUNDS_STASH = {}
local STR_EXTENSION = ".mp3"
if system.getInfo("platformName") ~= "Android" then STR_EXTENSION = ".caf" end

local function playSound(event) -- id
    audio.play(TBL_SOUNDS_STASH[event.id])
end

local function stopSound(event)
    audio.stop()
end

local function _playSoundCoins()
	if IS_PLAY_COINS then
    	audio.play(TBL_SOUNDS_STASH["coins"])
	    timer.performWithDelay(60, _playSoundCoins, 1)
	end
end

local function playSoundCoins(event)
	if not IS_PLAY_COINS then
		IS_PLAY_COINS = true
		_playSoundCoins()
	end
end

local function stopSoundCoins(event)
    IS_PLAY_COINS = false
end

local function _stopMusic()
    ID_CURRENT_BACKGROUND_MUSIC = 0

	if HANDLE_BACKGROUND_MUSIC then
	    local result = audio.stop(CHANNEL_BACKGROUND_MUSIC)
		audio.dispose(HANDLE_BACKGROUND_MUSIC)
		HANDLE_BACKGROUND_MUSIC = nil

		-- RELOADING FILES WHEN ERROR
		if result ~= 1 and #TBL_MUSICS_STASH > 0 then
			Jukebox:activateMusics(false)
			Jukebox:activateMusics(true)
		end

		return true
	end
	return false
end

local function _playMusic(id)
	if _stopMusic() then
    	_playMusic(id)
    else
	    HANDLE_BACKGROUND_MUSIC = audio.play(TBL_MUSICS_STASH[id], {channel=CHANNEL_BACKGROUND_MUSIC, loops=-1})

	    if HANDLE_BACKGROUND_MUSIC == nil then
    		_playMusic(id)
	    end  	
    end
    
    ID_CURRENT_BACKGROUND_MUSIC = id
end

local function playMusic(event) 
    if ID_CURRENT_BACKGROUND_MUSIC ~= event.id then
	    _playMusic(event.id)
	end
end

local function stopMusic(event)
	_stopMusic()
end

local function activateSounds(self, isActive)
	if isActive then
		TBL_SOUNDS_STASH = {
		    achievement = audio.loadSound("audio/achievement"..STR_EXTENSION),
		    alert = audio.loadSound("audio/alert"..STR_EXTENSION),
		    button = audio.loadSound("audio/button"..STR_EXTENSION),
		    coins = audio.loadSound("audio/coins"..STR_EXTENSION),
		    combo = audio.loadSound("audio/combo"..STR_EXTENSION),
		    countdown = audio.loadSound("audio/countdown"..STR_EXTENSION),
		    challengeExploded = audio.loadSound("audio/challengeExploded"..STR_EXTENSION),
		    challengeExploding = audio.loadSound("audio/challengeExploding"..STR_EXTENSION),
		    challengeWin = audio.loadSound("audio/challengeWin"..STR_EXTENSION),
		    bonusCollected = audio.loadSound("audio/bonusCollected"..STR_EXTENSION),
		    bonusObstacle = audio.loadSound("audio/bonusObstacle"..STR_EXTENSION),
		    flame = audio.loadSound("audio/flame"..STR_EXTENSION),
		    frozen = audio.loadSound("audio/frozen"..STR_EXTENSION),
		    gameover = audio.loadSound("audio/gameover"..STR_EXTENSION),
		    ice = audio.loadSound("audio/ice"..STR_EXTENSION),
		    iceBig = audio.loadSound("audio/iceBig"..STR_EXTENSION),
		    jump = audio.loadSound("audio/jump"..STR_EXTENSION),
		    meteory = audio.loadSound("audio/meteory"..STR_EXTENSION),
		    negation = audio.loadSound("audio/negation"..STR_EXTENSION),
		    ok = audio.loadSound("audio/ok"..STR_EXTENSION),
		    phoenix = audio.loadSound("audio/phoenix"..STR_EXTENSION),
		    phoenixExplosions = audio.loadSound("audio/phoenixExplosions"..STR_EXTENSION),
		    powerup = audio.loadSound("audio/powerup"..STR_EXTENSION),
		    starCollision1 = audio.loadSound("audio/starCollision1"..STR_EXTENSION),
		    starCollision2 = audio.loadSound("audio/starCollision2"..STR_EXTENSION),
		    starCollision3 = audio.loadSound("audio/starCollision3"..STR_EXTENSION),
		    starExplosion = audio.loadSound("audio/starExplosion"..STR_EXTENSION),
		    record = audio.loadSound("audio/record"..STR_EXTENSION),
		    recordComboBonus = audio.loadSound("audio/recordComboBonus"..STR_EXTENSION),
		    recordScore = audio.loadSound("audio/recordScore"..STR_EXTENSION),
		    recordScoreBonus = audio.loadSound("audio/recordScoreBonus"..STR_EXTENSION),
		    recordTimeBonus = audio.loadSound("audio/recordTimeBonus"..STR_EXTENSION),
		    reflect = audio.loadSound("audio/reflect"..STR_EXTENSION),
		    shield = audio.loadSound("audio/shield"..STR_EXTENSION),
		    shoow = audio.loadSound("audio/shoow"..STR_EXTENSION),
		    spaceshipExplosion = audio.loadSound("audio/spaceshipExplosion"..STR_EXTENSION),
		    spaceshipShot = audio.loadSound("audio/spaceshipShot"..STR_EXTENSION),
		    spaceshipHit = audio.loadSound("audio/spaceshipHit"..STR_EXTENSION),
		    stage = audio.loadSound("audio/stage"..STR_EXTENSION),
		    stone = audio.loadSound("audio/stone"..STR_EXTENSION),
		    stoneBig = audio.loadSound("audio/stoneBig"..STR_EXTENSION),
		    unfrozen = audio.loadSound("audio/unfrozen"..STR_EXTENSION),
		    unlocked = audio.loadSound("audio/unlocked"..STR_EXTENSION),
		    untouchable = audio.loadSound("audio/untouchable"..STR_EXTENSION),
		    vortex = audio.loadSound("audio/vortex"..STR_EXTENSION),
		    yes = audio.loadSound("audio/yes"..STR_EXTENSION),
		    woosh = audio.loadSound("audio/woosh"..STR_EXTENSION),
		}

		Jukebox:addEventListener("playSound", playSound)
		Jukebox:addEventListener("stopSound", stopSound)
		Jukebox:addEventListener("stopSoundCoins", stopSoundCoins)
		Jukebox:addEventListener("playSoundCoins", playSoundCoins)
	else
		for i=#TBL_SOUNDS_STASH, 1 do
			if TBL_SOUNDS_STASH[i] ~= nil and TBL_SOUNDS_STASH[i] > 0 then
				audio.stop(TBL_SOUNDS_STASH[i])
				audio.dispose(TBL_SOUNDS_STASH[i])
				TBL_SOUNDS_STASH[i] = nil
			end
		end
		TBL_SOUNDS_STASH = {}

		Jukebox:removeEventListener("playSound", playSound)
		Jukebox:removeEventListener("stopSound", stopSound)
		Jukebox:removeEventListener("stopSoundCoins", stopSoundCoins)
		Jukebox:removeEventListener("playSoundCoins", playSoundCoins)
	end
end

local function activateMusics(self, isActive)
	if isActive then
		TBL_MUSICS_STASH = {
		    audio.loadStream("audio/musicMenu"..(STR_EXTENSION)), -- 0
		    audio.loadStream("audio/musicGameplay"..(STR_EXTENSION)), -- 1
		    nil, -- 2
		    audio.loadStream("audio/musicResults"..(STR_EXTENSION == ".mp3" and ".wav" or STR_EXTENSION)), --3
		    audio.loadStream("audio/musicChallenge"..(STR_EXTENSION)), -- 4 
		    audio.loadStream("audio/musicBonus"..(STR_EXTENSION == ".mp3" and ".wav" or STR_EXTENSION)), -- 5
		    nil, -- 6
		    nil, -- 7
		    nil, -- 8
		    nil, -- 9
		    audio.loadStream("audio/musicResults"..(STR_EXTENSION == ".mp3" and ".wav" or STR_EXTENSION)), -- 10
		    nil, -- 11
		}

		self:addEventListener("playMusic", playMusic)
		self:addEventListener("stopMusic", stopMusic)
	else
		for i=#TBL_MUSICS_STASH, 1 do
			if TBL_MUSICS_STASH[i] ~= nil and TBL_MUSICS_STASH[i] > 0 then
				audio.stop(TBL_MUSICS_STASH[i])
				audio.dispose(TBL_MUSICS_STASH[i])
				TBL_MUSICS_STASH[i] = nil
			end
		end
		TBL_MUSICS_STASH = {}
		if HANDLE_BACKGROUND_MUSIC ~= nil and HANDLE_BACKGROUND_MUSIC > 0 then
			audio.stop(HANDLE_BACKGROUND_MUSIC)
			audio.dispose(HANDLE_BACKGROUND_MUSIC)
		end
		HANDLE_BACKGROUND_MUSIC = nil
		ID_CURRENT_BACKGROUND_MUSIC = 0

		Jukebox:removeEventListener("playMusic", playMusic)
		Jukebox:removeEventListener("stopMusic", stopMusic)
	end
end

local function setPitch(self, value)
	local source = audio.getSourceFromChannel(1)
    al.Source(source, al.PITCH, value)
end


Jukebox.activateSounds = activateSounds
Jukebox.activateMusics = activateMusics
Jukebox.setPitch = setPitch

return Jukebox