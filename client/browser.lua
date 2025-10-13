local craftium = require("craftium")
local dns = require("dnsapi")
local mchttp = require("mchttp")
local basalt = require("/basalt")

local state = {}
state.mchttp = mchttp
state.bookmark = nil
state.frame = basalt.getMainFrame()
    :initializeState("booked_site", nil, true, "/states/BaseFrame.state")
function handleCCHTTP(url)
    local addr, err = dns.lookup(url,5)
    if addr then
        local firstSlash = string.find(url, "/")
        if not firstSlash then firstSlash = "/" end
        local result = mchttp.request(addr,80,nil,string.sub(url, firstSlash),"GET",5)
        if result.body then
            local browserFrame = browserFrameWidget(result.body, state.frame)
            if state.browser then state.browser:destroy() end
            state.browser = browserFrame
            return browserFrame
        end
    end
end
function handleFILE(path)
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
function handleHTTP(url)

end
function handleURL(url)
    local urlPieces = {}
    local n = 1
    url = url .. "://"
    for s in string.gmatch(url,  "(.-)(".."://"..")" ) do
        urlPieces[n] = s
        n = n + 1
    end
    if urlPieces[1] == "file" then
        state.browser = handleFILE(urlPieces[2])
    elseif urlPieces[1] == "http" then
        state.browser = handleHTTP(urlPieces[2])
    elseif urlPieces[1] == "cchttp" then
        state.browser = handleCCHTTP(urlPieces[2])
    else
        state.browser = handleFILE("/cchttp/client/error.ccml")
    end
    if not state.browser then
        state.browser = handleFILE("/cchttp/client/error.ccml")
    end
end
function addressBarWidget(frame)
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
            local state = state.frame:getState("booked_site")
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
        end)
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
                handleURL(url)
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
            local bookedState = state.frame:getState("booked_site")
            if bookedState == address:getText() then
                state.frame:setState("booked_site", nil)
                bookmark:setBackground(colors.black)
                    :setForeground(colors.white)

            else
                state.frame:setState("booked_site", address:getText())
                bookmark:setBackground(colors.white)
                    :setForeground(colors.black)
            end
        end)
    if state.frame:getState("booked_site") then
        address:setText(state.frame:getState("booked_site"))
    end
    return widget
end
function browserFrameWidget(data, frame)
    local widget = frame:addContainer()
        :setWidth("{parent.width}")
        :setHeight("{parent.height - 1}")
        :setBackground(colors.white)
        :setForeground(colors.black)
        :setPosition(1, 2)
    craftium.startInstance(data, widget, state.mchttp)
    return widget
    
end

function main()
    
    if state.frame:getState("booked_site") then
        handleURL(state.frame:getState("booked_site"))
    else
        handleURL("file://example.ccml")
    end
    state.addressBar = addressBar
    local addressBar = addressBarWidget(state.frame)
    basalt.run()
end
main()
--     local addr, err = dns.lookup(arg[1],5)
--     if addr then
--         print(addr)
--         local result = mchttp.request(addr,80,nil,"/","GET",5)
--         if result.status == 176 then error(result.body,0) end
--         local browserFrame = browserFrameWidget(result.body,state.frame,mchttp)
--         local addressBar = addressBarWidget(state.frame)
--         basalt.run()
--     else
--         error(err,0)
--     end
-- end
