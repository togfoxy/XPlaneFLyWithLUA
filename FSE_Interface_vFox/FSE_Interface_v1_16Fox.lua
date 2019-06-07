--________________________________________________________--
-- FlyWithLua AddOn-Script for FS-Economy/X-Economy
-- This file has to be put into the Folder X-Plane/Resources/Plugins/FlyWithLua/Scripts
-- Teddii / 2014-07-30
-- This script will show a small interface to interact with the X-Economy Script.
-- It's only shown, if your mouse hover over the area of the interface.
-- You might what to change the position of the interface below.
--
-- This script is based on Carsten Lynker's "quick settings.lua", that came with FlyWithLua.
--
-- This is only a basic script. There are many other actions possible
-- with FlyWithLua, e.g. speak a warning text or even pause X-Plane
-- when groundspeed goes over 15kts without FSE flight started ...
-- 
-- FlyWithLua can be downloaded from: http://forums.x-plane.org/index.php?app=downloads&showfile=17468
-- User Support via X-Plane.org Forum: http://forums.x-plane.org/index.php?showforum=188
--________________________________________________________--
--History:

--Version 1.0 2014-07-30 Teddii
--	release
--
--Version 1.1 2014-08-09 Teddii
--	Added code to handle new "fse_connected" dataref
--	Added an option to always show the interface when "departing"
--
--Version 1.2 2014-08-19 Teddii
--	Removed the code fragment that draws a box in the lower left corner
--
--Version 1.3 2014-11-30 Teddii
--	Added code to handle new "fse_airborne" dataref
--
--Version 1.4 2014-12-19 Teddii
--	Added code to show a warning, if gear is not compatible with new XFSE client
--
--Version 1.5 2014-12-20 Teddii
--	Added menu entry "plugins/FlyWithLua_Macros/Always show FSE-Interface on ground" to switch visibility on/off
--
--Version 1.6 2015-01-09 Teddii
--	Added some code to work around the DataRef Update issue
--  Added menu entry to switch off window while "departing"
--	Removed code to show a warning, if gear is not compatible with new XFSE client
--
--Version 1.7 2015-03-01 Teddii
--  Added "Finish flight" function
--
--Version 1.8 2015-03-02 Teddii
--  snapper suggested to swap the cancel buttons
--
--Version 1.9 2015-04-25 Teddii
--  Fixed: permanently changing the window behaviour didn't worked as described (Thanks to Remen for finding this!)
--
--Version 1.10 2015-05-21 Teddii
--  Added: Handler function "eventTakeOffWithoutFseFlightStarted()" for a "flight not started" event added
--  (and added a default T2S message and a commented out "pause toggle")
--
--Version 1.11 2015-05-22 Teddii
--  Changed: "flight not started" check now takes the groundspeed into account
--  Changed: fadeout after takeoff now also takes the groundspeed into account
--
--Version 1.12 2015-05-24 Teddii
--  delayed the "flight not started" check
--
--Version 1.13 2015-06-10 Teddii
--  fixed the code to fire the warning only once :-)
--
--Version 1.14 2015-08-03 Teddii
--  the start flight button will now appear three seconds after finish flight was pressed
--  it seems X-Plane issues one more click sometimes, that will start the flight immediately again
--
--Version 1.15 2015-08-03 Teddii
--  resized the clickzone of the start/finish button to be easier to click on
--
--Version 1.16 2017-09-12 Renee_h
--  updated to be compatible with X-Economy version 1.9.0
--  removed refernces for "airbone", added refernces for "canendflight"
--
--Version 1.16Foxv1 2019-June-1 TOGFox
--  Will now automatically start FSE flight if the pilot forgets to do so
--
--Version 1.16Foxyv2 2019-June-1 TOGFox
--  Will now pause FSE if the client is not running and connected (logged in)
--
--Version 1.16Foxyv3 2019-June-3 TOGFox
--  Now recognises when the sim is in replay mode
--
--Version 1.16Foxyv4 2019-June-3 TOGFox
--  Automatically sets QNH to local airport upon takeoff
--
--Version 1.16Foxyv5 2019-June-4 TOGFox
--  Adjusted the window just a touch
--
--Version 1.16Foxyv6 2019-June-7 TOGFox
--  Corrected a defect where barameter was not always set automatically
--
--________________________________________________________--

