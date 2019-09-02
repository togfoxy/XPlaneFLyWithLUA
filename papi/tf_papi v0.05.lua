-- Virtual PAPI lights
-- TOGFox
-- v0.01 	- initial release
-- v0.02 	- adjusted distance to airport by -500m to approximate the end of the runway
--		 	- added an indicator(arrow) that shows if you're moving towards the 3 deg glide slope or away from it.
--		 	- recalibrated the lights as it was bringing the pilot in too low
-- v0.03 	- added the ICAO text message
-- v0.04 	- added some complex predictive formula's to try to predict where the plane is intending to land and lock on to that airport
--			- re-calibrated the lights to work for YFLI (sea-level)
--			- now requires common functions v0.03
-- v0.05	- finally fixed bug with assuming incorrect AGL
--			- correctly calibrated red/white lights to 3.2 degrees
			

local bolDisplayArrow = 1 -- change this to a zero if you do NOT want to see the arrow
local papiX = 25
local papiY = 915

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

local tf_common_functions = require "tf_common_functions_003"
require "graphics"

dataref("tf_InReplayMode", "sim/time/is_in_replay")
dataref("tf_VerticalFPM","sim/flightmodel/position/vh_ind_fpm")
dataref("tf_PilotAltMSL", "sim/cockpit2/gauges/indicators/altitude_ft_pilot")
dataref("tf_PilotOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("tf_AltAGL","sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")

dataref("tf_GroundSpeed", "sim/flightmodel/position/groundspeed")
dataref("tf_PlaneHeading", "sim/flightmodel/position/psi")

local fltLat2
local fltLong2

local fltLastDistanceToAirport = 999	--previous measurement
local degPreviousAngleToAirport	= 0		--previous measurement

function tfpapi_DrawPAPILights(fltApproachAngle, degAngleChange)
	--draw routines

	local firstthreshold = 2.8
	local secondthreshold = 3.00
	--						3.2
	local thirdthreshold = 3.4
	local fourththreshold = 3.6
	
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
		
		--graphics.draw_string(papiX, (papiY - 40), degAngleChange)
		--graphics.draw_string(papiX, (papiY - 55), fltApproachAngle)
		
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
	local arrAirportDetails = {}
	local fltDistanceToAirport	--current distance
	local fltTimeToAirportInSeconds	--assumed flight time to reach the destination airport
	local degAngleToAirport
	local fltAltitudeDifference
	local fltConvNMtoFT = 6076.1
	local degDelta			--tracks the angle (degrees) change during approach. Tells us if plane is moving towards or away from glide slope
	local PredictedLat		--this is where we think the craft will be
	local PredictedLong		--this is where we think the craft will be
	
	if tf_InReplayMode == 0 then	--make sure we're not in replay mode
		--because airports can be bunched in pretty tight, we DON'T always want to find the closest airport to the current location because
		--sometimes we want to find the closest airport to where we will be in 2 minutes. In other words - it's a poor man's "look ahead" algorithm
		--To make this smarter, we can apply different rules when on long, medium and short final, based on altitude.
		
		--If the craft is on approach at 3000 feet then the most likely destination is somewhere 10nm in front of the craft.
		--If the craft is on approach at 1500 feet then the most likely destination is 5nm in front of the craft. etc.
		--If the craft is outside expected/normal altitudes then it doesn't matter - the lights won't work anyway!

		fltDistanceInNM = 0		--a default value
	
		if tf_AltAGL >= 150 and tf_AltAGL <= 451 then
			fltDistanceInNM = 1
		end
		if tf_AltAGL >= 450 and tf_AltAGL <= 751 then
			fltDistanceInNM = 2
		end
		if tf_AltAGL >= 750 and tf_AltAGL <= 1051 then
			fltDistanceInNM = 3
		end
		if tf_AltAGL >= 1050 and tf_AltAGL <= 1351 then
			fltDistanceInNM = 4
		end
		if tf_AltAGL >= 1350 and tf_AltAGL <= 1651 then
			fltDistanceInNM = 5
		end
		if tf_AltAGL >= 1650 and tf_AltAGL <= 1951 then
			fltDistanceInNM = 6
		end
		if tf_AltAGL >= 1950 and tf_AltAGL <= 2251 then
			fltDistanceInNM = 7
		end
		if tf_AltAGL >= 2250 and tf_AltAGL <= 2551 then
			fltDistanceInNM = 8
		end
		if tf_AltAGL >= 2550 and tf_AltAGL <= 2851 then
			fltDistanceInNM = 9
		end
		if tf_AltAGL >= 2850 and tf_AltAGL <= 4000 then
			fltDistanceInNM = 10
		end		
		
		--print("Heading:" .. tf_PlaneHeading)
		PredictedLat = 0
		PredictedLong = 0

		--[[
		print("Distance NM:" .. fltDistanceInNM .. " Bearing:" .. tf_PlaneHeading)
		
		local arrTemp = tf_common_functions.AddNMToLatLong(LATITUDE,LONGITUDE, fltDistanceInNM, 0)
		PredictedLat = arrTemp["Lat"]
		PredictedLong = arrTemp["Long"]
		print("Bearing 0")
		print("Lat1:" .. PredictedLat .. " Long1:" .. PredictedLong)
		print("==============")
		
		
		local arrTemp = tf_common_functions.AddNMToLatLong(LATITUDE,LONGITUDE, fltDistanceInNM, 90)
		PredictedLat = arrTemp["Lat"]
		PredictedLong = arrTemp["Long"]
		print("Bearing 90")
		print("Lat1:" .. PredictedLat .. " Long1:" .. PredictedLong)
		print("==============")

		
		local arrTemp = tf_common_functions.AddNMToLatLong(LATITUDE,LONGITUDE, fltDistanceInNM, 180)
		PredictedLat = arrTemp["Lat"]
		PredictedLong = arrTemp["Long"]
		print("Bearing 180")
		print("Lat1:" .. PredictedLat .. " Long1:" .. PredictedLong)
		print("==============")
		
		local arrTemp = tf_common_functions.AddNMToLatLong(LATITUDE,LONGITUDE, fltDistanceInNM, 270)
		PredictedLat = arrTemp["Lat"]
		PredictedLong = arrTemp["Long"]
		print("Bearing 270")
		print("Lat1:" .. PredictedLat .. " Long1:" .. PredictedLong)
		print("==============")		
		
		
		local arrTemp = tf_common_functions.AddNMToLatLong(LATITUDE,LONGITUDE, fltDistanceInNM, tf_PlaneHeading)
		PredictedLat = arrTemp["Lat"]
		PredictedLong = arrTemp["Long"]
		print("Bearing " .. tf_PlaneHeading)
		print("Lat1:" .. PredictedLat .. " Long1:" .. PredictedLong)
		print("==============")		
		]]--
		if fltDistanceInNM > 0 then
			--Send the current location, how far we need to scan ahead, and current flight heading into this function
			--and retrieve back the predicted lat/long for this aircraft
			local arrTemp = tf_common_functions.AddNMToLatLong(LATITUDE,LONGITUDE, fltDistanceInNM, tf_PlaneHeading)
			PredictedLat = arrTemp["Lat"]
			PredictedLong = arrTemp["Long"]
		end
	
		--Now that we know where we might be in x seconds from now, lets see what the closest airport to this predicted position is
		arrAirportDetails = tf_common_functions.tf_GetClosestAirportInformation(PredictedLat, PredictedLong) 
	
		--Now that we know what is the closest airport to the PREDICTED position, we need to find out what that airport is and how far away it is
		fltDistanceToAirport = tf_common_functions.tf_distanceInNM(LATITUDE,LONGITUDE,arrAirportDetails["Lat"],arrAirportDetails["Long"])
		
		--print("Closest airport:"..arrAirportDetails["ICAO"] .. " Distance:" .. fltDistanceToAirport .. " Looking ahead:" .. fltDistanceInNM)
	
		--print(LATITUDE)
		--print(LONGITUDE)
		--print("***")
		--print (tf_PilotAltMSL)
		--print (arrAirportDetails["Height"] * 3.28)	
		--print(tf_PilotAltMSL .. "-" .. (arrAirportDetails["Height"] * 3.28) .. "=" .. (tf_PilotAltMSL) - (arrAirportDetails["Height"] * 3.28 ))
		if fltDistanceToAirport <= 10 and (fltDistanceToAirport < fltLastDistanceToAirport) then	--pilot is close to the airport and approaching
			--print("alpha")
			--determine approach angle
			--determine difference in altitude_ft_pilot

			fltAltitudeDifference = (tf_PilotAltMSL) - (arrAirportDetails["Height"] * 3.28 ) --convert meters to feet
			
			
			--the next line does some trigonometry with the altitude difference, distance to airport (less an arbitrary 500m to approxiate the
			--end of the runway), and includes a conversion of NM to ft
			degAngleToAirport = math.deg(math.atan(fltAltitudeDifference/((fltDistanceToAirport - 0.750) * fltConvNMtoFT )))
			
			if degAngleToAirport >= 2.5 and degAngleToAirport <= 4.0 then	--disable lights if it is clear pilot is not shooting for runway
				--print("beta")
				--start drawing papi
				if tf_PilotOnTheGround == 0 and fltAltitudeDifference > 0.25 then	--don't draw lights if on ground or closer than 250 feet to the ground
					--print("charlie")
					--work out if angle is increasing or decreasing. This is passed to the draw function so it can draw the arrow
					degDelta = degAngleToAirport - degPreviousAngleToAirport
					tfpapi_DrawPAPILights(degAngleToAirport, degDelta)
					graphics.draw_string(papiX - 5, papiY+20, arrAirportDetails["ICAO"], "white")
				end
			else
				--print("Outside glide slope:" .. degAngleToAirport)
			end
			
			degPreviousAngleToAirport = degAngleToAirport
		end
		--print (round(fltLastDistanceToAirport,1) .. " " .. round(fltDistanceToAirport,1))
		fltLastDistanceToAirport = fltDistanceToAirport
	end

end

do_every_draw("tfpapi_main()")
