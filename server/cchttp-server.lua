local api = {}

api.MODEM = peripheral.find("modem")
local function getListener(listeners, path, method)
    for i, listener in ipairs(listeners) do
        if 
                (listener.route == path or string.match("^"..string.gsub(listener.route, "\\*", ".*").."$", path)) 
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
                if packet.host ~= os.getComputerID then goto continue_loop end
                local listener = getListener(lib.listeners, packet.path, packet.method)
                if not listener then goto continue_loop end
                print("Method "..packet.method.." called at "..packet.path)
                _ = {
                    "GET" = function()
                        local ret = listener.func(packet)
                        modem.transmit(100, port, {
                            status = 200,
                            headers = {["content-type"]=ret.contentType},
                            body = ret.body,
                            recipient = packet.from
                        })
                    end, "POST" = function()
                        listener.func(packet)
                    end
                }[packet.method]()
                -- if packet.host == os.computerID() then
                --     print("ID RIGHT")
                --     local success = false
                --     for i,a in ipairs(lib.listeners) do
                --         print(a.route,a.method,a.func)
                --         if a.route == packet.path then
                --             print("ROUTE RIGHT")
                --             if a.method == packet.method then
                --                 print("METHOD RIGHT")
                --                 if packet.method == "POST" then
                --                     a.func(packet)
                --                     success = true
                --                     break
                --                 elseif packet.method == "GET" then
                --                     print("METHOD GET")
                --                     local ret = a.func(packet)
                --                     modem.transmit(100,port,{
                --                         status = 200,
                --                         headers = {["content-type"]=ret.contentType},
                --                         body = ret.body,
                --                         recipient = packet.from
                --                     })
                --                     success = true
                --                     break
                --                 end
                --             end
                --         elseif string.gmatch(a.packet, "^"..string.gsub(a.route, "\\*", ".*").."$") then
                --             print("Hit wildcard !")

                --         end
                --     end
                -- end
            end
            ::continue_loop::
        end
    end
    local obj = {listeners={}}
    setmetatable(obj,{__index = lib})
    return lib
end

return api
