local api = {}

api.MODEM = peripheral.find("modem")
local function getListener(listeners, path, method)
    for i, listener in ipairs(listeners) do
        if 
                (listener.route == path or string.match("^"..string.gsub(listener.route, "*", ".*").."$", path)) 
                and listener.method == method then
            return listener
        end
    end
end
function api.new(port)
    local lib = {listeners={}}
    function lib:listen(route,method,func)
        print(route,method,func)
        table.insert(lib.listeners,{
            func = func,
            route = route,
            method = method
        })
        
    end

    function lib:run()
        local modem = api.MODEM
        modem.open(port)
        while true do
            local ev = {os.pullEvent()}
            if ev[1] == "modem_message" then
                print("Message In!!!")
                local packet = ev[5]
                if packet.host ~= os.getComputerID() then goto continue_loop end
                local listener = getListener(lib.listeners, packet.path, packet.method)
                if not listener then goto continue_loop end
                print("Method "..packet.method.." called at "..packet.path)
                local temp = ({
                    GET = function()
                        local ret = listener.func(packet)
                        modem.transmit(100, port, {
                            status = ret.status,
                            headers = {["content-type"]=ret.contentType},
                            body = ret.body,
                            recipient = packet.from
                        })
                    end, POST = function()
                        listener.func(packet)
                    end
                })[packet.method]()
            end
            ::continue_loop::
        end
    end
    local obj = {listeners={}}
    setmetatable(obj,{__index = lib})
    return lib
end

return api
