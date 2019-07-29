-- FSE_HUD
-- TOGFox
-- Thanks to Teddii on the FSEconomy forums for the inspiration to write this HUD
-- For support: post on x-plane.org

-- v0.01
-- v0.02
-- v0.03
--		Corrected 'end flight' bug
-- v0.04
--		Auto-end flight works better
-- v0.05
--		Added a hot-spot marker to guide the mouse.
-- v0.06
--		Redesigned the GUI
-- v0.07
--		Re-introduced flight time and fuel used
--v0.08
--		Added some automation - fixed the time/fuel used
--v0.09
--		Added voice alerts for VR peeps
--v0.10
--		Adjusted fuel calculations
--		Stopped auto-register from registering a flight while sim is paused
--		Added audible alarm if auto-end flight fails to work
--v0.11
--		Corrected incorrect fuel reports

-- Requires tf_common_functions v0.02 or later

local bolShowHotSpot = 1	--Change this to zero if you don't like the marker
local intHudXStart = 15		--This can be changed
local intHudYStart = 575	--This can be changed

--These are user preferences VALUES. Do NOT change these
local ACTION_NONE = 0			--no action
local ACTION_ATCDEFAULT = 1			--ATC voice with default ATC text settings
local ACTION_PAUSE = 4				--Pauses the sim
local ACTION_AUTORESOLVE = 8	--auto-resolve

--These are the preferences - set to one or more values described above
local intActionTypeConnect = ACTION_AUTORESOLVE
local intActionTypeRegisterFlight = ACTION_AUTORESOLVE
local intActionTypeEndflight = ACTION_AUTORESOLVE

------------------------------------------------------------------------
-- Don't change anything below here
------------------------------------------------------------------------
require "graphics"
require "tf_common_functions"local bolLoginAlertRaised = 0	--to ensure alerts aren't raised more than once

local strHUDVersion = "v0.11"

local bolFlightRegisteredAlertRaised = 0
local bolFlightNotEndedAlertRaised = 0
local bolAttemptedToAutoConnect = 0
local bolAttemptedToAutoRegister = 0


local intButtonHeight = 30			--the clickable 'panels' are called buttons
local intButtonWidth = 140			--the clickable 'panels' are called buttons
local intHeadingHeight = 20
local intFrameBorderSize = 5
local fltTransparency = 0.10		--alpha value for the boxes

--These help draw the status panel
local fltFlightStartTimeSeconds = os.clock() --tracks time at start of flight
local fltFuelStartWeightKGs = 0		--tracks fuel weight at start of flight
local fltFlightTimeSeconds = 0		--what gets displayed on screen
local fltFuelUsedOnFlightKGs = 0	--what gets displayed on screen

local bolCancelArmed = 0			--0 = cancel button is not armed. 1 = cancel button is armed
local bolDeparted = 0				--0 = not yet departed from originating airport. Used for automation


local fltTimerForEndFlight = 10	--wait this many seconds before auto-ending a flight
local fltBeginLandedTimer = 0	--the time at landing

