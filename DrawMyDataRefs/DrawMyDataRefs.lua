--v1.0 initial release
--v1.1 Improved compatibility with other scrips

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

dataref("intMTBF","sim/operation/failures/mean_time_between_failure_hrs","writable")

local fltConvNMtoFT = 6076.1
local degAngleToWaypoint = 999.9
local strClosestAirport

local intNextMsgLine = 700



function round(num, idp)
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end	

function tfdmdr_OutputMessage(strMsg, intNextLine)
	draw_string(15, intNextLine, strMsg, "white")
	intNextMsgLine = intNextMsgLine - 15
end

function tfDMDR_GetClosestAirport()
    -- get airport info
	-- sets global variable strClosestAirport
	local navref
    navref = XPLMFindNavAid( nil, nil, LATITUDE, LONGITUDE, nil, xplm_Nav_Airport)
    local logAirportId
    local logAirportName
	
    -- all output we are not intereted in can be send to variable _ (a dummy variable)
	_, _, _, _, _, _, strClosestAirport, _ = XPLMGetNavAidInfo(navref)
end

function DrawMyDataRefs()

	local fltDisttoWPinFT = fltDisttoWP * fltConvNMtoFT
	degAngleToWaypoint = math.deg(math.atan(fltRadarAlt/fltDisttoWPinFT))
	
	--get closest airport
	
	intNextMsgLine = 1040
	
	tfdmdr_OutputMessage("Craft ICAO= " .. strCraftICAO, intNextMsgLine)
	if fltFlapHandle <= 0.1 then
		tfdmdr_OutputMessage("Flaps handle= up", intNextMsgLine)
	elseif fltFlapHandle >= 0.9 then
		tfdmdr_OutputMessage("Flaps handle= down", intNextMsgLine)
	else
		tfdmdr_OutputMessage("Flaps handle= half", intNextMsgLine)		
	end
	
	if fltSpeedBrakeRatio <=0.1 then
		tfdmdr_OutputMessage("Speedbrakes= off", intNextMsgLine)
	elseif fltSpeedBrakeRatio >=0.9 then
		tfdmdr_OutputMessage("Speedbrakes= full", intNextMsgLine)
	else
		tfdmdr_OutputMessage("Speedbrakes= half" , intNextMsgLine)
	end
	
	if intGearHandle == 0 then
		tfdmdr_OutputMessage("Gear handle= up", intNextMsgLine)
	else
		tfdmdr_OutputMessage("Gear handle= down", intNextMsgLine)
	end
	
	if intParkBrake == 0 then
		tfdmdr_OutputMessage("Park brake= off", intNextMsgLine)
	else
		tfdmdr_OutputMessage("Park brake= on", intNextMsgLine)
	end

	tfdmdr_OutputMessage("Wheel brake= " .. round(fltWheelBrake,1), intNextMsgLine)
	
	if bolAutopilotOn == 0 then
		tfdmdr_OutputMessage("Autopilot= off", intNextMsgLine)
	else
		tfdmdr_OutputMessage("Autopilot= on ", intNextMsgLine)
	end
	tfdmdr_OutputMessage("============", intNextMsgLine)
	tfdmdr_OutputMessage("QNH= " .. round((fltQNH * 100),0), intNextMsgLine)
	tfdmdr_OutputMessage("Airspeed setting= " .. fltAirSpeedSetting, intNextMsgLine)
	tfdmdr_OutputMessage("Heading bug= " .. round(fltHeadingBug,0), intNextMsgLine)
	tfdmdr_OutputMessage("V Velocity= " .. intVertVelocity, intNextMsgLine)
	tfdmdr_OutputMessage("Alt setting= " .. intAltDialFt, intNextMsgLine)
	tfdmdr_OutputMessage("Pitch deg= " .. round(fltPitchHold,1), intNextMsgLine)
	tfdmdr_OutputMessage("Angle= " .. round(degAngleToWaypoint,1), intNextMsgLine)
		
	if datRAlt < 25 then
		tfdmdr_OutputMessage("MTBF= " .. round(intMTBF,1), intNextMsgLine)
	end
end


-- do_every_draw("draw_my_datarefs()")
do_every_draw("DrawMyDataRefs()")


