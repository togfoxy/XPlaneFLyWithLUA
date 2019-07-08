
require "graphics"

DataRef("fse_connected", "fse/status/connected")
--DataRef("fse_flighttime", "fse/status/flighttime")
DataRef("fse_flying", "fse/status/flying")
dataref("bolOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("intParkBrake", "sim/flightmodel/controls/parkbrake")
dataref("datGSpd", "sim/flightmodel/position/groundspeed")

local intHudXStart = 15
local intHudYStart = 475
local intButtonWidth = 90
local intButtonHeight = 30
local intButtonBorder = 1

local bolAutoConnect = 0
local bolAutoStart = 0
local bolAutoEnd = 0
local bolCancelledArmed = 0
local intAlarmType = 1	--None; text only; voice only; text and voice

function tfFSE_DrawAutoConnect()
	local x1 = intHudXStart
	local y1 =intHudYStart + (intButtonHeight * 3) + intButtonBorder
	local x2 =intHudXStart + intButtonWidth - intButtonBorder
	local y2 =intHudYStart + (intButtonHeight * 4)
	
	graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Auto-connect", "white")
	if bolAutoConnect == 1 then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "enabled", "white")
		graphics.set_color( 0, 1, 0, 0.20) --green
	else
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "disabled", "white")
		graphics.set_color( 1, 0, 0, 0.20) --red
	end

	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_DrawAutoStart()
	local x1 = intHudXStart
	local y1 =intHudYStart + (intButtonHeight * 2) + intButtonBorder
	local x2 =intHudXStart + intButtonWidth - intButtonBorder
	local y2 =intHudYStart + (intButtonHeight * 3)
	
	graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Auto-start", "white")
	if bolAutoStart == 1 then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "enabled", "white")
		graphics.set_color( 0, 1, 0, 0.20) --green
	else
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "disabled", "white")
		graphics.set_color( 1, 0, 0, 0.20) --red
	end	
	
	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_DrawAutoEnd()
	local x1 = intHudXStart
	local y1 =intHudYStart + (intButtonHeight * 1) + intButtonBorder
	local x2 =intHudXStart + intButtonWidth - intButtonBorder
	local y2 =intHudYStart + (intButtonHeight * 2)
	
	graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.6), "Auto-end", "white")
	if bolAutoEnd == 1 then
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "enabled", "white")
		graphics.set_color( 0, 1, 0, 0.20) --green
	else
		graphics.draw_string((x1 + intButtonWidth * 0.15), (y1 + intButtonHeight * 0.2), "disabled", "white")
		graphics.set_color( 1, 0, 0, 0.20) --red
	end		
	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_DrawLogin()

	if fse_connected == 1 then
		graphics.draw_string((intHudXStart + intButtonWidth * 1.15), (intHudYStart + intButtonHeight *3.4), "Logged in", "white")
		graphics.set_color( 0, 1, 0, 0.20) --green
	else
		graphics.draw_string((intHudXStart + intButtonWidth * 1.10), (intHudYStart + intButtonHeight *3.4), "Not logged in", "white")
		graphics.set_color( 1, 0, 0, 0.20) --red
	end
	
	local x1 = intHudXStart + intButtonWidth + intButtonBorder
	local y1 =intHudYStart + (intButtonHeight * 3) + intButtonBorder
	local x2 =intHudXStart + (intButtonWidth * 2)
	local y2 =intHudYStart + (intButtonHeight * 4)
	
	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_DrawRegisterFlight()

	if fse_flying > 0 then
		graphics.draw_string((intHudXStart + intButtonWidth * 1.15), (intHudYStart + intButtonHeight *2.6), "Flight", "white")
		graphics.draw_string((intHudXStart + intButtonWidth * 1.15), (intHudYStart + intButtonHeight *2.2), "registered", "white")
		graphics.set_color( 1, 1, 1, 0.20) --white
		
	else
		graphics.draw_string((intHudXStart + intButtonWidth * 1.15), (intHudYStart + intButtonHeight *2.6), "Register", "white")
		graphics.draw_string((intHudXStart + intButtonWidth * 1.15), (intHudYStart + intButtonHeight *2.2), "flight", "white")
		graphics.set_color( 0, 1, 0, 0.20) --green
	end
	
	local x1 = intHudXStart + intButtonWidth + intButtonBorder
	local y1 =intHudYStart + (intButtonHeight * 2) + intButtonBorder
	local x2 =intHudXStart + (intButtonWidth * 2)
	local y2 =intHudYStart + (intButtonHeight * 3)
	
	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_DrawEndFlight()
	if bolOnTheGround == 1 and intParkBrake == 1 and datGSpd <= 5 and fse_flying == 1 then
		graphics.draw_string((intHudXStart + intButtonWidth * 1.15), (intHudYStart + intButtonHeight * 1.4), "End", "white")
		graphics.set_color( 0, 1, 0, 0.20) --green
	else
		
		graphics.set_color( 1, 1, 1, 0.20) --white
	end
	
	local x1 = intHudXStart + intButtonWidth + intButtonBorder
	local y1 =intHudYStart + (intButtonHeight * 1) + intButtonBorder
	local x2 =intHudXStart + (intButtonWidth * 1.5) - intButtonBorder
	local y2 =intHudYStart + (intButtonHeight * 2)
	
	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_DrawCancelFlight()

	if fse_flying == 1 then
		graphics.draw_string((intHudXStart + intButtonWidth * 1.54), (intHudYStart + intButtonHeight * 1.4), "Cancel", "white")

		if bolCancelledArmed > 0 then
			graphics.set_color( 1, 1, 0, 0.20) --yellow
		else
			graphics.set_color( 0, 1, 0, 0.20) --green
		end
	else
		graphics.set_color( 1, 1, 1, 0.20) --white
	end
	local x1 = intHudXStart + intButtonWidth * 1.5 + intButtonBorder
	local y1 =intHudYStart + (intButtonHeight * 1) + intButtonBorder
	local x2 =intHudXStart + (intButtonWidth * 2)
	local y2 =intHudYStart + (intButtonHeight * 2)
	
	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_DrawOptions()
	local x1 = intHudXStart
	local y1 = intHudYStart 
	local x2 = intHudXStart + intButtonWidth * 2 
	local y2 = intHudYStart + (intButtonHeight) - intButtonBorder
	
	graphics.set_color( 1, 1, 1, 0.20) --white
	graphics.draw_rectangle(x1, y1, x2, y2)
