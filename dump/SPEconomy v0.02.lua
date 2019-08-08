
dataref("tfsp_bolOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("tfsp_datGSpd", "sim/flightmodel/position/groundspeed")
dataref("tfsp_fltAltAGL", "sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
dataref("tfsp_fltCurrentFuelWeightKGs" ,"sim/flightmodel/weight/m_fuel_total")

local bolDebugMode = 1
local strDepartureICAO
local fltDepartureLat
local fltDepatureLong
local fltDeparureTime
local fltDepartureFuelWeightKG
local bolHasDeparted = 0

local strArrivalICAO
local fltArrivalLat
local fltArrivalLong
local fltArrivalTime
local fltArrivalFuelWeightKG

local fltFlightDistance
local fltFlightTime
local fltFlightFuelUsedKG
local strPilotUserName

local tf_common_functions = require "tf_common_functions_003"
require "graphics"


function ParseCSVLine(inputline)
	--input: string from file (income table)
	local pos = 0	--string position of next ';'
	local fieldnum = 1	--track which table 'field' we have saved
	local arrResult = {}
	local strTempInputLine = inputline	--use this so the inputline parameter is preserved
	
	while string.len(strTempInputLine) > 1 do
		pos = string.find(strTempInputLine,";")
		if pos == nil or pos == 0 then
			pos = string.len(strTempInputLine) + 1
		end
		
		arrResult[fieldnum] = string.sub(strTempInputLine,1,(pos-1))
		--print("fieldnum= " .. fieldnum)
		--print(arrResult[fieldnum])
		
		fieldnum = fieldnum + 1
		strTempInputLine = string.sub(strTempInputLine, (pos+1))
	end
	return arrResult
end

function AddIncomeToTransactions(TransArray)
	--Accept an array and add income transactions to file
	--print("About to save transacion")
	--print(TransArray[1])
	--print(TransArray[2])
	--print(TransArray[3])
	--print(TransArray[4])
	--print(TransArray[5])

	local strTemp
	local strFilename = SCRIPT_DIRECTORY .. "SPE\\SPE_TransactionLog.txt"
	strTemp = os.date("%d/%b/%Y %X", os.time()) .. ";" .. TransArray[1] .. ";" .. TransArray[2] .. ";" .. TransArray[3] .. ";" .. TransArray[4] .. ";" .. TransArray[5] .."\n"
	
	local file = io.open(strFilename, "a")
	file:write(strTemp)
	io.close(file)
	
	print("SPE: Transaction save complete")	

end

function ProcessIncomeTable(FlightDistance)
	local position = 0
	local k = 0						--counts the rows as the file is read		
	local arrIncomeArray = {}	--Holds the parsed incomes
	local strFilename = SCRIPT_DIRECTORY .. "SPE\\SPE_IncomeTable.txt"
	local file = io.open(strFilename, "r")
	
	if file then
		--print(k)
		for line in file:lines() do
			--print(k)
			if k > 0 then		--the first line in the file is a comment - skip that and don't read it
				--print(k)
				--print("SPE: IncomeTable=" .. line)
				
				--read the entier line into this array
				arrIncomeArray = ParseCSVLine(line)
				
				--print("arrIncomeArray[3]= " .. arrIncomeArray[3])
				
				payrate = math.random(arrIncomeArray[3],arrIncomeArray[4])
				--print("Payrate= " .. payrate)	--##
				--print("FlightDistance= " .. FlightDistance)
				
				--react to the income type
				if arrIncomeArray[2] == "nm" then
					payamount = payrate * FlightDistance
				end
				if arrIncomeArray[2] == "flight" then
					payamount = payrate
				end
				
				--print("payamount= ".. payamount)
				local arrTransaction = {arrIncomeArray[1], "System", strPilotUserName, payamount, "Pilot pay"}
				AddIncomeToTransactions(arrTransaction)
			end
			k = k + 1
		end
		io.close(file)
		if k ~=nil and k > 0 then 
			print("SPE: income file load successful.")
		else 
			print("SPE: income file load failed or file is empty. Non-critical error.") 
		end
	else
		print("SPE: income file not found. Non-critical error.")
	end		
end

function ProcessExpenseTable(ArrivalICAO, FlightDistance)
	--processing expenses is tricky as they persist and are different for each airport. There are two cases:
	--a) the pilot has never been so there is no economic data and it needs to be created;
	--b) there is already economic data and that needs to be adopted (with natural variance/fluctuations)
	local position = 0
	local i = 0
	local k = 0						--counts the rows as the file is read	

	local arrExpenseArray = {}			--Holds the parsed incomes
	local arrRegionalArray = {}		--Holds regional economic data
	local strExpenseFilename = SCRIPT_DIRECTORY .. "SPE\\SPE_ExpenseTable.txt"
	local strRegionalFilename= SCRIPT_DIRECTORY .. "SPE\\SPE_" .. ArrivalICAO .. "Economy.txt"				--holds persistent economic data for the region
	local expensefile = io.open(strExpenseFilename, "r")
	local regionalfile = io.open(strRegionalFilename, "r")
	
	--load all the regional data first so we have that on hand
	if regionalfile then
		for regionalline in regionalfile:lines() do
			if i > 0 then	--skip the file header
				arrRegionalArray = ParseCSVLine(regionalline)	--loads array 1 -> name
			end
			i = i + 11
		end
		io.close(regionalfile)
		if i ~=nil and i > 0 then 
			print("SPE: regional file load successful.")
		else 
			print("SPE: regional file load failed or file is empty. Non-critical error.") 
		end
	else
		print("SPE: Regional not found. Non-critical error.")
	end
	
	--step through the master expenses and load that into an array. If there is a regional item of the same name then use that instead
	if expensefile then
		for expenseline in expensefile:lines() do
			if k > 0 then	--skip header
				arrExpenseArray = ParseCSVLine(expenseline)	--loads array 1 -> name
				
				--there is now a handle on the first master expense. See if there is a regional value already.
				strExpenseName = arrExpenseArray[1]
				if tf_common_functions.tf_GetArraySize(arrRegionalArray) > 0 then
					--loop through to see if this expense is recorded already
					local j = 1
					for varElement in (arrRegionalArray) do

					--## tired. No idea what I'm doing - going to bed before Skismo catches me doing something weird.
					

					end			
			
				end
			end
		end
		io.close(expensefile)
	else
		print("SPE: expense file not found. Non-critical error.")
	end	
