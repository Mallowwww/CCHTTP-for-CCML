local api = {}
local basalt = require("/basalt")
-- Based on MCHTTP by HHOY
function crawlForNode(node, name)
    if not node then return nil end
    if node.tag == name then return node end
    if node.children then
        for i,j in pairs(node.children) do
            result = crawlForNode(j, name)
            if result then return result end
        end
    end
    return nil
end
function crawlForNodeFromAttribute(node, attribute, value)
    if not node then return nil end
    if node.attribute[attribute] == value then return node end
    if node.children then
        for i,j in pairs(node.children) do
            result = crawlForNode(j, name)
            if result then return result end
        end
    end
    return nil
end
function api.startInstance(siteData, frame, mchttp)
    api.frame = frame
    local tX,tY = frame:getSize()
    local xml = basalt.getAPI("xml")
    if not xml then
        print("ERROR - XML plugin not found")
        return
    end
    local parsed = xml.parseText(siteData)
    if not parsed then
        print("ERROR - Can't parse xml")
        return
    end
    local env = {
        frame = api.frame,
        os = {
            pullEvent = os.pullEvent,
            queueEvent = os.queueEvent,
            startTimer = os.startTimer,
            cancelTimer = os.cancelTimer,
            sleep = sleep,
            colors = colors,
            time = os.time,
            date = os.date,
        },
        sleep = sleep,
        keys = keys,
        colors = colors,
        colours = colours,
        error = error,
        frame = frame,
        getNode = function(value) 
            for i,j in pairs(parsed) do
                local result = crawlForNodeFromAttribute(j, "id", value) 
                if result then return result end
            end
        end
    } 
    if mchttp then
        env.mchttp = mchttp
    end
    --local func, err = load(siteData,"site",nil,env)
    local customEnv = nil
    for i=1, #parsed do
        local temp = crawlForNode(parsed[i], "env")
        if temp then
            customEnv = temp.value
            break
        end
    end
    local customEnvTable = nil
    if customEnv then 
        customEnvTable = load("return "..string.gsub(customEnv, "%s+", ""), nil, "bt", env) 
    end
    
    if customEnv and customEnvTable then
        for i,j in pairs(customEnvTable) do
            if not env[i] then
                env[i] = j
            end
        end
    end
    api.frame:loadXML(siteData, env)
    
end

return api
