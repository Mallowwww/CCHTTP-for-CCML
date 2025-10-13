local craftium = require("craftium")
local dns = require("dnsapi")
local mchttp = require("mchttp")
local basalt = require("/basalt")

if type(arg[1]) ~= "string" then
    error("Argument 1 expected to be string",0)
end
local state = {}
state.frame = basalt.getMainFrame()
function addressBarWidget(frame)
    local widget = frame:addContainer()
        :setWidth("{parent.width}")
        :setHeight(1)
        :setBackground(colors.gray)
    return widget
end
function browserFrameWidget(data, frame, mchttp)
    local widget = frame:addContainer()
        :setWidth("{parent.width}")
        :setHeight("{parent.height - 1}")
        :setY(2)
    craftium.startInstance(data, widget, mchttp)
end
if fs.exists(arg[1]) then
    
    local handle = fs.open(arg[1],"r")
    local data = handle.readAll()
    handle.close()
    craftium.startInstance(data, state.frame)
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
