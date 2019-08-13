-- Compass Time
-- TOGFox
-- v0.03: Skismo: what you doing in here?
-- v0.04: Fixed, I think.

print("heyh")
local bolCompassTimeActive = 1	--set to zero to deactivate compass time

local tf_common_functions = require "tf_common_functions_003"

function get_timezone()
  local now = os.time()
  return os.difftime(now, os.time(os.date("!*t", now)))
end
local function get_tzoffset(timezone)
  local h, m = math.modf(timezone / 3600)
  return string.format("%+.4d", 100 * h + 60 * m)
end

function get_simtimezone()
	dataref("simlocaltimehours", "sim/cockpit2/clock_timer/local_time_hours")
	dataref("simzulutimehours", "sim/cockpit2/clock_timer/zulu_time_hours")
	return simlocaltimehours-simzulutimehours
end

local fltOrigin = 1565350862	--arbitrary point in the past

local currentYear = os.date("!%Y")
local currentMonth = os.date("!%m")
local currentDay = os.date("!%d")
local currentHour = os.date("!%H")
local currentMinute = os.date("!%M")
local fltCurrentZuluTime = os.time{year=currentYear, month=currentMonth, day=currentDay, hour=currentHour, min=currentMinute}

--print(fltOrigin)
--print(fltCurrentZuluTime)

--get target zulu time based on algorithm
local delta = (fltCurrentZuluTime - fltOrigin) * (20/24)
--print(delta)
delta = tf_common_functions.round(delta, 0)


local targetzulutime = fltOrigin + delta
--print(targetzulutime)

local targetzuluHours = os.date("%H", targetzulutime)
print(targetzuluHours)

local targetzuluMinutes = os.date("%M", targetzulutime)
print(targetzuluMinutes)

local targetSecondsSinceMidnight = (targetzuluHours * 60 * 60) + (targetzuluMinutes * 60)
--print(targetSecondsSinceMidnight)

--Now we have a target time in zulu, make local time same as this, adjusting for timezones
local fltTimeZoneAdjustmentHours = get_simtimezone()
local fltTimeZoneAdjustmentSeconds = (fltTimeZoneAdjustmentHours * 60 * 60)

if bolCompassTimeActive == 1 then
	local zulu_t = dataref_table("sim/time/zulu_time_sec")
	zulu_t[0] = targetSecondsSinceMidnight - fltTimeZoneAdjustmentSeconds
end
