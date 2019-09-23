-- tf_low_vis_lights
-- by TOGFox
-- v0.01

dataref("tf_fltVisibility_Mtr", "sim/graphics/view/visibility_effective_m")
dataref("tf_bolAirportLightsOn", "sim/graphics/scenery/airport_lights_on")
dataref("tf_bolLightsOverride", "sim/operation/override/override_airport_lites", "writable")



function tf_CheckVisibility()

	if tf_fltVisibility_Mtr < 5000 then
		-- check if lights are on
		if tf_bolAirportLightsOn == 0 then
			tf_bolLightsOverride = 1
			tf_bolAirportLightsOn = 1
		end
	else
		tf_bolLightsOverride = 0
	end
end

do_sometimes("tf_CheckVisibility()")