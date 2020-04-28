-- Waypoint protection
-- TOGFox - edge33
-- v0.01 	- initial release
-- v0.02	- no changes (yet)
-- v0.03	- added menu
-- v0.04	- wired menu
-- v0.05	- changed to support FMS for 738 Laminar
	-- added fix for several waypoints too close
	-- route changed before hitting the waypoint
	-- correct route if plain drifts from the path
strVersion = "0.05"

dataref("tf_DMEDistance", "laminar/B738/fms/lnav_dist_next")
dataref("tf_InReplayMode", "sim/time/is_in_replay")
dataref("tf_GroundCompression", "sim/time/ground_speed", "writeable")
dataref("tf_DistanceFromDestination", "laminar/B738/FMS/dist_dest", "readonly")
dataref("tf_SimPaused", "sim/time/paused", "writeable")
dataref("tf_TrackOffset", "laminar/B738/fms/xtrack", "readonly")

local tf_ProtectionActive = 0	-- a tracker so we know when the GC has been adjusted down
local tf_TurnGCOnTarget = 0		-- this is the distance to the next WP to turn on TC
local tf_WPThreshold = 8		-- this is the distance to/from the WP where GC needs to be 1
local tf_scriptActivate = false	-- this flags toggles the script activation
local tf_missed = 0
local tf_SelectedCompressionRate = 1
local tf_previousTarget = tf_DMEDistance

-- not working yet
local tf_distanceToPause = 0	-- this is the distance from the final destination to pause the sim


function tf_WaypointProtectionMain()
	

	
	if not tf_scriptActivate then
		return true;
	end

	--print("active" .. "Replay:" .. tf_InReplayMode .. "distance to next: " .. tf_DMEDistance)
	if tf_InReplayMode == 0 and tf_DMEDistance > 0.1 then

		-- If the plane is going away from the path
		if tf_TrackOffset > 0.3 then
			print("drifting away")
			tf_GroundCompression = 1
			tf_ProtectionActive = 1
		end

		-- to detected missed waypoints:
		-- if the plane misses to reset speed at a waypoint becouse FMS moves to the next WP early (in case of a turn)
		local tf_currentTarget = tf_DMEDistance
		if tf_currentTarget > tf_previousTarget and tf_ProtectionActive == 0  then
			print ("WARNING: skipped wp")
			tf_GroundCompression = 1
			tf_ProtectionActive = 1
			local tf_distanceToMissed = tf_previousTarget
			tf_TurnGCOnTarget = tf_currentTarget - tf_distanceToMissed - 3
			return true
		end
		tf_previousTarget = tf_DMEDistance
		-- print ("now is " .. tf_currentTarget)
		-- print ("before was " .. tf_previousTarget)

		if (tf_distanceToPause > 0 and tf_distanceToPause == math.floor(tf_DistanceFromDestination+0.5) ) then
			print("pause")
			tf_SimPaused = 1
			tf_GroundCompression = 1
			tf_ProtectionActive = 0
			tf_TurnGCOnTarget = 0
			tf_scriptActivate = false
		end
		
		-- I changed the multiplier while in safe mode
		if tf_ProtectionActive == 1 and tf_GroundCompression > 1 then
			print("correcting behavior")
			tf_GroundCompression = 1
		end

		-- I am close to the waypoint I need to reset speed to 1
		--if tf_DMEDistance < tf_WPThreshold and tf_GroundCompression > 1 and tf_ProtectionActive == 0 then
		if tf_DMEDistance < tf_WPThreshold and tf_GroundCompression > 1  then
			tf_GroundCompression = 1
			tf_ProtectionActive = 1
		end
		
		if tf_DMEDistance > tf_WPThreshold and tf_ProtectionActive == 1 and tf_TurnGCOnTarget == 0 then
			-- a bit of a trick is used here
			-- when the plane moves past the waypoint, DME is set to 50nm or some large number to the next wp
			-- Need to use that to see how far we moved away from the last WP
			if (tf_DMEDistance - 3) > tf_WPThreshold then --fix waypoint too close
				tf_TurnGCOnTarget = tf_DMEDistance - 3	-- when we have moved this nm towards next DME then we can use TC.
			end
		end
		
		if tf_DMEDistance > tf_WPThreshold and tf_ProtectionActive == 1 and tf_DMEDistance < tf_TurnGCOnTarget then
			print("restoring: ".. tf_SelectedCompressionRate)
			tf_GroundCompression = tf_SelectedCompressionRate
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
	local changed, newVal = imgui.Checkbox("Activate Smart Ground Acceleration", tf_scriptActivate)
	if changed then
		tf_scriptActivate = newVal
		if not tf_scriptActivate then
			tf_GroundCompression = 1
			tf_ProtectionActive = 0
			tf_TurnGCOnTarget = 0
			tf_SelectedCompressionRate = 1
		end
	end
	imgui.TextUnformatted("Actual multiplier is: " .. tf_GroundCompression)
	imgui.TextUnformatted("Distance from destination: " .. math.floor(tf_DistanceFromDestination+0.5))

	local choices = {1, 2, 4, 8, 16}
	-- BeginCombo starts a combo box. The first parameter is the label, the
	-- second parameter the text of the currently selected choice.
	if imgui.BeginCombo("Ground speed multiplier", tf_SelectedCompressionRate) then
		-- Loop over all choices
		for i = 1, #choices do
			-- The Selectable function adds a choice to a combobox.
			-- The first parameter is the label, the second one
			-- should be true if this choice is currently selected.
			if imgui.Selectable(choices[i], choice == i) then
				-- Selectable returns true when a new choice was selected,
				-- we should then copy the choice into our choice variable
				tf_SelectedCompressionRate = choices[i]
				tf_GroundCompression = tf_SelectedCompressionRate
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
		local newNumber = tonumber(newTextD)
		if not ( newNumber == nil ) then
			tf_WPThreshold = newNumber
		end
	end

	-- Allow the user to input text
	imgui.TextUnformatted("Pause when at the following distance from destination (0: disabled)")
	local changedP, newTextP = imgui.InputText(" ", tf_distanceToPause, 4)
	-- Parameters: Label, current text, maximum number of allowed characters
	if changedP then
		local newNumber = tonumber(newTextP)
		if not ( newNumber == nil ) then
			tf_distanceToPause = newNumber
		end
	end



	imgui.TextUnformatted("DME: " .. tf_DMEDistance .. " GC: " .. tf_GroundCompression .. " PA: " .. tf_ProtectionActive .. " TH: " .. tf_WPThreshold .. " TOT: ".. tf_TurnGCOnTarget)
end

do_often("tf_WaypointProtectionMain()")

-- create macro
add_macro("Smart Ground Acceleration (Open)", "tf_SGA_show_window()")
create_command("FlyWithLua/SmartGroundAcceleration", "Smart Ground Acceleration (Open)", "tf_SGA_show_window()", "", "")
	






