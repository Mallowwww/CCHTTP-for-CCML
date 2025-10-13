local craftium = require("craftium")
local dns = require("dnsapi")
local mchttp = require("mchttp")
local basalt = require("/basalt")

if type(arg[1]) ~= "string" then
    error("Argument 1 expected to be string",0)
end
local state = {}
state.bookmark = nil
state.frame = basalt.getMainFrame()
function addressBarWidget(frame)
    local bookmark = {}
    local widget = frame:addContainer()
        :setWidth("{parent.width}")
        :setHeight(1)
        :setBackground(colors.gray)
    local address = widget:addInput()
        :setPlaceholder("www.example.fi")
        :setPosition(4, 1)
        :setHeight(1)
        :setWidth("{parent.width - 6}")
        :setForeground(colors.white)
        :setBackground(colors.black)
        :onChange(function(self)
            local state = bookmark:getState("booked_state")
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
            
        end)
    bookmark = widget:addButton()
        :setPosition(3, 1)
        :setWidth(1)
        :setHeight(1)
        :setText("*")
        :setBackground(colors.black)
        :setForeground(colors.white)
        :initializeState("booked_site", nil, true, "ccml/client/booked_site.state")
        :onClick(function(self)
            self:setState("booked_site", address:getText())
            bookmark:setBackground(colors.white)
                :setForeground(colors.black)
        end)
    return widget
end
function browserFrameWidget(data, frame, mchttp)
    local widget = frame:addContainer()
        :setWidth("{parent.width}")
        :setHeight("{parent.height - 1}")
        :setPosition(1, 2)
    craftium.startInstance(data, widget, mchttp)
end
if fs.exists(arg[1]) then
    
    local handle = fs.open(arg[1],"r")
    local data = handle.readAll()
    handle.close()
    local browserFrame = browserFrameWidget(data,state.frame,mchttp)
    local addressBar = addressBarWidget(state.frame)
    basalt.run()
else
    local addr, err = dns.lookup(arg[1],5)
    if addr then
        print(addr)
        local result = mchttp.request(addr,80,nil,"/","GET",5)
        if result.status == 176 then error(result.body,0) end
        local browserFrame = browserFrameWidget(result.body,state.frame,mchttp)
        local addressBar = addressBarWidget(state.frame)
        basalt.run()
    else
        error(err,0)
    end
end
