--********************************
--Persistent Parking
--TOGFOX
--v0.01
--v0.02 - now writes to file only if on the ground and not flying
--v0.03 - better way of determining if plane is parked
--v0.04 - fixed a defect that gave really bad experiences if you crashed
--v0.05 - added an extra safeguard to stop loading old positions when landing
--v0.06 - will now save location only if engine is off (stops saving location when holding short or lined up and waiting)
--v0.07 - refactored code so it is ready for a beta release
--v0.08 - simplified the database save/load functions to help reduce bugs
--********************************

--********************************
local tfpp_bActivatePersistentParking = true
local tfpp_bLoadPersistentParking = true	--set to false if this needs to be turned off permanently or temporarily
local tfpp_bSavePersistentParking = true
--********************************
local tfpp_PersistentParkingParams = {}
local tfpp_strCurrentAirport = "YBBN"
local tfpp_fltLocalX = 0
local tfpp_fltLocalY = 0
local tfpp_fltLocalZ = 0
local tfpp_fltHeading = 0
local tfpp_bArrayInitialised = false	--has the file been read yet?
local tfpp_fltairportlat = 0
local tfpp_fltairportlong = 0

--these datarefs help determine if the plane has landed
dataref("tfpp_datRAlt", "sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
dataref("tfpp_datGSpd", "sim/flightmodel/position/groundspeed")
dataref("tfpp_InReplayMode", "sim/time/is_in_replay")
dataref("tfpp_bolOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("tfpp_intParkBrake","sim/flightmodel/controls/parkbrake")
dataref("tfpp_bolEngineRunning", "sim/flightmodel/engine/ENGN_running")


function tfpp_GetClosestAirport()
    -- get airport info
	-- sets global variable tfpp_strCurrentAirport
	local navref
    navref = XPLMFindNavAid( nil, nil, LATITUDE, LONGITUDE, nil, xplm_Nav_Airport)
	
    -- all output we are not intereted in can be send to variable _ (a dummy variable)
	_, _, _, _, _, _, tfpp_strCurrentAirport, _ = XPLMGetNavAidInfo(navref)
	
	--print("Closest airport = " .. tfpp_strCurrentAirport)

end

function tfpp_GetCurrentGeoLocation()
	--reads dataref's and stores into global variables
	tfpp_fltLocalX = get("sim/flightmodel/position/local_x")
	tfpp_fltLocalY = get("sim/flightmodel/position/local_y")
	tfpp_fltLocalZ = get("sim/flightmodel/position/local_z")
	tfpp_fltHeading = get("sim/flightmodel/position/psi")
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
	--store the latest geopos into the tfpp_PersistentParkingParams array
	local tmpIndex	--this is the index of the array
	local tmpString	--this is the value to be stored in the array
	
	tmpIndex = tfpp_strCurrentAirport .. "XPOS"
	tmpString = tfpp_fltLocalX
	--print(tmpString)
	tfpp_PersistentParkingParams[tmpIndex] = tmpString
	--print(tfpp_PersistentParkingParams[tmpIndex])

	tmpIndex = tfpp_strCurrentAirport .. "YPOS"
	tmpString = tfpp_fltLocalY
	--print(tmpString)
	tfpp_PersistentParkingParams[tmpIndex] = tmpString
	--print(tfpp_PersistentParkingParams[tmpIndex])

	tmpIndex = tfpp_strCurrentAirport .. "ZPOS"
	tmpString = tfpp_fltLocalZ
	--print(tmpString)
	tfpp_PersistentParkingParams[tmpIndex] = tmpString
	--print(tfpp_PersistentParkingParams[tmpIndex])

	tmpIndex = tfpp_strCurrentAirport .. "HPOS"
	tmpString = tfpp_fltHeading
	--print(tmpString)
	tfpp_PersistentParkingParams[tmpIndex] = tmpString
	--print(tfpp_PersistentParkingParams[tmpIndex])
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
			
	local file = io.open(AIRCRAFT_PATH.."tfpp_PersistentParkingParams.txt", "w")
	file:write("-- File for: "..AIRCRAFT_FILENAME.." --\n") -- Write file header
	for param, value in pairs(tfpp_PersistentParkingParams) do
		file:write(param .. "=" .. value .. "\n") -- Write parameter, value and type to file
	end
	if file:seek("end") > 0 then 
		--print("File save successful!") 
	else 
		print("Persistent parking save failed for unknown reasons.") 
	end
	io.close(file)
end

function tfpp_loadfromfile()
	local position = 0
	local file = io.open(AIRCRAFT_PATH.."tfpp_PersistentParkingParams.txt", "r")
	
	if file then
		local i = 0
		for line in file:lines() do
			position = 0
			--print("Input line = " .. line)
			position = string.find(line, "=")		--postion ==0 means the '==' is not found so its a blank line or header line
			--print(position)
			if position ~=nil then
				k = string.sub(line, 1, (position - 1))
				v = string.sub(line, (position + 1))
				tfpp_PersistentParkingParams[k] = v
				i = i + 1
			end
		end
		io.close(file)
		if i ~=nil and i > 0 then 
			print("Persistent parking: file load successful.")
			--print("local X = " .. tfpp_fltLocalX)
		else 
			print("Persistent parking: file load failed or file is empty. Non-critical error.") 
		end
	else
		print("Persistent parking: file not found. Non-critical error.")
	end
end

function tfpp_main()

	--get closest airport
	tfpp_GetClosestAirport()	--this sets the global variable tfpp_strCurrentAirport
	
	if not tfpp_bArrayInitialised and tfpp_bolOnTheGround == 1 and tfpp_InReplayMode == 0 and tfpp_datGSpd <= 4 and tfpp_intParkBrake == 1 then
	
		if tfpp_bLoadPersistentParking then
			tfpp_loadfromfile()
			--print("******************")
			--print("Current airport = " .. tfpp_strCurrentAirport)
			--print("")
			
			if tfpp_PersistentParkingParams[tfpp_strCurrentAirport .. "XPOS"] == nil then
				--Current airport is not on file. Allow the loading at ramp
				print("Persistent parking: no airport data found. Nothing to do.")
				--print(tfpp_strCurrentAirport)
				--print(tfpp_PersistentParkingParams[tfpp_strCurrentAirportXPOS])
				
				
			else
				--There is geo data for the current eirport. Load those into the datarefs
				print("Persistent parking: " .. tfpp_strCurrentAirport .. " airport data found.")
				--print("heading before applying file = " .. get("sim/flightmodel/position/psi"))
				tfpp_fltLocalX = tfpp_PersistentParkingParams[tfpp_strCurrentAirport .. "XPOS"]
				tfpp_fltLocalY = tfpp_PersistentParkingParams[tfpp_strCurrentAirport .. "YPOS"]
				tfpp_fltLocalZ = tfpp_PersistentParkingParams[tfpp_strCurrentAirport .. "ZPOS"]
				tfpp_fltHeading= tfpp_PersistentParkingParams[tfpp_strCurrentAirport .. "HPOS"]
				--print("heading on file = ".. tfpp_fltHeading)

				--if tfpp_fltLocalX > 0 then	--some very basic error checking. Don't set aircraft to obviously bad data
				set("sim/flightmodel/position/local_x", tfpp_fltLocalX)
				set("sim/flightmodel/position/local_z", tfpp_fltLocalZ)
				set("sim/flightmodel/position/local_y", tfpp_fltLocalY)
				set("sim/flightmodel/position/psi", tfpp_fltHeading)	
					
				print("Persistent parking: aircraft relocation complete.")
				--end
				
				--print("heading after applying file = " .. get("sim/flightmodel/position/psi"))
				
			end
		end
		tfpp_bArrayInitialised = true
	end
	
	--get current geographic location
	tfpp_GetCurrentGeoLocation()
	
	--store that in the array
	--if tfpp_datGSpd < 10 and tfpp_datRAlt < 25 and tfpp_InReplayMode == 0 then
	--if on the ground and stopped with the park brake on and not in replay mode then ...
	if tfpp_bolOnTheGround == 1 and tfpp_datGSpd < 10 and tfpp_InReplayMode == 0 and tfpp_intParkBrake == 1 and tfpp_bolEngineRunning == 0 then
		--write whole array to table
		tfpp_UpdateArray()
		
		if tfpp_bSavePersistentParking then
			tfpp_writetofile()
		end		
	end
end

if tfpp_bActivatePersistentParking then
	do_sometimes("tfpp_main()")
end












