-- -- -- -- -- -- -- -- -- -- -- -- --
-- -- TOGFox common functions module 
-- -- v0.01
-- -- -- -- -- -- -- -- -- -- -- -- --
module(..., package.seeall);

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


