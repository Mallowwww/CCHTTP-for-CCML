-- Example server file
local cchttpserver = require("cchttp-server")

local app = cchttpserver.new(80)

local directory = "/cchttp/server"

app:listen("/echo","GET",function(pack)
    return {body=pack.body,contentType="text/plain", status=404}
end)

app:listen("/post","POST",function(pack)
    print("MSG:",pack.body)
end)
app:listen("/*", "GET", function(pack)
    print("Wildcard hit! ", pack.body)
    if pack.path[-1] == "/" then pack.path = string.sub(pack.path, 1, #pack.path) end
    local location = directory.."/"..pack.path
    if fs.isDir(location) then
        location = location.."/index.ccml"
    end
    local status = 200
    
    if not fs.exists(location) or fs.isDir(location) then status = 404 end
    local handle = nil
    if status == 404 then
        handle = fs.open(directory.."/404.ccml", "r")
    else
        handle = fs.open(location, "r")
    end
    local data = nil
    if handle then
        data = handle.readAll()
        handle.close()
    else
        data = ""
    end
    return {body=data,contentType="text/plain", status = status}
end)
app:listen("/", "GET", function(pack)
    print("Got message: ", pack.body)
    local handle = fs.open(directory.."/".."index.ccml", "r")
    local data = handle.readAll()
    handle.close()
    return {body=data,contentType="text/plain", status=200}
end)

app:run()
