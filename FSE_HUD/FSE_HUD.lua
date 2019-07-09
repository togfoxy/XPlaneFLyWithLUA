-- FSE_HUD
-- TOGFox
-- Thanks to Teddii on the FSEconomy forums for the inspiration to write this HUD
-- For support: post on x-plane.org
-- v0.02

local intHudXStart = 15		--This can be changed
local intHudYStart = 475	--This can be changed
-- ---------------------------------------------------------------------
require "graphics"

dataref("fse_connected", "fse/status/connected")
dataref("TEXTOUT", "sim/operation/prefs/text_out", "writeable")
dataref("fse_flying", "fse/status/flying")
dataref("bolOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("intParkBrake", "sim/flightmodel/controls/parkbrake")
dataref("datGSpd", "sim/flightmodel/position/groundspeed")

dataref("fltFuelWeightKG" ,"sim/flightmodel/weight/m_fuel_total")
dataref("fltFuelWeightLBS" ,"sim/aircraft/weight/acf_m_fuel_tot")

local fltInitialFuelWeightKGS = 0	--for GUI status report
local fltInitialFuelWeightLBS = 0	--for GUI status report

local intButtonWidth = 95
local intButtonHeight = 30
local intButtonBorder = 1

local bolCancelledArmed = 0		--the CANCEL flight button is a two click event. This tracks that button state

--Different alarm actions: 
-- 0 = None
-- 1 = text only
-- 2 = voice only
-- 3 = text and voice
-- 4 = auto-resolve
local ACTION_NONE = 0			--no action
local ACTION_TEXTONLY = 1		--text alert
local ACTION_VOICEONLY = 2		--voice alert
local ACTION_TEXTANDVOICE = 3	--text and voice
local ACTION_AUTORESOLVE = 4	--auto-resolve

local intActionTypeLogin = ACTION_AUTORESOLVE
local intActionTypeRegisterFlight = ACTION_AUTORESOLVE
local intActionTypeEndflight = ACTION_AUTORESOLVE

local bolLoginAlertRaised = 0
local bolFlightRegisteredAlertRaised = 0
local bolFlightNotEndedAlertRaised = 0

local fltBeginTimer = 0				--timer for tracking how long the flight has ended
local fltTimerForEndFlight = 10		--seconds. How long the plane needs to be landed before it tries to auto-end flight

-- ############################################################################
-- ##### Drawing functions
-- ############################################################################

function tfFSE_DrawAutoConnect()
	local x1 = intHudXStart
	local y1 = intHudYStart + (intButtonHeight * 3) + intButtonBorder
	local x2 = intHudXStart + intButtonWidth - intButtonBorder
	local y2 = intHudYStart + (intButtonHeight * 4)
	
	if intActionTypeLogin == ACTION_NONE then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "No", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "action", "white")
	elseif intActionTypeLogin == ACTION_TEXTONLY then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Text", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "alert", "white")
	elseif intActionTypeLogin == ACTION_VOICEONLY then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Voice", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "alert", "white")
	elseif intActionTypeLogin == ACTION_TEXTANDVOICE then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Text and", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "voice alert", "white")
	else
		-- Auto-resolve
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Auto", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "connect", "white")
	end
		
	if intActionTypeLogin > ACTION_NONE then
		graphics.set_color( 0, 1, 0, 0.20) --green
	else
		graphics.set_color( 1, 0, 0, 0.20) --red
	end

	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_DrawAutoStart()
	local x1 = intHudXStart
	local y1 = intHudYStart + (intButtonHeight * 2) + intButtonBorder
	local x2 = intHudXStart + intButtonWidth - intButtonBorder
	local y2 = intHudYStart + (intButtonHeight * 3)
	
	--print("zz" .. intActionTypeRegisterFlight)
	
	if intActionTypeRegisterFlight == ACTION_NONE then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "No", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "action", "white")
	elseif intActionTypeRegisterFlight == ACTION_TEXTONLY then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Text", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "alert", "white")
	elseif intActionTypeRegisterFlight == ACTION_VOICEONLY then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Voice", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "alert", "white")
	elseif intActionTypeRegisterFlight == ACTION_TEXTANDVOICE then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Text and", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "voice alert", "white")
	else
		-- Auto-resolve
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Auto", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "register", "white")
	end

	if intActionTypeRegisterFlight > ACTION_NONE then
		graphics.set_color( 0, 1, 0, 0.20) --green
	else
		graphics.set_color( 1, 0, 0, 0.20) --red
	end

	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_DrawAutoEnd()
	local x1 = intHudXStart
	local y1 =intHudYStart + (intButtonHeight * 1) + intButtonBorder
	local x2 =intHudXStart + intButtonWidth - intButtonBorder
	local y2 =intHudYStart + (intButtonHeight * 2)
	
	if intActionTypeEndflight == ACTION_NONE then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "No", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "action", "white")
	elseif intActionTypeEndflight == ACTION_TEXTONLY then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Text", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "alert", "white")
	elseif intActionTypeEndflight == ACTION_VOICEONLY then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Voice", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "alert", "white")
	elseif intActionTypeEndflight == ACTION_TEXTANDVOICE then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Text and", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "voice alert", "white")
	else
		-- Auto-resolve
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Auto", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "register", "white")
	end

	if intActionTypeEndflight > ACTION_NONE then
		graphics.set_color( 0, 1, 0, 0.20) --green
	else
		graphics.set_color( 1, 0, 0, 0.20) --red
	end

	graphics.draw_rectangle(x1, y1, x2, y2)	
