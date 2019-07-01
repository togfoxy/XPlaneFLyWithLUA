require "graphics"
require "HUD"

dataref("strCraftICAO", "sim/aircraft/view/acf_ICAO")
dataref("fltFlapHandle","sim/flightmodel2/controls/flap_handle_deploy_ratio")
dataref("fltSpeedBrakeRatio", "sim/cockpit2/controls/speedbrake_ratio")
dataref("intGearHandle","sim/cockpit/switches/gear_handle_status")
dataref("intParkBrake","sim/flightmodel/controls/parkbrake")
dataref("fltWheelBrake","sim/cockpit2/controls/left_brake_ratio")
dataref("bolAutopilotOn","sim/cockpit2/autopilot/servos_on")

-- init the HUD
local HUDX = 150
local HUDY = 1000
local HUDWidth = 315
local HUDHeight = 43
HUD.begin_HUD(HUDX, HUDY, HUDWidth, HUDHeight, "tf_DashHUD", "always")

-- Plane model
HUD.create_element("PlaneICAO",0,HUDHeight - 20,HUDWidth,20)
HUD.draw_string(5, 7, 10, strCraftICAO)

-- Six 'switch' pannels
local NumOfPanels = 6
local PanelWidth = 0
local PanelHeight = 21
local flapIndicatorHeight = 20
local flapIndicatorY = 10			--random value

PanelWidth = (HUDWidth/NumOfPanels)

--flaps panel
HUD.create_element("FlapLight",0, HUDHeight - 41, PanelWidth, PanelHeight)
HUD.draw_string(5,7,10, "Flaps")
HUD.create_backlight_indicator(0,PanelHeight - 2,PanelWidth,2, "fltFlapHandle <= 0.1", 0.5,0.5,1,1)
HUD.create_backlight_indicator(0,PanelHeight - (PanelHeight * 0.33) ,PanelWidth,PanelHeight * 0.33, "fltFlapHandle > 0.1 and fltFlapHandle <0.50", 0.5,0.5,1,1)
HUD.create_backlight_indicator(0,PanelHeight - (PanelHeight * 0.66) ,PanelWidth,PanelHeight * 0.66, "fltFlapHandle >= 0.50 and fltFlapHandle <0.70", 0.5,0.5,1,1)
HUD.create_backlight_indicator(0,PanelHeight - (PanelHeight * 1) ,PanelWidth,PanelHeight * 1, "fltFlapHandle >= 0.70", 0.5,0.5,1,1)

--speed brake panel
HUD.create_element("SpeedLight",(PanelWidth * 1),HUDHeight - 41, PanelWidth, PanelHeight)
HUD.draw_string(5,7,10, "Speed")
HUD.create_backlight_indicator(0, PanelHeight - 2, PanelWidth, 2, "fltSpeedBrakeRatio < 0.1", 0.5,0.5,1,1)
HUD.create_backlight_indicator(0, PanelHeight - (PanelHeight * 0.5), PanelWidth, PanelHeight * 0.5, "fltSpeedBrakeRatio >= 0.1 and fltSpeedBrakeRatio < 0.75", 0.5,0.5,1,1)
HUD.create_backlight_indicator(0, PanelHeight - (PanelHeight * 1), PanelWidth, PanelHeight * 1, "fltSpeedBrakeRatio >= 0.75", 0.5,0.5,1,1)

--gear handle panel
HUD.create_element("GearHandle",(PanelWidth * 2),HUDHeight - 41, PanelWidth, PanelHeight)
HUD.draw_string(5,7,10, "Gear")
HUD.create_backlight_indicator(0, PanelHeight - 2, PanelWidth, 2, "intGearHandle < 0.4", 0.5,0.5,1,1)
HUD.create_backlight_indicator(0, PanelHeight - (PanelHeight * 1), PanelWidth, PanelHeight * 1, "intGearHandle >= 0.4", 0.5,0.5,1,1)

--park brake
HUD.create_element("ParkBrake",(PanelWidth * 3),HUDHeight - 41, PanelWidth, PanelHeight)
HUD.draw_string(5,7,10, "Park")
HUD.create_backlight_indicator(0, PanelHeight - 2, PanelWidth, 2, "intParkBrake < 0.4", 0.5,0.5,1,1)
HUD.create_backlight_indicator(0, PanelHeight - (PanelHeight * 1), PanelWidth, PanelHeight * 1, "intParkBrake >= 0.4", 0.5,0.5,1,1)

--wheel brake
HUD.create_element("WheelBrake",(PanelWidth * 4),HUDHeight - 41, PanelWidth, PanelHeight)
HUD.draw_string(5,7,10, "Wheel")
HUD.create_backlight_indicator(0,PanelHeight - 2,PanelWidth,2, "fltWheelBrake <= 0.1", 0.5,0.5,1,1)
HUD.create_backlight_indicator(0,PanelHeight - (PanelHeight * 0.33) ,PanelWidth,PanelHeight * 0.33, "fltWheelBrake > 0.1 and fltWheelBrake <0.50", 0.5,0.5,1,1)
HUD.create_backlight_indicator(0,PanelHeight - (PanelHeight * 0.66) ,PanelWidth,PanelHeight * 0.66, "fltWheelBrake >= 0.50 and fltWheelBrake <0.70", 0.5,0.5,1,1)
HUD.create_backlight_indicator(0,PanelHeight - (PanelHeight * 1) ,PanelWidth,PanelHeight * 1, "fltWheelBrake >= 0.70", 0.5,0.5,1,1)

--autopilot 
HUD.create_element("AutoPilot",(PanelWidth * 5),HUDHeight - 41, PanelWidth, PanelHeight)
HUD.draw_string(5,7,10, "A/P")
HUD.create_backlight_indicator(0, PanelHeight - 2, PanelWidth, 2, "bolAutopilotOn < 0.4", 0.5,0.5,1,1)
HUD.create_backlight_indicator(0, PanelHeight - (PanelHeight * 1), PanelWidth, PanelHeight * 1, "bolAutopilotOn >= 0.4", 0.5,0.5,1,1)













--HUD.create_click_switch(0, 0, 40, 35, "xp_autopilot_mode", 1, 2)


--HUD.draw_string(x,y,fontsize,"string",red,green,blue,alpha

-- finish the HUD
HUD.end_HUD()