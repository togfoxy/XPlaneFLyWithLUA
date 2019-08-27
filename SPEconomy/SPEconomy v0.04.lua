
local bolDebugMode = 0

dataref("tfsp_bolOnTheGround", "sim/flightmodel/failures/onground_any")
dataref("tfsp_datGSpd", "sim/flightmodel/position/groundspeed")
dataref("tfsp_fltAltAGL", "sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
dataref("tfsp_fltCurrentFuelWeightKGs" ,"sim/flightmodel/weight/m_fuel_total")


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

local arrRegionalArray = {}

local tf_common_functions = require "tf_common_functions_003"
require "graphics"
require "socket"


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

function AddToTransactions(TransArray)
	--Accept an array and add income transactions to file
	--print("About to save transacion")
	--print(TransArray[1])	--Departure
	--print(TransArray[2])	--Arrival	
	--print(TransArray[3])	--Desc
	--print(TransArray[4])	--Payer
	--print(TransArray[5])	--Payee
	--print(TransArray[6])	--Amount
	--print(TransArray[7])	--Comment

	local strTemp
	local strFilename = SCRIPT_DIRECTORY .. "SPE\\SPE_TransactionLog.txt"
	strTemp = os.date("%d/%b/%Y %X", os.time()) .. ";" .. TransArray[1] .. ";" .. TransArray[2] .. ";" .. TransArray[3] .. ";" .. TransArray[4] .. ";" .. TransArray[5] ..";" .. TransArray[6] .. ";" .. TransArray[7] .. "\n"
	
	local file = io.open(strFilename, "a")
	file:write(strTemp)
	io.close(file)
	
	print("SPE: Transaction created")	

end

function ApppendRegionalDataFile(RegionKey, RegionValue)
--write the regionaldata to file
	local strRegionalFilename= SCRIPT_DIRECTORY .. "SPE\\SPE_" .. "RegionalData.txt"				--holds persistent economic data for every region
	local strTemp = RegionKey .. "=" .. RegionValue .. "\n"
	
	local file = io.open(strRegionalFilename, "a")
	file:write(strTemp)
	io.close(file)
	
	print("SPE: Regional data file appended")	
end

function ProcessIncomeTable(ArrivalICAO, FlightDistance, FlightTime)
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
				if arrIncomeArray[2] == "hr" then
					payamount = tf_common_functions.round(payrate * (FlightTime / 60 / 60), 2)	--convert to hours
				end
				
				--print("payamount= ".. payamount)
				local arrTransaction = {strDepartureICAO, ArrivalICAO, arrIncomeArray[1], "System", strPilotUserName, payamount, "Pilot pay"}
				--print("About to add to transaction alpha")
				AddToTransactions(arrTransaction)
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
	local k = 0						--counts the rows as the master expense file is read	

	local arrExpenseArray = {}			--Holds the parsed incomes
	local strExpenseFilename = SCRIPT_DIRECTORY .. "SPE\\SPE_ExpenseTable.txt"
	
	local expensefile = io.open(strExpenseFilename, "r")
	local regionalfile
	local itemrate = 0
	local bolRegionalExpenseFound = 0	--use this to track if a regional file was discovered
	local arrKey						--array key
	local arrValue						--array value
	
	--step through the master expenses \
	if expensefile then
		for expenseline in expensefile:lines() do
			if k > 0 then	--skip header
				arrExpenseArray = ParseCSVLine(expenseline)	--loads array 
				

				--##Just for now, will ignore the regionalfile bit and apply the raw expense
				--check the random probability	--## this probability roll should probably be moved higher up
				--print(arrExpenseArray[2])
				if math.random(0,100) <= tonumber(arrExpenseArray[2]) then		--this element is the probability factor
					--apply this line item
					
					arrRegionalKey = ArrivalICAO .. arrExpenseArray[1]
					if arrRegionalArray[arrRegionalKey] ~= nil then
						--whatever is in expense[1], need to see if it also exists in regional array
						itemrate=arrRegionalArray[arrRegionalKey]
					else
						itemrate = math.random(arrExpenseArray[4],arrExpenseArray[5])	--min/max for the item		
						arrRegionalArray[arrRegionalKey] = itemrate
						ApppendRegionalDataFile(arrRegionalKey, itemrate)
					end					

					if arrExpenseArray[3] == "flight" then
						
						local arrTransaction = {strDepartureICAO, ArrivalICAO, arrExpenseArray[6], strPilotUserName, "System", itemrate, arrExpenseArray[6]}
						--print("About to add to transaction beta")
						AddToTransactions(arrTransaction)
						
					end
					

				else
					--random probability failed. Do nothing.
				end

			end
			k = k + 1
		end
		io.close(expensefile)
		if k ~=nil and k > 0 then 
			print("SPE: master expense file load successful.")
		else 
			print("SPE: master expense file load failed or file is empty. Non-critical error.") 
		end		
		
	else
		print("SPE: master expense file not found. Non-critical error.")
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
	
	if tfsp_bolOnTheGround == 0 and tfsp_fltAltAGL > 20 and tfsp_datGSpd > 25 and bolHasDeparted == 0 then
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
		if bolDebugMode == 0 then
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
		
		ProcessIncomeTable(strArrivalICAO, fltFlightDistance, fltFlightTime)
		ProcessExpenseTable(strArrivalICAO, fltFlightDistance)
		
		--wait for one second so file operations can settle down
		starttimer = os.clock()
		currenttimer = os.clock()
		while currenttimer < starttimer + 1 do
			currenttimer = os.clock()
		end
			
		ExportTransactionLogToHTML()
	
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
	--print("bolHasDeparted =" .. bolHasDeparted)
	CheckIfDeparted()
	CheckIfLanded()
end

function FakeDepature()
--For debugging: fake a departure
	strDepartureICAO = "YMML"
	fltDepartureLat = LATITUDE
	fltDepatureLong = LONGITUDE
	fltDeparureTime = os.time()
	fltDepartureFuelWeightKG = tfsp_fltCurrentFuelWeightKGs
	fltFlightDistance = 15.3
	bolHasDeparted = 1
end

ImportGlobalSettings()

if bolDebugMode == 1 then
	FakeDepature()
end

function ImportRegionData()
	--Import regional data into the global array

	local position = 0
	local k = 0						--counts the rows as the file is read		
	--local arrIncomeArray = {}	--Holds the parsed incomes
	local strFilename = SCRIPT_DIRECTORY .. "SPE\\SPE_RegionalData.txt"
	local file = io.open(strFilename, "r")
	
	if file then
		--print(k)
		for line in file:lines() do
			--print(k)
			if k > 0 then		--the first line in the file is a comment - skip that and don't read it
				--look for the '=' sign
				position = string.find(line, "=")
				if position > 0 then
					arrIndex = string.sub(line, 1, position-1)
					arrValue = string.sub(line, position+1)	
					arrRegionalArray[arrIndex] = arrValue
				end
			end
			k = k + 1
		end
		io.close(file)
		if k ~=nil and k > 0 then 
			print("SPE: Regional file load successful.")
		else 
			print("SPE: Regional file load failed or file is empty. Non-critical error.") 
		end
	else
		print("SPE: Regional file not found. Non-critical error.")
	end		
end	
	
function ExportTransactionLogToHTML()
--read in the transaction log csv and export to html
	
	local strMode="header"		--tracs where in the template we are
	local arrTransactionArray = {}
	local i = 1				--track file row number
	local intBalance = 0	--calculates the balance on the fly
	
	--delete existing html file
	local strTransactionLogHTML = SCRIPT_DIRECTORY .. "SPE\\HTML\\SPE_TransactionLog.html"
	local strTransactionLogHTMLTemplate = SCRIPT_DIRECTORY .. "SPE\\Templates\\SPE_TransactionLogHTMLTemplate.html"
	local strTransactionLogCSV = SCRIPT_DIRECTORY .. "SPE\\SPE_TransactionLog.txt"
	
	--print("creating html")
	os.remove(strTransactionLogHTML)
	
	--open new html file for appending
	local htmlfile = io.open(strTransactionLogHTML, "a")
	
	--open html template for reading
	local htmltemplatefile = io.open(strTransactionLogHTMLTemplate, "r")
	
	--open csv template for reading
	local csvfile = io.open(strTransactionLogCSV, "r")
	
	--for each line in html template do
	if htmltemplatefile then
		for templateline in htmltemplatefile:lines() do
			if strMode=="header" then
				if string.sub(templateline, 1, 15) == "<!--BeginLog-->" then
					strMode="body"
				else
					htmlfile:write(templateline .. "\n")
				end
			end
			if strMode=="body" then
				--need to do the dynamic stuff
				if csvfile then
					for csvline in csvfile:lines() do
						if i > 1 then		--skip the file header
							arrTransactionArray = ParseCSVLine(csvline)	--loads array 
							
							
							print(arrTransactionArray[1])
							print(arrTransactionArray[2])
							print(arrTransactionArray[3])
							print(arrTransactionArray[4])
							print(arrTransactionArray[5])
							print(arrTransactionArray[6])
							print(arrTransactionArray[6])							
							
							htmlfile:write("<tr>" .. "\n")
							htmlfile:write("<td>" .. arrTransactionArray[1] .. "</td>" .. "\n")
							htmlfile:write("<td>" .. arrTransactionArray[2] .. "</td>" .. "\n")
							htmlfile:write("<td>" .. arrTransactionArray[3] .. "</td>" .. "\n")
							htmlfile:write("<td>" .. arrTransactionArray[4] .. "</td>" .. "\n")
							htmlfile:write("<td>" .. arrTransactionArray[5] .. "</td>" .. "\n")
							htmlfile:write("<td>" .. arrTransactionArray[6] .. "</td>" .. "\n")
							htmlfile:write("<td>" .. arrTransactionArray[7] .. "</td>" .. "\n")
							htmlfile:write("<tr>" .. "\n")
							
							--intBalance = intBalance + arrTransactionArray[6]
						else
							--skip file header
							i = i +1
						end
					end
					
					htmlfile:write("</tbody>" .. "\n")
					htmlfile:write("</table>" .. "\n")
					strMode="footer"
				else
					--##
				end
			end
			if strMode == "footer" then

			end
		end
	end
	--print("Charlie")
	
	htmlfile:write("<p>Opening balance: $0</p>" .. "\n")
	--htmlfile:write("<p>Income: $999" .. "</p>\n")
	htmlfile:write("<p>Current balance: $" .. intBalance .."</p>\n")
	
	io.close(htmlfile)
	io.close(htmltemplatefile)
	io.close(csvfile)

end	

function sleep(sec)
    socket.select(nil, nil, sec)
end
--os.remove(SCRIPT_DIRECTORY .. "dme.txt")
math.randomseed(os.time())
ImportRegionData()
do_sometimes("tfspe_Main()")






