end

function tfFSE_DrawLogin()
	local x1 = intHudXStart + intButtonWidth + intButtonBorder
	local y1 =intHudYStart + (intButtonHeight * 3) + intButtonBorder
	local x2 =intHudXStart + (intButtonWidth * 2)
	local y2 =intHudYStart + (intButtonHeight * 4)

	if fse_connected == 1 then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.4), "Logged in", "white")
		graphics.set_color( 1, 1, 1, 0.20) --white
	else
		graphics.draw_string((x1 + intButtonWidth * 0.10), (y1 + intButtonHeight * 0.4), "Not logged in", "white")
		graphics.set_color( 0, 1, 0, 0.20) --green
	end
	
	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_DrawRegisterFlight()
	local x1 = intHudXStart + intButtonWidth + intButtonBorder
	local y1 =intHudYStart + (intButtonHeight * 2) + intButtonBorder
	local x2 =intHudXStart + (intButtonWidth * 2)
	local y2 =intHudYStart + (intButtonHeight * 3)

	if fse_flying > 0 or fse_connected == 0 then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Flight", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "registered", "white")
		graphics.set_color( 1, 1, 1, 0.20) --white
		
	else
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Register", "white")
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "flight", "white")
		graphics.set_color( 0, 1, 0, 0.20) --green
	end

	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_DrawEndFlight()
	local x1 = intHudXStart + intButtonWidth + intButtonBorder
	local y1 =intHudYStart + (intButtonHeight * 1) + intButtonBorder
	local x2 =intHudXStart + (intButtonWidth * 1.5) - intButtonBorder
	local y2 =intHudYStart + (intButtonHeight * 2)
	
	graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.4), "End", "white")
	if bolOnTheGround == 1 and intParkBrake == 1 and datGSpd <= 5 and fse_flying == 1 then
		graphics.set_color( 0, 1, 0, 0.20) --green
	else
		graphics.set_color( 1, 1, 1, 0.20) --white
	end
		
	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_DrawCancelFlight()
	local x1 = intHudXStart + intButtonWidth * 1.5 + intButtonBorder
	local y1 =intHudYStart + (intButtonHeight * 1) + intButtonBorder
	local x2 =intHudXStart + (intButtonWidth * 2)
	local y2 =intHudYStart + (intButtonHeight * 2)
	
	if fse_flying == 1 then
		if bolCancelledArmed == 1 then
			graphics.draw_string((x1 + intButtonWidth * 0.05), (y1 + intButtonHeight * 0.6), "Really", "white")
			graphics.draw_string((x1 + intButtonWidth * 0.03), (y1 + intButtonHeight * 0.2), "Cancel?", "white")
			graphics.set_color( 1, 1, 0, 0.20) --yellow
		else
			graphics.draw_string((x1 + intButtonWidth * 0.03), (y1 + intButtonHeight * 0.4), "Cancel", "white")
			graphics.set_color( 0, 1, 0, 0.20) --green
		end
	else
		graphics.set_color( 1, 1, 1, 0.20) --white
	end
	
	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_DrawStatus()
	local x1 = intHudXStart
	local y1 = intHudYStart 
	local x2 = intHudXStart + intButtonWidth * 2 
	local y2 = intHudYStart + (intButtonHeight) - intButtonBorder
	local strTempValue
	
	--draw flight
	strTempValue = "Flight time: " .. "0"
	graphics.draw_string(x1 + intButtonWidth * 0.15, y1 + intButtonHeight * 0.6, strTempValue, "white")
	
	--draw fuel used
	--print(fltInitialFuelWeightKGS .. ";" .. fltFuelWeightKG)
	if fse_flying == 1 then
		--strTempValue = "Fuel used: " .. (fltInitialFuelWeightKGS - fltFuelWeightKG) .. "kg / " .. (fltInitialFuelWeightLBS - fltFuelWeightLBS) .. " lbs"
		--graphics.draw_string(x1 + intButtonWidth * 0.15, y1 + intButtonHeight * 0.2, strTempValue, "white")
	end
	
	graphics.set_color( 1, 1, 1, 0.20) --white
	graphics.draw_rectangle(x1, y1, x2, y2)
