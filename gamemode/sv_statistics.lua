
function GM:SetupStatisticsTables()
	local res = sql.Query([[CREATE TABLE IF NOT EXISTS mu_round(id INTEGER PRIMARY KEY, timePlayed UNSIGNED INT, numPlayers UNSIGNED INT)]])
	if res then
		print(res)
		if type(res) == "table" then
			PrintTable(res)
		end
	elseif res == false then
		print("Stats SQL error: " .. sql.LastError())
	end
end

function GM:RefreshStatisticsTables()
	local res = sql.Query([[DROP TABLE mu_round]])
	if res then
		print(res)
		if type(res) == "table" then
			PrintTable(res)
		end
	elseif res == false then
		print("Stats SQL error: " .. sql.LastError())
	end
	self:SetupStatisticsTables()
end

function GM:AddRoundStatistic(secondsPlayed, numPlayers)
	local code = [[INSERT INTO mu_round(timePlayed, numPlayers) VALUES(%1, %2)]]
	code = code:gsub("%%1", sql.SQLStr(tonumber(secondsPlayed) or 0, true), 1)
	code = code:gsub("%%2", sql.SQLStr(tonumber(numPlayers) or 0, true), 1)
	local res = sql.Query(code)
	if res == false then
		print("Stats SQL error: " .. sql.LastError())
		return
	end
end

function comma_value(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(tostring(n),'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

local function formatf(str, ...)
	local i = 1
	local args = {...}
	str = str:gsub("%%([^1-9%.A-z]*)([^A-z%.]*)%.?([^A-z%.]*)([A-z])", function (f, a, c, t)
		-- print(f, a, c, t)
		local tl = t:lower()
		local flags = {}
		for i = 1, #f do
			flags[f:sub(i, i)] = true
		end
		local res = "notype:" ..  tostring(tl)
		local value = args[i]
		if tl == "d" then
			value = math.floor(tonumber(value or 0) or 0)
			res = tostring(math.abs(value))
		elseif tl == "f" then
			value = tonumber(value or 0) or 0
			if c == nil || c == "" then
				res = tostring(value)
			else
				local pow = 10 ^ (math.max(1, tonumber(c or 1) or 1))
				res = tostring(math.Round(math.abs(value) * pow) / pow)
				local a, b = res:match("([^%.]*)%.([^%.]*)")
				local padding = tonumber(c or 0) or 0
				if a then
					if #b < padding then
						res = res .. ("0"):rep(padding - #b)
					end
				else
					res = res .. "." .. ("0"):rep(padding)
				end
			end
		elseif tl == "s" then
			res = tostring(value or "") or ""
		end
		local pre = ""
		if tl == "d" || tl == "f" then
			if flags[","] then
				res = comma_value(res)
			end
			if value >= 0 then
				if flags[" "] then
					pre = " "
				elseif flags["+"] then
					pre = "+"
				end
			else
				pre = "-"
			end
		end
		if flags["0"] then
			local padding = tonumber(a or 0) or 0
			if #res + #pre < padding then
				res = ("0"):rep(padding - (#res + #pre)) .. res
			end
		else
			local padding = tonumber(a or 0) or 0
			if #res < padding then
				if flags["-"] then
					res = res .. (" "):rep(padding - #res)
				else
					res = (" "):rep(padding - #res) .. res
				end
			end
		end
		res = pre .. res
		i = i + 1
		return res
	end)
	return str
end

local function printf(str, ...)
	print(formatf(str, ...))
end

concommand.Add("mu_stats_print", function ()
	local code = [[SELECT * FROM mu_round LIMIT 100]]
	local res = sql.Query(code)
	if res == false then
		print("Stats SQL error: " .. sql.LastError())
		return
	end
	if res then
		printf("|%5s|%7s|%10s|", "Round", "Players", "Time")
		for k, v in pairs(res) do
			printf("|%5d|%7d|%10f|", v.id, v.numPlayers, v.timePlayed)
		end
	end
end)