-- v0.01
-- Fox

--Requires tf_common_functions_006

-- Constants
local tf_strICAO="KMSP"					-- Destination airport
local tf_DistanceToDest = 8000			-- The distance to track at which to start landing
local tf_MaxAcceptableIAS = 130			-- The point at which we throttle down
local tf_MinAcceptableIAS = 120			-- The point at which we throttle up (should be above stall point!)
local tf_SafeGearSpeed = 163			-- The rated safe speed to lower landing gear
local tf_PreferredDescentRate = -1000	-- The preferred descent rate in feet per min
local tf_PreferredLandingRate = -200	-- The preferred descent rate when touching down
local tf_LandingThrottle = 0.50			-- Throttle % needed when touching down
local tf_SafeParkBrakeSpeed = 25		-- The taxi speed that is safe to apply the park brake
local tf_DistFromAirport = 10			-- The nm from the airport that the approach should start
local tf_FlareAltitude = 200			-- The altitude AGL where the flare should begin
  
-- Status trackers
local tf_scriptactive = 0
local tf_fltDistToDest = 99999

-- Datarefs
dataref("tf_fltAltAGL","sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
dataref("tf_IndicatedAirSpeed", "sim/flightmodel/position/indicated_airspeed")
dataref ("tf_fltThrottleRatio","sim/flightmodel/engine/ENGN_thro","writable",0)
dataref("tf_intGearHandle","sim/cockpit/switches/gear_handle_status","writable")
dataref("tf_bolPC12ParkBrake","pc12/gear/parking_brake","writable")
dataref("tf_InReplayMode","sim/time/is_in_replay")
dataref("tf_vs","sim/cockpit2/gauges/indicators/vvi_fpm_pilot")
dataref("tf_fltPitchHold","sim/cockpit2/autopilot/sync_hold_pitch_deg","writable")
dataref("tf_fltFlapHandleRatio","sim/cockpit2/controls/flap_handle_deploy_ratio", "writable" , 0)
dataref("tf_intAPAltMode","sim/cockpit/autopilot/altitude_mode","writable")
dataref("tf_bolFuelLatch", "pc12/engine/cut_off_ladge","writable")
dataref("tf_bolSimPaused", "sim/time/paused")



local tf_distancetodestination = 100	-- dummy value for testing
local tf_AutoLand_PreviousAngleToAirport = 0
local fltConvNMtoFT = 6076.1

local tf_common_functions = require "tf_common_functions_006"

function tf_AutoLandMain()
	local arrAirportDetails = {}
	local PredictedLat		--this is where we think the craft will be
	local PredictedLong		--this is where we think the craft will be

	if tf_InReplayMode == 0 and tf_bolSimPaused == 0 then

		tf_fltDistToDest = (tf_common_functions.tf_GetDistanceToICAO(tf_strICAO) -0.600)
		--print("Distance to TOD: " .. tf_fltDistToDest)
		
		if tf_fltDistToDest < (tf_DistFromAirport) and tf_scriptactive == 0 then
			tf_scriptactive = 1		-- means plane is beyound take off and script needs to do things
			print("Activating script")
		end

		if tf_scriptactive == 1 then
			if tf_fltAltAGL > tf_FlareAltitude and tf_fltDistToDest > 0.450 then
			
				print("Descending")
				
				-- need to descend (but not ready to land)
				
				if tf_intAPAltMode ~= 15 then
					--tf_intAPAltMode = 15
					command_once("sim/autopilot/altitude_hold")
				end
				
				if tf_IndicatedAirSpeed > tf_MaxAcceptableIAS then
					tf_fltThrottleRatio = tf_fltThrottleRatio * 0.95	-- throttle down
				end
				if tf_IndicatedAirSpeed < tf_MinAcceptableIAS then
					tf_fltThrottleRatio = tf_fltThrottleRatio * 1.05	-- throtlle up
				end
				
				if tf_fltFlapHandleRatio < 0.3 then
					command_once("sim/flight_controls/flaps_down")
				end
				if tf_fltFlapHandleRatio > 0.4 then
					command_once("sim/flight_controls/flaps_up")
				end
				
				if tf_IndicatedAirSpeed < (tf_SafeGearSpeed * 0.95) and tf_intGearHandle < 1 then
					command_once("sim/flight_controls/landing_gear_down")
					tf_intGearHandle = 1
				end
				if tf_IndicatedAirSpeed > (tf_SafeGearSpeed) and tf_intGearHandle == 1 then					
					-- raise gear if speed is somehow excessive
					command_once("sim/flight_controls/landing_gear_up")
					tf_intGearHandle = 0
				end
		
		
				-- what is our radar alt compared to the destination airport?
				local arrAirportDetails = tf_common_functions.tf_GetSpecificAirportInformation(tf_strICAO)
				local fltAltitudeDifference = tf_fltAltAGL - (arrAirportDetails["Height"] * 3.28 ) --convert meters to feet
				
				local degAngleToAirport = math.deg(math.atan(fltAltitudeDifference/((tf_fltDistToDest - 0.750) * fltConvNMtoFT )))
				print("Angle to airport: " .. degAngleToAirport)
				
				--work out if angle is increasing or decreasing. This is passed to the draw function so it can draw the arrow
				print ("Previous AoA:" .. tf_AutoLand_PreviousAngleToAirport)
				local degDelta = degAngleToAirport - tf_AutoLand_PreviousAngleToAirport
				print("degDelta1: " .. degDelta)
				
				-- need to moderate descent speed
				if tf_fltAltAGL > tf_FlareAltitude then
					-- continue descending
					
					if tf_vs > 0 then
						tf_fltPitchHold = tf_fltPitchHold - 4
						print("Stopping the climb")
					else
					
						-- need to moderate plane pitch based on which glide slope 'zone' the plane is in and the rate of change when in that zone.
						-- when on the correct glide slope, rate of change should be minimal (small corrections only)
							
						local CurrentZone = 0
						CurrentZone = tf_common_functions.DetermineCurrentGlideSlopeZone(degAngleToAirport)
						print("Current zone: " .. CurrentZone)
						
						-- this are the preferred delta's for each zone. Need to try to stay UNDER these delta's for a smooth descent inside the glide slope
						-- degDelta can be */- and that's okay.
						-- these are */- tolerances
						local Zone1Delta = 0.065
						local Zone2Delta = 0.070
						local Zone3Delta = 0.065
						local Zone4Delta = 0.070
						local Zone5Delta = 0.1
						
						if CurrentZone == 4 or CurrentZone == 5 then
							tf_fltPitchHold = tf_fltPitchHold - 2
							print("Zone > 3: dropping nose")
						end							
						
						if CurrentZone == 1 and degDelta < (0.05) then
							-- nose too low 
							tf_fltPitchHold = tf_fltPitchHold + 0.5
							print("Zone 1: raising nose")
						end
						
						if CurrentZone == 1 and degDelta > (Zone1Delta) then
							-- nose too low 
							tf_fltPitchHold = tf_fltPitchHold - 0.5
							print("Zone 1: dropping nose")
						end						
												
						if CurrentZone == 2 and degDelta < (Zone2Delta*-1) then
							tf_fltPitchHold = tf_fltPitchHold + 1
							print("Zone 2: raising nose")
						end
						
						if CurrentZone == 2 and degDelta > (Zone2Delta) then
							tf_fltPitchHold = tf_fltPitchHold - 1
							print("Zone 2: dropping nose")
						end
						
						if CurrentZone == 3 and degDelta < (Zone3Delta*-1) then
							tf_fltPitchHold = tf_fltPitchHold + 1
							print("Zone 3: raising nose")
						end
						if CurrentZone == 3 and degDelta > (Zone3Delta) then
							tf_fltPitchHold = tf_fltPitchHold - 1
							print("Zone 3: lowering nose")
						end
						
						if CurrentZone == 4 and degDelta < (Zone4Delta*-1) then
							tf_fltPitchHold = tf_fltPitchHold + 1
							print("Zone 4: raising nose")
						end

						if CurrentZone == 5 and degDelta < (Zone5Delta*-1) then
							tf_fltPitchHold = tf_fltPitchHold + 1
							print("Zone 5: raising nose")
						end	

						if CurrentZone == 1 or CurrentZone == 2 and tf_AutoLand_PreviousAngleToAirport > degAngleToAirport then
							-- we seem to be going the wrong way!
							tf_fltPitchHold = tf_fltPitchHold + 1
							print("raising nose")
						end
					end
				
				else

								
				end
				
				tf_AutoLand_PreviousAngleToAirport = degAngleToAirport
				PreviousZone = CurrentZone
				--print("degDelta1: " .. degDelta)
			else
			
				-- how to complete the landing?
				
				if tf_vs < tf_PreferredLandingRate then
					tf_fltPitchHold = tf_fltPitchHold + 2
				end
				if tf_vs > (tf_PreferredLandingRate + 50) then
					tf_fltPitchHold = tf_fltPitchHold - 0.5
				end
				
				if tf_fltPitchHold < -4 then
					tf_fltPitchHold = 4
				end
				
				if tf_bolFuelLatch == 1 then
					print("Unlatching")
					-- command_once("pc12/engine/cutoff_protection_toggle")	-- doesn't work
					tf_bolFuelLatch = 0
				end
				
				
				tf_fltThrottleRatio = 0
					
				print("Landing ...")
				
				print(tf_IndicatedAirSpeed)
				print(tf_SafeParkBrakeSpeed)
				print(tf_bolPC12ParkBrake)
				
				-- engine off

				command_once("sim/engines/mixture_min")
				print("Engaging brakes")
				tf_bolPC12ParkBrake = 1

				if tf_IndicatedAirSpeed < 5 then
					tf_scriptactive = 0			
				end

			end	

		end
	end
end

do_sometimes("tf_AutoLandMain()")