end

-- ############################################################################
-- ##### Mouse click events
-- ############################################################################

function tfFSE_MouseClick()
	if MOUSE_STATUS ~= "down" then
		return
	end
	
	local x1
	local x2
	local y1
	local y2
	
	--print(MOUSE_X .. ";" .. MOUSE_Y)
	
	--is autoconnect toggled?
	x1 = intHudXStart
	y1 =intHudYStart + (intButtonHeight * 3) + intButtonBorder
	x2 =intHudXStart + intButtonWidth - intButtonBorder
	y2 =intHudYStart + (intButtonHeight * 4)
	if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
		--bolAutoConnect = 1 - bolAutoConnect	--flips 0 to 1 and 1 to 0
		intActionTypeLogin = intActionTypeLogin + 1
		if intActionTypeLogin > ACTION_AUTORESOLVE then
			--cycle back to 'none'
			intActionTypeLogin = ACTION_NONE
		end
	end
	
	--is auto-register toggled?
	x1 = intHudXStart
	y1 =intHudYStart + (intButtonHeight * 2) + intButtonBorder
	x2 =intHudXStart + intButtonWidth - intButtonBorder
	y2 =intHudYStart + (intButtonHeight * 3)
	if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
		--bolAutoStart = 1 - bolAutoStart	--flips 0 to 1 and 1 to 0
		intActionTypeRegisterFlight = intActionTypeRegisterFlight + 1
		if intActionTypeRegisterFlight > ACTION_AUTORESOLVE then
			intActionTypeRegisterFlight = ACTION_NONE
		end
		
		--print(intActionTypeRegisterFlight)
	end		
	
	--is auto-end toggled?
	x1 = intHudXStart
	y1 =intHudYStart + (intButtonHeight * 1) + intButtonBorder
	x2 =intHudXStart + intButtonWidth - intButtonBorder
	y2 =intHudYStart + (intButtonHeight * 2)
	if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
		--bolAutoEnd = 1 - bolAutoEnd	--flips 0 to 1 and 1 to 0
		intActionTypeEndflight = intActionTypeEndflight + 1
		if intActionTypeEndflight > ACTION_AUTORESOLVE then
			intActionTypeEndflight = ACTION_NONE
		end
	end	
	
	--is Log in clicked?
	x1 = intHudXStart + intButtonWidth + intButtonBorder
	y1 =intHudYStart + (intButtonHeight * 3) + intButtonBorder
	x2 =intHudXStart + (intButtonWidth * 2)
	y2 =intHudYStart + (intButtonHeight * 4)
	if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
		if fse_connected == 0 then
			command_once("fse/server/connect")
		end
	end

	--is Register Flight clicked?
	x1 = intHudXStart + intButtonWidth + intButtonBorder
	y1 =intHudYStart + (intButtonHeight * 2) + intButtonBorder
	x2 =intHudXStart + (intButtonWidth * 2)
	y2 =intHudYStart + (intButtonHeight * 3)
	if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
		if fse_flying == 0 then
			command_once("fse/flight/start")
			bolCancelledArmed = 0
			--capture fuel at start of flight so status can be reported on GUI
			fltInitialFuelWeightKGS = fltFuelWeightKG
			fltInitialFuelWeightLBS = fltFuelWeightLBS
			
			--print(fltInitialFuelWeightKGS)
		end
	end	
	
	--is End flight clicked?
	x1 = intHudXStart + intButtonWidth + intButtonBorder
	y1 =intHudYStart + (intButtonHeight * 1) + intButtonBorder
	x2 =intHudXStart + (intButtonWidth * 1.5) - intButtonBorder
	y2 =intHudYStart + (intButtonHeight * 2)
	if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
		if bolOnTheGround == 1 and intParkBrake == 1 and datGSpd <= 5 and fse_flying == 1 then
			command_once("fse/flight/finish")
			bolCancelledArmed = 0
		end
	end	
	
	--is Cancel flight clicked?
	x1 = intHudXStart + intButtonWidth * 1.5 + intButtonBorder
	y1 =intHudYStart + (intButtonHeight * 1) + intButtonBorder
	x2 =intHudXStart + (intButtonWidth * 2)
	y2 =intHudYStart + (intButtonHeight * 2)
	if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
		if fse_flying == 1 then
			command_once("fse/flight/cancelArm")
			bolCancelledArmed = bolCancelledArmed + 1
			if bolCancelledArmed > 1 then
				command_once("fse/flight/cancelConfirm")
			end
		end
	end
