--[[
=======================================================================
xnumber_translator.lua
此脚本整合了 98wubi 财务大写的高精度与 xnumber 的多维读法及计算功能。

【来源一：98wubi】
-- 来源 https://github.com/yanhuacuo/98wubi-tables > http://98wb.ysepan.com/
-- 数字、金额大写
-- 原触发前缀默认为 recognizer/patterns/number 的第 2 个字符，即 R（本合并版已兼容 = 等符号触发，并改为读取 xnumber）

【来源二：xnumber】
xnumber.lua: realize a yong-style number typing experience in RIME
usage:
0. this script is intended for xkjd6 but also work for other schemas (may need some custimizations)
1. place this script in `rime\lua`
2. modify `rime\rime.lua` by adding a line like `xnumber_translator = require("xnumber_translator")`
3. modify your schema (like `xkjd6.schema.yaml`) by adding an item like `- lua_translator@xnumber_translator` under the `engine/translators` section
4. re-deploy RIME and enjoy (the default trigger key is `=`)
change log:
v0.0.1(20201010) - initial version written by thXnder(别打脸)
=======================================================================
--]]

local function splitNumPart(str)
    local part = {}
    part.int, part.dot, part.dec = string.match(str, "^(%d*)(%.?)(%d*)")
    return part
end

local function decimal_func(str, posMap, valMap)
    local dec
    posMap = posMap or { [1] = "角", [2] = "分", [3] = "厘", [4] = "毫" }
    valMap = valMap or { [0] = "零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖" }
    if #str > 4 then dec = string.sub(tostring(str), 1, 4) else dec = tostring(str) end
    dec = string.gsub(dec, "0+$", "")

    if dec == "" then return "整" end

    local result = ""
    for pos = 1, #dec do
        local val = tonumber(string.sub(dec, pos, pos))
        if val ~= 0 then result = result .. valMap[val] .. posMap[pos] else result = result .. valMap[val] end
    end
    result = result:gsub(valMap[0] .. valMap[0], valMap[0])
    return result:gsub(valMap[0] .. valMap[0], valMap[0])
end

local function formatNum(num, t)
    local digitUnit, wordFigure
    local result = ""
    num = tostring(num)
    if tonumber(t) < 1 then digitUnit = { "", "十", "百", "千" } else digitUnit = { "", "拾", "佰", "仟" } end
    if tonumber(t) < 1 then
        wordFigure = { "〇", "一", "二", "三", "四", "五", "六", "七", "八", "九" }
    else
        wordFigure = { "零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖" }
    end
    if string.len(num) > 4 or tonumber(num) == 0 then return wordFigure[1] end
    local lens = string.len(num)
    for i = 1, lens do
        local n = wordFigure[tonumber(string.sub(num, -i, -i)) + 1]
        if n ~= wordFigure[1] then result = n .. digitUnit[i] .. result else result = n .. result end
    end
    result = result:gsub(wordFigure[1] .. wordFigure[1], wordFigure[1])
    result = result:gsub(wordFigure[1] .. "$", "")
    result = result:gsub(wordFigure[1] .. "$", "")
    return result
end

local function number2cnChar(num, flag, digitUnit, wordFigure)
    local result = ""
    if tonumber(flag) < 1 then
        digitUnit = digitUnit or { [1] = "万", [2] = "亿" }
        wordFigure = wordFigure or { [1] = "〇", [2] = "一", [3] = "十", [4] = "元" }
    else
        digitUnit = digitUnit or { [1] = "万", [2] = "亿" }
        wordFigure = wordFigure or { [1] = "零", [2] = "壹", [3] = "拾", [4] = "元" }
    end
    local lens = string.len(num)
    if lens < 5 then
        result = formatNum(num, flag)
    elseif lens < 9 then
        result = formatNum(string.sub(num, 1, -5), flag) .. digitUnit[1] .. formatNum(string.sub(num, -4, -1), flag)
    elseif lens < 13 then
        result = formatNum(string.sub(num, 1, -9), flag) .. digitUnit[2] .. formatNum(string.sub(num, -8, -5), flag) .. digitUnit[1] .. formatNum(string.sub(num, -4, -1), flag)
    else
        result = ""
    end

    result = result:gsub("^" .. wordFigure[1], "")
    result = result:gsub(wordFigure[1] .. digitUnit[1], "")
    result = result:gsub(wordFigure[1] .. digitUnit[2], "")
    result = result:gsub(wordFigure[1] .. wordFigure[1], wordFigure[1])
    result = result:gsub(wordFigure[1] .. "$", "")
    if lens > 4 then result = result:gsub("^" .. wordFigure[2] .. wordFigure[3], wordFigure[3]) end
    if result ~= "" then result = result .. wordFigure[4] else result = "数值超限！" end
    return result
end

local function number2zh(num, t)
    local result, wordFigure
    result = ""
    if tonumber(t) < 1 then
        wordFigure = { "〇", "一", "二", "三", "四", "五", "六", "七", "八", "九" }
    else
        wordFigure = { "零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖" }
    end
    if tostring(num) == nil then return "" end
    for pos = 1, string.len(num) do
        result = result .. wordFigure[tonumber(string.sub(num, pos, pos) + 1)]
    end
    result = result:gsub(wordFigure[1] .. wordFigure[1], wordFigure[1])
    return result:gsub(wordFigure[1] .. wordFigure[1], wordFigure[1])
