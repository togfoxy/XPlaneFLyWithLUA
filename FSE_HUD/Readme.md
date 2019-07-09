FSE_HUD

TOGFox

v0.02

v0.03

v0.04 

    Auto-end flight works better

v0.05

    Added a hot-spot marker to help guide the mouse

REQUIRES: tf_common_functions.lua placed into the \FlyWithLua\Modules folder

Notes: You can reposition the HUD by adjusting these two lines:

local intHudXStart = 15

local intHudYStart = 475

Location 0,0 is the bottom left corner of your screen. If you want to move the HUD up, then increase Y. If you want to move the HUD to the right/centre, then increase X. Suggest you increment by values of 50 or 75 unless you know what you're doing.

Notes: If you don't like the hot-spot marker then you can set this value to zero:

bolShowHotSpot = 1	--Change this to zero if you don't like the marker