end

function ImportGlobalSettings()
	--Red the glboal settings from file
	strPilotUserName = "TOGFox"				--##todo

end

function AppendFlightLog(DepartureTime,ArrivalTime,PilotUserName,DepartureICAO,ArrivalICAO, FlightTime, FlightDistance, FuelUsed, tailnmber, planemodel, dayhours,nighthours)
                        
	--Append the flight log with the provided parameters
	
	--##
	local strTemp
	local strFilename = SCRIPT_DIRECTORY .. "SPE\\SPE_FlightLog.txt"
	strTemp = DepartureTime..";".. ArrivalTime..";"..PilotUserName..";".. DepartureICAO..";"..ArrivalICAO..";"..FlightTime..";"..FlightDistance..";"..FuelUsed..";"..tailnmber..";".. planemodel..";".."0"..";".."0".."\n"
	
	local file = io.open(strFilename, "a")
	file:write(strTemp)
	io.close(file)
	
	print("SPE: Flight log appended")
end

function CheckIfDeparted()
	--record essential data if a departure is deteccted
	
	if tfsp_bolOnTheGround == 0 and tfsp_fltAltAGL > 20 and tfsp_datGSpd > 50 and bolHasDeparted == 0 then
		--pilot has departed. Capture departure information
		local arrAirportInfo = {}
		arrAirportInfo = tf_common_functions.tf_GetClosestAirportInformation(LATITUDE, LONGITUDE)
		strDepartureICAO = arrAirportInfo["ICAO"]
		fltDepartureLat = LATITUDE
		fltDepatureLong = LONGITUDE
		fltDeparureTime = os.time()
		fltDepartureFuelWeightKG = tfsp_fltCurrentFuelWeightKGs
		bolHasDeparted = 1
	end
