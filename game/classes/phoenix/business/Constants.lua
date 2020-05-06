local Constants = {

	TOP = display.screenOriginY + 9,
	LEFT = (display.contentWidth - display.actualContentWidth) * .5 + 6,
	RIGHT = display.actualContentWidth + (display.contentWidth - display.actualContentWidth) * .5 - 6,
	BOTTOM = display.actualContentHeight + (display.contentHeight - display.actualContentHeight) * .5 - 9,
	TIME_PAUSED = nil,

	-- ADS APPLOVIN (https://www.applovin.com)
	STR_KEY_APPLOVIN_AD = "T2H88S6B426g6f6fDTv2x15Nvi51_SGXVXge_nq3pxkvbrZpJSrFTxcMdiOcAf9fCqIBb7FO3zIfpsS6JILnEz",
	NUM_GAMES_PLAYED_TO_SHOW_AD = 5,
	NUM_COINS_REWARDED_VIDEO_AD = 100,
	NUM_WAIT_MILLISECONDS_TO_HIDE_AD_IF_NOT_SHOW = 1000,

	-- RATE US
	NUM_GAMES_PLAYED_TO_SHOW_RATE = 10,

}

return Constants