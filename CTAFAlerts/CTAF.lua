--v0.1 initial release

dataref("bolInReplayMode","sim/time/is_in_replay")
dataref("bolOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("fltVerticalFPM","sim/flightmodel/position/vh_ind_fpm")

dataref("fltPlane1Lat", "sim/multiplayer/position/plane2_lat")
dataref("fltPlane1Long", "sim/multiplayer/position/plane2_lon")

local loopcount = 0
local fltRecentAirportLat
local fltRecentAirportLong
local strRecentAirportName

function tfCTAF_deg2rad(deg)
    return deg * (math.pi/180)
end

function tfCTAF_distanceInNM(lat1, lon1, lat2, lon2)
    local R = 6371 -- Radius of the earth in km
    local dLat = tfCTAF_deg2rad(lat2-lat1)
    local dLon = tfCTAF_deg2rad(lon2-lon1);
    local a = math.sin(dLat/2) * math.sin(dLat/2) +
        math.cos(tfCTAF_deg2rad(lat1)) * math.cos(tfCTAF_deg2rad(lat2)) * 
        math.sin(dLon/2) * math.sin(dLon/2)
    local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    local d = R * c * 0.539956803 -- distance in nm
    return d
end

function tfCTAF_GetClosestAirport(tmpLat, tmpLong)
    -- get airport info
	-- sets variable strClosestAirport
	
	local navref
	
    navref = XPLMFindNavAid( nil, nil, tmpLat, tmpLong, nil, xplm_Nav_Airport)
	
	-- all output we are not intereted in can be send to variable _ (a dummy variable)
	_, fltRecentAirportLat, fltRecentAirportLong, _, _, _, result, _ = XPLMGetNavAidInfo(navref)


	--strRecentAirportName = result
	return result
end

function tfCTAF_main()
	local strPilotsClosestAirport
	local strPlane1ClosestAirport
	local fltPlane1DistanceToAirport

	
	--if the pilot is descending and
		--not on the ground
		--then check every ai plane
			--to see if they are at the same airport and within 2nm of that airport.

	--check that the pilot is descending (i.e. on approach)
	--print("check 1")
	if fltVerticalFPM <= -100 then
		--print("check 2")
		--ensure plane has not landed (still in flight)
		if bolOnTheGround == 0 then
			--print("check 3")
			--check for each aircraft
			
			strPilotsClosestAirport = tfCTAF_GetClosestAirport(LATITUDE, LONGITUDE)
			strPlane1ClosestAirport = tfCTAF_GetClosestAirport(fltPlane1Lat,fltPlane1Long)
			
			--print(strPilotsClosestAirport .. strPlane1ClosestAirport)
			
			if strPilotsClosestAirport == strPlane1ClosestAirport then
				
				--print("check 4")
				--see if AI is within 2nm of airport
				fltPlane1DistanceToAirport = tfCTAF_distanceInNM(fltRecentAirportLat, fltRecentAirportLong, fltPlane1Lat,fltPlane1Long)
				--print("****************")
				--print(strRecentAirportName)
				--print(fltRecentAirportLat)
				--print(fltRecentAirportLong)
				--print(fltPlane1Lat)
				--print(fltPlane1Long)
				
				--print("distance = " .. fltPlane1DistanceToAirport)
				--print("Pilot distance = " .. tfCTAF_distanceInNM(fltRecentAirportLat, fltRecentAirportLong, LATITUDE,LONGITUDE))
				if fltPlane1DistanceToAirport <= 6 then	--remember this is in km
					--AI is close enough for CTAF reports
					if loopcount >= 3 then
						--print("check 5")
						XPLMSpeakString("CTAF alert")
						loopcount = 0
					else
						--print("check 6: loop = " .. loopcount )
						loopcount = loopcount + 1
					end
				end
			end
		end
	end
end

do_sometimes("tfCTAF_main()")