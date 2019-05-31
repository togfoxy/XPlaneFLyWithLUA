
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

dataref("bolEnableRandomFailures", "sim/operation/failures/enable_random_failures","writable")
dataref("intMTBF","sim/operation/failures/mean_time_between_failure_hrs","writable")

function round(num, idp)
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end	

function OutputMessage(strMsg, intNextLine)
	draw_string(15, intNextLine, strMsg, "red")
	intNextMsgLine = intNextMsgLine - 15
end

function draw_failures()

	bolEnableRandomFailures = 1
	intMTBF = 300.0
	
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
end

do_every_draw("draw_failures()")


