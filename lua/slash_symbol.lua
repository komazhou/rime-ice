-- lua/slash_symbol.lua
local function translator(input, seg, env)
    -- 拦截 / 加小写字母或数字的输入（例如 /fh, /1, /10）
    if not string.match(input, "^/[0-9a-z]+$") then return end

    -- 提取后缀并拼装上游真实的配置路径
    local suffix = string.sub(input, 2)
    local config_path = "punctuator/symbols/V" .. suffix
    
    local config = env.engine.schema.config
    local list = config:get_list(config_path)

    -- 若上游配置存在该节点，则遍历并输出为候选符号
    if list then
        for i = 0, list.size - 1 do
            local val = list:get_value_at(i).value
            yield(Candidate("symbol", seg.start, seg._end, val, "符号"))
        end
    end
end

return translator