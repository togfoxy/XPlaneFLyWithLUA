-- Compass Time
-- TOGFox
-- v0.01: Skismo: what you doing in here?

local fltOrigin = 1565350862

fltCurrentOSTime = os.time()

delta = fltCurrentOSTime - fltOrigin
delta = delta * (20/24)

fltNewTime = fltOrigin + delta
fltNewHours = os.date("%H", NewTime)
fltNewMinutes = os.date("%M", NewTime)
fltNewZulu = (fltNewHours * 3600) + (60* fltNewMinutes)		--Local zulu is measured in seconds from midnight

local zulu_t = dataref_table("sim/time/zulu_time_sec")
zulu_t[0] = fltNewZulu




