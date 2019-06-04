dataref("strCraftICAO", "sim/aircraft/view/acf_ICAO")
dataref("fltFlapHandle","sim/flightmodel2/controls/flap_handle_deploy_ratio")
dataref("fltSpeedBrakeRatio", "sim/cockpit2/controls/speedbrake_ratio")
dataref("intGearHandle","sim/cockpit/switches/gear_handle_status")
dataref("intParkBrake","sim/flightmodel/controls/parkbrake")
dataref("fltWheelBrake","sim/cockpit2/controls/left_brake_ratio")
dataref("fltHeadingBug","sim/cockpit/autopilot/heading_mag")
dataref("fltAirSpeedSetting","sim/cockpit2/autopilot/airspeed_dial_kts")
dataref("intVertVelocity","sim/cockpit/autopilot/vertical_velocity")
dataref("intAltDialFt","sim/cockpit2/autopilot/altitude_dial_ft")
dataref("fltPitchHold","sim/cockpit2/autopilot/sync_hold_pitch_deg")
dataref("fltBarometer","sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot")
dataref("bolAutopilotOn","sim/cockpit2/autopilot/servos_on")
dataref("fltRadarAlt", "sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
dataref("fltDisttoWP", "sim/cockpit2/radios/indicators/gps_dme_distance_nm")
dataref("fltQNH", "sim/weather/barometer_sealevel_inhg")

local fltConvNMtoFT = 6076.1
local degAngleToWaypoint = 999.9

function round(num, idp)
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end	

function OutputMessage(strMsg, intNextLine)
	draw_string(15, intNextLine, strMsg, "white")
	intNextMsgLine = intNextMsgLine - 15
end

intNextMsgLine = 700
function DrawMyDataRefs()

	local fltDisttoWPinFT = fltDisttoWP * fltConvNMtoFT
	degAngleToWaypoint = math.deg(math.atan(fltRadarAlt/fltDisttoWPinFT))
	
	intNextMsgLine = 1040
	
	OutputMessage("Craft ICAO= " .. strCraftICAO, intNextMsgLine)
	if fltFlapHandle <= 0.1 then
		OutputMessage("Flaps handle= up", intNextMsgLine)
	elseif fltFlapHandle >= 0.9 then
		OutputMessage("Flaps handle= down", intNextMsgLine)
	else
		OutputMessage("Flaps handle= half", intNextMsgLine)		
	end
	
	if fltSpeedBrakeRatio <=0.1 then
		OutputMessage("Speedbrakes= off", intNextMsgLine)
	elseif fltSpeedBrakeRatio >=0.9 then
		OutputMessage("Speedbrakes= full", intNextMsgLine)
	else
		OutputMessage("Speedbrakes= half" , intNextMsgLine)
	end
	
	if intGearHandle == 0 then
		OutputMessage("Gear handle= up", intNextMsgLine)
	else
		OutputMessage("Gear handle= down", intNextMsgLine)
	end
	
	if intParkBrake == 0 then
		OutputMessage("Park brake= off", intNextMsgLine)
	else
		OutputMessage("Park brake= on", intNextMsgLine)
	end

	OutputMessage("Wheel brake= " .. round(fltWheelBrake,1), intNextMsgLine)
	OutputMessage("============", intNextMsgLine)
	OutputMessage("QNH= " .. round((fltQNH * 100),0), intNextMsgLine)
	
	if bolAutopilotOn == 0 then
		OutputMessage("Autopilot= off", intNextMsgLine)
	else
		OutputMessage("Autopilot= on ", intNextMsgLine)
	end
	
	OutputMessage("Airspeed setting= " .. fltAirSpeedSetting, intNextMsgLine)
	OutputMessage("Heading bug= " .. round(fltHeadingBug,0), intNextMsgLine)
	OutputMessage("V Velocity= " .. intVertVelocity, intNextMsgLine)
	OutputMessage("Alt setting= " .. intAltDialFt, intNextMsgLine)
	OutputMessage("Pitch deg= " .. round(fltPitchHold,1), intNextMsgLine)
	OutputMessage("Angle= " .. round(degAngleToWaypoint,1), intNextMsgLine)
	
end

-- do_every_draw("draw_my_datarefs()")
do_every_draw("DrawMyDataRefs()")