end

-- ############################################################################
-- ##### Miscellaneous functions
-- ############################################################################


function tfFSE_DoAutomation()
	--detect key events and react according to the action settings specified by the user
	
	--if taxiing and not logged in then check if there needs to be an action
	--print(datGSpd .. ";" .. fse_connected .. ";" .. bolLoginAlertRaised .. ";" .. intActionTypeLogin)
	if datGSpd > 5 and fse_connected == 0 and bolLoginAlertRaised == 0 then
		if intActionTypeLogin == ACTION_NONE then
			--do nothing
		elseif intActionTypeLogin == ACTION_TEXTONLY then
			--display a text warning
		
			-- ## TODO: how to display a string outside a do_every_draw event?
			
		elseif intActionTypeLogin == ACTION_VOICEONLY then
			--audible only
			speakNoText("Not logged into FSE") 
		elseif intActionTypeLogin == ACTION_TEXTANDVOICE then
			--text and audible
			XPLMSpeakString("Not logged into FSE")
		else
			--auto-resolve
			command_once("fse/server/connect")
		end
		
		bolLoginAlertRaised = 1	--this prevents the alert being raised multiple times
			
	end
	--if taking off and not registered flight then check if there needs to be an action
	if bolOnTheGround == 0 and fse_flying == 0 and bolFlightRegisteredAlertRaised == 0 and fse_connected == 1 then
		

		if intActionTypeRegisterFlight == ACTION_NONE then
			--do nothing
		elseif intActionTypeRegisterFlight == ACTION_TEXTONLY then
			--display a text warning
		
			-- ## TODO: how to display a string outside a do_every_draw event?
			
		elseif intActionTypeRegisterFlight == ACTION_VOICEONLY then
			--audible only
			speakNoText("Flight not registered with FSE") 
		elseif intActionTypeRegisterFlight == ACTION_TEXTANDVOICE then
			--text and audible
			XPLMSpeakString("Flight not registered with FSE")
		else
			--auto-resolve
			command_once("fse/flight/start")
			fltInitialFuelWeightKGS = fltFuelWeightKG
			fltInitialFuelWeightLBS = fltFuelWeightLBS	

			--print(fltInitialFuelWeightKGS)
		end

		bolFlightRegisteredAlertRaised = 1  --this prevents the alert being raised multiple times
	end
	
	
	--if landed then check if there needs to be an action
	if bolOnTheGround == 1 and datGSpd < 2 and intParkBrake == 1 and fse_flying == 1 and bolFlightNotEndedAlertRaised == 0 then
		if fltBeginTimer == 0 then	--if timer is not started then start the timer.
			fltBeginTimer = os.clock()
		end
		
		if os.clock() > fltBeginTimer + fltTimerForEndFlight then
			--try to end flight

			--## Need to build in a 15 second timer to give the pilot to end flight manually
			if intActionTypeEndflight == ACTION_NONE then
				--do nothing
			elseif intActionTypeEndflight == ACTION_TEXTONLY then
				--display a text warning
			
				-- ## TODO: how to display a string outside a do_every_draw event?
				
			elseif intActionTypeEndflight == ACTION_VOICEONLY then
				--audible only
				speakNoText("Flight not ended") 
			elseif intActionTypeEndflight == ACTION_TEXTANDVOICE then
				--text and audible
				XPLMSpeakString("Flight not ended")
			else
				--auto-resolve
				command_once("fse/flight/finish")
			end

			bolFlightNotEndedAlertRaised = 1  --this prevents the alert being raised multiple times	
		end
	

	
	
	
	end
	
	
	
end

function speakNoText(sText)
	-- Thanks to prokopiu from X-Plane.org
	TEXTOUT=false
	XPLMSpeakString(sText)
	TEXTOUT=true
end

function tfFSE_main()
	--check for mouse_over
	if MOUSE_X < intHudXStart or MOUSE_X > (intHudXStart + intButtonWidth * 2) or MOUSE_Y < intHudYStart or MOUSE_Y > intHudYStart + (intButtonHeight * 4) then
		return
	else
		XPLMSetGraphicsState(0,0,0,1,1,0,0)
		tfFSE_DrawAutoConnect()
		tfFSE_DrawAutoStart()
		tfFSE_DrawAutoEnd()
		tfFSE_DrawLogin()
		tfFSE_DrawRegisterFlight()
		tfFSE_DrawEndFlight()
		tfFSE_DrawCancelFlight()
		tfFSE_DrawStatus()
	end
end


--note to myself: need to deal with replay mode

do_every_draw("tfFSE_main()")
do_on_mouse_click("tfFSE_MouseClick()")
do_sometimes("tfFSE_DoAutomation()")


