-- -- -- -- -- -- -- -- -- -- -- -- --
-- -- TOGFox PAPI
-- -- v0.01
-- -- -- -- -- -- -- -- -- -- -- -- --

require "tf_common_functions"
require "graphics"

dataref("tf_InReplayMode", "sim/time/is_in_replay")
dataref("tf_VerticalFPM","sim/flightmodel/position/vh_ind_fpm")
dataref("tf_PilotAltMSL", "sim/cockpit2/gauges/indicators/altitude_ft_pilot")
dataref("tf_PilotOnTheGround", "sim/flightmodel/failures/onground_any")

local fltLastDistanceToAirport = 999	--previous measurement

function tfpapi_DrawPAPILights(fltApproachAngle)
	--draw routines
	local papiX = 25
	local papiY = 915
	
	--0 -> 2.6 =   red   red   red   red
	--2.7 -> 2.9 = white red   red   red
	--3.0 -> 3.2 = white white red   red
	--3.3 -> 3.5 = white white white red
	--3.6 -> 5.0 = white white white white
	
	
	if fltApproachAngle <= 2.6 then	
		graphics.set_color(1,0,0,0.5) -- red light
	else
		graphics.set_color(1,1,1,0.5) -- white light
	end
	graphics.draw_filled_circle(papiX,papiY, 7)

	if fltApproachAngle <= 2.9 then	
		graphics.set_color(1,0,0,0.5) -- red light
	else
		graphics.set_color(1,1,1,0.5) -- white light
	end
	graphics.draw_filled_circle(papiX + 20,papiY, 7)	

	if fltApproachAngle <= 3.2 then	
		graphics.set_color(1,0,0,0.5) -- red light
	else
		graphics.set_color(1,1,1,0.5) -- white light
	end
	graphics.draw_filled_circle(papiX + 40,papiY, 7)

	if fltApproachAngle <= 3.5 then	
		graphics.set_color(1,0,0,0.5) -- red light
	else
		graphics.set_color(1,1,1,0.5) -- white light
	end
	graphics.draw_filled_circle(papiX + 60,papiY, 7)	
	
	--graphics.draw_string(papiX, (papiY - 40), fltApproachAngle)

end

function tfpapi_main()
	local arrAirportDetails = tf_common_functions.tf_GetClosestAirportInformation(LATITUDE, LONGITUDE) --, arrAirportDetails)
	local fltDistanceToAirport	--current distance

	local degAngleToAirport
	local fltAltitudeDifference
	local fltConvNMtoFT = 6076.1
	
	if tf_InReplayMode == 0 then	--make sure we're not in replay mode
		fltDistanceToAirport = tf_common_functions.tf_distanceInNM(LATITUDE,LONGITUDE,arrAirportDetails["Lat"],arrAirportDetails["Long"])
		if fltDistanceToAirport <= 10 and (fltDistanceToAirport < fltLastDistanceToAirport) then	--pilot is close to the airport and approaching
			--determine approach angle
			--determine difference in altitude_ft_pilot
			fltAltitudeDifference = (tf_PilotAltMSL) - (arrAirportDetails["Height"] * 3.28 ) --convert meters to feet
			--graphics.draw_string(25, 400, tf_PilotAltMSL .. " " .. (arrAirportDetails["Height"] * 3.28))
			degAngleToAirport = math.deg(math.atan(fltAltitudeDifference/(fltDistanceToAirport * fltConvNMtoFT )))
			
			--graphics.draw_string(25, 375, degAngleToAirport)
			
			if degAngleToAirport >= 2.0 and degAngleToAirport <= 3.5 then	--disable lights if it is clear pilit is not shooting for runway
				--start drawing papi
				if tf_PilotOnTheGround == 0 and fltAltitudeDifference > 0.25 then	--don't draw lights if on ground or closer than 1/2 nm
					tfpapi_DrawPAPILights(degAngleToAirport)
				end
			end

		end
		--print (round(fltLastDistanceToAirport,1) .. " " .. round(fltDistanceToAirport,1))
		fltLastDistanceToAirport = fltDistanceToAirport
	end

end


--do_sometimes("tfpapi_main()")
do_every_draw("tfpapi_main()")
