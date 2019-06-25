--v0.1 initial release
--v0.2 Now supports up to 11 AI planes

local fltAIPlaneLat = {0,0,0,0,0,0,0,0,0,0,0}
local fltAIPlaneLong= {}

dataref("tfCTAF_bolInReplayMode","sim/time/is_in_replay")
dataref("bolOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("fltVerticalFPM","sim/flightmodel/position/vh_ind_fpm")

dataref("tmpLat1", "sim/multiplayer/position/plane1_lat")
dataref("tmpLon1", "sim/multiplayer/position/plane1_lon")
fltAIPlaneLat[1] = tmpLat1
fltAIPlaneLong[1]= tmpLon1

dataref("tmpLat2", "sim/multiplayer/position/plane2_lat")
dataref("tmpLon2", "sim/multiplayer/position/plane2_lon")
fltAIPlaneLat[2] = tmpLat2
fltAIPlaneLong[2]= tmpLon2

dataref("tmpLat3", "sim/multiplayer/position/plane3_lat")
dataref("tmpLon3", "sim/multiplayer/position/plane3_lon")
fltAIPlaneLat[3] = tmpLat3
fltAIPlaneLong[3]= tmpLon3

dataref("tmpLat4", "sim/multiplayer/position/plane4_lat")
dataref("tmpLon4", "sim/multiplayer/position/plane4_lon")
fltAIPlaneLat[4] = tmpLat4
fltAIPlaneLong[4]= tmpLon4

dataref("tmpLat5", "sim/multiplayer/position/plane5_lat")
dataref("tmpLon5", "sim/multiplayer/position/plane5_lon")
fltAIPlaneLat[5] = tmpLat5
fltAIPlaneLong[5]= tmpLon5

dataref("tmpLat6", "sim/multiplayer/position/plane6_lat")
dataref("tmpLon6", "sim/multiplayer/position/plane6_lon")
fltAIPlaneLat[6] = tmpLat6
fltAIPlaneLong[6]= tmpLon6

dataref("tmpLat7", "sim/multiplayer/position/plane7_lat")
dataref("tmpLon7", "sim/multiplayer/position/plane7_lon")
fltAIPlaneLat[7] = tmpLat7
fltAIPlaneLong[7]= tmpLon7

dataref("tmpLat8", "sim/multiplayer/position/plane8_lat")
dataref("tmpLon8", "sim/multiplayer/position/plane8_lon")
fltAIPlaneLat[8] = tmpLat8
fltAIPlaneLong[8]= tmpLon8

dataref("tmpLat9", "sim/multiplayer/position/plane9_lat")
dataref("tmpLon9", "sim/multiplayer/position/plane9_lon")
fltAIPlaneLat[9] = tmpLat9
fltAIPlaneLong[9]= tmpLon9

dataref("tmpLat10", "sim/multiplayer/position/plane10_lat")
dataref("tmpLon10", "sim/multiplayer/position/plane10_lon")
fltAIPlaneLat[10] = tmpLat10
fltAIPlaneLong[10]= tmpLon10

dataref("tmpLat11", "sim/multiplayer/position/plane11_lat")
dataref("tmpLon11", "sim/multiplayer/position/plane11_lon")
fltAIPlaneLat[11] = tmpLat11
fltAIPlaneLong[11]= tmpLon11

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
	--print("********************")
	--print(fltAIPlaneLat[2])
	if fltVerticalFPM <= -100 and tfCTAF_bolInReplayMode == 0 then
		--print("check 2")
		--ensure plane has not landed (still in flight)
		if bolOnTheGround == 0 then
			--print("check 3")
			--check for each aircraft
			
			strPilotsClosestAirport = tfCTAF_GetClosestAirport(LATITUDE, LONGITUDE)
			
			for i=2,11 do
				--print("I = " .. i )
				--print(" and fltAIPlaneLat = " .. fltAIPlaneLat[4])
				strAIPlaneClosestAirport = tfCTAF_GetClosestAirport(fltAIPlaneLat[i],fltAIPlaneLong[i])
				if strPilotsClosestAirport == strAIPlaneClosestAirport then
					--print("Check 3")
					fltAIPlaneDistanceToAirport = tfCTAF_distanceInNM(fltRecentAirportLat, fltRecentAirportLong, fltAIPlaneLat[i],fltAIPlaneLong[i])
					if fltAIPlaneDistanceToAirport <= 6 then	-- this is in km
						--print ("Check 4")
						if loopcount >= 3 then
							XPLMSpeakString("CTAF alert")
							loopcount = 0
						else
							loopcount = loopcount + 1
							--print("loopcount = " .. loopcount)
						end
					end
				end
			end
		end
	end
end

do_sometimes("tfCTAF_main()")