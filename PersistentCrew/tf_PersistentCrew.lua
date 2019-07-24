--********************************
--** Persistent crew
--** TOGFOX
--** v0.01
--********************************

local tfpc_Database = {}			-- database that is loaded from file

local tfpc_bolCrewOnBoard = 0				-- tracks if crew are on the current flight
local tfpc_bolArrivalProcessed = 1		-- it is important to initialise this to '1' to avoid processing crew on session start

local tfpc_bolDepartureProcessed = 0	--
local tfpc_strDrawMessage = ""
local intDrawTimer = 0

dataref("tfpc_bolOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("tfpc_datGSpd", "sim/flightmodel/position/groundspeed")
dataref("tfpc_bolReplayMode", "sim/time/is_in_replay")
dataref("tfpc_bolParkBrake","sim/flightmodel/controls/parkbrake")
dataref("tfpc_bolEngineRunning", "sim/flightmodel/engine/ENGN_running")

require "graphics"
require "tf_common_functions"

function disp_time(fltTime)
	local days = math.floor(fltTime/86400)
	local hours = math.floor(math.fmod(fltTime, 86400)/3600)
	local minutes = math.floor(math.fmod(fltTime,3600)/60)
	local seconds = math.floor(math.fmod(fltTime,60))
	--print("Days:"..days)
	return days
end
function getTableSize(t)
    local count = 0
    for _, __ in pairs(t) do
        count = count + 1
    end
    return count
end
function tfpc_ReadDiskToArray()
-- Load from file into array
	--print("Read Disk")

	local position		--this looks for the "=" character in the input line
	local file = io.open(SCRIPT_DIRECTORY.."PersistentCrew.txt","r")

	if file then
		for line in file:lines() do
			--print("This line is:" .. line)

			position = string.find(line, "=")
			if position > 0 then
				--print("Position is:" .. position)
				k = string.sub(line, 1, (position - 1))
				v = string.sub(line, (position + 1))
				tfpc_Database[k] = v

				--print("K is:" .. k)
				--print("V is:" .. v)				
			end
		end
		io.close(file)
		
	end
end	
		
function tfpc_WriteArrayToDisk()
-- Save from array into file
	print("Write Disk")
	local file = io.open(SCRIPT_DIRECTORY.."PersistentCrew.txt","w")
	for k, v in pairs(tfpc_Database) do
		file:write(k .. "=" .. v .. "\n")
	end	
	io.close(file)
end

function tfpc_main()

	if tfpc_bolReplayMode == 0 then
	
		if tfpc_bolOnTheGround == 0 and tfpc_bolDepartureProcessed == 0 then
			--print("Detected departure")
			--detected a departure. Updated the database accordingly.
			local strAirportDetails = tf_common_functions.tf_GetClosestAirportInformation(LATITUDE, LONGITUDE) --Airport Details
			local strIndex = strAirportDetails["ICAO"] .. "CrewQty"
			if tfpc_Database[strIndex] ~= nil then
				if tfpc_Database[strIndex] > 0 then
					tfpc_Database[strIndex] = tfpc_Database[strIndex] - 1
					if tfpc_Database[strIndex] < 1 then
						--no crew left at this airport. Reset other information captured at this airport
						tfpc_Database[strIndex] = 0		-- precaution
						
						strIndex = strAirportDetails["ICAO"].."DateArrived"
						tfpc_Database[strIndex] = ""
					end
					tfpc_bolCrewOnBoard = 1
				end
			end
			tfpc_bolDepartureProcessed = 1
			tfpc_bolArrivalProcessed = 0
		end 

		if tfpc_bolOnTheGround == 1 and tfpc_datGSpd < 5 and tfpc_bolParkBrake == 1 then
			
			--landing detected
			--need to be mindful that the pilot has either just landed (arrival processed = 0) or the session has just started (arrival processed = 1)
			tfpc_bolDepartureProcessed = 0		-- A landing is detected - reset the "not departed" flag
			
			if tfpc_bolArrivalProcessed == 0 then
				-- a flight has just been completed
				--print("Detected landing")
				if tfpc_bolCrewOnBoard then
					local strAirportDetails = tf_common_functions.tf_GetClosestAirportInformation(LATITUDE, LONGITUDE) --Airport Details
					local strIndex = strAirportDetails["ICAO"] .. "CrewQty"
					
					if tfpc_Database[strIndex] == nil then
						tfpc_Database[strIndex] = 1
					else
						tfpc_Database[strIndex] = tfpc_Database[strIndex] + 1
					end
					
					strIndex = strAirportDetails["ICAO"].."DateArrived"
					tfpc_Database[strIndex] = os.clock()
					tfpc_bolCrewOnBoard = 0
					
					tfpc_WriteArrayToDisk()
				end
				
				tfpc_bolArrivalProcessed = 1
			else
				-- a session has just started and the pilot is on the ground
				-- need to check if planes start sessions with parkbrake on
				-- need to display where all the crew are
				
				--print("Detected new session")
				
				if getTableSize(tfpc_Database) == 0 then
					--Database is empty - read from file
					tfpc_ReadDiskToArray()	--establishes the tfpc_Database array based on file contents
				end
				local strTemp = "You have crew at this airport:"
				local strTemp1 = ""
				local bolCrewFound = 0
				local strICAO = ""
				for k, v in pairs(tfpc_Database) do
					--determine if the array item is "CrewQty" or "DateArrived"
					strICAO = string.sub(k,1, 4)
					strTemp1 = string.sub(k,(string.len(k)) - 6)	--gets the last x characters from the key/index (not value)
					--print(strTemp1)
					if strTemp1 == "CrewQty" then
						if tonumber(v) > 0 then	--check if any crew are at the current airport
							--construct a string of airports that have staff
							if bolCrewFound == 0 then
								--cheeky hack - if no crew found yet then this is the first
								strTemp = strTemp .. " " .. string.sub(k,1, 4)
							else
								--this is not the first airport - include the comma. Grammar matters!
								strTemp = strTemp .. ", " .. string.sub(k,1, 4)
							end
							
							
							
							--determine the time arrived
							fltTimeStayed = os.clock() - tfpc_Database[strICAO.."DateArrived"]
							--fltTimeStayed = (tf_common_functions.tf_SecondsToClockFormat(fltTimeStayed))
							--print (fltTimeStayed)
							--print(tf_common_functions.tf_SecondsToClockFormat(fltTimeStayed))
							
							strTemp = strTemp .. ". Time stayed: " .. disp_time(fltTimeStayed) .. " days."

							bolCrewFound = 1
							--print ("strTemp:" .. strTemp)
						end
					end
				end
				--print(bolCrewFound)
				if bolCrewFound == 1 then
					--print("One crew found")
					--draw the list of airports to the screen
				else
					strTemp = ""	--reset the temp string back to nothing so it is known that no crew was found.
				end
				tfpc_strDrawMessage = strTemp	--set the global string to this value so that it can be drawn.
				tfpc_bolArrivalProcessed = 1
				--print(tfpc_strDrawMessage)
			end
		end
	end
end

function tfpc_DrawMessage()
--this is inentionally seperate and tiny so it is processed quickly
	--print(tfpc_strDrawMessage)

	if tfpc_strDrawMessage ~= "" then
		XPLMSetGraphicsState(0,0,0,1,1,0,0)
		graphics.draw_string(800,1000,tfpc_strDrawMessage)
		
		if intDrawTimer == 0 then
			intDrawTimer = os.clock()
		end
		
		if os.clock() > (intDrawTimer + 15) then
			--remove text after x seconds
			tfpc_strDrawMessage = ""
			intDrawTimer = 0
		end
	end
end

do_sometimes("tfpc_main()")
do_every_draw("tfpc_DrawMessage()")



	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	




