-- Virtual PAPI lights
-- TOGFox
-- v0.01 - initial release
-- v0.02 - adjusted distance to airport by -500m to approximate the end of the runway
--		 - added an indicator(arrow) that shows if you're moving towards the 3 deg glide slope or away from it.
--		 - recalibrated the lights as it was bringing the pilot in too low

local bolDisplayArrow = 1 -- change this to a zero if you do NOT want to see the arrow

--[[
Installation

Place tf_papi.lua file into the FWL Scripts directory. Place tf_common_functions.lua into the FWL Modules directory
How to use

The script works silently and constantly in the background. There is no GUI and no interaction needed from the pilot. To disable the virutual PAPI lights simply delete the tf_papi.lua file (and optionally, the tf_common_functions.lua file).

To disable the script, you can:

    remove the tf_papi.lua file out of your scripts folder

How does it work?

The script monitors the plane's movement during flight and will display virtual PAPI lights in the top left corner of the screen. The lights will appear when:

    the plane is not in replay mode and
    the plane is moving towards the closest airport and
    the plane is 10nm away or less from the closest airport and
    the plane appears to be on a descent angle (3 degree glide slope +/- an element of error)

The virtual PAPI lights will appear when these conditions are met.
Known issues

    Some airports are really close together and this might confuse the plug-in. The lights will still work - but will be "locked" on the wrong airport
    real PAPI lights are calibrated for the end of the runway. The virtual lights are calibrated for the centre of the airport. Excpet slightly inconsisten results.
]]--

require "tf_common_functions"
require "graphics"

dataref("tf_InReplayMode", "sim/time/is_in_replay")
dataref("tf_VerticalFPM","sim/flightmodel/position/vh_ind_fpm")
dataref("tf_PilotAltMSL", "sim/cockpit2/gauges/indicators/altitude_ft_pilot")
dataref("tf_PilotOnTheGround", "sim/flightmodel/failures/onground_any")

local fltLastDistanceToAirport = 999	--previous measurement
local degPreviousAngleToAirport	= 0		--previous measurement

function tfpapi_DrawPAPILights(fltApproachAngle, degAngleChange)
	--draw routines
	local papiX = 25
	local papiY = 915
	
	local firstthreshold = 2.6
	local secondthreshold = 3.0
	local thirdthreshold = 3.5
	local fourththreshold = 3.7
	
	--0 -> 2.6 =   red   red   red   red
	--2.7 -> 2.9 = white red   red   red
	--3.0 -> 3.2 = white white red   red
	--3.3 -> 3.5 = white white white red
	--3.6 -> 5.0 = white white white white
	
	--first papi
	if fltApproachAngle <= firstthreshold then	
		graphics.set_color(1,0,0,0.5) -- red light
	else
		graphics.set_color(1,1,1,0.5) -- white light
	end
	graphics.draw_filled_circle(papiX,papiY, 7)

	--second papi
	if fltApproachAngle <= secondthreshold then	
		graphics.set_color(1,0,0,0.5) -- red light
	else
		graphics.set_color(1,1,1,0.5) -- white light
	end
	graphics.draw_filled_circle(papiX + 20,papiY, 7)	

	--third papi
	if fltApproachAngle <= thirdthreshold then	
		graphics.set_color(1,0,0,0.5) -- red light
	else
		graphics.set_color(1,1,1,0.5) -- white light
	end
	graphics.draw_filled_circle(papiX + 40,papiY, 7)

	--fourth papi
	if fltApproachAngle <= fourththreshold then	
		graphics.set_color(1,0,0,0.5) -- red light
	else
		graphics.set_color(1,1,1,0.5) -- white light
	end
	graphics.draw_filled_circle(papiX + 60,papiY, 7)	
	
	if bolDisplayArrow == 1 then
		--determine the colour for the arrow
		if (fltApproachAngle < 3.2 and degAngleChange < 0) or (fltApproachAngle > 3.2 and degAngleChange >0) then
			--outside the slope and geting wore is bad. Red
			graphics.set_color(1,0,0,0.5) -- red
		else
			graphics.set_color(0,0.5,0,0.5) -- green
		end
		
		graphics.draw_string(papiX, (papiY - 40), degAngleChange)
		graphics.draw_string(papiX, (papiY - 55), fltApproachAngle)
		
		if fltApproachAngle > secondthreshold and fltApproachAngle <=thirdthreshold then  --if 2nd light is white and 3rd light is red then ...		
			--on glide slope - don't draw an arrow
		else
			if degAngleChange > 0.0002 then	--changes are very minute so we go to quite a few decimal places
				graphics.draw_angle_arrow(papiX+80, papiY -3,0,15,7.5,2)
			elseif degAngleChange < -0.0002 then
				graphics.draw_angle_arrow(papiX+80, papiY +3,180,15,7.5,2)
			else
				graphics.set_color(1,1,1,0.5) -- white
				graphics.draw_angle_line(papiX+76, papiY,90,15)
			end
		end
	end

end

function tfpapi_main()
	local arrAirportDetails = tf_common_functions.tf_GetClosestAirportInformation(LATITUDE, LONGITUDE) --, arrAirportDetails)
	local fltDistanceToAirport	--current distance

	local degAngleToAirport
	local fltAltitudeDifference
	local fltConvNMtoFT = 6076.1
	local degDelta					--tracks the angle (degrees) change during approach
	
	if tf_InReplayMode == 0 then	--make sure we're not in replay mode
		fltDistanceToAirport = tf_common_functions.tf_distanceInNM(LATITUDE,LONGITUDE,arrAirportDetails["Lat"],arrAirportDetails["Long"])
		--print(fltDistanceToAirport - 0.750)
		if fltDistanceToAirport <= 10 and (fltDistanceToAirport < fltLastDistanceToAirport) then	--pilot is close to the airport and approaching
			--determine approach angle
			--determine difference in altitude_ft_pilot
			fltAltitudeDifference = (tf_PilotAltMSL) - (arrAirportDetails["Height"] * 3.28 ) --convert meters to feet
			
			--the next line does some trigonometry with the altitude difference, distance to airport (less an arbitrary 500m to approxiate the
			--end of the runway), and includes a conversion of NM to ft
			degAngleToAirport = math.deg(math.atan(fltAltitudeDifference/((fltDistanceToAirport - 0.750) * fltConvNMtoFT )))
			
			--graphics.draw_string(25, 375, degAngleToAirport)
			
			if degAngleToAirport >= 2.0 and degAngleToAirport <= 3.5 then	--disable lights if it is clear pilit is not shooting for runway
				--start drawing papi
				if tf_PilotOnTheGround == 0 and fltAltitudeDifference > 0.25 then	--don't draw lights if on ground or closer than 1/2 nm
					--work out if angle is increasing or decreasing
					degDelta = degAngleToAirport - degPreviousAngleToAirport
					tfpapi_DrawPAPILights(degAngleToAirport, degDelta)
				end
			end
			
			--graphics.draw_string(25, 400, degPreviousAngleToAirport .. " : " .. degAngleToAirport)

			degPreviousAngleToAirport = degAngleToAirport
		end
		--print (round(fltLastDistanceToAirport,1) .. " " .. round(fltDistanceToAirport,1))
		fltLastDistanceToAirport = fltDistanceToAirport
	end

end

--do_sometimes("tfpapi_main()")
do_every_draw("tfpapi_main()")
