local api = {}
local basalt = require("/basalt")
local dns = require("dnsapi")
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
function crawlForElementWithAttribute(element, attribute, value)
    if not element then return nil end
    if element[attribute] and (element[attribute] == "\""..value.."\"" or element[attribute] == value) then return element end
    
    if element.children then
        for i,j in pairs(element.children) do
            result = crawlForElementWithAttribute(j, attribute, value)
            if result then return result end
        end
    end
    return nil
end
function crawlForElementsWithAttribute(element, attribute, value)
    if not element then return {} end
    if element[attribute] and (element[attribute] == "\""..value.."\"" or element[attribute] == value) then return {element} end
    local temp = {}
    if element.children then
        for i,j in pairs(element.children) do
            result = crawlForElementWithAttribute(j, attribute, value)
            if result then temp = temp:concat(result) end
        end
    end
    return temp
end
function api.startInstance(siteData, frame, cchttp, http, redirect, cookies)
    api.frame = frame
    local tX,tY = frame:getSize()
    local xml = basalt.getAPI("xml")
    if not xml then
        print("ERROR - XML plugin not found")
        return
    end
    local parsed = nil
    pcall(function() parsed = xml.parseText(siteData) end)
    if not parsed then
        print("ERROR - Can't parse xml")
        frame:addLabel()
            :setText("XML parse error:\nAre you trying to load an HTML website?")
            :setWidth("{parent.width}")
            :setHeight("{parent.height}")
            :setAutoSize(false)
        return
    end
    local env = {
        frame = api.frame,
        os = {
            pullEvent = os.pullEvent,
            queueEvent = os.queueEvent,
            startTimer = os.startTimer,
            cancelTimer = os.cancelTimer,
            sleep = os.sleep,
            time = os.time,
            date = os.date,
        },
        sleep = sleep,
        keys = keys,
        colors = colors,
        colours = colours,
        pairs = pairs,
        tostring = tostring,
        type = type,
        error = error,
        textutils = textutils,
        getElement = function(value) 
            local result = crawlForElementWithAttribute(api.frame, "id", value) 
            if result then return result end
            
            return nil
        end
    } 
    if redirect then
        env.redirect = redirect
    end
    if dns then
        env.dns = dns
    end
    if cchttp then
        env.cchttp = cchttp
    end
    if http then
        env.http = http
    end
    if statusCode then
        env.statusCode = statusCode
    end
    if cookies then
        env.cookies = cookies
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
        local temp = "return "..customEnv
        customEnvTable = load(temp, nil, "bt", env)()
    end
    
    if customEnv and customEnvTable then
        for i,j in pairs(customEnvTable) do
            if not env[i] then
                env[i] = j
            end
        end
    end
    api.frame:loadXML(siteData, env)
    if env.onStart and type(env.onStart) == "function" then
        env.onStart()
    end
end

return api
