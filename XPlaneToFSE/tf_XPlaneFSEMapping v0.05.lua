-- TOGFox
-- v0.01 - initial release
-- v0.02 - changed the term FBO to airport
-- v0.03 - started reverse search functions
-- v0.04 - enhanced text display
--		 - the alternate airports is now always tied to a FSE airport
-- v0.05 - can now read and display comments

local strVersion = "0.05"

if not SUPPORTS_FLOATING_WINDOWS then
    -- to make sure the script doesn't stop old FlyWithLua versions
    logMsg("PauseAt requires a newer version of FlyWithLua. Your version of FlyWithLua doesn't support imgui, please upgrade.")
    return
end

local tf_XPtoFSE_arrXplaneAirports = {}
local tf_XP2FSEWnd = nil
local strOutput ="Initialised"
local strDefaultInput = ""

local tf_common_functions = require "tf_common_functions_v2_00"

function tf_XPtoFSE_loadfromfile()
	local position = 0
	local strFilename = SCRIPT_DIRECTORY .. "tf\\tf_XPlaneFSEMapping.txt"
	local file = io.open(strFilename, "r")
	local strXPlane = ""	--the XPlane airport
	local strFSEFBO = ""	--the equivaalent FSE airport
	local strFSEComments	--the comments in the file
	local v = ""
	
	if file then
		local i = 0
		for line in file:lines() do
			if i > 0 then	--skip the first row because it's a header.
				position = 0
				--print("Input line = " .. line)
				position = string.find(line, ";")		--position ==0 means the ';' is not found so its a blank line or header line
				--print(position)
				if position ~=nil then
					-- we need to strip out seven attributes so this gets repeatitive
					
					strXPlane = string.sub(line, 1, (position - 1))	-- this is the bit before position
					
					--this takes the remainder of 'line' and assigns it to 'v'
					v = string.sub(line, (position + 1))	-- this is the remainder of the line after the position
					--print("strXPlane:" .. strXPlane)

					
					position = string.find(v, ";")
					--print("Position: " .. position)
					if position ~= nil then
						strFSEFBO = string.sub(v, 1, (position - 1))
						v = string.sub(line, (position + 1))	-- this is the remainder of the line after the position

					end

					--Read the 3rd attribute
					position = string.find(v, ";")
					if position ~= 1 then
						strThirdValue = string.sub(v, 1, (position - 1))

					end					
					v = string.sub(v, (position + 1))	-- this is the remainder of the line after the position
						
					--Read the 4th attribute
					position = string.find(v, ";")
					if position ~= 1 then
						strFourthValue = string.sub(v, 1, (position - 1))

					end	
					v = string.sub(v, (position + 1))	-- this is the remainder of the line after the position
					
					--Read the 5th attribute
					position = string.find(v, ";")
					if position ~= 1 then
						strFifthValue = string.sub(v, 1, (position - 1))
					end						
					v = string.sub(v, (position + 1))	-- this is the remainder of the line after the position
					
					
					--Read the 6th attribute
					position = string.find(v, ";")
					if position ~= 1 then
						strSixthValue = string.sub(v, 1, (position - 1))
					end		
					v = string.sub(v, (position + 1))	-- this is the remainder of the line after the position
					
					--Read the 7th attribute. This is the last attribute so its a bit different
					position = string.find(v, ";")
					if position == 1 then
						strFBOComments = string.sub(v, 2)
					end							
					--v = string.sub(v, (position + 1))	-- this is the remainder of the line after the position

					tf_XPtoFSE_arrXplaneAirports[strXPlane] = {}		-- need to explicitly instantiate this sub-array item
					--Element [0] = the Xplane airport (i.e a zero bound array)
					tf_XPtoFSE_arrXplaneAirports[strXPlane][1] = strFSEFBO
					tf_XPtoFSE_arrXplaneAirports[strXPlane][6] = strFBOComments
					-- can insert other things like 3D airport flag here when ready
					
					--print("strXplane: " .. strXPlane .. "; strFSEFBO: " .. strFSEFBO .. "; array: " .. tf_XPtoFSE_arrXplaneAirports[strXPlane][1] .. "; Comment: " .. strFBOComments)
				end
			end
			i = i + 1
		end
		io.close(file)
		if i ~=nil and i > 0 then 
			--print("Persistent parking: file load successful.")
			--print("local X = " .. tfpp_fltLocalX)
		else 
			--print("Persistent parking: file load failed or file is empty. Non-critical error.") 
		end
	else
		--print("Persistent parking: file not found. Non-critical error.")
	end
