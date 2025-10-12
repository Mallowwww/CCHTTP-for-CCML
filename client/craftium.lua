local api = {}
local basalt = require("basalt")
-- Based on MCHTTP by HHOY
function crawlForNode(node, name)
    if not node then return nil end
    if node.ni == name then return node end
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
    local env = {
        frame = api.frame,
        os = {
            pullEvent = os.pullEvent,
            queueEvent = os.queueEvent,
            startTimer = os.startTimer,
            cancelTimer = os.cancelTimer,
            sleep = sleep,
            time = os.time,
            date = os.date,
        },
        sleep = sleep,
        keys = keys,
        colors = colors,
        colours = colours,
        error = error,
        window = window
    } 
    if mchttp then
        env.mchttp = mchttp
    end
    --local func, err = load(siteData,"site",nil,env)
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
    local customEnv = crawlForNode("env")
    if customEnv and textutils.unserialise(customEnv) then
        for i,j in customEnv do
            if not env[i] then
                env[i] = j
            end
        end
    else if customEnv and textutils.unserialise("{"..customEnv.."}") then
        customEnv = "{"..customEnv.."}"
        for i,j in customEnv do
            if not env[i] then
                env[i] = j
            end
        end
    end
    api.frame:loadXML(siteData, env)
    
end

return api