--position of the interface
local XMin=15
local YMin=735 --770 is also good

--set your lease time left warning in seconds
local LeaseTimeLeftWarnSecs=1800

DataRef("fse_connected", 	"fse/status/connected")
DataRef("fse_flying",       "fse/status/flying")
DataRef("fse_canendflight", "fse/status/canendflight")
DataRef("fse_leasetime",    "fse/status/leasetime")
DataRef("fse_flighttime",   "fse/status/flighttime")
dataref("datRAlt", 			"sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
dataref("datGSpd", 			"sim/flightmodel/position/groundspeed")
dataref("bolInReplayMode", "sim/time/is_in_replay")
dataref("fltQNH", "sim/weather/barometer_sealevel_inhg")
dataref("fltQNHSetting" , "sim/cockpit/misc/barometer_setting", "writeable")

--set to "deactivate" if you want to see the interface only when hovering the mouse over it
add_macro("Always show FSE-Interface when on ground", "gAlwaysShowFseInterfaceOnGround=true", "gAlwaysShowFseInterfaceOnGround=false",
			"activate")

function eventTakeOffWithoutFseFlightStarted()
	if fse_connected == 1 then
		XPLMSpeakString("Registering flight with FSE")
		command_once("fse/flight/start")
	end
end
--________________________________________________________--


require "graphics"
--________________________________________________________--



--________________________________________________________--

XMax=XMin+130
YMax=YMin+80
showCancelC = false

local StartButtonTimer=os.clock()

--________________________________________________________--

do_often("fse_interface_check_often()")
do_every_draw("fse_interface_info()")
do_on_mouse_click("fse_interface_events()")
--________________________________________________________--

do_every_frame("fse_interface_check()")
function fse_interface_check()
end
--________________________________________________________--

local flightNotStarted=0
local FSEclientNotStarted=0

function fse_interface_check_often()

	if bolInReplayMode == 0 then
		if (datGSpd>20) then
			if FSEclientNotStarted < 3 then
				FSEclientNotStarted = FSEclientNotStarted + 1
			end
			if FSEclientNotStarted == 2 then	--check if client is started
				if fse_connected == 0 then
					XPLMSpeakString("Not logged into FSE")
					command_once("sim/operation/pause_toggle")			
				end
			end
		end

		if(datRAlt>25 and datGSpd>20) then
			if(flightNotStarted<3) then --count from 0 to 3 (because we check the flight state for often as the FSE client does)
				flightNotStarted=flightNotStarted+1
			end
			if(flightNotStarted==2) then --trigger event once(!) on stage 2
				if (fse_flying==0) then
					eventTakeOffWithoutFseFlightStarted()
					
				end
			end
			fltQNHSetting = fltQNH
		end
		if(datRAlt<10 and datGSpd<5) then
			flightNotStarted=0
		end
	end
end


local mouseHover
function fse_interface_info()
	mouseHover=true
	-- does we have to draw anything?
	if MOUSE_X < XMin or MOUSE_X > XMax or MOUSE_Y < YMin or MOUSE_Y > YMax then
		mouseHover=false
	end
	
	if(mouseHover==false) then
		if(datRAlt<10 and datGSpd<5) then
			if(fse_flying==0 and gAlwaysShowFseInterfaceOnGround==false) then
				return
			end
		elseif (flying == 1 and fse_leasetime>=LeaseTimeLeftWarnSecs) then
			return
		else
			return
		end
	end
	
	-- init the graphics system
	XPLMSetGraphicsState(0,0,0,1,1,0,0)

	-- draw transparent backgroud
	graphics.set_color(0, 0, 0, 0.5)
	graphics.draw_rectangle(XMin, YMin, XMax, YMax)

	--if(datOnGround~=0) then
	--	draw_string_Helvetica_10(XMin+5, YMin+85, "Plane is ON GROUND!")
	--end
	
	-- draw lines around the hole block
	if(fse_connected==0) then
		graphics.set_color(0.8, 0.8, 0.8, 0.5) 	 --grey
	else
		if(fse_flying==0) then
			graphics.set_color(1, 0, 0, 0.5) 	 --red
		elseif(fse_leasetime<LeaseTimeLeftWarnSecs) then -- fse_flying==1
			graphics.set_color(1, 1, 0, 0.5) 	 --yellow
		else -- flying==1
			graphics.set_color(0, 1, 0, 0.5)
		end
	end
	graphics.set_width(2)
	graphics.draw_line(XMin, YMin, XMin, YMax)
	graphics.draw_line(XMin, YMax, XMax, YMax)
	graphics.draw_line(XMax, YMax, XMax, YMin)
	graphics.draw_line(XMax, YMin, XMin, YMin)

	graphics.draw_line(XMin, 	YMin+30, XMax-1,  YMin+30) 	--hor
	graphics.draw_line(XMin+35, YMin+1,  XMin+35, YMin+30)	--vert1
	graphics.draw_line(XMin+40, YMin+1,  XMin+40, YMin+30)	--vert2
	graphics.draw_line(XMin+86, YMin+1,  XMin+86, YMin+30)	--vert3

	graphics.set_color(1, 1, 1, 0.8)

	if(fse_connected==0) then
			draw_string_Helvetica_10(XMin+5, YMin+67,     "Status            : offline")
	else
		if(fse_flying==0) then
			draw_string_Helvetica_10(XMin+5, YMin+67,     "Status            : on ground")
		else
			draw_string_Helvetica_10(XMin+5, YMin+67,     "Status            : enroute")
			str=string.format("Flight Time      : %02i:%02i:%02i",math.floor(fse_flighttime/3600),math.floor((fse_flighttime%3600)/60),(fse_flighttime%60))
			draw_string_Helvetica_10(XMin+5, YMin+52, str)
			str=string.format("Lease Time left: %02i:%02i:%02i",math.floor(fse_leasetime/3600),math.floor((fse_leasetime%3600)/60),(fse_leasetime%60))
			draw_string_Helvetica_10(XMin+5, YMin+37, str)
		end
	end
	
	if(fse_connected==0) then
			draw_string_Helvetica_10(XMin+46, YMin+11, "LOGIN")
	else
		if(fse_flying==0) then
			if(StartButtonTimer<=os.clock()) then
				draw_string_Helvetica_10(XMin+5, YMin+17, "Start")
				draw_string_Helvetica_10(XMin+5, YMin+5,  "Flight")
			end
			showCancelC=false
		else
			draw_string_Helvetica_10(XMin+91, YMin+17, "Cancel")
			draw_string_Helvetica_10(XMin+91, YMin+5,  " ARM")
			if(fse_canendflight==1) then
				draw_string_Helvetica_10(XMin+5, YMin+17, "Finish")
				draw_string_Helvetica_10(XMin+5, YMin+5,  "Flight")
			end
		end
		if(showCancelC) then
			draw_string_Helvetica_10(XMin+44, YMin+17, "Cancel")
			draw_string_Helvetica_10(XMin+44, YMin+5,  "Confirm")
		end
	end

end
--________________________________________________________--

function fse_interface_events()
	-- we will only react once
	if MOUSE_STATUS ~= "down" then
		return
	end
	
	if MOUSE_X > XMin and MOUSE_X < XMin+36 and MOUSE_Y > YMin and MOUSE_Y < YMin+31 then
		if(fse_flying==0) then
			if(StartButtonTimer<=os.clock()) then
				command_once("fse/flight/start")
			else
				-- do nothing until timer runs out
			end
		else
			StartButtonTimer=os.clock()+3
			command_once("fse/flight/finish")
		end
		RESUME_MOUSE_CLICK = false
	end
	if MOUSE_X > XMin+90 and MOUSE_X < XMin+120 and MOUSE_Y > YMin+5 and MOUSE_Y < YMin+25 then
		command_once("fse/flight/cancelArm")
		showCancelC=true
		RESUME_MOUSE_CLICK = false
	end
	if MOUSE_X > XMin+50 and MOUSE_X < XMin+70 and MOUSE_Y > YMin+5 and MOUSE_Y < YMin+25 then
		if(fse_connected==0) then
			command_once("fse/server/connect")
		else
			command_once("fse/flight/cancelConfirm")
		end
		RESUME_MOUSE_CLICK = false
	end
	if MOUSE_X > XMin+5 and MOUSE_X < XMax-5 and MOUSE_Y > YMin+35 and MOUSE_Y < YMax-5 then
		command_once("fse/window/toggle")
		RESUME_MOUSE_CLICK = false
	end
end
--________________________________________________________--