end

function CheckIfLanded()
	--do a whole bunch of stuff if a landing is detected
	if tfsp_bolOnTheGround == 1 and tfsp_datGSpd < 5 and bolHasDeparted == 1 then
		--detected a landing. Do stuff
		local arrAirportInfo = {}
		arrAirportInfo = tf_common_functions.tf_GetClosestAirportInformation(LATITUDE, LONGITUDE)
		strArrivalICAO = arrAirportInfo["ICAO"]
		
		fltArrivalLat = LATITUDE
		fltArrivalLong = LONGITUDE
		fltArrivalTime = os.time()
		fltArrivalFuelWeightKG = tfsp_fltCurrentFuelWeightKGs
		bolHasDeparted = 0
		
		--Calculate distance between airports
		if not bolDebugMode then
			fltFlightDistance = tf_common_functions.tf_distanceInNM(fltDepartureLat,fltDepatureLong,fltArrivalLat,fltArrivalLong)
			fltFlightDistance = tf_common_functions.round(fltFlightDistance,1)
		end
		
		--Calculate time in the air
		fltFlightTime = fltArrivalTime - fltDeparureTime		--##note - this doesn't work with time acceleration
		
		--Calculate day/night hours								--maybe pilot pay will improve when th elog reaches certain milestones
		
		--Calculate fuel used (kg)
		fltFlightFuelUsedKG = fltDepartureFuelWeightKG - fltArrivalFuelWeightKG 
		fltFlightFuelUsedKG = tf_common_functions.round(fltFlightFuelUsedKG,1)
		--print(fltDepartureFuelWeightKG)
		--print(fltArrivalFuelWeightKG)
		--print(fltFlightFuelUsedKG)
	
		--Append flight log with date/time, pilots name, departure, destination, tail number, model, day hours, night hours
		AppendFlightLog(os.date("%d/%b/%Y %X", fltDeparureTime),os.date("%d/%b/%Y %X", fltArrivalTime),strPilotUserName, strDepartureICAO, strArrivalICAO, tf_common_functions.tf_SecondsToClockFormat(fltFlightTime, 0), fltFlightDistance,fltFlightFuelUsedKG,PLANE_TAILNUMBER, PLANE_ICAO, 0,0) --##day/night hours not done yet
		
		ProcessIncomeTable(fltFlightDistance)
		
		ProcessExpenseTable(strArrivalICAO, fltFlightDistance)
	
	else
		--print(fltDepartureFuelWeightKG)
		--print(tfsp_fltCurrentFuelWeightKGs)
		if tfsp_bolOnTheGround == 0 then
			--do dodgy fuel stuff
			if fltDepartureFuelWeightKG == nil or fltDepartureFuelWeightKG < 1 or fltDepartureFuelWeightKG < tfsp_fltCurrentFuelWeightKGs then
				fltDepartureFuelWeightKG = tfsp_fltCurrentFuelWeightKGs
			end
		end
	end
end


function tfspe_Main()
	CheckIfDeparted()
	CheckIfLanded()
	
	--print(os.date("%d/%b/%Y %X", os.time()))
	--print(os.time())

end

function FakeDepature()
--For debugging: fake a departure
	bolDebugMode = 1
	strDepartureICAO = "61WA"
	fltDepartureLat = LATITUDE
	fltDepatureLong = LONGITUDE
	fltDeparureTime = os.time()
	fltDepartureFuelWeightKG = tfsp_fltCurrentFuelWeightKGs
	fltFlightDistance = 11.7
	bolHasDeparted = 1
end

ImportGlobalSettings()
if bolDebugMode then
	FakeDepature()
end

--os.remove(SCRIPT_DIRECTORY .. "dme.txt")
do_sometimes("tfspe_Main()")



























