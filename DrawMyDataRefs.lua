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

function round(num, idp)
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end	

function draw_my_datarefs()
	
	pos = bubble(15,850, "Craft ICAO= " .. strCraftICAO, 
							"Flaps handle= " .. fltFlapHandle, 
							'Speedbrakes= ' .. fltSpeedBrakeRatio, 
							"Gear handle= " .. intGearHandle,
							"Park brake= " .. intParkBrake,
							"Wheel brake= " .. fltWheelBrake,
							"==================",
							"Autopilot on= " .. bolAutopilotOn,
							"Airspeed setting= " .. fltAirSpeedSetting,
							"Heading bug= " .. round(fltHeadingBug,0),
							"V Velocity= " .. intVertVelocity,
							"Alt setting= " .. intAltDialFt,
							"Pitch deg= " .. round(fltPitchHold,1)
							)
	
end

do_every_draw("draw_my_datarefs()")