dataref("tf_fltCurrentFuelWeightKGs" ,"sim/flightmodel/weight/m_fuel_total")
dataref("tf_fse_connected", "fse/status/connected")
dataref("tf_fse_flying", "fse/status/flying")
dataref("tf_bolOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("tf_datGSpd", "sim/flightmodel/position/groundspeed")
dataref("tf_intATCTextOut", "sim/operation/prefs/text_out", "writeable")
dataref("tf_fltAltAGL", "sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
dataref("tf_bolSimPaused", "sim/time/paused")
dataref("tf_InReplayMode", "sim/time/is_in_replay")

function tfFSE_DrawOutsidePanel()
	--Draws the overall box
	local x1 = intHudXStart
	local y1 = intHudYStart
	local x2 = x1 + intFrameBorderSize + intButtonWidth + intButtonWidth + intFrameBorderSize
	local y2 = y1 + intFrameBorderSize + intButtonHeight + intButtonHeight + intHeadingHeight + intFrameBorderSize
	
	graphics.set_color(1, 1, 1, fltTransparency) --white
	graphics.draw_rectangle(x1,y1,x2,y2)
end

function tfFSE_DrawInsidePanel()
	--Draws the inside panel
	local x1 = intHudXStart + intFrameBorderSize
	local y1 = intHudYStart + intFrameBorderSize
	local x2 = x1 + intButtonWidth + intButtonWidth
	local y2 = y1 + intButtonHeight + intButtonHeight + intHeadingHeight

	graphics.set_color(1, 1, 1, fltTransparency) --white
	graphics.draw_rectangle(x1,y1,x2,y2)
end

function tfFSE_DrawHeadingPanel()
	--Draws the heading panel and text at the top of the inside panel
	local x1 = intHudXStart + intFrameBorderSize
	local y1 = intHudYStart + intFrameBorderSize + intButtonHeight + intButtonHeight
	local x2 = x1 + intButtonWidth + intButtonWidth
	local y2 = y1 + intHeadingHeight
	
	graphics.draw_string((x1 + (intButtonWidth * 0.70)),(y1 + (intButtonHeight * 0.25)), "FSE HUD " .. strHUDVersion, "white")
	
	graphics.set_color(1, 1, 1, fltTransparency) --white
	graphics.draw_rectangle(x1,y1,x2,y2)	
end

function tfFSE_DrawStatusPanel()
	--Draw the status panel that displays flight time and fuel used
	--Note to me: this method doesn't work when ground acel is used. Suggest finding a dataref that displays flight time.
	local x1 = intHudXStart + intFrameBorderSize
	local y1 = intHudYStart + intFrameBorderSize
	local x2 = x1 + intButtonWidth + intButtonWidth
	local y2 = y1 + intButtonHeight
	local strTemp
	
	--print(fltFuelUsedOnFlightKGs .. ";" .. fltFuelStartWeightKGs ..";" ..tf_fltCurrentFuelWeightKGs)
	--Work out what the panel values are
	if tf_fse_flying == 1 then
		fltFlightTimeSeconds = os.clock() - fltFlightStartTimeSeconds
		
		--This bit is a hack. The fuel is suppose to sync when you start flight but there is a timing problem so we do it here as well
		if (fltFlightTimeSeconds > 0 and fltFlightTimeSeconds < 9) then -- and (fltFuelUsedOnFlightKGs <= 0) then
			fltFuelStartWeightKGs = tf_fltCurrentFuelWeightKGs
			--print("Start Weight:" .. fltFuelStartWeightKGs)
			--print("Current Weight:" .. tf_fltCurrentFuelWeightKGs)
			print("ping 1")
		end
		
		fltFuelUsedOnFlightKGs = tf_common_functions.round((fltFuelStartWeightKGs - tf_fltCurrentFuelWeightKGs), 1)
		
		if fltFuelUsedOnFlightKGs <= 0 then 
			fltFuelUsedOnFlightKGs = 0 
			fltFuelStartWeightKGs = tf_fltCurrentFuelWeightKGs
			--print("Fuel irregularity detected - non-vital error: FSE HUD not reporting correct fuel usage.")
			--print("fltFuelUsedOnFlightKGs:" .. fltFuelUsedOnFlightKGs .. " fltFuelStartWeightKGs:" .. fltFuelStartWeightKGs .. " tf_fltCurrentFuelWeightKGs:" .. tf_fltCurrentFuelWeightKGs)
		end
	end
	
	strTemp = "Flight time: " ..  tf_common_functions.tf_SecondsToClockFormat(fltFlightTimeSeconds)
	graphics.draw_string(x1 + (intButtonWidth * 0.05),y1 + (intButtonHeight * 0.6),strTemp,"white")
	
	local fltFuelUsedOnFlightGALs = tf_common_functions.round((fltFuelUsedOnFlightKGs / 2.60),1)
	strTemp = "Fuel used: " .. fltFuelUsedOnFlightKGs .. " KGs / " .. fltFuelUsedOnFlightGALs .. " gals"
	graphics.draw_string(x1 + (intButtonWidth * 0.05), y1 + (intButtonHeight * 0.2), strTemp, "white")	
	
	graphics.set_color(1, 1, 1, fltTransparency) --white
	graphics.draw_rectangle(x1,y1,x2,y2)
	
	--print(fltFlightStartTimeSeconds .. ";" .. fse_flighttime)
	
end

function tfFSE_DrawCorner()
	--Draw one corner of the HUD so people know where to put the mouse_over
	graphics.set_color(0,0,0,0.75)	--black
	
	--draw the vertical line
	local x1 = intHudXStart
	local y1 = intHudYStart + intFrameBorderSize + intButtonHeight + intButtonHeight
	local x2 = x1
	local y2 = y1 + intHeadingHeight + intFrameBorderSize
	graphics.draw_line(x1,y1,x2,y2)
	
	--draw the horizontal line
	--x1 = x1		--no change
	y1 = y2
	x2 = x1 + intButtonWidth * 0.25
	y2 = y1
	graphics.draw_line(x1,y1,x2,y2)
end

function tfFSE_DrawAlphaState()
	--Alpha state = not connected to FSE
	local x1 = intHudXStart + intFrameBorderSize
	local y1 = intHudYStart + intFrameBorderSize + intButtonHeight
	local x2 = x1 + intButtonWidth + intButtonWidth
	local y2 = y1 + intButtonHeight
	
	graphics.draw_string(x1 + (intButtonWidth * 0.15), y1 + (intButtonHeight * 0.4), "Click to connect", "white")
	
	graphics.set_color( 0, 1, 0, fltTransparency) --green
	graphics.draw_rectangle(x1,y1,x2,y2)
	
	--draw button outline
	graphics.set_color(0,0,0,0.5)	--black
	graphics.draw_line(x1,y1,x2,y1)
	graphics.draw_line(x2,y1,x2,y2)
	graphics.draw_line(x2,y2,x1,y2)
	graphics.draw_line(x1,y2,x1,y1)
end

function tfFSE_DrawBetaState()
	--Beta state = connected but not enroute
	local x1 = intHudXStart + intFrameBorderSize
	local y1 = intHudYStart + intFrameBorderSize + intButtonHeight
	local x2 = x1 + intButtonWidth + intButtonWidth
	local y2 = y1 + intButtonHeight
	
	graphics.draw_string(x1 + (intButtonWidth * 0.15), y1 + (intButtonHeight * 0.4), "Click to register flight", "white")
	
	graphics.set_color( 0, 1, 0, fltTransparency) --green
	graphics.draw_rectangle(x1,y1,x2,y2)
	
	--draw button outline
	graphics.set_color(0,0,0,0.5)	--black
	graphics.draw_line(x1,y1,x2,y1)
	graphics.draw_line(x2,y1,x2,y2)
	graphics.draw_line(x2,y2,x1,y2)
	graphics.draw_line(x1,y2,x1,y1)
end

function tfFSE_DrawCharlieState()
	--Charlie state = flight in progress (cancel not armed)
	
	--There are two buttons side by side in this state
	local x1 = intHudXStart + intFrameBorderSize
	local y1 = intHudYStart + intFrameBorderSize + intButtonHeight
	local x2 = x1 + intButtonWidth
	local y2 = y1 + intButtonHeight
	
	graphics.draw_string(x1 + (intButtonWidth * 0.15), y1 + (intButtonHeight * 0.4), "Flight in progress", "white")
	
	graphics.set_color(1, 1, 1, fltTransparency) --white
	graphics.draw_rectangle(x1,y1,x2,y2)	
	
	--draw button outline
	graphics.set_color(0,0,0,0.5)	--black
	graphics.draw_line(x1,y1,x2,y1)
	graphics.draw_line(x2,y1,x2,y2)
	graphics.draw_line(x2,y2,x1,y2)
	graphics.draw_line(x1,y2,x1,y1)
	
	--Draw the second button
	x1 = x2
	--y1 = y1		--y1 doesn't change value
	x2 = x1 + intButtonWidth
	y2 = y1 + intButtonHeight	
	
	graphics.draw_string(x1 + (intButtonWidth * 0.1), y1 + (intButtonHeight * 0.4), "Click to cancel flight", "white")
	
	graphics.set_color( 0, 1, 0, fltTransparency) --green
	graphics.draw_rectangle(x1,y1,x2,y2)

	--draw button outline
	graphics.set_color(0,0,0,0.5)	--black
	graphics.draw_line(x1,y1,x2,y1)
	graphics.draw_line(x2,y1,x2,y2)
	graphics.draw_line(x2,y2,x1,y2)
	graphics.draw_line(x1,y2,x1,y1)	

	
end

function tfFSE_DrawDeltaState()
	--Delta state = flight in progress (cancel is armed)

	--There are two buttons side by side in this state
	local x1 = intHudXStart + intFrameBorderSize
	local y1 = intHudYStart + intFrameBorderSize + intButtonHeight
	local x2 = x1 + intButtonWidth
	local y2 = y1 + intButtonHeight
	
	graphics.draw_string(x1 + (intButtonWidth * 0.15), y1 + (intButtonHeight * 0.4), "Really cancel?", "white")
	
	graphics.set_color(1, 1, 0, fltTransparency) --yellow
	graphics.draw_rectangle(x1,y1,x2,y2)

	--draw button outline
	graphics.set_color(0,0,0,0.5)	--black
	graphics.draw_line(x1,y1,x2,y1)
	graphics.draw_line(x2,y1,x2,y2)
	graphics.draw_line(x2,y2,x1,y2)
	graphics.draw_line(x1,y2,x1,y1)	
	
	--Draw the second button
	x1 = x2
	--y1 = y1		--y1 doesn't change value
	x2 = x1 + intButtonWidth
	y2 = y1 + intButtonHeight	
	
	graphics.draw_string(x1 + (intButtonWidth * 0.15), y1 + (intButtonHeight * 0.4), "Click to un-cancel", "white")
	
	graphics.set_color( 0, 1, 0, fltTransparency) --green
	graphics.draw_rectangle(x1,y1,x2,y2)	

	--draw button outline
	graphics.set_color(0,0,0,0.5)	--black
	graphics.draw_line(x1,y1,x2,y1)
	graphics.draw_line(x2,y1,x2,y2)
	graphics.draw_line(x2,y2,x1,y2)
	graphics.draw_line(x1,y2,x1,y1)	
end

function tfFSE_DrawEchoState()
	--Echo state = flight in progress but stopped on the ground (ready to end flight)
	
	--There are two buttons side by side in this state
	local x1 = intHudXStart + intFrameBorderSize
	local y1 = intHudYStart + intFrameBorderSize + intButtonHeight
	local x2 = x1 + intButtonWidth
	local y2 = y1 + intButtonHeight
	
	graphics.draw_string(x1 + (intButtonWidth * 0.05), y1 + (intButtonHeight * 0.4), "Click to end flight", "white")
	
	graphics.set_color( 0, 1, 0, fltTransparency) --green
	graphics.draw_rectangle(x1,y1,x2,y2)	
	
	--draw button outline
	graphics.set_color(0,0,0,0.5)	--black
	graphics.draw_line(x1,y1,x2,y1)
	graphics.draw_line(x2,y1,x2,y2)
	graphics.draw_line(x2,y2,x1,y2)
	graphics.draw_line(x1,y2,x1,y1)
	
	--Draw the second button
	x1 = x2
	--y1 = y1		--y1 doesn't change value
	x2 = x1 + intButtonWidth
	y2 = y1 + intButtonHeight	
	
	graphics.draw_string(x1 + (intButtonWidth * 0.05), y1 + (intButtonHeight * 0.4), "Click to cancel flight", "white")
	
	graphics.set_color( 0, 1, 0, fltTransparency) --green
	graphics.draw_rectangle(x1,y1,x2,y2)

	--draw button outline
	graphics.set_color(0,0,0,0.5)	--black
	graphics.draw_line(x1,y1,x2,y1)
	graphics.draw_line(x2,y1,x2,y2)
	graphics.draw_line(x2,y2,x1,y2)
	graphics.draw_line(x1,y2,x1,y1)	
end

function tfFSE_DrawButtons()
	--Examines FSE and flight state to draw the correct buttons in the correct place.
	--There is a finite number of button states so are just hardcoded here
	
	if tf_fse_connected == 0 then
		--tf_fse_connected == 0
		tfFSE_DrawAlphaState()
	else
		if tf_fse_flying == 0 then
			--tf_fse_connected == 1
			--tf_fse_flying == 0
			tfFSE_DrawBetaState()
		else
			if bolCancelArmed == 0 then
				if tf_bolOnTheGround == 1 and tf_datGSpd <= 5 and os.clock() >= fltBeginLandedTimer + 4 then
					--tf_fse_connected == 1
					--tf_fse_flying == 1
					--bolCancelArmed == 0
					--tf_bolOnTheGround == 1
					--tf_datGSpd <= 5
					--been stopped for at least 4 seconds
					tfFSE_DrawEchoState()
				else
					--tf_fse_connected == 1
					--tf_fse_flying == 1
					--bolCancelArmed == 0
					--tf_bolOnTheGround == ?
					--tf_datGSpd == ?
					tfFSE_DrawCharlieState()
				end
			else
				--tf_fse_connected == 1
				--tf_fse_flying == 1
				--bolCancelArmed == 1
				tfFSE_DrawDeltaState()
			end
		end
	end	
end
	
function tfFSE_DrawThings()

	XPLMSetGraphicsState(0,0,0,1,1,0,0)
	
	if bolShowHotSpot == 1 then
		tfFSE_DrawCorner()
	end
	
	--check for mouse over before drawing
	local x1 = intHudXStart
	local y1 = intHudYStart
	local x2 = x1 + intFrameBorderSize + intButtonWidth + intButtonWidth + intFrameBorderSize
	local y2 = y1 + intFrameBorderSize + intButtonHeight + intButtonHeight + intHeadingHeight + intFrameBorderSize	
	if MOUSE_X < x1 or MOUSE_X > x2 or MOUSE_Y < y1 or MOUSE_Y > y2 then
		--don't draw
	else
		tfFSE_DrawOutsidePanel()
		tfFSE_DrawInsidePanel()
		tfFSE_DrawHeadingPanel()
		tfFSE_DrawStatusPanel()
		tfFSE_DrawButtons()
	end
end	
	
function tfFSE_ConnectToServer()
	command_once("fse/server/connect")
	bolLoginAlertRaised = 0
	bolFlightRegisteredAlertRaised = 0
	bolAttemptedToAutoRegister = 0
end

function tfFSE_RegisterFlight()
	if tf_fse_flying == 0 and tf_fse_connected == 1 and tf_bolSimPaused == 0 then
		command_once("fse/flight/start")
		bolCancelArmed = 0
		fltFuelStartWeightKGs = tf_fltCurrentFuelWeightKGs
		--print("ping 2")
		fltFlightStartTimeSeconds = os.clock()
		bolFlightRegisteredAlertRaised = 0
		bolAttemptedToAutoRegister = 0
		bolFlightNotEndedAlertRaised = 0
	end
end	
	
function tfFSE_CancelArm()
	--Arm the cancel
	command_once("fse/flight/cancelArm")
	bolCancelArmed = 1

end

function tfFSE_ReallyCancel()
	if bolCancelArmed == 1 then	--this is unnecessary but for safety
		command_once("fse/flight/cancelConfirm")
		bolCancelArmed = 0
		bolFlightRegisteredAlertRaised = 0
		bolAttemptedToAutoRegister = 0
	end
end
	
function tfFSE_EndFlight()
	command_once("fse/flight/finish")
	bolAttemptedToAutoRegister = 0
	bolFlightNotEndedAlertRaised = 0
end	
	
function tfFSE_MouseClick()
	--process mouse click hot spots
	
	--check if button hot spot is clicked
	
	--alpha state
	local x1 = intHudXStart + intFrameBorderSize
	local y1 = intHudYStart + intFrameBorderSize + intButtonHeight
	local x2 = x1 + intButtonWidth + intButtonWidth
	local y2 = y1 + intButtonHeight
	
	--print (tf_fse_flying .. ";" .. bolCancelArmed .. ";" .. tf_bolOnTheGround .. ";" .. tf_datGSpd)
	
	if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
		if tf_fse_connected == 0 then
			--Alpha state
			--try to log in
			tfFSE_ConnectToServer()
			return
		end
		
		if tf_fse_connected == 1 and tf_fse_flying == 0 then
			--Beta state
			tfFSE_RegisterFlight()
			return
		end
		
		--The buttons get small for Charlie, Delta and Echo state - so need more granularity
		x1 = intHudXStart + intFrameBorderSize
		y1 = intHudYStart + intFrameBorderSize + intButtonHeight
		x2 = x1 + intButtonWidth
		y2 = y1 + intButtonHeight
		
		--print(x1 .. ";" .. y1 .. ";" .. x2 .. ";" .. y2)
		--print(MOUSE_X ..";" .. MOUSE_Y)

		--check if left button is clicked
		if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
		
				--print("alpha")
		
				--The left button has been clicked
				if (tf_fse_flying == 1 and bolCancelArmed == 0) and (tf_bolOnTheGround == 0 or tf_datGSpd > 5) then
					--This button is disabled. Do nothing
					--print("beta")
					return
				end
				
				if tf_fse_flying == 1 and bolCancelArmed == 1 then
					--Really Cancel has been clicked
					tfFSE_ReallyCancel()
					--print("Charle")
					return
				end
				
				if tf_fse_flying == 1 and bolCancelArmed == 0 and tf_bolOnTheGround == 1 and tf_datGSpd <= 5 and os.clock() >= fltBeginLandedTimer + 4 then
					--End flight has been clicked
					--print("Trying to end flight")
					tfFSE_EndFlight()
					return
				end
		end
		
		--The bit above is the left button
		--This bit is the right button
		x1 = x2
		--y1 = y1		--y1 doesn't change value
		x2 = x1 + intButtonWidth
		y2 = y1 + intButtonHeight			
		if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
			if tf_fse_flying == 1 and bolCancelArmed == 0 then
				--Charle state
				--Cancel is armed
				tfFSE_CancelArm()
				return
			end
			
			if tf_fse_flying == 1 and bolCancelArmed == 1 then
				--Deta state
				--un-cancel flight
				bolCancelArmed = 0
				return
			end
		end
	end
end	

function tfFSE_Automation()	
	--detect key events and react according to the action settings specified by the user
	
	if tf_InReplayMode == 1 or tf_bolSimPaused == 1 then
		return
	end
	
	--if taxiing and not logged in then check if there needs to be an action
	if tf_datGSpd > 5 and tf_fse_connected == 0 and bolAttemptedToAutoConnect == 0 then
		--Check to see what action to do
		if intActionTypeConnect >= ACTION_AUTORESOLVE then
			tfFSE_ConnectToServer()
			bolAttemptedToAutoConnect = 1
		end
	end
	
	--if taking off and not registered flight then check if there needs to be an action

	if tf_bolOnTheGround == 0 and tf_fse_flying == 0 and tf_fse_connected == 1 and bolAttemptedToAutoRegister == 0 then
		if intActionTypeRegisterFlight >= ACTION_AUTORESOLVE then
			tfFSE_RegisterFlight()
			bolAttemptedToAutoRegister = 1
		end
	end
	
	--if landed then check if there needs to be an action
		
	if tf_bolOnTheGround == 1 and tf_datGSpd < 5 and tf_fse_flying == 1 and bolDeparted == 1 then
		if fltBeginLandedTimer == 0 then	--if timer is not started then start the timer.
			fltBeginLandedTimer = os.clock()
		end
		
		if os.clock() > fltBeginLandedTimer + fltTimerForEndFlight then
			--try to end flight
			if intActionTypeEndflight >= ACTION_AUTORESOLVE then
				tfFSE_EndFlight()
			end
		end
	end	

	--capture if plane has taken off
	if tf_bolOnTheGround == 0 and bolDeparted == 0 then
		bolDeparted = 1
	end
	
	if tf_fse_flying == 0 then
		bolDeparted = 0
		bolCancelArmed = 0
		fltBeginLandedTimer = 0
	end	
end
	
function tfFSE_CheckAlarms()
--Raise a voice alarm if auto-resolved didn't work

	--check the auto-connect worked
	if tf_datGSpd > 100 and tf_fse_connected == 0 and intActionTypeConnect >= ACTION_AUTORESOLVE and bolLoginAlertRaised == 0 then
		--It seems the autoconnect didn't work. Need to say something.
		XPLMSpeakString("Auto-connection failed")
		bolLoginAlertRaised = 1
	end
	
	--check that the auto-register worked
	if tf_bolOnTheGround == 0 and tf_fse_flying == 0 and tf_fse_connected == 1 and tf_fltAltAGL > 300 and bolFlightRegisteredAlertRaised == 0 then
		XPLMSpeakString("Flight auto-register failed")
		bolFlightRegisteredAlertRaised = 1
	end
	
	--check that the auto-end worked
	if tf_bolOnTheGround == 1 and tf_fse_flying == 1 and tf_datGSpd < 5 and (os.clock() > (fltBeginLandedTimer + fltTimerForEndFlight + 30)) and bolFlightNotEndedAlertRaised == 0 and bolDeparted == 1 then
		XPLMSpeakString("Flight auto-end failed")
		bolFlightNotEndedAlertRaised = 1
	end
	
end
	
do_every_draw("tfFSE_DrawThings()")
do_on_mouse_click("tfFSE_MouseClick()")
do_sometimes("tfFSE_Automation()")
do_sometimes("tfFSE_CheckAlarms()")
	
	
	
	
	