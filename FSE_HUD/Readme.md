FSE_HUD

v0.02

v0.03

v0.04 

    Auto-end flight works better

TOGFox

REQUIRES: tf_common_functions.lua placed into the \FlyWithLua\Modules folder

Notes: You can reposition the HUD by adjusting these two lines:

local intHudXStart = 15

local intHudYStart = 475


Location 0,0 is the bottom left corner of your screen. If you want to move the HUD up, then increase Y. If you want to move the HUD to the right/centre, then increase X. Suggest you increment by values of 50 or 75 unless you know what you're doing.