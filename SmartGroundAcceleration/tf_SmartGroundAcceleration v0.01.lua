-- Waypoint protection
-- TOGFox
-- v0.01 	- initial release
-- v0.02	- no changes (yet)

dataref("tf_DMEDistance", "sim/cockpit2/radios/indicators/hsi_dme_distance_nm_pilot")
dataref("tf_InReplayMode", "sim/time/is_in_replay")
dataref("tf_GroundCompression", "sim/time/ground_speed", "writeable")

local tf_ProtectionActive = 0	-- a tracker so we know when the GC has been adjusted down
local tf_RequestedGCValue = 1	-- track the requested GC value so it can be restored when needed
local tf_TurnGCOnTarget = 0		-- this is the distance to the next WP to turn on TC
local tf_WPThreshold = 2		-- this is the distance to/from the WP where GC needs to be 1


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

do_often("tf_WaypointProtectionMain()")






