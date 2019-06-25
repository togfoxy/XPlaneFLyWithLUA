-- v1.1 Detects a rough landing and deducts 'time' off the MTBF
-- v1.2 Correctly registers a landing and calculates MTBF better
-- v1.3 Added two more failure alerts
-- v1.4 Added a reward for super smooth landings
-- v1.5 Improved compatibility with other scripts
-- v1.6 Added alerts for stalled engine compressor

local intHardLandingLimit = -500
local intRewardLandingLimit = -150
local intNextMsgLine = 450
local bolEnableRandomFailures = 1

require "graphics"

--These should probably be reported
dataref("intRudderTrim", "sim/operation/failures/rel_rud_trim_run")

--Undecided if these should be reported
dataref("intGearActFailed", "sim/operation/failures/rel_gear_act")
dataref("intFlapActFailed", "sim/operation/failures/rel_flap_act")
dataref("intAPFailed", "sim/operation/failures/rel_otto")
dataref("intDeIceFailed", "sim/operation/failures/rel_antice")
dataref("intDepressure", "sim/operation/failures/rel_depres_slow")
dataref("intElecPumpFailed", "sim/operation/failures/rel_hydpmp_ele")
dataref("intManifold1Failed", "sim/operation/failures/rel_MP_ind_0")
dataref("intManifold2Failed", "sim/operation/failures/rel_MP_ind_1")
dataref("intMagneto1Failed","sim/operation/failures/rel_magLFT0")
dataref("intMagneto2Failed","sim/operation/failures/rel_magLFT1")
dataref("intFuelFlow1Failed","sim/operation/failures/rel_eng_lo0")
dataref("intFuelFlow2Failed","sim/operation/failures/rel_eng_lo1")
dataref("intEng1Flameout","sim/operation/failures/rel_engfla0")
dataref("intEng2Flameout","sim/operation/failures/rel_engfla1")
dataref("intEng3Flameout","sim/operation/failures/rel_engfla2")
dataref("intEng4Flameout","sim/operation/failures/rel_engfla3")
dataref("intEng1Seized","sim/operation/failures/rel_seize_0")
dataref("intEng2Seized","sim/operation/failures/rel_seize_1")
dataref("intEng3Seized","sim/operation/failures/rel_seize_2")
dataref("intEng4Seized","sim/operation/failures/rel_seize_3")
dataref("intCom1Failed","sim/operation/failures/rel_com1")
dataref("intStarter1Failed", "sim/operation/failures/rel_startr0")
dataref("intWheelCollapsed", "sim/operation/failures/rel_collapse1")
dataref("intCompressor1Stalled", "sim/operation/failures/rel_comsta0")
dataref("intCompressor2Stalled", "sim/operation/failures/rel_comsta1")

--These are being reported but maybe shouldn't be
dataref("intPFDFailed", "sim/operation/failures/rel_g_pfd")

dataref("bolEnableRandomFailures", "sim/operation/failures/enable_random_failures","writable")


function tffa_round(num, idp)
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end	


function tffa_OutputMessage(strMsg)
	draw_string(15, intNextMsgLine, strMsg, "red")
	intNextMsgLine = intNextMsgLine - 15
end

function draw_failures()
	
	local strMessage = " "
	intNextMsgLine = 450
	
	if intGearActFailed == 6 then
		tffa_OutputMessage("Landing gear failure")
	end
	if intFlapActFailed == 6 then
		tffa_OutputMessage("Flaps failure")
	end
	if intAPFailed == 6 then
		tffa_OutputMessage("Autopilot failure")
	end
	if intDeIceFailed == 6 then
		tffa_OutputMessage("De-icing failure")
	end	
	if intDeIceFailed == 6 then
		tffa_OutputMessage("Cabin depressurising")
	end	
	if intElecPumpFailed == 6 then
		tffa_OutputMessage("Electric hydraulic pump failure")
	end	
	if intManifold1Failed == 6 then
		tffa_OutputMessage("Manifold 1 failure")
	end		
	if intManifold2Failed == 6 then
		tffa_OutputMessage("Manifold 2 failure")
	end			
	if intMagneto1Failed == 6 then
		tffa_OutputMessage("Magneto 1 failure")
	end		
	if intMagneto2Failed == 6 then
		tffa_OutputMessage("Magneto 2 failure")
	end	
	if intFuelFlow1Failed == 6 then
		tffa_OutputMessage("Fuel pump 1 failure")
	end		
	if intFuelFlow2Failed == 6 then
		tffa_OutputMessage("Fuel pump 2 failure")
	end		
	if intEng1Flameout == 6 or intEng2Flameout == 6 or intEng3Flameout == 6 or intEng4Flameout == 6 then
		tffa_OutputMessage("Engine flameout")
	end
	if intEng1Seized == 6 or intEng2Seized == 6 or intEng3Seized == 6 or intEng4Seized == 6 then
		tffa_OutputMessage("Engine seized")
	end	
	if intCom1Failed == 6 then
		tffa_OutputMessage("Radio failure")
	end
	if intPFDFailed == 6 then
		tffa_OutputMessage("Primary flight display failure")
	end
	if intRudderTrim == 6 then	
		tffa_OutputMessage("Rudder failed")
	end
	if intStarter1Failed == 6 then	
		tffa_OutputMessage("Starter failure")
	end	
	if intWheelCollapsed == 6 then	
		tffa_OutputMessage("Landing gear collapse")
	end		

	if intCompressor1Stalled == 6 or intCompressor2Stalled == 6 then	
		tffa_OutputMessage("Compressor stalled")
	end		
end

dataref("bolOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("fltVerticalFPM","sim/flightmodel/position/vh_ind_fpm")
dataref("intMTBF","sim/operation/failures/mean_time_between_failure_hrs","writable")
dataref("datRAlt","sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")

local bolFlying = 0
local fltExcessSpeed = 0

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
		end
				
		--record that we have landed
		bolFlying = 0
		--command_once("sim/operation/pause_toggle")
	end
end



function PreflightInspection()
	--math.randomseed(os.time()) ﻿
	fltRndNum = math.random(0,1)
end



do_every_draw("draw_failures()")
do_every_frame("tffa_DetectCrash()")


