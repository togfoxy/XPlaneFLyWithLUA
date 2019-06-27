--********************************
--** Persistent Parking
--** TOGFOX
--** v0.01
--** v0.02 - now writes to file only if on the ground and not flying
--** v0.03 - better way of determining if plane is parked
--** v0.04 - fixed a defect that gave really bad experiences if you crashed
--** v0.05 - added an extra safeguard to stop loading old positions when landing
--********************************

--********************************
local bActivatePersistentParking = true
local bLoadPersistentParking = true	--set to false if this needs to be turned off permanently or temporarily
local bSavePersistentParking = true
--********************************
local PersistentParams = {}
local strCurrentAirport = "YBBN"
local fltLocalX = 0
local fltLocalY = 0
local fltLocalZ = 0
local fltHeading = 0
local bArrayInitialised	= false	--has the file been read yet?
local fltairportlat = 0
local fltairportlong = 0

--these datarefs help determine if the plane has landed
dataref("tfpp_datRAlt", "sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
dataref("tfpp_datGSpd", "sim/flightmodel/position/groundspeed")
dataref("tfpp_InReplayMode", "sim/time/is_in_replay")
dataref("tfpp_bolOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("tfpp_intParkBrake","sim/flightmodel/controls/parkbrake")


function tfpp_GetClosestAirport()
    -- get airport info
	-- sets global variable strCurrentAirport
	local navref
    navref = XPLMFindNavAid( nil, nil, LATITUDE, LONGITUDE, nil, xplm_Nav_Airport)
	
    -- all output we are not intereted in can be send to variable _ (a dummy variable)
	_, _, _, _, _, _, strCurrentAirport, _ = XPLMGetNavAidInfo(navref)
	
	--print("Closest airport = " .. strCurrentAirport)

end

function tfpp_GetCurrentGeoLocation()
	--reads dataref's and stores into global variables
	fltLocalX = get("sim/flightmodel/position/local_x")
	fltLocalY = get("sim/flightmodel/position/local_y")
	fltLocalZ = get("sim/flightmodel/position/local_z")
	fltHeading = get("sim/flightmodel/position/psi")
	--print("heading on dataref1= " .. get("sim/flightmodel/position/psi"))
end

function tfpp_deg2rad(deg)
    return deg * (math.pi/180)
end

function tfpp_distanceInNM(lat1, lon1, lat2, lon2)
    local R = 6371 -- Radius of the earth in km
    local dLat = tfpp_deg2rad(lat2-lat1)
    local dLon = tfpp_deg2rad(lon2-lon1);
    local a = math.sin(dLat/2) * math.sin(dLat/2) +
        math.cos(tfpp_deg2rad(lat1)) * math.cos(tfpp_deg2rad(lat2)) * 
        math.sin(dLon/2) * math.sin(dLon/2)
    local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    local d = R * c * 0.539956803 -- distance in nm
    return d
end

function tfpp_UpdateArray()
	--store the latest geopos into the PersistentParams array
	local tmpIndex	--this is the index of the array
	local tmpString	--this is the value to be stored in the array
	
	tmpIndex = strCurrentAirport .. "XPOS"
	tmpString = fltLocalX
	--print(tmpString)
	PersistentParams[tmpIndex] = tmpString
	--print(PersistentParams[tmpIndex])

	tmpIndex = strCurrentAirport .. "YPOS"
	tmpString = fltLocalY
	--print(tmpString)
	PersistentParams[tmpIndex] = tmpString
	--print(PersistentParams[tmpIndex])

	tmpIndex = strCurrentAirport .. "ZPOS"
	tmpString = fltLocalZ
	--print(tmpString)
	PersistentParams[tmpIndex] = tmpString
	--print(PersistentParams[tmpIndex])

	tmpIndex = strCurrentAirport .. "HPOS"
	tmpString = fltHeading
	--print(tmpString)
	PersistentParams[tmpIndex] = tmpString
	--print(PersistentParams[tmpIndex])
	--print("heading on dataref2= " .. get("sim/flightmodel/position/psi"))
	

end

function tfpp_pairs_by_keys (t, f)
	--used by tfpp_writetofile
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
  return iter
end

function tfpp_writetofile()
			
	file = io.open(AIRCRAFT_PATH.."PersistentParams.txt", "w")
	file:write("-- File for: "..AIRCRAFT_FILENAME.." --\n") -- Write file header
	for param, value in tfpp_pairs_by_keys(PersistentParams) do -- Save sorted list
		local valtype = type(value) -- Store value type

		--print("param = " .. param)
		--print("value = " .. value)

		value=tostring(value) -- Convert all values to string (useful for booleans)
		--print("after value = " .. param.." = "..value)
		file:write(param," = ",value," : ",valtype,"\n") -- Write parameter, value and type to file
	end
	if file:seek("end") > 0 then 
		print("File save successful!") 
	else 
		print("File save failed!") 
	end
	io.close(file)
end

function tfpp_loadfromfile()
	local position
	local file = io.open(AIRCRAFT_PATH.."PersistentParams.txt", "r")
	
	if file then
		local i = 0
		for line in file:lines() do
			--print("Input line = " .. line)
			position = string.find(line, "=", 2, true)
			if position then
				local param, value, valtype = line:match("(.*)%s=%s(.*)%s:%s(.*)") --Split line
				--print("Param: "..param.." Value: "..value.." Type: "..valtype)
				if valtype == "boolean" then 
					PersistentParams[param] = ( value == "true" ) -- Checks for and sets boolean values. Credit to jjj.
				elseif 
					valtype == "number" then 
						PersistentParams[param] = tonumber(value) -- Checks for and sets number type values. Credit to jjj.
				else 
					PersistentParams[param] = value 
				end -- Interprets value as string. Credit to jjj.
								
				i = i + 1
			end
		end
		io.close(file)
		if i ~=nil and i > 0 then 
			print("File load successful!")
			--print("local X = " .. fltLocalX)
		else 
			print("File load failed!") 
		end
	else
		print("File not found!")
	end
end

function tfpp_main()

	--get closest airport
	tfpp_GetClosestAirport()	--thi sets the global variable strCurrentAirport
	
	if not bArrayInitialised and tfpp_bolOnTheGround == 1 and tfpp_InReplayMode == 0 and tfpp_datGSpd <= 4 then
	
		if bLoadPersistentParking then
			tfpp_loadfromfile()
			--print("******************")
			print("Current airport = " .. strCurrentAirport)
			--print("")
			
			if PersistentParams[strCurrentAirport .. "XPOS"] == nil then
				--Current airport is not on file. Allow the loading at ramp
				print("No airport data found. Nothing to do - loading at ramp")
				
			else
				--There is geo data for the current eirport. Load those into the datarefs
				print(strCurrentAirport .. " airport data found")
				--print("heading before applying file = " .. get("sim/flightmodel/position/psi"))
				fltLocalX = PersistentParams[strCurrentAirport .. "XPOS"]
				fltLocalY = PersistentParams[strCurrentAirport .. "YPOS"]
				fltLocalZ = PersistentParams[strCurrentAirport .. "ZPOS"]
				fltHeading= PersistentParams[strCurrentAirport .. "HPOS"]
				--print("heading on file = ".. fltHeading)

				--if fltLocalX > 0 then	--some very basic error checking. Don't set aircraft to obviously bad data
					set("sim/flightmodel/position/local_x", fltLocalX)
					set("sim/flightmodel/position/local_z", fltLocalZ)
					set("sim/flightmodel/position/local_y", fltLocalY)
					set("sim/flightmodel/position/psi", fltHeading)	
					
					print("Aircraft relocation complete")
				--end
				
				--print("heading after applying file = " .. get("sim/flightmodel/position/psi"))
				
			end

			
		end
		bArrayInitialised = true
	end
	
	--get current geographic location
	tfpp_GetCurrentGeoLocation()
	
	--store that in the array
	--if tfpp_datGSpd < 20 and tfpp_datRAlt < 25 and tfpp_InReplayMode == 0 then
	--if on the ground and stopped with the park brake on and not in replay mode then ...
	if tfpp_bolOnTheGround == 1 and tfpp_datGSpd < 10 and tfpp_InReplayMode == 0 and tfpp_intParkBrake == 1 then
		--write whole array to table
		tfpp_UpdateArray()
		
		if bSavePersistentParking then
			tfpp_writetofile()
		end		
	end
end

if bActivatePersistentParking then
	do_sometimes("tfpp_main()")
end












