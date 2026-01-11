local craftium = require("craftium")
local dns = require("dnsapi")
local cchttp = require("cchttp")
local basalt = require("/basalt")

local state = {}

peripheral.find("modem", rednet.open)

state.indicator = "disconnected" -- "disconnected", "connecting", "connected"
state.cchttp = cchttp
state.http = http
state.bookmark = nil
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
    state.bookmark = data.bookmark
    state.cookies = data.cookies
end

local function saveConfig()
    if not fs.exists("/.config") then
        return
    end
    local handle = fs.open("/.config/ccsurf.json", "w")
    if not handle then return end
    local data = {
        bookmark = state.bookmark,
        cookies = state.cookies
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
local function addressBarWidget(frame)
    local bookmark = {}
    local widget = frame:addContainer()
        :setWidth("{parent.width}")
        :setHeight(1)
        :setBackground(colors.gray)
    local address = widget:addInput()
        :setPlaceholder("cchttp://www.example.fi")
        :setPosition(4, 1)
        :setHeight(1)
        :setWidth("{parent.width - 6}")
        :setForeground(colors.white)
        :setBackground(colors.black)
        :onChange("text", function(self)
            local state = state.bookmark
            if state == self:getText() then
                bookmark:setBackground(colors.white)
                    :setForeground(colors.black)
            else
                bookmark:setBackground(colors.black)
                    :setForeground(colors.white)
            end
        end)
    local close = widget:addButton()
        :setPosition("{parent.width}", 1)
        :setWidth(1)
        :setHeight(1)
        :setText("X")
        :setBackground(colors.red)
        :setForeground(colors.black)
        :onClick(function()
            basalt.stop()
            term.setCursorPos(1,1)
        end)
    local indicator = widget:addContainer()
        :setWidth(1)
        :setHeight(1)
        :setPosition(1, 1)
        :setBackground(colors.green)
    function changeIndicator()
        while true do
            local time = os.clock() * 3
            if state.indicator == "connected" then
                indicator:setBackground(colors.green)
                break
            elseif state.indicator == "disconnected" then
                indicator:setBackground(colors.red)
                break
            else
                if time % 2 < 1 then
                    indicator:setBackground(colors.yellow)
                else
                    indicator:setBackground(colors.black)
                end
            end
            os.sleep(.05)
        end
    end
    local go = widget:addButton()
        :setPosition("{parent.width-2}", 1)
        :setWidth(2)
        :setHeight(1)
        :setText("->")
        :setBackground(colors.green)
        :setForeground(colors.black)
        :onClick(function()
            local url = address:getText()
            if url then
                state.indicator = "connecting"
                basalt.schedule(changeIndicator)
                os.sleep(1)
                local result = handleURL(url)
                if result then
                    state.indicator = "connected"
                else
                    state.indicator = "disconnected"
                end
            end
        end)
    bookmark = widget:addButton()
        :setPosition(2, 1)
        :setWidth(1)
        :setHeight(1)
        :setText("*")
        :setBackground(colors.black)
        :setForeground(colors.white)
        :onClick(function(self)
            local bookedState = state.bookmark
            if bookedState == address:getText() then
                state.bookmark = nil
                bookmark:setBackground(colors.black)
                    :setForeground(colors.white)

            else
                state.bookmark = address:getText()
                bookmark:setBackground(colors.white)
                    :setForeground(colors.black)
            end
        end)
    if state.bookmark then
        address:setText(state.bookmark)
    end
    widget.address = address
    widget.go = go
    widget.bookmark = bookmark
    widget.close = close
    widget.indicator = indicator
    return widget
end
function handleRedirect(url)
    state.indicator = "connecting"
    os.sleep(1)
    local result = handleURL(url)
    if result then
        state.indicator = "connected"
    else
        state.indicator = "disconnected"
    end
end
function browserFrameWidget(data, frame, cookies)
    local widget = frame:addContainer()
        :setWidth("{parent.width}")
        :setHeight("{parent.height - 1}")
        :setBackground(colors.white)
        :setForeground(colors.black)
        :setPosition(1, 2)
    
    craftium.startInstance(data, widget, state.cchttp, state.http, handleRedirect, state.cookies)
    return widget
    
end

local function main()
    print("Meleah Lily's CCSurf v1.0")
    print("All Rights Reserved")
    os.sleep(1)
    if state.bookmark then
        handleURL(state.bookmark)
    else
        handleURL("file://example.ccml")
    end
    local addressBar = addressBarWidget(state.frame)
    state.addressBar = addressBar
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
