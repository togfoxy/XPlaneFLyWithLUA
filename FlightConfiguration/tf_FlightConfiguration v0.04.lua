-- LoadAH2 by TOGFox 2/sept/2020
-- v0.01 - initial release

local strVersion = "0.04"

if not SUPPORTS_FLOATING_WINDOWS then
    -- to make sure the script doesn't stop old FlyWithLua versions
    logMsg("LoadAH2 requires a newer version of FlyWithLua. Your version of FlyWithLua doesn't support imgui, please upgrade.")
    return
end

local tf_common_functions = require "tf_common_functions_v2_00"

tf_LAH2Window = nil
strEnteredPayload = ""
strEnteredFuel = ""
strEnteredDay = ""
strEnteredMonth = ""
strEnteredHour = ""
strEnteredMinute = ""

intEnteredPayload = 0
intEnteredFuel = 0
intEnteredDay = 0
intEnteredMonth = 0
intEnteredHour = 0
intEnteredMinute = 0

choice = 1 					-- for radio button. 1 = kg. 2 = lbs.
bolFillCentreTank = true	-- True = "fill centre tank" is on by default
							-- False = "fill centre tank" is off by default

zulu_t = dataref_table("sim/time/zulu_time_sec","writable")	

dataref("tf_fltPayloadWeightKGs", "sim/flightmodel/weight/m_fixed","writable")

dataref("tf_CurrentDay", "sim/cockpit2/clock_timer/current_day")
dataref("tf_CurrentMonth", "sim/cockpit2/clock_timer/current_month")
dataref("tf_CurrentDateDays", "sim/time/local_date_days","writeable")

tf_arrTankRatios = dataref_table("sim/aircraft/overflow/acf_tank_rat")	-- an array up to nine
tf_arrTankWeightsKGS = dataref_table("sim/flightmodel/weight/m_fuel", "writable")	-- an array up to nine	
dataref("tf_fltMaximumFuelWeightKGs" ,"sim/aircraft/weight/acf_m_fuel_tot","writable")
dataref("tf_intNumberofTanks","sim/aircraft/overflow/acf_num_tanks")


-- Sets the name of the onclose function.
--float_wnd_set_onclose(wnd, "tf_close_floating_window")
-- The first parameter must be a handle to a window previously created with float_wnd_create and the
-- second parameter set the name of the onclose function.	

function tf_LAH2_show_window()
    tf_LAH2Window = float_wnd_create(475, 225, 1, true)	-- width/height
    float_wnd_set_title(tf_LAH2Window, "Configure Flight " .. strVersion)
    float_wnd_set_imgui_builder(tf_LAH2Window, "tf_LAH2Window_build_Window")
end


-- When on_close it called, it is illegal to do anything with the wnd variable
-- It is also not allowed to create new windows in on_close!
--function tf_close_floating_window(wnd)
--end