end

-- ================= 新增：xnumber 的多维读法与转换 =================

local function speakLiterally(str, valMap)
    valMap = valMap or {
        [0]="零", "一", "二", "三", "四", "五", "六", "七", "八", "九",
        ["+"]="正", ["-"]="负", ["."]="点", [""]=""
    }
    local tbOut = {}
    for k = 1, #str do
        local v = string.sub(str, k, k)
        v = tonumber(v) or v
        tbOut[k] = valMap[v]
    end
    return table.concat(tbOut)
end

local function speakMillitary(str)
    return speakLiterally(str, {[0]="洞", "幺", "两", "三", "四", "五", "六", "拐", "八", "勾", ["+"]="正", ["-"]="负", ["."]="点", [""]=""})
end

local function baseConverse(str, from, to)
    local str10 = str
    if from == 16 then str10 = string.format("%d", str) end
    local strout = str10
    if to == 16 then strout = string.format("%#x", str10) end
    return strout
end

-- ================= 主处理函数 =================

local function number_translatorFunc(pureNum, rawNum)
    local numberPart = splitNumPart(pureNum)
    local result = {}
    
    -- 1. 基础数字大/小写
    if numberPart.dot ~= "" then
        table.insert(result, { number2cnChar(numberPart.int, 0, { "万", "亿" }, { "〇", "一", "十", "点" }) .. number2zh(numberPart.dec, 0), "〔数字小写〕" })
        table.insert(result, { number2cnChar(numberPart.int, 1, { "萬", "億" }, { "〇", "一", "十", "点" }) .. number2zh(numberPart.dec, 1), "〔数字大写〕" })
    else
        table.insert(result, { number2cnChar(numberPart.int, 0, { "万", "亿" }, { "〇", "一", "十", "" }), "〔数字小写〕" })
        table.insert(result, { number2cnChar(numberPart.int, 1, { "萬", "億" }, { "零", "壹", "拾", "" }), "〔数字大写〕" })
    end

    -- 2. 金额大/小写 (保留 98wb 会计书写补丁)
    table.insert(result, { number2cnChar(numberPart.int, 0) .. decimal_func(numberPart.dec, { [1] = "角", [2] = "分", [3] = "厘", [4] = "毫" }, { [0] = "〇", "一", "二", "三", "四", "五", "六", "七", "八", "九" }), "〔金额小写〕" })

    local number2cnCharInt = number2cnChar(numberPart.int, 1)
    local number2cnCharDec = decimal_func(numberPart.dec, { [1] = "角", [2] = "分", [3] = "厘", [4] = "毫" }, { [0] = "零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖" })
    if string.len(numberPart.int) > 4 and number2cnCharInt:find('^拾[壹贰叁肆伍陆柒捌玖]?') and number2cnCharInt:find('[万亿]') then
        local number2cnCharInt_var = number2cnCharInt:gsub('^拾', '壹拾')
        table.insert(result, { number2cnCharInt_var .. number2cnCharDec , "〔金额大写〕"})
    else
        table.insert(result, { number2cnCharInt .. number2cnCharDec , "〔金额大写〕"})
    end

    -- 3. xnumber 特殊读法 (支持识别正负号)
    table.insert(result, { speakLiterally(rawNum), "〔冷读〕" })
    table.insert(result, { speakMillitary(rawNum), "〔军语〕" })

    return result
end

local function xnumber_translator(input, seg, env)
    -- 动态获取 xnumber 触发键配置，增加空值保护
    local pattern = env.engine.schema.config:get_string('recognizer/patterns/xnumber')
    if pattern and string.len(pattern) >= 2 then
        env.number_keyword = env.number_keyword or string.sub(pattern, 2, 2)
    else
        env.number_keyword = "=" -- 如果未配置，默认兜底使用 =
    end
    
    if env.number_keyword ~= '' and input:sub(1, 1) == env.number_keyword then
        local input2 = string.sub(input, 2) -- 提取触发键之后的字符

        -- 场景A：判断是否为纯数字（允许正负号和小数点）
        if string.match(input2, "^[%+%-]?%d*%.?%d*$") and input2 ~= "" and input2 ~= "+" and input2 ~= "-" and input2 ~= "." then
            -- 提取绝对值部分用于金额运算，原值用于冷读/军语
            local pureNum = string.match(input2, "^[%+%-]?(%d*%.?%d*)$")
            local numberPart = number_translatorFunc(pureNum, input2)
            
            for i = 1, #numberPart do
                yield(Candidate(input, seg.start, seg._end, numberPart[i][1], numberPart[i][2]))
            end

            -- 如果是纯整数，追加十六进制转换
            if string.match(input2, "^[%+%-]?%d+$") then
                yield(Candidate(input, seg.start, seg._end, baseConverse(input2, 10, 16), "〔十六进制〕"))
            end
        else
            -- 场景B：如果不是纯数字，则尝试执行计算 (Calculation)
            local ok, ret = pcall(load, "return "..input2)
            if ok and type(ret) == "function" then
                local calcOk, calcRet = pcall(ret)
                if calcOk and calcRet then
                    yield(Candidate(input, seg.start, seg._end, tostring(calcRet), "〔计算结果〕"))
                end
            end
        end
    end
end

return xnumber_translator