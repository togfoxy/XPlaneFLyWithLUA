-- -- -- -- -- -- -- -- -- -- -- -- --
--TOGFox common functions module 
--v0.01
--v0.02 Added tf_SecondsToClockFormat function
--v0.03 Added tf_GetArraySize
--		Refactored tf_SecondsToClockFormat to include a new optional parameter
-- -- -- -- -- -- -- -- -- -- -- -- --
module(..., package.seeall);


function AddNMToLatLong(fltLat1, fltLong1, fltDistanceNM, fltBearing)
	--Input: Lat1/Long1 is the co-ordinate starting point
	--		 Distance is the NM that needs to be added to the lat/long
	--		 Bearing is the compass bearing (direction) to move towards
	--Output: an array containing the new lat/long

	if fltLat1 > 0 then
		--northern hemisphere - nothing to do
	else
		--southern hemisphere - flip the bearing
		fltBearing = 360 - fltBearing
		if fltBearing > 359 then 
			fltBearing = fltBearing - 360
		end
		if fltBearing < 0 then
			fltBearing = 360 + fltBearing
		end
	end
	
	local fltRadians = 6378.14
	
	--convert nm to kilometers
	local fltDistanceKM = fltDistanceNM * 1.852	-- convert to km	

	local fltLat2 = math.deg((fltDistanceKM/fltRadians) * math.cos(math.rad(fltBearing))) + fltLat1
	local fltLong2 = math.deg((fltDistanceKM/(fltRadians*math.sin(math.rad(fltLat2)))) * math.sin(math.rad(fltBearing))) + fltLong1
	
	local arrLatLong = {}
	arrLatLong["Lat"] = fltLat2
	arrLatLong["Long"] = fltLong2
	return arrLatLong
end

function tf_GetClosestAirportInformation(fltLat,fltLong) --, AirportArray)
    -- get airport info
	-- sets global variable strClosestAirport
	local AirportArray = {}
	local navref
	local strClosestAirport
	
	--print(fltLat)
	--print(fltLong)
	
    navref = XPLMFindNavAid( nil, nil, fltLat, fltLong, nil, xplm_Nav_Airport)

    -- all output we are not intereted in can be send to variable _ (a dummy variable)
	aa, bb, cc, dd, ee, ff, gg, hh = XPLMGetNavAidInfo(navref)

	AirportArray["Lat"] = bb
	AirportArray["Long"] = cc
	AirportArray["Height"] = dd -- metres above mean sea level
	AirportArray["Frequency"] = ee
	AirportArray["Heading"] = ff
	AirportArray["ICAO"] = gg
	AirportArray["Name"] = hh

	return AirportArray
end

function round(num, idp)
	--Input: number to round; decimal places required
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end	

function tf_deg2rad(deg)
    return deg * (math.pi/180)
end

function tf_distanceInNM(lat1, lon1, lat2, lon2)
    local R = 6371 -- Radius of the earth in km
    local dLat = tf_deg2rad(lat2-lat1)
    local dLon = tf_deg2rad(lon2-lon1);
    local a = math.sin(dLat/2) * math.sin(dLat/2) +
        math.cos(tf_deg2rad(lat1)) * math.cos(tf_deg2rad(lat2)) * 
        math.sin(dLon/2) * math.sin(dLon/2)
    local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    local d = R * c * 0.539956803 -- distance in nm
    return d
end

function tf_GetArraySize(MyArray)
	--Input: an array/table with key/value pairs
	--Output: an integer value.
    local count = 0
    for _, __ in pairs(MyArray) do
        count = count + 1
    end
    return count
end

function tf_SecondsToClockFormat(intSeconds, bolJustShowDays)
	--Input: seconds as an integer, usually as a result of some clock/time operation
	--		 bolJustShowDays is a 0/1 setting that lets you hide hours and minutes
	--Note: v0.03 introduced the bolJustShowDays parameter. For backwards compatibility, it will default to 0 meaning days do not show by default
	local intSeconds = tonumber(intSeconds)
	local strTemp = ""
	
	if intSeconds <= 0 then
		return "00:00:00";
	else
		local days = string.format("%02.f", math.floor(intSeconds/86400))
		local hours = string.format("%02.f", math.floor(intSeconds/3600))
		local mins = string.format("%02.f", math.floor(intSeconds/60 - (hours*60)))
		local secs = string.format("%02.f", math.floor(intSeconds - hours*3600 - mins *60))
		
		strTemp = days
		if bolJustShowDays == 0 then
			strTemp = strTemp .. ":" .. hours ..":" .. mins .. ":" .. secs
		end
		return strTemp
	end



end











