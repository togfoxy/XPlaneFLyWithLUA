--v0.01
-- TOGFox

if not SUPPORTS_FLOATING_WINDOWS then
    -- to make sure the script doesn't stop old FlyWithLua versions
    logMsg("PauseAt requires a newer version of FlyWithLua. Your version of FlyWithLua doesn't support imgui, please upgrade.")
    return
end

local tf_XPtoFSE_arrXplaneAirports = {}
local tf_XP2FSEWnd = nil
local strOutput ="Initialised"

function tf_XPtoFSE_loadfromfile()
	local position = 0
	local strFilename = SCRIPT_DIRECTORY .. "tf\\tf_XPlaneFSEMapping.txt"
	local file = io.open(strFilename, "r")
	local strXPlane = ""
	local strFSEFBO = ""
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
					
					--print("Line: " .. line)
					strXPlane = string.sub(line, 1, (position - 1))	-- this is the bit before position
					v = string.sub(line, (position + 1))	-- this is the remainder of the line after the position
					--print("strXPlane:" .. strXPlane)
					--print("v: " .. v)
					
					position = string.find(v, ";")
					--print("Position: " .. position)
					if position ~= nil then
						strFSEFBO = string.sub(v, 1, (position - 1))
						print("strFSEFBO:" .. strFSEFBO)
					end
					--print("strXplane: " .. strXPlane .. "; strFSEFBO: " .. strFSEFBO)
					
					tf_XPtoFSE_arrXplaneAirports[strXPlane] = {}		-- need to explicitly instantiate this sub-array item
					tf_XPtoFSE_arrXplaneAirports[strXPlane][1] = strFSEFBO
					-- can insert other things like 3D airport flag here when ready
					
					--print("strXplane: " .. strXPlane .. "; strFSEFBO: " .. strFSEFBO .. "; array: " .. tf_XPtoFSE_arrXplaneAirports[strXPlane][1])
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
    tf_XP2FSEWnd = float_wnd_create(250, 140, 1, true)
    float_wnd_set_title(tf_XP2FSEWnd, "Xplane to FSE")
    float_wnd_set_imgui_builder(tf_XP2FSEWnd, "tf_XP2FSE_build_Window")
end

function tf_XP2FSE_build_Window(wnd, x, y)
	-- set up the xplane to FSE section
	
	imgui.TextUnformatted("Xplane ICAO:")
	-- Parameters: label, current text, maximum number of allowed characters
	local changed, strInputValue = imgui.InputText("", "", 5)

	--print(tf_XPtoFSE_arrXplaneAirports["YITT"][1])
	
	if changed then
		strEnteredICAO = string.upper(strInputValue)
	end
	
	
	if imgui.Button("XP to FSE") then
		-- The Button function creates a button with the given label. It returns true in the
		-- moment where the button is released, i.e. the if statement is used to check whether
		-- the action behind the button should now be executed. Let's make the button toggle a variable:
		
		-- do something
		
		-- on XPlane to FSE button
		--	validate the text box
		--	output arrXplaneAirports[textbox]
		
		-- print("strEnteredICAO:" .. strEnteredICAO)
		

		if tf_XPtoFSE_arrXplaneAirports[strEnteredICAO] then
			strOutput = "The FSE FBO is " .. tf_XPtoFSE_arrXplaneAirports[strEnteredICAO][1]
		else
			strOutput = "ICAO cannot be mapped to FSE"
		end
		

		
		-- print (strOutput)
		
	end
	
	imgui.TextUnformatted(strOutput)
		
end
        
tf_XPtoFSE_loadfromfile()


-- create macro
add_macro("XP2FSE", "tf_XP2FSE_show_window()")
create_command("FlyWithLua/XPlaneToFSE_toggle", "XPlane to FSE (Open)", "tf_XP2FSE_show_window()", "", "")
	