function tf_LAH2Window_build_Window(wnd, x, y)
	-- set up the xplane to FSE section
	
	local payloadchanged, strInputValue = imgui.InputText("Payload", strEnteredPayload, 7) --label, current text, maximum number of allowed characters
	if payloadchanged then
		strEnteredPayload = strInputValue
	end

	--imgui.TextUnformatted("Fuel:")
	-- Parameters: label, current text, maximum number of allowed characters
	local fuelchanged, strInputValue2 = imgui.InputText("Fuel", strEnteredFuel, 7)
	if fuelchanged then
		strEnteredFuel = strInputValue2
	end
	
	imgui.Separator()

	--imgui.TextUnformatted("Day:")
	imgui.TextUnformatted("Current date value: " .. tf_CurrentDay)
	imgui.TextUnformatted("Current month value: " .. tf_CurrentMonth)
	

	if imgui.Button("- 1 month") then
		tf_CurrentDateDays = tf_CurrentDateDays - 30
	end
	imgui.SameLine()
	if imgui.Button("- 1 day") then
		tf_CurrentDateDays = tf_CurrentDateDays - 1
	end
	imgui.SameLine()	
	if imgui.Button("+ 1 day") then
		tf_CurrentDateDays = tf_CurrentDateDays +1
	end
	imgui.SameLine()
	if imgui.Button("+ 1 month") then
		tf_CurrentDateDays = tf_CurrentDateDays +30
	end
	
	imgui.Separator()
	
	--imgui.TextUnformatted("Zulu hour:")
	-- Parameters: label, current text, maximum number of allowed characters
	local hourchanged, strInputValue5 = imgui.InputText("Zulu hour", strEnteredHour, 7)
	if hourchanged then
		strEnteredHour = strInputValue5
	end		
	
	--imgui.TextUnformatted("Zulu minute:")
	-- Parameters: label, current text, maximum number of allowed characters
	local minutechanged, strInputValue6 = imgui.InputText("Zulu minute", strEnteredMinute, 7)
	if minutechanged then
		strEnteredMinute = strInputValue6
	end	
	imgui.Separator()
	
	
	-- Radio buttons: Specify whether the choice is currently active as parameter.
	-- Returns true when the choice is selected.
	if imgui.RadioButton("kilograms (kg)", choice == 1) then
		choice = 1
	end
	imgui.SameLine()
	if imgui.RadioButton("pounds (lbs)", choice == 2) then
		choice = 2
	end
	
	if tf_intNumberofTanks == 3 then
		imgui.SameLine()
		-- The following function creates a checkbox:
		local changed, newVal = imgui.Checkbox("Fill centre tank first", bolFillCentreTank)
		-- The first parameter is the caption of the checkbox, it will be displayed right of the checkbox.
		-- The second parameter is the current boolean value.
		
		-- The function returns two values: a bool to indicate whether the value was changed and the new value. 
		if changed then
			bolFillCentreTank = newVal
		end
	end
	
	imgui.Separator()	
	
	if imgui.Button("Configure with above values") then
		-- The Button function creates a button with the given label. It returns true in the
		-- moment where the button is released, i.e. the if statement is used to check whether
		-- the action behind the button should now be executed. 
		
		-- update datarefs
		tf_ConfigureFlight(strEnteredPayload, strEnteredFuel, intEnteredDay, intEnteredMonth, strEnteredHour, strEnteredMinute, bolFillCentreTank)
		
		float_wnd_destroy(wnd)
	end	
	
end
      
	  
	  
function tf_ConfigureFlight(strPayload, strFuel, intDay, intMonth, strHour, strMinute, bolFCT)
	-- strFuel
	-- bolFCT = fill centre tank first

	-- choice is the variable that holds the radio button value.
	-- 1 = kg and 2 = lbs
	
	if choice == 2 then 
		strPayload = tonumber(strPayload) * 0.4535
		strFuel = tonumber(strFuel) * 0.4535	-- convert the lbs value to a kgs value
	end

	-- adjust payload
	tf_fltPayloadWeightKGs = tonumber(strPayload)

	if not bolFCT then	
		-- adjust fuel evenly across all tanks evenly according to tank ratio (in kgs)
		for i=0,9 do 
			tf_arrTankWeightsKGS[i] = strFuel * tf_arrTankRatios[i]
		end

	else
		-- fill centre tank first. Need some fancy math
		-- determine centre tank capacity
		fltCentreTankMax = tf_fltMaximumFuelWeightKGs * tf_arrTankWeightsKGS[1]	-- array item 1 is actually the 2nd element
		-- print (fltCentreTankMax)
			
		if tonumber(strFuel) < fltCentreTankMax then
			tf_arrTankWeightsKGS[0] = 0
			tf_arrTankWeightsKGS[1] = strFuel
			tf_arrTankWeightsKGS[2] = 0
		else
			-- centre tank needs to fill with left overs onto the secondary tanks
			tf_arrTankWeightsKGS[1] = fltCentreTankMax
			strFuel = strFuel - fltCentreTankMax
			
			tf_arrTankWeightsKGS[0] = tf_common_functions.tf_round(strFuel/2)
			tf_arrTankWeightsKGS[2] = tf_common_functions.tf_round(strFuel/2)

		end
	end
	

	
-- set time
	-- can't set hours and minutes directly but can manipulate through 'seconds'
	-- sim/cockpit2/clock_timer/zulu_time_hours
	-- sim/cockpit2/clock_timer/zulu_time_minutes
	if not tf_common_functions.tf_IsStringEmpty(strHour) then
		zulu_t[0] = (strHour * 60 *60) + (strMinute * 60) + (3*60) -- reduce the pre-flight timy by 3 minutes
	end

	-- sim/cockpit2/clock_timer/current_day
	if intDay > 0 then
		tf_CurrentDay = intDay
	end
	
	-- sim/cockpit2/clock_timer/current_month
	if intMonth > 0 then
		tf_currentMonth = intMonth
	end
end
	  
  
-- create macro
-- add_macro("LoadAH2", "tf_LAH2_show_window()")
create_command("FlyWithLua/LoadAirHauler2", "LAH2 (open)", "tf_LAH2_show_window()", "", "")


