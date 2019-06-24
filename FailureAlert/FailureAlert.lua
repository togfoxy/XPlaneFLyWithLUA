-- v1.1 Detects a rough landing and deducts 'time' off the MTBF
-- v1.2 Correctly registers a landing and calculates MTBF better
-- v1.3 Added two more failure alerts
-- v1.4 Added a reward for super smooth landings

intHardLandingLimit = -500
intRewardLandingLimit = -150

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

--These are being reported but maybe shouldn't be
dataref("intPFDFailed", "sim/operation/failures/rel_g_pfd")

dataref("bolEnableRandomFailures", "sim/operation/failures/enable_random_failures","writable")
bolEnableRandomFailures = 1

function round(num, idp)
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end	


function OutputMessage(strMsg, intNextLine)
	draw_string(15, intNextLine, strMsg, "white")
	intNextMsgLine = intNextMsgLine - 15
end

function draw_failures()
	
	local strMessage = " "
	intNextMsgLine = 450
	
	if intGearActFailed == 6 then
		OutputMessage("Landing gear failure", intNextMsgLine)
	end
	if intFlapActFailed == 6 then
		OutputMessage("Flaps failure", intNextMsgLine)
	end
	if intAPFailed == 6 then
		OutputMessage("Autopilot failure", intNextMsgLine)
	end
	if intDeIceFailed == 6 then
		OutputMessage("De-icing failure", intNextMsgLine)
	end	
	if intDeIceFailed == 6 then
		OutputMessage("Cabin depressurising", intNextMsgLine)
	end	
	if intElecPumpFailed == 6 then
		OutputMessage("Electric hydraulic pump failure", intNextMsgLine)
	end	
	if intManifold1Failed == 6 then
		OutputMessage("Manifold 1 failure", intNextMsgLine)
	end		
	if intManifold2Failed == 6 then
		OutputMessage("Manifold 2 failure", intNextMsgLine)
	end			
	if intMagneto1Failed == 6 then
		OutputMessage("Magneto 1 failure", intNextMsgLine)
	end		
	if intMagneto2Failed == 6 then
		OutputMessage("Magneto 2 failure", intNextMsgLine)
	end	
	if intFuelFlow1Failed == 6 then
		OutputMessage("Fuel pump 1 failure", intNextMsgLine)
	end		
	if intFuelFlow2Failed == 6 then
		OutputMessage("Fuel pump 2 failure", intNextMsgLine)
	end		
	if intEng1Flameout == 6 or intEng2Flameout == 6 or intEng3Flameout == 6 or intEng4Flameout == 6 then
		OutputMessage("Engine flameout", intNextMsgLine)
	end
	if intEng1Seized == 6 or intEng2Seized == 6 or intEng3Seized == 6 or intEng4Seized == 6 then
		OutputMessage("Engine seized", intNextMsgLine)
	end	
	if intCom1Failed == 6 then
		OutputMessage("Radio failure", intNextMsgLine)
	end
	if intPFDFailed == 6 then
		OutputMessage("Primary flight display failure", intNextMsgLine)
	end
	if intRudderTrim == 6 then	
		OutputMessage("Rudder failed", intNextMsgLine)
	end
	if intStarter1Failed == 6 then	
		OutputMessage("Starter failure", intNextMsgLine)
	end	
	if intWheelCollapsed == 6 then	
		OutputMessage("Landing gear collapse", intNextMsgLine)
	end		

	
end

dataref("bolOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("fltVerticalFPM","sim/flightmodel/position/vh_ind_fpm")
dataref("intMTBF","sim/operation/failures/mean_time_between_failure_hrs","writable")
dataref("datRAlt","sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")

local bolFlying = 0
local fltExcessSpeed = 0

function DetectCrash()
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
do_every_frame("DetectCrash()")


