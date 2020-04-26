-- Waypoint protection
-- TOGFox - edge33
-- v0.01 	- initial release
-- v0.02	- no changes (yet)
-- v0.03	- added menu
strVersion = "0.03"

dataref("tf_DMEDistance", "sim/cockpit2/radios/indicators/hsi_dme_distance_nm_pilot")
dataref("tf_InReplayMode", "sim/time/is_in_replay")
dataref("tf_GroundCompression", "sim/time/ground_speed", "writeable")

local tf_ProtectionActive = 0	-- a tracker so we know when the GC has been adjusted down
local tf_RequestedGCValue = 1	-- track the requested GC value so it can be restored when needed
local tf_TurnGCOnTarget = 0		-- this is the distance to the next WP to turn on TC
local tf_WPThreshold = 2		-- this is the distance to/from the WP where GC needs to be 1
local tf_pickedMultiplier = 2;	-- this is the selected multiplier
local tf_scriptActivate = 0;	-- this flags toggles the script activation
local tf_distanceToPause = 0;	-- this is the distance from the final destination to pause the sim


function tf_WaypointProtectionMain()

	if tf_InReplayMode == 0 and tf_DMEDistance > 0.1 then
	
		-- print("DME: " .. tf_DMEDistance .. " GC: " .. tf_GroundCompression .. " PA: " .. tf_ProtectionActive)
	
		if tf_DMEDistance < tf_WPThreshold and tf_GroundCompression > 1 and tf_ProtectionActive == 0 then
			-- preserve this so we can restore it later
			tf_RequestedGCValue = tf_GroundCompression
			
			tf_GroundCompression = 1
			tf_ProtectionActive = 1
		
		end
		
		if tf_DMEDistance > tf_WPThreshold and tf_ProtectionActive == 1 and tf_TurnGCOnTarget == 0 then
			-- a bit of a trick is used here
			-- when the plane moves past the waypoint, DME is set to 50nm or some large number to the next wp
			-- Need to use that to see how far we moved away from the last WP
			tf_TurnGCOnTarget = tf_DMEDistance - 3	-- when we have moved this nm towards next DME then we can use TC.
		end
		
		if tf_DMEDistance > tf_WPThreshold and tf_ProtectionActive == 1 and tf_DMEDistance < tf_TurnGCOnTarget then
			tf_GroundCompression = tf_RequestedGCValue
			tf_ProtectionActive = 0
			tf_TurnGCOnTarget = 0
		end
	end



end


function tf_SGA_show_window()
	tf_XP2FSEWnd = float_wnd_create(600, 200, 1, true)
    float_wnd_set_title(tf_XP2FSEWnd, "Smart Ground Acceleration " .. strVersion)
    float_wnd_set_imgui_builder(tf_XP2FSEWnd, "tf_SGA_build_Window")
end


function tf_SGA_build_Window(wnd, x, y)
	-- set up the xplane to GSA menu

	-- Parameters: label, Current value for the switch
	local changed, newVal = imgui.Checkbox("Activate Smart Ground Acceleration", scriptActivate)
	if changed then
		scriptActivate = newVal
	end

	local choices = {"2", "4", "8", "16"}
	-- BeginCombo starts a combo box. The first parameter is the label, the
	-- second parameter the text of the currently selected choice.
	
	if imgui.BeginCombo("Ground speed multiplier", tf_pickedMultiplier) then
		-- Loop over all choices
		for i = 1, #choices do
			-- The Selectable function adds a choice to a combobox.
			-- The first parameter is the label, the second one
			-- should be true if this choice is currently selected.
			if imgui.Selectable(choices[i], choice == i) then
				-- Selectable returns true when a new choice was selected,
				-- we should then copy the choice into our choice variable
				choice = i
				tf_pickedMultiplier = choices[i]
			end
		end
		-- _Must_ be called if and only if BeginCombo returns true, i.e.
		-- when the combobox is currently open
		imgui.EndCombo()	
	end
	-- Allow the user to input text
	
	imgui.TextUnformatted("Safe distance from/to WP")
	local changedD, newTextD = imgui.InputText("", tf_WPThreshold, 2)
	-- Parameters: Label, current text, maximum number of allowed characters
	if changedD then
		tf_WPThreshold = newTextD
	end

	-- Allow the user to input text
	imgui.TextUnformatted("Pause when at the following distance from destination (0: disabled)")
	local changedP, newTextP = imgui.InputText(" ", tf_distanceToPause, 4)
	-- Parameters: Label, current text, maximum number of allowed characters
	if changedP then
		tf_distanceToPause = newTextP
	end
end

do_often("tf_WaypointProtectionMain()")

-- create macro
add_macro("Smart Ground Acceleration (Open)", "tf_SGA_show_window()")
create_command("FlyWithLua/SmartGroundAcceleration", "Smart Ground Acceleration (Open)", "tf_SGA_show_window()", "", "")
	






