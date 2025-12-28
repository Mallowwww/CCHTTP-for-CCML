local craftium = require("craftium")
local dns = require("dnsapi")
local cchttp = require("cchttp")
local basalt = require("/basalt")

local state = {}

peripheral.find("modem", rednet.open)

state.cchttp = cchttp
state.http = http
state.cookies = {}
state.frame = basalt.getMainFrame()
    -- :initializeState("booked_site", nil, true, "/states/BaseFrame.state") -- old state system


local function loadConfig()
    if not fs.exists("/.config") then
        fs.makeDir("/.config")
    end
    local handle = fs.open("/.config/ccsurf.json", "r")
    if not handle then return end
    local data = textutils.unserialiseJSON(handle.readAll())
    if not data then return end
end

local function saveConfig()
    if not fs.exists("/.config") then
        return
    end
    local handle = fs.open("/.config/ccsurf.json", "w")
    if not handle then return end
    local data = {
    }
    
    handle.write(textutils.serialiseJSON(data))

end

local function handleCCHTTP(url)
    local addr, err = dns.lookup(url,5)
    if addr then
        local firstSlash = string.find(url, "/")
        local result = nil
        if not firstSlash then
            result = cchttp.request(addr,80,nil, "/","GET",5)
        else
            result = cchttp.request(addr,80,nil,string.sub(url, firstSlash),"GET",5)
        end
        
        if result and result.body then
            local browserFrame = browserFrameWidget(result.body, state.frame)
            if state.browser then state.browser:destroy() end
            state.browser = browserFrame
            return browserFrame
        end
    end
end
local function handleFILE(path)
    if not path or (not fs.exists(path)) then return end
    local handle = fs.open(path, "r")
    if not handle then return end
    local data = handle.readAll()
    handle.close()
    if (state.browser) then
        state.browser:destroy()
    end
    local browserFrame = browserFrameWidget(data,state.frame)
    return browserFrame

end
local function handleHTTP(url)
    local data = http.get(url)
    if data then
        if state.browser then
            state.browser:destroy()
        end
        return browserFrameWidget(data.readAll(), state.frame)
        
    end
    
end
local function handleURL(url)
    local urlPieces = {}
    local n = 1
    local result = true
    if state.addressBar then
        state.addressBar.address:setText(url)
    end
    url = url .. "://"
    for s in string.gmatch(url,  "(.-)(".."://"..")" ) do
        urlPieces[n] = s
        n = n + 1
    end
    if urlPieces[1] == "file" then
        state.browser = handleFILE(urlPieces[2])
    elseif urlPieces[1] == "http" then
        state.browser = handleHTTP(url)
    elseif urlPieces[1] == "cchttp" then
        state.browser = handleCCHTTP(urlPieces[2])
    else
        result = false
        state.browser = handleFILE("/cchttp/client/error.ccml")
    end
    if not state.browser then
        result = false
        state.browser = handleFILE("/cchttp/client/error.ccml")
    end
    return result
end

function browserFrameWidget(data, frame, cookies)
    local widget = frame:addContainer()
        :setWidth("{parent.width}")
        :setHeight("{parent.height}")
        :setBackground(colors.white)
        :setForeground(colors.black)
        :setPosition(1, 1)
    craftium.startInstance(data, widget, state.cchttp, state.http, handleURL, state.cookies)
    return widget
    
end

local function main()
    print("Meleah Lily's CCSurf v1.0")
    print("All Rights Reserved")
    os.sleep(1)
    if state.bookmark then
        handleURL(state.bookmark)
    else
        handleURL("file://index.ccml")
    end
    basalt.run()
    saveConfig()
end
loadConfig()
main()
--     local addr, err = dns.lookup(arg[1],5)
--     if addr then
--         print(addr)
--         local result = cchttp.request(addr,80,nil,"/","GET",5)
--         if result.status == 176 then error(result.body,0) end
--         local browserFrame = browserFrameWidget(result.body,state.frame,cchttp)
--         local addressBar = addressBarWidget(state.frame)
--         basalt.run()
--     else
--         error(err,0)
--     end
-- end
