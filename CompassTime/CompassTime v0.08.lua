-- origin date/time = 1/Aug/2019  (day 213)


--local currentMonth = os.date("!%m")
--local currentDay = os.date("!%d")
--local currentHour = os.date("!%H")
--local currentMinute = os.date("!%M")

local tf_common_functions = require "tf_common_functions_003"
local zulu_t = dataref_table("sim/time/zulu_time_sec")	

local RunOnce = 0	--Set to 1 to DISABLE

function DIV(a,b)
    return (a - a % b) / b
end

function ignoreme()
	if currentYear == 2020 then
		--next year
		delta = (31 + 30 + 31 + 30 + 31) * 24 * 60	-- remaining minutes in LAST year
		delta = delta + CurrentDayInYear
		
		debugstate = "Alpha"
	end
end

function get_simtimezone()
	dataref("simlocaltimehours", "sim/cockpit2/clock_timer/local_time_hours")
	dataref("simzulutimehours", "sim/cockpit2/clock_timer/zulu_time_hours")
	return simlocaltimehours-simzulutimehours
end

function tf_CompassTimeMain()

	if RunOnce == 0 then
		local OriginDayInYear = 213
		local currentYear = tonumber(os.date("!%Y"))
		local CurrentDayInYear = os.date("!%j")
		local delta = 0		--day difference betwen now (zulu) and the origin
		
		print("Current year: " .. currentYear)
		print("Current day in year: " .. CurrentDayInYear)

		if currentYear == 2019 then
			delta = CurrentDayInYear - OriginDayInYear
			print("Days since origin: " .. delta)
			
			--convert days (delta) into minutes
			delta = (delta * 24 * 60) + (os.date("!%H") *60) + (os.date("!%M"))
			print("Minutes since origin : " .. delta)
			
			--apply a 20 hour day
			delta = delta * (29/24)			-- this is the target number of minutes since origin
			delta = tf_common_functions.round(delta, 0)
			print("Target minutes after adjustment: " .. delta)		
			
			--convert this back to days/hours/mins
			delta = delta % (60*24)			-- 1440 minutes per day
			print("Target total minutes since midnight: " .. delta)
						
			LocalHours = DIV(delta,60)	--target local hours/mins
			print("Target hours since midnight: " .. LocalHours)
			
			LocalMins = delta % LocalHours
			print("Target minutes since midnight: " .. LocalMins)
			
			print("Intended local time: " .. LocalHours .. ":" .. LocalMins)
			
			local TargetLocalTime = delta * 60
			print("Target local sim time (secs): " .. TargetLocalTime)
			
			print("Current local zulu sim time (secs): " .. zulu_t[0])
			
			local SimTimeZone = get_simtimezone()
			print("Sim timezone: " .. SimTimeZone)
			
			print("About to subtract " .. (SimTimeZone * 60 * 60) .. " seconds to reach target local time.")			
			TargetLocalTime = TargetLocalTime - (SimTimeZone * 60 * 60)
			
			zulu_t[0] = TargetLocalTime
			
		else
			print("CompassTime: Script has expired. Aborting.")
		end
		
		RunOnce = 1
	end
end	
	

do_sometimes("tf_CompassTimeMain()")




