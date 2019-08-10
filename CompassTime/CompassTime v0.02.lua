-- Compass Time
-- TOGFox
-- v0.01: Skismo: what you doing in here?

local fltOrigin = 1565350862

--==========================================================

-- Compute the difference in seconds between local time and UTC.
local function get_timezone()
  local now = os.time()
  return os.difftime(now, os.time(os.date("!*t", now)))
end
timezone = get_timezone()

-- Return a timezone string in ISO 8601:2000 standard form (+hhmm or -hhmm)
local function get_tzoffset(timezone)
  local h, m = math.modf(timezone / 3600)
  return string.format("%+.4d", 100 * h + 60 * m)
end
tzoffset = get_tzoffset(timezone)
print("hey " .. tzoffset)

-- return the timezone offset in seconds, as it was on the time given by ts
-- Eric Feliksik
local function get_timezone_offset(ts)
	local utcdate   = os.date("!*t", ts)
	local localdate = os.date("*t", ts)
	localdate.isdst = false -- this is the trick
	return os.difftime(os.time(localdate), os.time(utcdate))
end

--=========================================================

fltCurrentOSTime = os.time()

delta = fltCurrentOSTime - fltOrigin
delta = delta * (20/24)

fltNewTime = fltOrigin + delta
fltNewHours = os.date("%H", NewTime)
fltNewMinutes = os.date("%M", NewTime)
fltNewZulu = (fltNewHours * 3600) + (60* fltNewMinutes)		--Local zulu is measured in seconds from midnight
print(fltNewZulu)

fltTimeZoneAdjustment = string.sub(tzoffset,1,3)	
print(fltTimeZoneAdjustment)
fltNewZulu = fltNewZulu - (fltTimeZoneAdjustment * 60 * 60 )	--convert offest to seconds and adjust zulu
print(fltNewZulu)

if fltNewZulu > 86400 then
	fltNewZulu = fltNewZulu - 86400
end
if fltNewZulu < 0 then
	fltNewZulu = fltNewZulu + 86400
end

local zulu_t = dataref_table("sim/time/zulu_time_sec")
zulu_t[0] = fltNewZulu










