-- Example server file
local cchttpserver = require("cchttp-server")

local app = cchttpserver.new(80)

local directory = "/cchttp/server"

app:listen("/echo","GET",function(pack)
    return {body=pack.body,contentType="text/plain"}
end)

app:listen("/post","POST",function(pack)
    print("MSG:",pack.body)
end)
app:listen("/*", "GET", function(pack)
    print("Wildcard hit! ", pack.body)
    if pack.path[-1] == "/" then pack.path = string.sub(pack.path, 1, #pack.path) end
    local location = directory.."/"..pack.path..".ccml", "r"
    if not fs.exists(location) then return {body="404",contentType="text/plain"} end
    local handle = fs.open(location, "r")
    local data = handle.readAll()
    handle.close()
    return {body=data,contentType="text/plain"}
end)
app:listen("/", "GET", function(pack)
    print("Got message: ", pack.body)
    local handle = fs.open(directory.."/".."index.ccml", "r")
    local data = handle.readAll()
    handle.close()
    return {body=data,contentType="text/plain"}
end)

app:run()
