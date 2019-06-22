--********************************
--** Persistent Parking
--** TOGFOX
--** v0.01
--**
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

function tfpp_GetClosestAirport()
    -- get airport info
	-- sets global variable strCurrentAirport
	local navref
    navref = XPLMFindNavAid( nil, nil, LATITUDE, LONGITUDE, nil, xplm_Nav_Airport)
    local logAirportId
    local logAirportName
	
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
	
	if not bArrayInitialised then
	
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

			bArrayInitialised = true
		end
	end
	
	--get current geographic location
	--print("heading before get geo = " .. get("sim/flightmodel/position/psi"))
	tfpp_GetCurrentGeoLocation()
	
	--store that in the array
	tfpp_UpdateArray()
	
	--write whole array to table
	--at some point, we only want to write to file sometimes
	if bSavePersistentParking then
		tfpp_writetofile()
	end
	
	--print("heading of plane = ".. fltHeading)
	--print("heading during main loop = " .. get("sim/flightmodel/position/psi"))
	
end

if bActivatePersistentParking then
	do_sometimes("tfpp_main()")
end