end

function tf_XP2FSE_show_window()
    tf_XP2FSEWnd = float_wnd_create(350, 140, 1, true)
    float_wnd_set_title(tf_XP2FSEWnd, "Xplane to FSE " .. strVersion)
    float_wnd_set_imgui_builder(tf_XP2FSEWnd, "tf_XP2FSE_build_Window")
end


function tf_XP2FSE_ReverseSearch(strFSEAirport)
	-- input: FSE airport
	-- output: list of compatible XPlane airports as a string
	local returnvalue = ""
	local counter = 0			-- count how many xplane icao's are found
	local arrXPICAO = {}		-- temporary array that holds the reverse search results
	
	--print (tf_common_functions.tf_GetArraySize(tf_XPtoFSE_arrXplaneAirports))
	
	for index, value in pairs(tf_XPtoFSE_arrXplaneAirports) do
	
		
		-- index is the ICAO
		xpicao = index
		fseicao = tf_XPtoFSE_arrXplaneAirports[index][1]
		
		if fseicao == strFSEAirport then
			counter = counter + 1
			arrXPICAO[counter] = xpicao
			--returnvalue = returnvalue .. xpicao .. "; "
		end
	end
	
	if counter > 0 then
		-- now that all the results are captured in arrXPICAO, loop through this array, construct a return string and pick out a preferred destination while doing so
		-- counter holds the size of the results array. Choose a random ICAO from this results array
		
		local rndnum = math.random(1, counter)
		local myindex = 0
		
		for myindex=1,counter do
			if myindex == rndnum then
				-- this is the ICAO chosen randomly so put a little symbol on the front
				returnvalue = returnvalue .. ">"
			end
			
			returnvalue = returnvalue .. arrXPICAO[myindex] .. "; "
		end
	else
		returnvalue = nil
	end
	
	
	--print(returnvalue)
	return (returnvalue)
	

end

function tf_XP2FSE_build_Window(wnd, x, y)
	-- set up the xplane to FSE section
	
	imgui.TextUnformatted("ICAO:")
	-- Parameters: label, current text, maximum number of allowed characters
	local changed, strInputValue = imgui.InputText("", strDefaultInput, 5)

	--print(tf_XPtoFSE_arrXplaneAirports["YITT"][1])
	
	if changed then
		strEnteredICAO = string.upper(strInputValue)
		strDefaultInput = strEnteredICAO
	end
	
	
	if imgui.Button("Click to map this airport") then
		-- The Button function creates a button with the given label. It returns true in the
		-- moment where the button is released, i.e. the if statement is used to check whether
		-- the action behind the button should now be executed. 
		
		-- print("strEnteredICAO:" .. strEnteredICAO)
		
		if tf_XPtoFSE_arrXplaneAirports[strEnteredICAO] then
			strOutput = "The FSE equivalent is " .. tf_XPtoFSE_arrXplaneAirports[strEnteredICAO][1] .. "."
		else
			strOutput = "ICAO cannot be mapped to FSE. The database may be incomplete."
		end
		
		strReverseSearch = tf_XP2FSE_ReverseSearch(strEnteredICAO)
		if strReverseSearch ~= nil then
			strOutput = strOutput .. "\n" .. "Alternate XPlane airports are " .. strReverseSearch
		end
		
		if tf_XPtoFSE_arrXplaneAirports[strEnteredICAO][6] ~=nil then
			strOutput = strOutput .. "\n" .. tf_XPtoFSE_arrXplaneAirports[strEnteredICAO][6]
		end
	
	end
	
	imgui.TextUnformatted(strOutput)
		
end
      
tf_XPtoFSE_loadfromfile()


-- create macro
add_macro("XP2FSE", "tf_XP2FSE_show_window()")
create_command("FlyWithLua/XPlaneToFSE_toggle", "XPlane to FSE (Open)", "tf_XP2FSE_show_window()", "", "")
	
