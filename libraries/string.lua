local StringUtil = {}

function StringUtil:GenerateString(Length: number)
	local String = ""
	for i = 1, Length do
		String = String .. string.char(math.random(33, 126))
	end
	return String
end

function StringUtil:GenerateBytes(Length: number)
	local bytecode = "0x"
	for i = 1, Length do
		bytecode = bytecode .. string.format("%x", math.random(0, 15))
	end
	return bytecode
end

return StringUtil