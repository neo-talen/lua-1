--[[----------------------------------------------------------------------------
Author:
	hongtianlong@corp.netease.com
Data:
	2022/3/14
Description:

----------------------------------------------------------------------------]]--

-- sizeof TSting: 24 + len(string) + 1 ('/0')  // Byte
--[[ sizeof Table: 56 (empty table)  // Byte
			simple array: 56 + sizeof(TValue) * array_num  // sizeof(TValue) == 16
			hash array: 56 + sizeof(Node) * node_num  // sizeof(Node) == 24 / 32  rehash 1, 2, 3, 5, 8, 9 ...
	--]]--

n = 1000

--package.cpath = package.cpath .. ';C:/Users/hongtianlong/.PyCharm2019.1/config/plugins/intellij-emmylua/classes/debugger/emmy/windows/x64/?.dll'
--function start_debug()
--	local dbg = require('emmy_core')
--	dbg.tcpConnect('localhost', 9988)
--	dbg.breakHere()
--
--end


function test_same_short_string()
	collectgarbage('collect')
	local before = collectgarbage('count')
	collectgarbage('stop')
	for i = 1, n do
		local s = '012345678901234567890123456789' .. '0'
	end
	local after = collectgarbage('count')
	funcname = debug.getinfo(1).name
	print(funcname..' memory used: ' .. (after - before).."K")
end


function test_same_long_string()
	collectgarbage('collect')
	local before = collectgarbage('count')
	collectgarbage('stop')
	for i = 1, n do
		local s = '01234567890123456789012345678901234567890123456789' .. '0'
	end
	local after = collectgarbage('count')
	funcname = debug.getinfo(1).name
	print(funcname..' memory used: ' .. (after - before).."K")
end

function test_different_short_string()
	collectgarbage('collect')
	local before = collectgarbage('count')
	collectgarbage('stop')
	for i = 1, n do
		local s = '012345678901234567890123456789' .. i
	end
	local after = collectgarbage('count')
	funcname = debug.getinfo(1).name
	print(funcname..' memory used: ' .. (after - before).."K")
end


function test_different_long_string()
	collectgarbage('collect')
	local before = collectgarbage('count')
	collectgarbage('stop')
	for i = 1, n do
		local s = '01234567890123456789012345678901234567890123456789' .. i
	end
	local after = collectgarbage('count')
	funcname = debug.getinfo(1).name
	print(funcname..' memory used: ' .. (after - before).."K")
end


function test_different_short_string_with_format()
	collectgarbage('collect')
	local before = collectgarbage('count')
	collectgarbage('stop')
	for i = 1, n do
		local s = string.format('012345678901234567890123456789%d', i)
	end
	local after = collectgarbage('count')
	funcname = debug.getinfo(1).name
	print(funcname..' memory used: ' .. (after - before).."K")
end


function test_different_long_string_with_format()
	collectgarbage('collect')
	local before = collectgarbage('count')
	collectgarbage('stop')
	for i = 1, n do
		local s = string.format('01234567890123456789012345678901234567890123456789%d', i)
	end
	local after = collectgarbage('count')
	funcname = debug.getinfo(1).name
	print(funcname..' memory used: ' .. (after - before).."K")
end


--start_debug()

--test_different_short_string()
--test_different_long_string()
--collectgarbage('collect')
--test_different_short_string_with_format()
--test_different_long_string_with_format()


function test_table_mem_inc()
	t = {}
	text = 'diff mem'  --25 + #text(9) = 34 bytes
	collectgarbage('collect')
	collectgarbage('stop')
	for i = 1, 64 do
		--collectgarbage('collect')
		local s = {i}
		local before = collectgarbage('count')
		--collectgarbage('stop')
		t[i] = s
		local cur = collectgarbage('count')
		diff = (cur - before) * 1024  -- KB to Bytes
		print(text, i, string.format('%10d Bytes', diff))
	end

end


function test_table_mem_all()

	text = 'diff mem'  --25 + #text(9) = 34 bytes
	collectgarbage('collect')
	collectgarbage('stop')
	local before = collectgarbage('count')
	t = {}
	for i = 1, 64 do
		t[i] = i
	end
	local cur = collectgarbage('count')
	diff = (cur - before) * 1024  -- KB to Bytes
	print(text, i, string.format('%10d Bytes', diff))

end


function test_table_mem_all_2()

	text = 'diff mem'  --25 + #text(9) = 34 bytes
	collectgarbage('collect')
	collectgarbage('stop')
	local before = collectgarbage('count')
	tab = {}
	for i = 1, 63 do
		tab[#tab + 1] = i
	end
	local cur = collectgarbage('count')
	diff = (cur - before) * 1024  -- KB to Bytes
	print(text, i, string.format('%10d Bytes', diff))

end

-- test_table_mem_inc()
-- test_table_mem_all()
-- test_table_mem_all_2()


function test_table_rehash()
	t = {1, 2, 3, 4, 5}  -- array size 8
	for i, v in pairs(t) do print(i, v) end
	print(#t)
	print('-----------')
	t[4]=nil
	collectgarbage('collect')
	for i, v in pairs(t) do print(i, v) end
	print(#t)
	print('-----------')

	--t[8] = 500  --
	--for i, v in pairs(t) do print(i, v) end
	--print(#t)
	--print('-----------')

	t[100] = 10000
	for i, v in pairs(t) do print(i, v) end
	print(#t)
	print('-----------')


end


test_table_rehash()
