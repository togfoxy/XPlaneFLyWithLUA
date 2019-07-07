-- Rough landings
-- TOGFox
-- Detects a rough landing and reduces the MTBF for aircraft (global setting)
-- v0.01 - initial release

local intHardLandingLimit = -500	--you can adjust this up or down but make sure it is a negative value
local intRewardLandingLimit = -150  --you can adjust this up or down but make sure it is a negaive value and greater than the
									--hard landing limit. i.e -500 < -150 < 0


dataref("bolOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("fltVerticalFPM","sim/flightmodel/position/vh_ind_fpm")
dataref("intMTBF","sim/operation/failures/mean_time_between_failure_hrs","writable")
dataref("datRAlt","sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
dataref("bolEnableRandomFailures", "sim/operation/failures/enable_random_failures","writable")

local bolFlying = 0
local fltExcessSpeed = 0
local bolEnableRandomFailures = 1

function tffa_DetectCrash()
	if datRAlt > 15 then
		--we have taken off. Record that fact
		bolFlying = 1
	end
	
	if bolOnTheGround == 1 and bolFlying == 1 then
		--detected a landing
		fltExcessSpeed = fltVerticalFPM - intHardLandingLimit
		if fltExcessSpeed > 0 then
			fltExcessSpeed = 0
		end
		
		--deduct excess speed off the MTBF
		intMTBF = intMTBF + fltExcessSpeed
		
		if intMTBF < 500 then
			intMTBF = 500
		end
		
		--reward a super smooth landing
		if fltVerticalFPM >= intRewardLandingLimit then
			intMTBF = intMTBF + 50
			if intMTBF > 15000 then
				intMTBF = 15000
			end
		end
				
		--record that we have landed
		bolFlying = 0
		--command_once("sim/operation/pause_toggle")
	end
end

do_every_frame("tffa_DetectCrash()")