end

function tfFSE_MouseClick()
	if MOUSE_STATUS ~= "down" then
		return
	end
	
	local x1
	local x2
	local y1
	local y2
	
	--print(MOUSE_X .. ";" .. MOUSE_Y)

	--is Log in clicked?
		local x1 = intHudXStart + intButtonWidth + intButtonBorder
	y1 =intHudYStart + (intButtonHeight * 3) + intButtonBorder
	x2 =intHudXStart + (intButtonWidth * 2)
	y2 =intHudYStart + (intButtonHeight * 4)
	if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
		if fse_connected == 0 then
			command_once("fse/server/connect")
		end
	end
	
	--is autoconnect toggled?
	x1 = intHudXStart
	y1 =intHudYStart + (intButtonHeight * 3) + intButtonBorder
	x2 =intHudXStart + intButtonWidth - intButtonBorder
	y2 =intHudYStart + (intButtonHeight * 4)
	--print(y1 .. ";" .. y2)
	
	if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
		bolAutoConnect = 1 - bolAutoConnect	--flips 0 to 1 and 1 to 0
		--print(bolAutoConnect)
	end
	
	--is autostart toggled?
	x1 = intHudXStart
	y1 =intHudYStart + (intButtonHeight * 2) + intButtonBorder
	x2 =intHudXStart + intButtonWidth - intButtonBorder
	y2 =intHudYStart + (intButtonHeight * 3)
	--print(y1 .. ";" .. y2)
	
	if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
		bolAutoStart = 1 - bolAutoStart	--flips 0 to 1 and 1 to 0
		--print(bolAutoConnect)
	end	
	
	--is autoend toggled?
	x1 = intHudXStart
	y1 =intHudYStart + (intButtonHeight * 1) + intButtonBorder
	x2 =intHudXStart + intButtonWidth - intButtonBorder
	y2 =intHudYStart + (intButtonHeight * 2)
	if MOUSE_X >= x1 and MOUSE_X <= x2 and MOUSE_Y >= y1 and MOUSE_Y < y2 then
		bolAutoEnd = 1 - bolAutoEnd	--flips 0 to 1 and 1 to 0
		--print(bolAutoConnect)
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

end

function tfFSE_main()
	tfFSE_DrawAutoConnect()
	tfFSE_DrawAutoStart()
	tfFSE_DrawAutoEnd()
	tfFSE_DrawLogin()
	tfFSE_DrawRegisterFlight()
	tfFSE_DrawEndFlight()
	tfFSE_DrawCancelFlight()
	tfFSE_DrawOptions()
end

do_every_draw("tfFSE_main()")
do_on_mouse_click("tfFSE_MouseClick()")
