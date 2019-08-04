

FSE_HUD

TOGFox

REQUIRES: tf_common_functions.lua placed into the \FlyWithLua\Modules folder

Notes: You can reposition the HUD by adjusting these two lines:

local intHudXStart = 15

local intHudYStart = 475

Location 0,0 is the bottom left corner of your screen. If you want to move the HUD up, then increase Y. If you want to move the HUD to the right/centre, then increase X. Suggest you increment by values of 50 or 75 unless you know what you're doing.

Notes: If you don't like the hot-spot marker then you can set this value to zero:

bolShowHotSpot = 1 --Change this to zero if you don't like the marker

Notes: Audible alerts are OFF by default. VR pilots might want to turn them on by editing the script (carefully!)

Change these lines (row 40, 41 and 42):

local intActionTypeConnect = ACTION_AUTORESOLVE

local intActionTypeRegisterFlight = ACTION_AUTORESOLVE

local intActionTypeEndflight = ACTION_AUTORESOLVE

To this:

local intActionTypeConnect = ACTION_AUTORESOLVE + ACTION_ATCDEFAULT

local intActionTypeRegisterFlight = ACTION_AUTORESOLVE +ACTION_ATCDEFAULT

local intActionTypeEndflight = ACTION_AUTORESOLVE + ACTION_ATCDEFAULT

--v0.10

-- Adjusted fuel calculations

-- Stopped auto-register from registering a flight while sim is paused

-- Added audible alarm if auto-end flight fails to work

--v0.12
--		Added park brake = on when checking ot end flight
--		Tweaked the fuel conversion to gallons
--v0.13
--		Flight time is now FSE flight time
